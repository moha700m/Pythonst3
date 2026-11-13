#!/bin/sh
# Capture the Pythonst3 UI on the four reference iPhone sizes using simctl.
set -eu

APP="${1:?usage: capture_layouts.sh <path-to-Pythonst3.app> [output-dir]}"
OUT="${2:-screenshots}"
BUNDLE_ID="com.moha700m.pythonst3"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$OUT"

RUNTIME="$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["runtimes"]
candidates = [r for r in runtimes if r.get("platform") == "iOS" and r.get("isAvailable", True)]
if not candidates:
    raise SystemExit("No available iOS simulator runtime")
candidates.sort(key=lambda r: r.get("version", ""), reverse=True)
print(candidates[0]["identifier"])
')"

echo "Using simulator runtime: $RUNTIME"

capture() {
    name="$1"
    device_type="$2"
    expected="$3"
    slug="$4"

    udid="$(xcrun simctl create "Pythonst3-${slug}" "$device_type" "$RUNTIME")"
    echo "Created $name ($device_type) -> $udid"

    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b
    xcrun simctl ui "$udid" appearance dark >/dev/null 2>&1 || true
    xcrun simctl status_bar "$udid" override \
        --time "9:41" \
        --batteryState charged \
        --batteryLevel 100 \
        --wifiBars 3 \
        --cellularBars 4 >/dev/null 2>&1 || true

    xcrun simctl install "$udid" "$APP"

    SIMCTL_CHILD_PYTHONST3_HOME=1 \
        xcrun simctl launch "$udid" "$BUNDLE_ID" --pythonst3-home >/dev/null
    sleep 5
    xcrun simctl io "$udid" screenshot "$OUT/$slug-list.png"

    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    SIMCTL_CHILD_PYTHONST3_DEMO=1 \
        xcrun simctl launch "$udid" "$BUNDLE_ID" --pythonst3-demo >/dev/null
    sleep 5
    xcrun simctl io "$udid" screenshot "$OUT/$slug-workspace.png"

    # The launch screen uses the same near-black color as the app, so a fixed
    # sleep can capture the launch screen and look like a failed probe. Wait for
    # the marker that RootView writes once the real UI is on screen.
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true

    CONTAINER="$(xcrun simctl get_app_container "$udid" "$BUNDLE_ID" data 2>/dev/null || true)"
    MARKER=""
    if [ -n "$CONTAINER" ]; then
        MARKER="$CONTAINER/Documents/layout_probe.txt"
        rm -f "$MARKER"
    fi

    SIMCTL_CHILD_PYTHONST3_LAYOUT_PROBE=1 \
        xcrun simctl launch "$udid" "$BUNDLE_ID" --pythonst3-layout-probe >/dev/null

    waited=0
    while [ -n "$MARKER" ] && [ ! -f "$MARKER" ] && [ "$waited" -lt 30 ]; do
        sleep 1
        waited=$((waited + 1))
    done
    sleep 2

    xcrun simctl io "$udid" screenshot "$OUT/$slug-probe.png"

    if [ -n "$MARKER" ] && [ -f "$MARKER" ]; then
        echo "Probe marker: $(cat "$MARKER") (waited ${waited}s)"
    else
        echo "Probe marker: MISSING (probe launch did not reach the app)"
    fi

    swift "$SCRIPT_DIR/pixel_probe.swift" "$OUT/$slug-probe.png" "$expected"
    rm -f "$OUT/$slug-probe.png"

    xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
    xcrun simctl delete "$udid" >/dev/null 2>&1 || true

    python3 - "$OUT/$slug-list.png" "$OUT/$slug-workspace.png" "$expected" <<'PY'
import struct
import sys

expected = sys.argv[3]
for path in sys.argv[1:3]:
    with open(path, "rb") as handle:
        header = handle.read(24)
    width, height = struct.unpack(">II", header[16:24])
    actual = f"{width}x{height}"
    if actual != expected:
        raise SystemExit(f"{path}: expected {expected}, got {actual}")
    print(f"OK {path}: {actual}")
PY
}

capture "iPhone 17 Pro"     "iPhone 17 Pro"               "1206x2622" "iphone-17-pro"
capture "iPhone 17 Pro Max" "iPhone 17 Pro Max"           "1320x2868" "iphone-17-pro-max"
capture "iPhone 16"         "iPhone 16"                   "1179x2556" "iphone-16"
capture "iPhone SE (3rd)"   "iPhone SE (3rd generation)"  "750x1334"  "iphone-se"

echo "Layout screenshots written to $OUT"
