#!/bin/bash
# Rebuild the web version after editing the game in ~/Downloads/argent
set -e
GAME=~/Downloads/argent
OUT="$(cd "$(dirname "$0")" && pwd)"
cp "$OUT/index.html" /tmp/_argent_index.html 2>/dev/null || true
( cd "$GAME" && rm -f /tmp/argent.love && zip -j -q /tmp/argent.love conf.lua main.lua data.lua )
npx --yes love.js@latest -c -t "Argent" /tmp/argent.love "$OUT"
cp /tmp/_argent_index.html "$OUT/index.html"   # keep our fullscreen page

# Re-apply the IndexedDB save-persistence patch. Stock love.js only flushes the
# IDBFS mount on 'beforeunload', which is unreliable on Tesla / mobile browsers,
# so saves get lost. We expose Module.FS and also flush on a timer, on pagehide,
# and when the tab is hidden. This runs against the freshly generated love.js.
python3 - "$OUT/love.js" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
old='window.addEventListener("beforeunload",function(event){FS.syncfs(false,function(err){if(err){Module["printErr"](err)}})})'
new=('Module["FS"]=FS;'
     'var __lsync=function(){try{FS.syncfs(false,function(err){if(err){Module["printErr"](err)}})}catch(e){}};'
     'window.addEventListener("beforeunload",__lsync);'
     'window.addEventListener("pagehide",__lsync);'
     'document.addEventListener("visibilitychange",function(){if(document.hidden){__lsync()}});'
     'setInterval(__lsync,4000)')
if 'Module["FS"]=FS;' in s:
    print("save-persistence patch already present"); sys.exit(0)
n=s.count(old)
assert n==1, "save-sync anchor found %d times (expected 1) -- love.js format changed!"%n
open(p,'w').write(s.replace(old,new))
print("applied save-persistence patch to love.js")
PY

echo "Rebuilt into $OUT"
