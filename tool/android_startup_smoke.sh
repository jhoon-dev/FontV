#!/usr/bin/env bash
set -euo pipefail
adb install -r artifacts/smoke.apk
adb logcat -c
adb shell am start -W -n app.toolmoa.fontv/.MainActivity
sleep 20
adb logcat -d -v threadtime > artifacts/android-startup.log
adb exec-out screencap -p > artifacts/android-startup.png
if ! adb shell pidof app.toolmoa.fontv; then
  tail -n 160 artifacts/android-startup.log
  echo 'Font V release process exited during startup'
  exit 1
fi
if grep -E 'FATAL EXCEPTION|Fatal signal|Unhandled Exception' artifacts/android-startup.log; then
  echo 'A runtime failure was recorded'
  exit 1
fi
echo 'Font V release remained running after startup.'
