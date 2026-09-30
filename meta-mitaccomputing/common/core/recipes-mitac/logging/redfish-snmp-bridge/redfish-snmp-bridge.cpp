/*
// Copyright (c) 2026 MiTAC Computing Technology Corp.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
*/

// Follows the systemd journal for REDFISH_MESSAGE_ID entries and emits SNMP
// traps for OpenBMC registry Warning/Critical MessageKeys.
// MessageId: Registry[.version...].MessageKey (version digits ignored for lookup).

#include <nlohmann/json.hpp>
#include <phosphor-logging/lg2.hpp>
#include <sdbusplus/bus.hpp>
#include <snmp.hpp>
#include <xyz/openbmc_project/Common/error.hpp>
#include <xyz/openbmc_project/Logging/Entry/common.hpp>

#include <systemd/sd-journal.h>

#include <time.h>

#include <cerrno>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <map>
#include <optional>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <variant>

namespace
{

// Staged by bmcweb package (bmcweb_%.bbappend); source of MessageSeverity.
constexpr const char* openbmcRegistryPath =
    "/usr/share/bmcweb/registries/openbmc.json";

constexpr const char* redfishMessageIdField = "REDFISH_MESSAGE_ID";
constexpr const char* redfishMessageArgsField = "REDFISH_MESSAGE_ARGS";

// Cap UDP-friendly trap message size (OBMCErrorMessage OCTET STRING).
constexpr size_t maxTrapMessageLen = 255;

// Simple storm guard: max traps per fixed minute window.
constexpr unsigned maxTrapsPerMinute = 60;

// Wake periodically to flush rate-limit summaries while idle.
constexpr uint64_t journalWaitTimeoutUs = 30ULL * 1000ULL * 1000ULL; // 30s

// Startup probe only — keep short so a hung SNMP bus name can't stall follow.
constexpr uint64_t snmpProbeTimeoutUs = 2'000'000; // 2s

constexpr const char* snmpService = "xyz.openbmc_project.Network.SNMP";
constexpr const char* snmpManagerPath =
    "/xyz/openbmc_project/network/snmp/manager";
constexpr const char* snmpClientIface = "xyz.openbmc_project.Network.Client";

using Entry = sdbusplus::common::xyz::openbmc_project::logging::Entry;
using InternalFailure =
    sdbusplus::error::xyz::openbmc_project::common::InternalFailure;
using SeverityMap = std::map<std::string, Entry::Level>;

struct SeverityConfig
{
    std::string registryPrefix;
    SeverityMap severities;
};

uint64_t nowMs()
{
    return static_cast<uint64_t>(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch())
            .count());
}

std::string formatRfc3339Ms(uint64_t epochMs)
{
    const time_t sec = static_cast<time_t>(epochMs / 1000ULL);
    const unsigned ms = static_cast<unsigned>(epochMs % 1000ULL);
    std::tm tm{};
    if (gmtime_r(&sec, &tm) == nullptr)
    {
        return {};
    }
    char buf[40];
    const int n = std::snprintf(
        buf, sizeof(buf), "%04d-%02d-%02dT%02d:%02d:%02d.%03uZ",
        tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min,
        tm.tm_sec, ms);
    if (n <= 0 || static_cast<size_t>(n) >= sizeof(buf))
    {
        return {};
    }
    return std::string(buf);
}

// phosphor-snmp getManagers() is not in the installed public headers; mirror
// a minimal ObjectManager probe so we can warn when nothing will be sent.
// nullopt = could not determine (e.g. SNMP bus name not claimed yet on boot).
std::optional<bool> snmpManagersConfigured()
{
    using Value =
        std::variant<bool, uint8_t, int16_t, uint16_t, int32_t, uint32_t,
                     int64_t, uint64_t, std::string>;
    using PropertyMap = std::map<std::string, Value>;
    using InterfaceMap = std::map<std::string, PropertyMap>;
    using ObjectTree =
        std::map<sdbusplus::message::object_path, InterfaceMap>;

    try
    {
        auto bus = sdbusplus::bus::new_default();
        auto method = bus.new_method_call(
            snmpService, snmpManagerPath,
            "org.freedesktop.DBus.ObjectManager", "GetManagedObjects");
        auto reply = bus.call(method, snmpProbeTimeoutUs);
        ObjectTree objects;
        reply.read(objects);
        for (const auto& [path, ifaces] : objects)
        {
            (void)path;
            if (ifaces.contains(snmpClientIface))
            {
                return true;
            }
        }
        return false;
    }
    catch (const std::exception&)
    {
        return std::nullopt;
    }
}

