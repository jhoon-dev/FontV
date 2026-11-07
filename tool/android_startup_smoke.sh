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
# Exercise the lazy catalog and inline native-ad platform views as well.
SCREEN_SIZE=$(adb shell wm size | tr -d '\r' | sed -n 's/.*size: //p' | tail -1)
SCREEN_WIDTH=${SCREEN_SIZE%x*}
SCREEN_HEIGHT=${SCREEN_SIZE#*x}
for SCROLL in 1 2 3; do
  adb shell input swipe "$((SCREEN_WIDTH / 2))" "$((SCREEN_HEIGHT * 85 / 100))" "$((SCREEN_WIDTH / 2))" "$((SCREEN_HEIGHT * 35 / 100))" 600
  sleep 2
done
sleep 5
adb logcat -d -v threadtime > artifacts/android-startup.log
adb exec-out screencap -p > artifacts/android-startup.png
APP_PID=$(adb shell pidof app.toolmoa.fontv | tr -d '\r' || true)
test -n "$APP_PID" || { echo 'Font V exited while scrolling the release catalog'; exit 1; }
adb logcat -d --pid="$APP_PID" -v threadtime > artifacts/android-startup-app.log
if grep -E 'FATAL EXCEPTION|Fatal signal|Unhandled Exception' artifacts/android-startup-app.log; then
  exit 1
fi
echo 'Font V release catalog remained responsive after scrolling.'
