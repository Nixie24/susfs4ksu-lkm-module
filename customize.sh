#!/system/bin/sh

SKIPMOUNT=true
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=false

MODS_DIR="$MODPATH/mods"
LOADER_DIR="$MODS_DIR"
TMP_DIR="/data/local/tmp"
BOOT_D="${BOOT_D:-/data/adb/post-fs-data.d}"

# The module id, read from our own module.prop rather than taken from the
# installer's environment: the boot script's path and its MODDIR both depend on
# it, and an empty value would drop the script at "post-fs-data.d/.sh".
MODID=$(sed -n 's/^id=//p' "$MODPATH/module.prop" 2>/dev/null | head -n1)
[ -n "$MODID" ] || MODID="susfs4ksu_lkm"

ui_print "=============================="
ui_print "  SUSFS LKM  (susfs4ksu-lkm)"
ui_print "=============================="

# Shared helpers ship inside the zip under lib/, so they are at $MODPATH/lib at
# this point.
if [ -f "$MODPATH/lib/common.sh" ]; then
    . "$MODPATH/lib/common.sh"
else
    abort "! 安装包缺少 lib/common.sh，无法继续。"
fi

# 1. Environment
KVER=$(kernel_kver)
KREL=$(android_rel_kernel)
API=$(getprop ro.build.version.sdk 2>/dev/null)

ui_print "- 内核版本 : $(uname -r)"
ui_print "- 内核主版本: ${KVER:-未知}"
ui_print "- Android  : ${KREL:-未知} (API $API)"

if [ -z "$KVER" ]; then
    abort "! 无法读取内核版本，安装终止。"
fi

# 2. Download and load (must succeed)
mkdir -p "$MODS_DIR" 2>/dev/null

ui_print "- 正在匹配并下载 SUSFS 驱动..."

install_driver "$MODS_DIR"
RC=$?

if [ "$RC" = "1" ]; then
    abort "! 安装失败：无法联网下载驱动。请连网后重新刷入。"
elif [ "$RC" = "2" ]; then
    ui_print "- 内核版本: $(uname -r)"
    abort "! 安装失败：本机内核不是受支持的 GKI 变体。"
fi

# 3. Boot loader in /data/adb/post-fs-data.d/
ui_print "- 安装开机加载脚本: $BOOT_D/$MODID.sh"
mkdir -p "$BOOT_D" 2>/dev/null

rm "$BOOT_D/$MODID.sh" 2>/dev/null

cat >"$BOOT_D/$MODID.sh" <<EOF
#!/system/bin/sh
# Installed by the SUSFS LKM module ($MODID) - do not edit by hand.
# Removed automatically when the module is uninstalled.
# Lives in /data/adb/post-fs-data.d, so it runs before every module's own
# post-fs-data.sh.  Offline by design: it only inserts the staged image.

MODDIR="/data/adb/modules/$MODID"
[ -d "\$MODDIR" ] || exit 0

LOG_DIR="\$MODDIR/log"
mkdir -p "\$LOG_DIR" 2>/dev/null
SUSFS_LOG="\$LOG_DIR/module.log"
TMP_DIR="/data/local/tmp"
LOADER_DIR="\$MODDIR/mods"

. "\$MODDIR/lib/common.sh" 2>/dev/null || exit 0

boot_load "\$MODDIR/mods"
exit 0
EOF

chmod 0755 "$BOOT_D/$MODID.sh" 2>/dev/null

# 4. Permissions / metadata
set_perm_recursive "$MODPATH" 0 0 0755 0644
[ -f "$MODPATH/mods/$SUSFS_KO_NAME" ] && set_perm "$MODPATH/mods/$SUSFS_KO_NAME" 0 0 0644
[ -f "$MODPATH/mods/$SUSFS_LOADER_NAME" ] && set_perm "$MODPATH/mods/$SUSFS_LOADER_NAME" 0 0 0755
for _s in action.sh uninstall.sh; do
    [ -f "$MODPATH/$_s" ] && set_perm "$MODPATH/$_s" 0 0 0755
done

ui_print "- 安装完成。"
