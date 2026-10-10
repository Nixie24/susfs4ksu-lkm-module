#!/system/bin/sh
# 输出。ui_print 只在安装器里存在，其它场合退回 echo。

say() {
    if command -v ui_print > /dev/null 2>&1; then
        ui_print "$@"
    else
        echo "$@"
    fi
}

# 打印（或 ui_print）并追加到 $SUSFS_LOG
log() {
    say "$@"
    if [ -n "$SUSFS_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$SUSFS_LOG" 2> /dev/null
    fi
    return 0
}

# 只写日志、给人看，不污染 stdout 上机器可读的 k=v
note() {
    log "$@" >&2
}
