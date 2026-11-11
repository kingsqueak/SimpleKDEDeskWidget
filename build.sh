#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Builds dist/SimpleKDEDeskWidget-<version>.plasmoid (a zip of package/) and stamps
# the version from VERSION into package/metadata.json.
set -e
cd "$(dirname "$0")"
V=$(cat VERSION)
python3 - "$V" <<'PY'
import json, sys
p = "package/metadata.json"
m = json.load(open(p))
if m["KPlugin"]["Version"] != sys.argv[1]:
    m["KPlugin"]["Version"] = sys.argv[1]
    with open(p, "w") as f:
        json.dump(m, f, indent=4)
        f.write("\n")
PY
mkdir -p dist
OUT="dist/SimpleKDEDeskWidget-$V.plasmoid"
rm -f "$OUT"
(cd package && zip -qr -X "../$OUT" . -x '*/__pycache__/*' '*.pyc')
echo "$OUT"
sha256sum "$OUT"
