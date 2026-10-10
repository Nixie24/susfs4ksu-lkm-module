#!/system/bin/sh
# 上游 release 的查询与 asset 选址。

# 变体是不是只发在 prerelease 上的 dev 变体
is_dev_variant() {
    case " $SUSFS_VARIANTS_DEV " in
        *" $1 "*) return 0 ;;
    esac
    return 1
}

# ---------------------------------------------------------------------------
# release 信息。同一轮里重复查会命中缓存，换轮次前由调用方清掉临时文件
# ---------------------------------------------------------------------------

# 最新正式版的 release 详情（返回本地 json 路径）
release_json() {
    local _json="$TMP_DIR/.susfs_release.json"
    if [ ! -s "$_json" ]; then
        fetch "https://api.github.com/repos/$SUSFS_REPO/releases/latest" "$_json" || return 1
    fi
    [ -s "$_json" ] || return 1
    echo "$_json"
}

# 最近若干条 release（含 prerelease），给只发在预览版上的 dev 变体用
releases_json() {
    local _json="$TMP_DIR/.susfs_releases.json"
    if [ ! -s "$_json" ]; then
        fetch "https://api.github.com/repos/$SUSFS_REPO/releases?per_page=30" "$_json" || return 1
    fi
    [ -s "$_json" ] || return 1
    echo "$_json"
}

# 从 GitHub 的 json 里取普通字符串字段。GitHub 的 JSON 压成一行，值里不会有
# 转义引号，所以靠 [^"]* 收住；用 .* 会一路贪婪吃到行尾
json_str() {
    grep -oE "\"$2\":\"[^\"]*\"" "$1" 2> /dev/null | head -n1 \
        | sed -e "s|^\"$2\":\"||" -e 's|"$||'
}

# asset_url_in <json 文件> <变体>：从给定 JSON 里扫出该变体的下载地址
asset_url_in() {
    grep -oE '"browser_download_url":"[^"]*/susfs_guard_lkm-'"$2"'\.ko"' "$1" 2> /dev/null \
        | head -n1 \
        | sed -e 's|^"browser_download_url":"||' -e 's|"$||'
}

# 最新正式版的 tag
latest_tag() {
    local _json
    _json=$(release_json) || return 1
    json_str "$_json" tag_name
}

# asset_url <变体>。正式变体只发在最新正式版上；dev 变体只发在 prerelease 上，
# /releases/latest 永远指不到，只能扫列表
asset_url() {
    local _v="$1" _json _url
    if ! is_dev_variant "$_v"; then
        _json=$(release_json) && _url=$(asset_url_in "$_json" "$_v")
        [ -n "$_url" ] && {
            echo "$_url"
            return 0
        }
    fi
    _json=$(releases_json) || return 1
    asset_url_in "$_json" "$_v"
}
