#!/usr/bin/env bash
set -euo pipefail
adb install -r artifacts/smoke.apk
adb logcat -c
for ATTEMPT in 1 2; do
  adb shell am force-stop app.toolmoa.fontv
  adb shell am start -W -n app.toolmoa.fontv/.MainActivity
  sleep 20
  adb logcat -d -v threadtime > artifacts/android-startup.log
  adb exec-out screencap -p > artifacts/android-startup.png
  APP_PID=$(adb shell pidof app.toolmoa.fontv | tr -d '\r' || true)
  if [ -z "$APP_PID" ]; then
    grep -E 'AndroidRuntime|E flutter|F libc|F DEBUG' artifacts/android-startup.log || true
    echo 'Font V release process exited during startup'
    exit 1
  fi
  adb logcat -d --pid="$APP_PID" -v threadtime > artifacts/android-startup-app.log
  if grep -E 'FATAL EXCEPTION|Fatal signal|Unhandled Exception' artifacts/android-startup-app.log; then
    echo 'A Font V runtime failure was recorded'
    exit 1
  fi
  adb shell dumpsys activity activities | grep -E '(mResumedActivity|topResumedActivity).*app.toolmoa.fontv'
  echo "Font V release launch $ATTEMPT remained in the foreground."
done
