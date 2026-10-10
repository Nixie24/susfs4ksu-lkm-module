#!/system/bin/sh
# 从本机内核推出可能的 GKI 变体。

# "6.1" / uname -r 形如 "6.1.75-android14-11-g...-ab123"
kernel_kver() {
    uname -r 2> /dev/null | cut -d. -f1,2
}

# 从内核 release 串里抠 Android 版本："...-android14-11-..." -> "14"
android_rel_kernel() {
    uname -r 2> /dev/null | sed -n 's/.*-android\([0-9][0-9]*\)-.*/\1/p'
}

# API 级别 -> Android 版本。uname -r 里没有 -androidNN- 时的兜底
android_rel_api() {
    case "$1" in
        30) echo 11 ;;
        31 | 32) echo 12 ;;
        33) echo 13 ;;
        34) echo 14 ;;
        35) echo 15 ;;
        36) echo 16 ;;
        37) echo 17 ;;
        *) echo "" ;;
    esac
}

# 去重后的候选变体列表，按"可能性"降序排列：
# uname 里的标签 -> API 反查 -> 这个内核版本的全部已发布组合。
device_variants() {
    local _kv _seen _v _rel _api_rel

    _kv=$(kernel_kver)
    [ -n "$_kv" ] || return 1
    _seen=" "

    _rel=$(android_rel_kernel)
    if [ -n "$_rel" ]; then
        case "$_seen" in
            *" android${_rel}-${_kv} "*) ;;
            *)
                _seen="$_seen"android"${_rel}-${_kv} "
                echo "android${_rel}-${_kv}"
                ;;
        esac
    fi

    _api_rel=$(android_rel_api "$(getprop ro.build.version.sdk 2> /dev/null)")
    if [ -n "$_api_rel" ]; then
        case "$_seen" in
            *" android${_api_rel}-${_kv} "*) ;;
            *)
                _seen="$_seen"android"${_api_rel}-${_kv} "
                echo "android${_api_rel}-${_kv}"
                ;;
        esac
    fi

    for _v in $SUSFS_VARIANTS_ALL; do
        case "$_v" in
            *"-${_kv}")
                case "$_seen" in
                    *" $_v "*) ;;
                    *)
                        _seen="$_seen$_v "
                        echo "$_v"
                        ;;
                esac
                ;;
        esac
    done
}
