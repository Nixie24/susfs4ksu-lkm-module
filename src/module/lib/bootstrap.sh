#!/system/bin/sh
# 入口脚本共用引导：定位模块目录、准备日志目录、加载 lib/common.sh。
# 由 check.sh / status.sh / update.sh 在开头 source，例如：
#   SUSFS_BOOT_LOG=check.log . "${1:-${0%/*}}/lib/bootstrap.sh"
# source 之后可用：MODDIR、SUSFS_MODDIR、SUSFS_LOG，以及 lib 里的全部函数。

SUSFS_MODDIR="${1:-${0%/*}}"
[ -d "$SUSFS_MODDIR/lib" ] || SUSFS_MODDIR="${0%/*}"
MODDIR="$SUSFS_MODDIR"

mkdir -p "$SUSFS_MODDIR/log" 2> /dev/null
SUSFS_LOG="$SUSFS_MODDIR/log/$SUSFS_BOOT_LOG"

[ -f "$SUSFS_MODDIR/lib/common.sh" ] || {
    echo "❌ 缺少 lib/common.sh" >&2
    exit 1
}
. "$SUSFS_MODDIR/lib/common.sh"
