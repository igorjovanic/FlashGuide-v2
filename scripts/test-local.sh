#!/bin/zsh

set -euo pipefail

project="FlashGuideV2.xcodeproj"
scheme="FlashGuideV2"
preferred_runtime="${FLASHGUIDE_SIM_RUNTIME:-iOS 26.3}"
preferred_device="${FLASHGUIDE_SIM_DEVICE:-iPhone 17 Pro}"

extract_device_id() {
  awk '
    match($0, /\(([0-9A-F-]{36})\)/) {
      print substr($0, RSTART + 1, RLENGTH - 2)
    }
  ' | head -n 1
}

list_devices() {
  xcrun simctl list devices
}

booted_device_id="$(
  list_devices |
  awk '
    /^\-\- iOS / { in_ios=1; next }
    /^\-\- / { in_ios=0 }
    in_ios && /iPhone/ && /\(Booted\)/ {
      match($0, /\(([0-9A-F-]{36})\)/)
      if (RSTART > 0) {
        print substr($0, RSTART + 1, RLENGTH - 2)
      }
    }
  ' |
  head -n 1
)"

device_id="$booted_device_id"

if [[ -z "$device_id" ]]; then
  device_id="$(
    list_devices |
    awk '
      $0 == "-- '"$preferred_runtime"' --" { in_preferred_runtime=1; next }
      /^\-\- / { in_preferred_runtime=0 }
      in_preferred_runtime && index($0, "'"$preferred_device"'") > 0 && /\(Shutdown\)/ { print; exit }
    ' |
    extract_device_id
  )"
fi

if [[ -z "$device_id" ]]; then
  device_id="$(
    list_devices |
    awk '
      /^\-\- / { in_ios=0 }
      /^\-\- iOS / { in_ios=1; next }
      in_ios && /iPhone/ && /\(Shutdown\)/ { print; exit }
    ' |
    extract_device_id
  )"
fi

if [[ -z "$device_id" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 1
fi

echo "Running tests on simulator: $device_id"
xcrun simctl shutdown all >/dev/null 2>&1 || true
xcrun simctl boot "$device_id" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$device_id" -b >/dev/null
open -a Simulator --args -CurrentDeviceUDID "$device_id" >/dev/null 2>&1 || true
sleep 2

confirmed_device_id="$(
  list_devices |
  awk '
    index($0, "'"$device_id"'") > 0 && /\(Booted\)/ {
      match($0, /\(([0-9A-F-]{36})\)/)
      if (RSTART > 0) {
        print substr($0, RSTART + 1, RLENGTH - 2)
      }
    }
  ' |
  head -n 1
)"

if [[ -z "$confirmed_device_id" ]]; then
  echo "Simulator failed to stay booted: $device_id" >&2
  exit 1
fi

xcodebuild test -project "$project" -scheme "$scheme" -destination "platform=iOS Simulator,id=$device_id" "$@"
