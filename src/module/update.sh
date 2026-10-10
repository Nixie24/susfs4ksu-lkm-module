#!/system/bin/sh

# 返回码：0 成功 / 1 下载失败（网络）/ 2 KMI 不匹配

SUSFS_BOOT_LOG=update.log
. "${1:-${0%/*}}/lib/bootstrap.sh"

mkdir -p "$SUSFS_MODS_DIR" 2> /dev/null

log "==== SUSFS LKM 更新 ===="
log "内核版本: $(uname -r)"

if ! prepare_tmp "$SUSFS_MODDIR"; then
    log "❌ 找不到可写的工作目录"
    exit 1
fi

if ! command -v curl > /dev/null 2>&1 && ! command -v wget > /dev/null 2>&1 \
    && ! command -v busybox > /dev/null 2>&1; then
    log "❌ 无可用下载工具（curl / wget / busybox 均缺失）"
    exit 1
fi

TARGET="$SUSFS_MODS_DIR/$SUSFS_KO_NAME"
STAGE="$TMP_DIR/susfs_lkm_stage"
BAK="$TMP_DIR/$SUSFS_KO_NAME.bak"
mkdir -p "$STAGE" 2> /dev/null
rm -f "$BAK" 2> /dev/null

fail() {
    log "$1"
    echo "result=fail"
    echo "reason=$2"
    exit "$3"
}

_CHECK_ERR="$TMP_DIR/susfs_check.err"
CHECK_OUT=$(sh "$SUSFS_MODDIR/check.sh" "$SUSFS_MODDIR" 2> "$_CHECK_ERR")
_CHECK_RC=$?
[ -s "$_CHECK_ERR" ] && cat "$_CHECK_ERR"
if [ "$_CHECK_RC" -ne 0 ] || ! printf '%s\n' "$CHECK_OUT" | grep -q '^variant='; then
    fail "❌ 无法从上游获取可用变体，请检查网络" "download" 1
fi

_upstream_tag=$(printf '%s\n' "$CHECK_OUT" | sed -n 's/^tag=//p' | head -n1)

_id=$(sed -n 's/^id=//p' "$SUSFS_MODDIR/module.prop.template" 2> /dev/null | head -n1)
[ -n "$_id" ] || _id="susfs4ksu_lkm"
_old_dir="/data/adb/modules/$_id/mods"
_installed=$(version_in "$_old_dir")

if [ -n "$_upstream_tag" ] && [ "$_installed" = "$_upstream_tag" ]; then
    if [ "${ADOPT:-0}" = "1" ] && [ -s "$_old_dir/$SUSFS_KO_NAME" ]; then
        log "✅ 设备上已是 $_upstream_tag，沿用现有驱动，不下载"
        mkdir -p "$SUSFS_MODS_DIR" 2> /dev/null
        cp -f "$_old_dir/$SUSFS_KO_NAME" "$TARGET"
        [ -s "$_old_dir/$SUSFS_JSON_NAME" ] && cp -f "$_old_dir/$SUSFS_JSON_NAME" "$SUSFS_MODS_DIR/$SUSFS_JSON_NAME"
        chmod 0644 "$TARGET" 2> /dev/null

        if load_ko "$TARGET"; then
            write_state "$SUSFS_STATE_OK"
            render_module_prop "$SUSFS_STATE_OK"
            log "✅ 完成: $(installed_variant)"
            echo "result=ok"
            echo "tag=$_upstream_tag"
            echo "adopted=1"
            exit 0
        fi
        log "  取来的驱动加载失败，改为从上游下载"
        rm -f "$TARGET" 2> /dev/null
    elif ko_loaded; then
        log "✅ 设备上已经是 $_upstream_tag，跳过下载"
        echo "result=ok"
        echo "tag=$_upstream_tag"
        echo "skipped=1"
        exit 0
    fi
fi

_downloaded=0
_swapped=0
_fail="download"

# 把 check.sh 的 variant= / url= 配成 (变体 地址) 对，避免按行号错位
_pairs="$TMP_DIR/susfs_pairs"
: > "$_pairs"
_cand=""
printf '%s\n' "$CHECK_OUT" | while IFS= read -r _line; do
    case "$_line" in
        variant=*) _cand="${_line#variant=}" ;;
        url=*) [ -n "$_cand" ] && printf '%s %s\n' "$_cand" "${_line#url=}" ;;
    esac
done > "$_pairs"

while read -r _cand _url; do
    log "→ 尝试变体: $_cand"

    if ! fetch_verified "$_url" "$STAGE/$SUSFS_KO_NAME"; then
        log "  $_cand 下载失败"
        continue
    fi
    _downloaded=1
    _fail="load"

    _new=$(sha256 "$STAGE/$SUSFS_KO_NAME")
    _old=""
    [ -s "$TARGET" ] && _old=$(sha256 "$TARGET")

    if [ -n "$_new" ] && [ "$_new" = "$_old" ] && ko_loaded; then
        log "✅ 已是最新版本，无需更新"
        rm -f "$STAGE/$SUSFS_KO_NAME" 2> /dev/null
        echo "result=ok"
        echo "tag=$_upstream_tag"
        exit 0
    fi

    if [ "$_swapped" = "0" ]; then
        [ -s "$TARGET" ] && cp -f "$TARGET" "$BAK" 2> /dev/null
        if ko_loaded; then
            if unload_ko; then
                log "  已卸载旧驱动"
            else
                fail "❌ 卸载旧驱动失败，中止更新" "load" 1
            fi
        fi
        _swapped=1
    fi

    if load_ko "$STAGE/$SUSFS_KO_NAME"; then
        mv -f "$STAGE/$SUSFS_KO_NAME" "$TARGET"
        chmod 0644 "$TARGET" 2> /dev/null
        write_variant_json "$_cand" "$_upstream_tag" "$TARGET"
        write_state "$SUSFS_STATE_OK"
        render_module_prop "$SUSFS_STATE_OK"
        rm -f "$BAK" 2> /dev/null
        log "✅ 完成: $_cand"
        echo "result=ok"
        echo "tag=$_upstream_tag"
        exit 0
    fi

    log "  $_cand 下载成功但内核拒绝加载（KMI 不匹配），继续"
    rm -f "$STAGE/$SUSFS_KO_NAME" 2> /dev/null
done < "$_pairs"

if [ -s "$BAK" ]; then
    log "→ 回滚到上一个驱动"
    mv -f "$BAK" "$TARGET"
    if load_ko "$TARGET"; then
        log "已回滚到旧驱动"
        write_state "$SUSFS_STATE_OK"
        render_module_prop "$SUSFS_STATE_OK"
    else
        log "回滚后仍无法加载"
    fi
fi

if [ "$_downloaded" = "0" ]; then
    fail "❌ 无法从上游下载任何驱动，请检查网络" "download" 1
fi

fail "❌ 没有任何变体能被本机内核加载" "load" 2
