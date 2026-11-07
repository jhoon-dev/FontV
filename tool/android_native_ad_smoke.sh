#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts/screenshots
cleanup() {
  adb logcat -d -v brief -s Ads flutter > artifacts/ads-logcat.txt || true
}
trap cleanup EXIT TERM INT
flutter drive --driver=test_driver/native_ads.dart --target=integration_test/ads_test.dart -d emulator-5554 --verbose 2>&1 | tee artifacts/native-smoke.log
