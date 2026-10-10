#!/system/bin/sh

MODDIR=${0%/*}
SUSFS_MODDIR="$MODDIR"

if [ -f "$MODDIR/lib/common.sh" ]; then
    . "$MODDIR/lib/common.sh"
else
    PATH="$PATH:/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk"
    SUSFS_MODNAME="susfs_guard_lkm"
    SUSFS_SYSFS="/sys/module/$SUSFS_MODNAME"
fi

# 模块 id 就是模块目录名
BOOT_SCRIPT="${BOOT_SCRIPT:-/data/adb/post-fs-data.d/${MODDIR##*/}.sh}"
rm -f "$BOOT_SCRIPT" 2> /dev/null

[ -d "$SUSFS_SYSFS" ] || exit 0

command -v rmmod > /dev/null 2>&1 && rmmod "$SUSFS_MODNAME" > /dev/null 2>&1

exit 0
