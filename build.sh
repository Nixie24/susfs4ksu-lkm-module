#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"
ROOT="$PWD"
BUILD="$ROOT/build"
DIST="$ROOT/dist"
KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

prop() { sed -n "s/^$1=//p" module.prop | head -n1; }
ID=$(prop id)
VERSION=$(prop version)
[ -n "$ID" ] && [ -n "$VERSION" ] || { echo "build: module.prop is missing id/version" >&2; exit 1; }

PAYLOAD=(
    module.prop
    customize.sh
    action.sh
    uninstall.sh
    lib
)

rm -rf "$BUILD"
mkdir -p "$BUILD" "$DIST"
for f in "${PAYLOAD[@]}"; do
    [ -e "$f" ] || { echo "build: missing $f" >&2; exit 1; }
    cp -r "$f" "$BUILD/"
done
# mods/ is created at flash time, but ship it so the tree matches the docs.
mkdir -p "$BUILD/mods"
cp -f README.md LICENSE "$BUILD/" 2>/dev/null || true

# scripts must be executable inside the zip
find "$BUILD" -name '*.sh' -exec chmod 0755 {} +
chmod 0755 "$BUILD/lib"/*.sh 2>/dev/null || true

ZIP="$DIST/${ID}_${VERSION}.zip"
rm -f "$ZIP"
if command -v zip >/dev/null 2>&1; then
    ( cd "$BUILD" && zip -q -r "$ZIP" . -x '.*' )
else
    # Fall back to python's zipfile when `zip` is absent.
    python3 - "$BUILD" "$ZIP" <<'PY'
import os, sys, zipfile
build, out = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk(build):
        for name in files:
            p = os.path.join(root, name)
            z.write(p, os.path.relpath(p, build))
PY
fi

[ "$KEEP" = "1" ] || rm -rf "$BUILD"

echo "built: $ZIP"
echo "  id      : $ID"
echo "  version : $VERSION"
echo "  size    : $(wc -c <"$ZIP") bytes"
command -v unzip >/dev/null 2>&1 && { echo "  contents:"; unzip -l "$ZIP" | sed -n '4,$p' | sed 's/^/    /'; }
