#!/system/bin/sh
# 内核模块的加载 / 卸载。
# 依赖：ksud

ko_loaded() {
    [ -d "$SUSFS_SYSFS" ]
}

# load_ko <ko 路径>
load_ko() {
    local _img="$1"
    [ -s "$_img" ] || return 1
    command -v ksud > /dev/null 2>&1 || return 1
    ksud insmod "$_img" > /dev/null 2>&1
    ko_loaded
}

# unload_ko
unload_ko() {
    ko_loaded || return 0
    command -v rmmod > /dev/null 2>&1 || return 1
    rmmod "$SUSFS_MODNAME" > /dev/null 2>&1
    ko_loaded && return 1
    return 0
}
