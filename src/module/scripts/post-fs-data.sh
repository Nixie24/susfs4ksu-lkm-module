#!/system/bin/sh
# 开机脚本。安装时被拷成 /data/adb/post-fs-data.d/<模块id>.sh，
# 所以脚本自己的文件名就是模块 id，模块目录是 /data/adb/modules/ 下的同名目录。
#
# 纯离线：只加载已经暂存好的 .ko，绝不联网，免得把开机卡住。
# 最后把结果记进 state.json，并更新 module.prop 的 description。

MODDIR="/data/adb/modules/${0##*/}"
MODDIR="${MODDIR%.sh}"

[ -d "$MODDIR" ] || exit 0

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