// Prefer truncating MESSAGE_ARGS with a marker so structured fields stay intact.
// messageArgs is the journal REDFISH_MESSAGE_ARGS value (already comma-joined).
std::string buildTrapMessage(const std::string& messageId, Entry::Level level,
                             const std::string& timestamp,
                             std::string_view messageArgs)
{
    const char* sev =
        (level == Entry::Level::Critical) ? "Critical" : "Warning";
    std::ostringstream head;
    head << "REDFISH_MESSAGE_ID=" << messageId;
    head << " REDFISH_SEVERITY=" << sev;
    head << " REDFISH_TIMESTAMP=" << timestamp;
    std::string msg = head.str();

    if (messageArgs.empty())
    {
        if (msg.size() > maxTrapMessageLen)
        {
            msg.resize(maxTrapMessageLen);
        }
        return msg;
    }

    constexpr const char* argsKey = " REDFISH_MESSAGE_ARGS=";
    if (msg.size() + std::strlen(argsKey) >= maxTrapMessageLen)
    {
        if (msg.size() > maxTrapMessageLen)
        {
            msg.resize(maxTrapMessageLen);
        }
        return msg;
    }

    const size_t budget =
        maxTrapMessageLen - msg.size() - std::strlen(argsKey);
    std::string_view args = messageArgs;
    std::string truncated;
    if (args.size() > budget)
    {
        if (budget <= 3)
        {
            return msg;
        }
        truncated.assign(args.substr(0, budget - 3));
        truncated += "...";
        args = truncated;
    }
    msg += argsKey;
    msg.append(args);
    return msg;
}

// Load OpenBMC Redfish registry JSON; keep Warning/Critical MessageKeys only.
std::optional<SeverityConfig> loadSeverityMap(const std::string& path)
{
    std::ifstream in(path);
    if (!in)
    {
        lg2::error("Failed to open OpenBMC registry {PATH}", "PATH", path);
        return std::nullopt;
    }

    nlohmann::json root = nlohmann::json::parse(in, nullptr, false);
    if (root.is_discarded() || !root.contains("Messages") ||
        !root["Messages"].is_object())
    {
        lg2::error("Invalid OpenBMC registry {PATH}", "PATH", path);
        return std::nullopt;
    }

    SeverityConfig cfg;
    // Producers emit OpenBMC.0.1.*; registry Id may be OpenBMC.0.5.0 — prefix only.
    if (root.contains("Id") && root["Id"].is_string())
    {
        const std::string& id = root["Id"].get_ref<const std::string&>();
        const size_t dot = id.find('.');
        cfg.registryPrefix =
            (dot == std::string::npos) ? id : id.substr(0, dot);
    }
    if (cfg.registryPrefix.empty())
    {
        cfg.registryPrefix = "OpenBMC";
    }

    for (auto& [key, entry] : root["Messages"].items())
    {
        if (!entry.is_object() || !entry.contains("MessageSeverity") ||
            !entry["MessageSeverity"].is_string())
        {
            continue;
        }
        const std::string& sev =
            entry["MessageSeverity"].get_ref<const std::string&>();
        if (sev == "Critical")
        {
            cfg.severities.emplace(key, Entry::Level::Critical);
        }
        else if (sev == "Warning")
        {
            cfg.severities.emplace(key, Entry::Level::Warning);
        }
    }

    if (cfg.severities.empty())
    {
        lg2::error(
            "OpenBMC registry {PATH} has zero Warning/Critical MessageKeys",
            "PATH", path);
        return std::nullopt;
    }

    lg2::info(
        "Loaded {COUNT} Warning/Critical MessageKeys registry={REG} from {PATH}",
        "COUNT", cfg.severities.size(), "REG", cfg.registryPrefix, "PATH",
        path);
    return cfg;
}

