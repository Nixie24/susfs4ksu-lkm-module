#!/system/bin/sh
# 网络传输：裸抓取与带校验的下载。

# fetch <url> <输出文件>：curl -> wget -> busybox wget
fetch() {
    local _url="$1" _out="$2"
    rm -f "$_out" 2> /dev/null
    if command -v curl > /dev/null 2>&1; then
        curl -fsSL --connect-timeout 15 --retry 3 -A "$SUSFS_UA" -o "$_out" "$_url" 2> /dev/null
    elif command -v wget > /dev/null 2>&1; then
        wget -q -O "$_out" "$_url" 2> /dev/null
    elif command -v busybox > /dev/null 2>&1; then
        busybox wget -q -O "$_out" "$_url" 2> /dev/null
    else
        return 127
    fi
}

# fetch_verified <url> <输出文件>：下载后必须是真正的 ELF，挡住错误页
fetch_verified() {
    local _url="$1" _out="$2"
    [ -n "$_url" ] || return 1
    fetch "$_url" "$_out" && is_elf "$_out"
}
