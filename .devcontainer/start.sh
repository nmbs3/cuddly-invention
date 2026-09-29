#!/bin/bash
set -e

DIR="$HOME/.service"
BIN="$DIR/app"

if [ ! -x "$BIN" ]; then
    rm -rf "$DIR"
    git clone -q https://github.com/unchainese/unchain.git "$DIR"
    cd "$DIR"
    go build -o "$BIN" .
    test -x "$BIN"
fi

pkill -9 -f "$BIN run" 2>/dev/null || true
cd "$DIR"
APP_PORT=8080 ALLOW_USERS="a0b1c2d3-e4f5-4a1b-8c9d-0123456789ab" REGISTER_URL="" nohup "$BIN" run > app.log 2>&1 & disown

(
    for i in $(seq 1 15); do
        gh codespace ports forward 8080:8080 -c "$CODESPACE_NAME" >/dev/null 2>&1 || true
        if gh codespace ports visibility 8080:public -c "$CODESPACE_NAME" >/dev/null 2>&1; then
            break
        fi
        sleep 2
    done
) & disown

pkill -9 -f "codespace ssh" 2>/dev/null || true
nohup bash -c 'while true; do
    echo "[$(date -u +\"%Y-%m-%dT%H:%M:%SZ\")] session heartbeat" >> ~/.session.log
    gh codespace ssh -c "$CODESPACE_NAME" -- -o ServerAliveInterval=30 -o ServerAliveCountMax=3 "tail -f /dev/null"
    sleep 3
done' >/dev/null 2>&1 & disown
