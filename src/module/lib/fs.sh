#!/system/bin/sh
# 工作目录。

prepare_tmp() {
    local _fb="${1:-}"

    mkdir -p "$TMP_DIR" 2> /dev/null
    if [ -d "$TMP_DIR" ] && (: > "$TMP_DIR/.wtest") 2> /dev/null; then
        rm -f "$TMP_DIR/.wtest" 2> /dev/null
        return 0
    fi

    if [ -n "$_fb" ]; then
        mkdir -p "$_fb/.tmp" 2> /dev/null
        if [ -d "$_fb/.tmp" ] && (: > "$_fb/.tmp/.wtest") 2> /dev/null; then
            rm -f "$_fb/.tmp/.wtest" 2> /dev/null
            TMP_DIR="$_fb/.tmp"
            return 0
        fi
    fi

    return 1
}
