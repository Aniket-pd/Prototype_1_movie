#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/Prototype_1_movie.xcodeproj"
DERIVED_DATA="$ROOT_DIR/.build"
APP="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Prototype_1_movie.app"
BUNDLE_ID="aniket.Prototype-1-movie"
# Use matching devices so both sides of the demo have the same viewport and
# typography scale. The partner device is a second iPhone 17 simulator.
HOST_DEVICE="${SYNC_TABLE_HOST_DEVICE:-348F53B0-4287-4443-B4B6-38F814731D91}"
PARTNER_DEVICE="${SYNC_TABLE_PARTNER_DEVICE:-56EC6749-7A87-401F-AB7D-FAFA94F7F98E}"
BACKEND_URL="${SYNC_TABLE_BACKEND_URL:-http://localhost:8787}"
SERVER_SCRIPT="$ROOT_DIR/script/demo_server.sh"
SERVER_PID_FILE="$ROOT_DIR/.build/demo-server.pid"

mkdir -p "$DERIVED_DATA"
if [[ "$BACKEND_URL" == "http://localhost:8787" && -f "$SERVER_PID_FILE" ]]; then
  SERVER_PID="$(<"$SERVER_PID_FILE")"
  if kill -0 "$SERVER_PID" 2>/dev/null && [[ "$ROOT_DIR/script/demo_backend.py" -nt "$SERVER_PID_FILE" ]]; then
    kill "$SERVER_PID"
    for _ in {1..30}; do
      kill -0 "$SERVER_PID" 2>/dev/null || break
      sleep 0.1
    done
  fi
fi
if ! curl --silent --fail "$BACKEND_URL/health" >/dev/null; then
  nohup "$SERVER_SCRIPT" >"$ROOT_DIR/.build/demo-server.log" 2>&1 </dev/null &
  echo "$!" >"$SERVER_PID_FILE"
  for _ in {1..30}; do
    curl --silent --fail "$BACKEND_URL/health" >/dev/null && break
    sleep 0.1
  done
fi
curl --silent --request DELETE "$BACKEND_URL/tables" >/dev/null

xcodebuild \
  -project "$PROJECT" \
  -scheme Prototype_1_movie \
  -destination "platform=iOS Simulator,id=$HOST_DEVICE" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

for device in "$HOST_DEVICE" "$PARTNER_DEVICE"; do
  xcrun simctl boot "$device" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$device" -b
  xcrun simctl terminate "$device" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl uninstall "$device" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl install "$device" "$APP"
done

open -a Simulator
xcrun simctl launch "$HOST_DEVICE" "$BUNDLE_ID" --sync-role host --backend-url "$BACKEND_URL"
xcrun simctl launch "$PARTNER_DEVICE" "$BUNDLE_ID" --sync-role partner --backend-url "$BACKEND_URL"

echo "Host and partner launched against $BACKEND_URL"
echo "Backend log: $ROOT_DIR/.build/demo-server.log"
