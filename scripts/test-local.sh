#!/bin/zsh

set -euo pipefail

project="FlashGuideV2.xcodeproj"
scheme="FlashGuideV2"

booted_device_id="$(
  xcrun simctl list devices available |
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
    xcrun simctl list devices available |
    awk '
      /^\-\- iOS / { in_ios=1; next }
      /^\-\- / { in_ios=0 }
      in_ios && /iPhone 17/ && /\(Shutdown\)/ {
        match($0, /\(([0-9A-F-]{36})\)/)
        if (RSTART > 0) {
          print substr($0, RSTART + 1, RLENGTH - 2)
        }
      }
      in_ios && /iPhone/ && /\(Shutdown\)/ && first == "" {
        match($0, /\(([0-9A-F-]{36})\)/)
        if (RSTART > 0) {
          first = substr($0, RSTART + 1, RLENGTH - 2)
        }
      }
      END {
        if (first != "") {
          print first
        }
      }
    ' |
    head -n 1
  )"
fi

if [[ -z "$device_id" ]]; then
  echo "No available iPhone simulator found." >&2
  exit 1
fi

echo "Running tests on simulator: $device_id"
xcrun simctl bootstatus "$device_id" -b >/dev/null
xcodebuild test -project "$project" -scheme "$scheme" -destination "id=$device_id"
