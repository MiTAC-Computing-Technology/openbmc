#!/bin/bash
#
# Push BMC clock (the time source) to the UBB satellite BMC over Redfish.
# Direction is strictly BMC -> UBB. The satellite Redfish listens on
# 192.168.31.1:80 with AuthType=None (see entity-manager SatelliteController).
#
# Invoked two ways (same idempotent logic):
#   - ubb-timesync.service : once at boot (after network + usb_network)
#   - ubb-timesync.timer   : periodically, to correct drift / later steps
#
set -u

UBB_HOST="${UBB_HOST:-192.168.31.1}"
UBB_PORT="${UBB_PORT:-80}"
IFACE="${UBB_IFACE:-eth-ubb}"
# Skip the write when the UBB is already within this many seconds of the BMC.
# Avoids stepping the satellite clock (and backward jumps in its logs) on every
# tick. Redfish DateTime resolution is 1s, so keep this >= 2.
TOLERANCE_SEC="${UBB_TOLERANCE_SEC:-2}"

BASE="http://${UBB_HOST}:${UBB_PORT}/redfish/v1"
CURL="curl -sS --fail --connect-timeout 3 --max-time 10"

log() { echo "ubb-timesync: $*"; }

# Convert an ISO-8601 timestamp (e.g. 2025-03-06T17:11:21+00:00 or ...Z) to a
# UTC epoch. Pure bash arithmetic: the target's busybox `date` cannot parse
# ISO-8601 (`-d` rejects it, no `-D`). Prints the epoch, or returns 1.
iso_to_epoch() {
    local s="$1" Y Mo D h mi se sign oh om off y m mm era yoe doy doe days
    if [[ "$s" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})(Z|([+-])([0-9]{2}):?([0-9]{2}))?$ ]]; then
        Y=$((10#${BASH_REMATCH[1]})); Mo=$((10#${BASH_REMATCH[2]})); D=$((10#${BASH_REMATCH[3]}))
        h=$((10#${BASH_REMATCH[4]})); mi=$((10#${BASH_REMATCH[5]})); se=$((10#${BASH_REMATCH[6]}))
        sign=${BASH_REMATCH[8]}; oh=${BASH_REMATCH[9]}; om=${BASH_REMATCH[10]}
    else
        return 1
    fi
    # days from civil (Howard Hinnant's algorithm)
    y=$Y; m=$Mo
    (( m <= 2 )) && (( y-- ))
    if (( y >= 0 )); then era=$(( y/400 )); else era=$(( (y-399)/400 )); fi
    yoe=$(( y - era*400 ))
    if (( Mo > 2 )); then mm=$(( Mo-3 )); else mm=$(( Mo+9 )); fi
    doy=$(( (153*mm + 2)/5 + D - 1 ))
    doe=$(( yoe*365 + yoe/4 - yoe/100 + doy ))
    days=$(( era*146097 + doe - 719468 ))
    off=0
    if [ -n "$sign" ]; then
        off=$(( 10#${oh:-0}*3600 + 10#${om:-0}*60 ))
        [ "$sign" = "-" ] && off=$(( -off ))
    fi
    echo $(( days*86400 + h*3600 + mi*60 + se - off ))
}

# 1. Wait (bounded) for the UBB link to exist. usb_network.service + udev
#    rename create eth-ubb; on a cold boot this service may race it.
for _ in $(seq 1 10); do
    ip link show "$IFACE" >/dev/null 2>&1 && break
    sleep 1
done

# UBB is optional on this platform. No iface => nothing to sync; exit 0 so the
# oneshot + 2min timer do not spam OpenBMC.0.1.ServiceFailure via rsyslog
# (non-zero EXIT_STATUS -> /var/log/redfish).
if ! ip link show "$IFACE" >/dev/null 2>&1; then
    log "no UBB interface (${IFACE}); skipping sync"
    exit 0
fi

# 2. Discover the UBB Manager resource. Do not hardcode the id: enumerate the
#    collection and take the first non-self member. Fall back to the common id.
#    eth-ubb can exist (USB gadget) with no satellite peer ¡X treat unreachable
#    Redfish as "board absent", not a service failure.
managers=$($CURL "${BASE}/Managers" 2>/dev/null) || {
    log "UBB Redfish unreachable at ${UBB_HOST}:${UBB_PORT}; skipping sync"
    exit 0
}
mgr=$(printf '%s' "$managers" \
    | grep -o '"@odata\.id"[[:space:]]*:[[:space:]]*"[^"]*/Managers/[^"]*"' \
    | sed -E 's/.*"([^"]*)"$/\1/' \
    | head -n1)
# Fallback: this platform's UBB satellite exposes its manager as "AMC".
[ -z "$mgr" ] && mgr="/redfish/v1/Managers/AMC"
MGR_URL="http://${UBB_HOST}:${UBB_PORT}${mgr}"

# 3. BMC time = source of truth. Emit UTC ISO-8601 with an explicit offset so
#    the satellite is unambiguous regardless of its local TZ.
bmc_iso=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
bmc_epoch=$(date -u +%s)

# 4. Tolerance check. If we can read + parse the UBB clock and it is already
#    close, skip the write. Any parse failure falls through to an unconditional
#    push (safe default).
cur=$($CURL "$MGR_URL" 2>/dev/null \
    | grep -o '"DateTime"[[:space:]]*:[[:space:]]*"[^"]*"' \
    | sed -E 's/.*"([^"]*)"$/\1/' \
    | head -n1)
if [ -n "$cur" ]; then
    ubb_epoch=$(iso_to_epoch "$cur" 2>/dev/null || echo "")
    if [ -n "$ubb_epoch" ]; then
        diff=$(( bmc_epoch - ubb_epoch ))
        diff=${diff#-}
        if [ "$diff" -le "$TOLERANCE_SEC" ]; then
            log "in sync (drift ${diff}s <= ${TOLERANCE_SEC}s), skip ${mgr}"
            exit 0
        fi
        log "drift ${diff}s > ${TOLERANCE_SEC}s, updating ${mgr}"
    fi
fi

# 5. Push BMC time to the UBB Manager.
if $CURL -X PATCH -H "Content-Type: application/json" \
        -d "{\"DateTime\":\"${bmc_iso}\"}" "$MGR_URL" >/dev/null; then
    log "set ${mgr} DateTime=${bmc_iso}"
else
    log "failed to PATCH ${mgr} DateTime"
    exit 1
fi
