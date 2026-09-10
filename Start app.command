#!/bin/zsh
cd "${0:A:h}"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
if ! command -v node >/dev/null; then
  echo 'Node.js is needed. See README.md.'
  read '?Press Return to close.'
  exit 1
fi
if [[ ! -x ../work/local-planner ]]; then
  xcrun swiftc -parse-as-library LocalPlanner.swift -o ../work/local-planner || exit 1
fi
if [[ ! -x ../work/calendar-bridge ]]; then
  xcrun swiftc -parse-as-library CalendarBridge.swift -o ../work/calendar-bridge -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker CalendarInfo.plist || exit 1
fi
if curl -fsS http://localhost:5173/api/status >/dev/null 2>&1; then
  open http://localhost:5173
  exit 0
fi
node server.mjs &
app_pid=$!
trap 'kill "$app_pid" 2>/dev/null' EXIT INT TERM
sleep 1
open http://localhost:5173
wait "$app_pid"
