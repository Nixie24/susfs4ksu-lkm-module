#!/usr/bin/env bash
# 打包：把 src/module 下的模块装进 dist/<id>_<version>.zip。
# 宿主侧脚本，用 bash；模块运行时那些是 POSIX sh，两者别混。

set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SRC/../.." && pwd)"
BUILD="$ROOT/build"
DIST="$ROOT/dist"

KEEP=0
[ "${1:-}" = "--keep" ] && KEEP=1

# 模块 id 写在模板里
ID=$(sed -n 's/^id=//p' "$SRC/module.prop.template" | head -n1)
[ -n "$ID" ] || {
    echo "build: module.prop.template is missing id" >&2
    exit 1
}

# 版本号与 versionCode 的唯一来源，CI 也用它（scripts/version.ts）
command -v node > /dev/null 2>&1 || {
    echo "build: 需要 node 来生成版本号" >&2
    exit 1
}
read -r VERSION VERSION_CODE <<< "$(node "$ROOT/scripts/version.ts")"
[ -n "$VERSION" ] || {
    echo "build: 读不到 package.json 的 version" >&2
    exit 1
}

make_zip() {
    local _out="$1"
    if command -v zip > /dev/null 2>&1; then
        (cd "$BUILD" && zip -q -r "$_out" . -x '.*')
    elif command -v 7z > /dev/null 2>&1; then
        (cd "$BUILD" && 7z a -tzip -bd -y -xr'!.*' "$_out" . > /dev/null)
    else
        echo "build: 需要 zip 或 7z" >&2
        return 1
    fi
}

PAYLOAD=(
    customize.sh
    update.sh
    check.sh
    status.sh
    uninstall.sh
    lib
    scripts
    module.prop.template
)

rm -rf "$BUILD"
mkdir -p "$BUILD" "$DIST"
for f in "${PAYLOAD[@]}"; do
    [ -e "$SRC/$f" ] || {
        echo "build: missing $f" >&2
        exit 1
    }
    cp -r "$SRC/$f" "$BUILD/"
done
# mods/ 是刷入时生成的，但先放进包里让目录结构和文档一致
mkdir -p "$BUILD/mods"
cp -f "$ROOT/README.md" "$ROOT/LICENSE" "$BUILD/" 2> /dev/null || true

# WebUI：KernelSU 约定放在模块根的 webroot/ 下，里面要有 index.html
WEBROOT="$SRC/../webui/dist"
if [ -f "$WEBROOT/index.html" ]; then
    cp -r "$WEBROOT" "$BUILD/webroot"
else
    echo "build: 缺少 webroot（先跑 pnpm --filter webui run build）" >&2
    exit 1
fi

# module.prop 在包里先渲染一份，版本号在这儿烘进去。
# description 开头那段 {status}/{kernel}/{susfs} 要刷入或开机才知道，
# 包里只保留后面固定的说明文字；真正填上由 customize.sh / 开机脚本负责
sed -e "s|{version}|$VERSION|g" \
    -e "s|{versionCode}|$VERSION_CODE|g" \
    -e 's|^\(description=\).*{[A-Za-z]*} |\1|' \
    "$SRC/module.prop.template" > "$BUILD/module.prop"

find "$BUILD" -name '*.sh' -exec chmod 0755 {} +
chmod 0644 "$BUILD/module.prop"

ZIP="$DIST/${ID}_${VERSION}.zip"
rm -f "$ZIP"
make_zip "$ZIP"

[ "$KEEP" = "1" ] || rm -rf "$BUILD"

echo "built: $ZIP"
echo "  id      : $ID"
echo "  version : $VERSION ($VERSION_CODE)"
echo "  size    : $(wc -c < "$ZIP") bytes"
if command -v unzip > /dev/null 2>&1; then
    echo "  contents:"
    unzip -l "$ZIP" | sed -n '4,$p' | sed 's/^/    /'
fi
