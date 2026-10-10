#!/system/bin/sh
# 打印当前状态，给 WebUI 读。全部是 k=v，一行一个。
# 前几行是给人直接跑着看的，后面才是给 WebUI 解析的。

SUSFS_BOOT_LOG=status.log
. "${1:-${0%/*}}/lib/bootstrap.sh"

_kver=$(uname -r)
_variant=$(installed_variant)
[ -n "$_variant" ] || _variant="-"
_susfs=$(upstream_version)
_size=0
[ -s "$SUSFS_MODS_DIR/$SUSFS_KO_NAME" ] && _size=$(wc -c < "$SUSFS_MODS_DIR/$SUSFS_KO_NAME" | tr -d ' ')

if ko_loaded; then
    _state="$SUSFS_STATE_OK"
else
    _state="$SUSFS_STATE_FAIL"
fi

log "==== SUSFS LKM 状态 ===="
log "内核版本 : $_kver"
log "GKI 变体 : $_variant"
log "SuSFS 版本: $_susfs"
log "驱动大小 : $_size 字节"
log "加载状态 : $(loaded_label "$_state")"

echo "state=$_state"
echo "state_label=$(state_label "$_state")"
echo "kernel=$_kver"
echo "variant=$_variant"
echo "susfs=$_susfs"
echo "size=$_size"
echo "loaded=$(state_ok "$_state" && echo 1 || echo 0)"