// MessageId: Registry[.version fields...].MessageKey — key is the last field.
bool splitMessageId(std::string_view messageId, std::string& registry,
                    std::string& messageKey)
{
    const size_t first = messageId.find('.');
    if (first == std::string_view::npos || first == 0)
    {
        return false;
    }
    const size_t last = messageId.rfind('.');
    if (last + 1 >= messageId.size())
    {
        return false;
    }
    registry.assign(messageId.substr(0, first));
    messageKey.assign(messageId.substr(last + 1));
    return true;
}

std::optional<std::string> journalField(sd_journal* journal, const char* name)
{
    const void* data = nullptr;
    size_t length = 0;
    const int rc = sd_journal_get_data(journal, name, &data, &length);
    if (rc < 0)
    {
        return std::nullopt;
    }
    // Payload is "FIELD=value"
    const std::string_view raw(static_cast<const char*>(data), length);
    const size_t eq = raw.find('=');
    if (eq == std::string_view::npos || eq + 1 > raw.size())
    {
        return std::nullopt;
    }
    return std::string(raw.substr(eq + 1));
}

class RedfishSnmpBridge
{
  public:
    explicit RedfishSnmpBridge(SeverityConfig config) :
        config(std::move(config)),
        nextErrorId(static_cast<uint32_t>(nowMs() & 0xffffffffu))
    {
        if (nextErrorId == 0)
        {
            nextErrorId = 1;
        }

        // LOCAL_ONLY: system journal on this BMC (not remote).
        const int rc = sd_journal_open(&journal, SD_JOURNAL_LOCAL_ONLY);
        if (rc < 0)
        {
            throw std::runtime_error(std::string("sd_journal_open failed: ") +
                                     std::strerror(-rc));
        }
    }

    ~RedfishSnmpBridge()
    {
        if (journal != nullptr)
        {
            sd_journal_close(journal);
            journal = nullptr;
        }
    }

    RedfishSnmpBridge(const RedfishSnmpBridge&) = delete;
    RedfishSnmpBridge& operator=(const RedfishSnmpBridge&) = delete;

    void start()
    {
        if (const auto configured = snmpManagersConfigured();
            configured && !*configured)
        {
            lg2::warning(
                "No SNMP managers under {PATH}; sendTrap will be a no-op until one is configured",
                "PATH", snmpManagerPath);
        }

        // Do not replay historical events: cursor after the latest entry.
        int rc = sd_journal_seek_tail(journal);
        if (rc < 0)
        {
            throw std::runtime_error(std::string("sd_journal_seek_tail failed: ") +
                                     std::strerror(-rc));
        }
        // Position on the last entry so the next sd_journal_next waits for new.
        rc = sd_journal_previous(journal);
        if (rc < 0)
        {
            throw std::runtime_error(
                std::string("sd_journal_previous failed: ") +
                std::strerror(-rc));
        }

        lg2::info("Following journal for {FIELD}", "FIELD",
                  redfishMessageIdField);
    }

    // Returns false on fatal journal error so main can exit non-zero.
    bool run()
    {
        while (true)
        {
            const int wr = sd_journal_wait(journal, journalWaitTimeoutUs);
            if (wr < 0)
            {
                lg2::error("sd_journal_wait failed: {ERR}", "ERR",
                           std::strerror(-wr));
                return false;
            }
            if (wr == SD_JOURNAL_NOP)
            {
                flushRateLimitWindow();
                continue;
            }

            while (true)
            {
                const int nr = sd_journal_next(journal);
                if (nr < 0)
                {
                    lg2::error("sd_journal_next failed: {ERR}", "ERR",
                               std::strerror(-nr));
                    return false;
                }
                if (nr == 0)
                {
                    break;
                }
                processJournalEntry();
            }
        }
    }

  private:
    void flushRateLimitWindow()
    {
        using clock = std::chrono::steady_clock;
        const auto now = clock::now();
        if (now - trapWindowStart < std::chrono::minutes(1))
        {
            return;
        }
        if (suppressedInWindow > 0)
        {
            lg2::warning(
                "SNMP trap rate limit: suppressed {N} events in prior {MAX}/min window",
                "N", suppressedInWindow, "MAX", maxTrapsPerMinute);
        }
        trapWindowStart = now;
        trapsInWindow = 0;
        suppressedInWindow = 0;
        rateLimitActive = false;
    }

