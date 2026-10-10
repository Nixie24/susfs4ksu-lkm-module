#!/system/bin/sh

MODDIR="/data/adb/modules/${0##*/}"
MODDIR="${MODDIR%.sh}"

[ -d "$MODDIR" ] || exit 0

[ -e "$MODDIR/disable" ] && exit 0

mkdir -p "$MODDIR/log" "$MODDIR/mods" 2> /dev/null
SUSFS_LOG="$MODDIR/log/module.log"
SUSFS_MODDIR="$MODDIR"

[ -f "$MODDIR/lib/common.sh" ] || exit 0
. "$MODDIR/lib/common.sh" 2> /dev/null || exit 0

if ko_loaded || load_ko "$SUSFS_MODS_DIR/$SUSFS_KO_NAME"; then
    _state="$SUSFS_STATE_OK"
else
    _state="$SUSFS_STATE_FAIL"
    log "加载暂存驱动失败（没有暂存驱动，或者内核更新后 KMI 不匹配）"
    log "请从 WebUI 或手动运行 update.sh 重新获取"
fi

write_state "$_state"
render_module_prop "$_state"

exit 0
