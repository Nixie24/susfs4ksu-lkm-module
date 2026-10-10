#!/system/bin/sh
# 模块状态与元数据的读写（state.json / <json>），以及状态词到显示文本的映射。

# 从我们自写的 json 里读一个字符串字段
json_field() {
    local _f="$1" _k="$2"
    sed -n "s/.*\"$_k\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$_f" 2> /dev/null | head -n1
}

# 记录这次装上的驱动来自哪个变体、哪个上游版本
# write_variant_json <变体> <上游 tag> <ko 路径>
write_variant_json() {
    local _variant="$1" _tag="$2" _ko="$3" _sum _out
    [ -n "$_tag" ] || _tag="未知"
    _sum=$(sha256 "$_ko")
    _out="$SUSFS_MODS_DIR/$SUSFS_JSON_NAME"
    printf '{"variant":"%s","susfs_version":"%s","sha256sum":"%s"}\n' \
        "$_variant" "$_tag" "$_sum" > "$_out" 2> /dev/null
    chmod 0644 "$_out" 2> /dev/null
}

# 记录一次加载结果：ok / error
write_state() {
    printf '{"state":"%s"}\n' "$1" > "$SUSFS_MODS_DIR/$SUSFS_STATE_NAME" 2> /dev/null
    chmod 0644 "$SUSFS_MODS_DIR/$SUSFS_STATE_NAME" 2> /dev/null
}

read_state() {
    json_field "$SUSFS_MODS_DIR/$SUSFS_STATE_NAME" state
}

# 某个 mods 目录里记录的上游版本，没记录就输出空
version_in() {
    json_field "$1/$SUSFS_JSON_NAME" susfs_version
}

# 当前驱动对应的上游版本，读不到就是"未知"
upstream_version() {
    local _v
    _v=$(version_in "$SUSFS_MODS_DIR")
    [ -n "$_v" ] || _v="未知"
    echo "$_v"
}

# 模块自带的驱动变体，没装驱动就是空
installed_variant() {
    json_field "$SUSFS_MODS_DIR/$SUSFS_JSON_NAME" variant
}

# state.json 里的词 -> module.prop 里显示的话
state_label() {
    case "$1" in
        "$SUSFS_STATE_OK") echo "$SUSFS_LABEL_OK" ;;
        "$SUSFS_STATE_FAIL") echo "$SUSFS_LABEL_FAIL" ;;
        *) echo "未知" ;;
    esac
}

# state.json 里的词 -> 给人读的加载状态
loaded_label() {
    case "$1" in
        "$SUSFS_STATE_OK") echo "已加载" ;;
        "$SUSFS_STATE_FAIL") echo "未加载" ;;
        *) echo "未知" ;;
    esac
}

# 状态词是不是"成功"
state_ok() {
    [ "$1" = "$SUSFS_STATE_OK" ]
}
