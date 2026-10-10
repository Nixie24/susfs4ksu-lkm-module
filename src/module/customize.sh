#!/system/bin/sh

SKIPMOUNT=true
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=false

MODID=$(sed -n 's/^id=//p' "$MODPATH/module.prop.template" 2> /dev/null | head -n1)
[ -n "$MODID" ] || MODID="susfs4ksu_lkm"
BOOT_D="${BOOT_D:-/data/adb/post-fs-data.d}"

ui_print "SUSFS LKM (susfs4ksu-lkm)"

SUSFS_MODDIR="$MODPATH"
[ -f "$MODPATH/lib/common.sh" ] || abort "! 安装包缺少 lib/common.sh，无法继续。"
. "$MODPATH/lib/common.sh"

KVER=$(kernel_kver)
[ -n "$KVER" ] || abort "! 无法读取内核版本，安装终止。"

ui_print "- 内核版本 : $(uname -r)"
ui_print "- 内核主版本: $KVER"
ui_print "- Android  : $(android_rel_kernel) (API $(getprop ro.build.version.sdk 2> /dev/null))"

_old_dir="/data/adb/modules/$MODID/mods"
_old_ver=$(version_in "$_old_dir")

mkdir -p "$MODPATH/mods" 2> /dev/null
ui_print "- 正在匹配 SUSFS 驱动..."

if [ -n "$_old_ver" ]; then
    ui_print "- 设备上已有驱动: $_old_ver"
fi

ADOPT=1 sh "$MODPATH/update.sh" "$MODPATH"
RC=$?
case "$RC" in
    0) ;;
    1) abort "! 安装失败：无法联网下载驱动。请连网后重新刷入。" ;;
    2) abort "! 安装失败：本机内核不是受支持的 GKI 变体。" ;;
    *) abort "! 安装失败（错误码 $RC）。" ;;
esac

[ -s "$MODPATH/mods/$SUSFS_KO_NAME" ] || abort "! 安装失败：没有取得可用的驱动。"

ui_print "- 安装开机脚本: $BOOT_D/$MODID.sh"
mkdir -p "$BOOT_D" 2> /dev/null
rm -f "$BOOT_D/$MODID.sh" 2> /dev/null
cp -f "$MODPATH/scripts/post-fs-data.sh" "$BOOT_D/$MODID.sh"
chmod 0755 "$BOOT_D/$MODID.sh" 2> /dev/null

render_module_prop "$SUSFS_STATE_OK"

for _f in customize.sh update.sh uninstall.sh status.sh scripts/post-fs-data.sh; do
    [ -f "$MODPATH/$_f" ] && set_perm "$MODPATH/$_f" 0 0 0755
done
[ -f "$MODPATH/mods/$SUSFS_KO_NAME" ] && set_perm "$MODPATH/mods/$SUSFS_KO_NAME" 0 0 0644
[ -f "$MODPATH/module.prop" ] && set_perm "$MODPATH/module.prop" 0 0 0644
set_perm_recursive "$MODPATH/lib" 0 0 0755 0644
set_perm_recursive "$MODPATH/mods" 0 0 0755 0644

ui_print "- 安装成功，请重启设备生效。"
