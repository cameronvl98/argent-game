#!/bin/bash
# Rebuild the web version after editing the game in ~/Downloads/argent
set -e
GAME=~/Downloads/argent
OUT="$(cd "$(dirname "$0")" && pwd)"
cp "$OUT/index.html" /tmp/_argent_index.html 2>/dev/null || true
( cd "$GAME" && rm -f /tmp/argent.love && zip -j -q /tmp/argent.love conf.lua main.lua data.lua )
npx --yes love.js@latest -c -t "Argent" /tmp/argent.love "$OUT"
cp /tmp/_argent_index.html "$OUT/index.html"   # keep our fullscreen page
echo "Rebuilt into $OUT"
