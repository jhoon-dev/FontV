#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/screenshots
touch artifacts/native-smoke.log
(
  until grep -q 'Font V smoke: native ad rendered' artifacts/native-smoke.log; do sleep 1; done
  adb exec-out screencap -p > artifacts/screenshots/android-native-video.png
) &
SCREENSHOT_PID=$!
cleanup() {
  kill "$SCREENSHOT_PID" 2>/dev/null || true
  adb logcat -d -v brief -s Ads flutter > artifacts/ads-logcat.txt || true
}
trap cleanup EXIT TERM INT
flutter test integration_test/ads_test.dart -d emulator-5554 --verbose 2>&1 | tee artifacts/native-smoke.log
