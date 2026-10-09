#!/system/bin/sh

MODDIR=${0%/*}
# Same id the installer used; read from module.prop so the two cannot drift.
ID=$(sed -n 's/^id=//p' "$MODDIR/module.prop" 2>/dev/null | head -n1)
[ -n "$ID" ] || ID="susfs4ksu_lkm"
SUSFS_MODNAME="susfs_guard_lkm"
SUSFS_SYSFS="${SUSFS_SYSFS:-/sys/module/$SUSFS_MODNAME}"
BOOT_SCRIPT="${BOOT_SCRIPT:-/data/adb/post-fs-data.d/$ID.sh}"
PATH="$PATH:/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk"

# 1. Drop the boot loader so nothing tries to load the driver next boot.
[ -f "$BOOT_SCRIPT" ] && rm -f "$BOOT_SCRIPT" 2>/dev/null

# 2. Take the driver out of the running kernel.  It is filtered out of
#    /proc/modules for every caller including root, so /sys/module/<name> is
#    the only reliable presence check.
[ -d "$SUSFS_SYSFS" ] || exit 0

if command -v ksud >/dev/null 2>&1; then
    ksud rmmod "$SUSFS_MODNAME" >/dev/null 2>&1
fi

if [ -d "$SUSFS_SYSFS" ] && command -v rmmod >/dev/null 2>&1; then
    rmmod "$SUSFS_MODNAME" >/dev/null 2>&1
fi

exit 0