    bool allowTrap()
    {
        flushRateLimitWindow();
        if (trapsInWindow >= maxTrapsPerMinute)
        {
            if (!rateLimitActive)
            {
                rateLimitActive = true;
                lg2::warning(
                    "SNMP trap rate limit ({MAX}/min, fixed window); suppressing further events this window",
                    "MAX", maxTrapsPerMinute);
            }
            ++suppressedInWindow;
            return false;
        }
        ++trapsInWindow;
        return true;
    }

    void sendRedfishSnmpTrap(const std::string& messageId, Entry::Level level,
                             std::string_view messageArgs, uint64_t eventMs,
                             const std::string& timestamp)
    {
        if (!allowTrap())
        {
            return;
        }

        const std::string payload =
            buildTrapMessage(messageId, level, timestamp, messageArgs);

        const uint32_t errorId = nextErrorId++;
        if (nextErrorId == 0)
        {
            nextErrorId = 1;
        }
        const int32_t sev = static_cast<int32_t>(level);

        try
        {
            // sendTrap: GetManagedObjects + optional sync DNS per manager —
            // can stall this loop (journal wait still bounds idle recovery).
            // Empty manager list returns without error or packets.
            phosphor::network::snmp::sendTrap<
                phosphor::network::snmp::OBMCErrorNotification>(
                errorId, eventMs, sev, payload);
            lg2::info(
                "Dispatched Redfish SNMP notification {MSGID} severity={SEV} id={ID}",
                "MSGID", messageId, "SEV",
                level == Entry::Level::Critical ? "Critical" : "Warning", "ID",
                errorId);
        }
        catch (const InternalFailure& e)
        {
            lg2::error("SNMP trap failed for {MSGID}: {ERR}", "MSGID",
                       messageId, "ERR", e.what());
        }
        catch (const std::exception& e)
        {
            lg2::error("SNMP trap failed for {MSGID}: {ERR}", "MSGID",
                       messageId, "ERR", e.what());
        }
    }

    void processJournalEntry()
    {
        auto messageId = journalField(journal, redfishMessageIdField);
        if (!messageId || messageId->empty())
        {
            return;
        }

        std::string registry;
        std::string messageKey;
        if (!splitMessageId(*messageId, registry, messageKey))
        {
            lg2::debug("Skipping invalid MessageId {MSGID}", "MSGID",
                       *messageId);
            return;
        }

        if (registry != config.registryPrefix)
        {
            return;
        }

        auto it = config.severities.find(messageKey);
        if (it == config.severities.end())
        {
            return;
        }

        const std::string messageArgs =
            journalField(journal, redfishMessageArgsField).value_or("");

        uint64_t usec = 0;
        uint64_t eventMs = nowMs();
        if (sd_journal_get_realtime_usec(journal, &usec) >= 0)
        {
            eventMs = usec / 1000ULL;
        }
        std::string timestamp = formatRfc3339Ms(eventMs);
        if (timestamp.empty())
        {
            timestamp = std::to_string(eventMs);
        }

        sendRedfishSnmpTrap(*messageId, it->second, messageArgs, eventMs,
                            timestamp);
    }

    SeverityConfig config;
    uint32_t nextErrorId{1};
    sd_journal* journal{nullptr};
    std::chrono::steady_clock::time_point trapWindowStart{
        std::chrono::steady_clock::now()};
    unsigned trapsInWindow{0};
    unsigned suppressedInWindow{0};
    bool rateLimitActive{false};
};

} // namespace

int main()
{
    try
    {
        auto cfg = loadSeverityMap(openbmcRegistryPath);
        if (!cfg)
        {
            lg2::error("OpenBMC registry unavailable; exiting");
            return 1;
        }

        RedfishSnmpBridge bridge(std::move(*cfg));
        bridge.start();
        if (!bridge.run())
        {
            return 1;
        }
    }
    catch (const std::exception& e)
    {
        lg2::error("redfish-snmp-bridge failed: {ERR}", "ERR", e.what());
        return 1;
    }
    return 0;
}
