#!/system/bin/sh
# 查询上游最新版。输出一行一个 key=value：
#   tag=<上游 tag>
#   variant=<变体> / url=<下载地址>      可重复，按优先级排
# 给 update.sh 和 WebUI 用。查不到可用变体时退出码非 0。

SUSFS_BOOT_LOG=check.log
. "${1:-${0%/*}}/lib/bootstrap.sh"

# stdout 只放机器读的 k=v，人看的日志一律走 stderr（note 见 lib/output.sh）
if ! prepare_tmp "$SUSFS_MODDIR"; then
    note "❌ 找不到可写的工作目录"
    exit 1
fi

# 每次都重新查，别被上一轮留下的缓存骗了
rm -f "$TMP_DIR/.susfs_release.json" "$TMP_DIR/.susfs_releases.json" 2> /dev/null

_tag=$(latest_tag)
if [ -z "$_tag" ]; then
    note "❌ 查询上游失败"
    exit 1
fi
note "上游版本: $_tag"
echo "tag=$_tag"

# 候选：已装的变体排最前（原地升级），再补上根据本机推出来的，去重
_seen=" "
_found=0
for _cand in $(installed_variant) $(device_variants); do
    case "$_seen" in
        *" $_cand "*) continue ;;
    esac
    _seen="$_seen$_cand "

    _url=$(asset_url "$_cand")
    [ -n "$_url" ] || {
        # note "  $_cand 上游没有"
        continue
    }
    note "  $_cand 可用"
    echo "variant=$_cand"
    echo "url=$_url"
    _found=$((_found + 1))
done

if [ "$_found" -eq 0 ]; then
    note "❌ 上游没有本机可用的变体"
    note "   支持: $SUSFS_VARIANTS_STABLE"
    note "   dev : $SUSFS_VARIANTS_DEV"
    exit 1
fi

exit 0
