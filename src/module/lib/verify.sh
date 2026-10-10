#!/system/bin/sh
# 文件校验：哈希与格式判定。

# sha256 <文件>
sha256() {
    if command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" 2> /dev/null | cut -d' ' -f1
    elif command -v busybox > /dev/null 2>&1; then
        busybox sha256sum "$1" 2> /dev/null | cut -d' ' -f1
    else
        echo ""
    fi
}

# ELF 魔数校验，挡住 GitHub 的错误页
is_elf() {
    local _magic
    [ -s "$1" ] || return 1
    _magic=$(head -c 4 "$1" 2> /dev/null | od -An -tx1 2> /dev/null | tr -d ' \n')
    [ "$_magic" = "7f454c46" ]
}
