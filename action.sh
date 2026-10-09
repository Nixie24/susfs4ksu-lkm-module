#!/system/bin/sh
# =============================================================================
# action.sh - the "操作" (Action) button in the KernelSU manager.
#
# Pulls the newest upstream release for this device's GKI variant and hot-reloads
# the driver if it changed.  With no argument it does a full update; "status"
# just reports without touching anything.
# =============================================================================

MODDIR=${0%/*}
LOG_DIR="$MODDIR/log"
MODS_DIR="$MODDIR/mods"
TMP_DIR="/data/local/tmp"
LOADER_DIR="$MODS_DIR"

mkdir -p "$LOG_DIR" 2>/dev/null
SUSFS_LOG="$LOG_DIR/action.log"

if [ ! -f "$MODDIR/lib/common.sh" ]; then
    echo "❌ 缺少 lib/common.sh，无法运行。"
    exit 1
fi
. "$MODDIR/lib/common.sh"
RC=0

case "${1:-update}" in
    status|check)
        status_report "$MODS_DIR"
        ;;
    reload)
        if ko_loaded && ! unload_ko; then
            log "❌ 无法卸载当前驱动"
            RC=1
        elif load_ko "$MODS_DIR/$SUSFS_KO_NAME"; then
            log "✅ 已重新加载 $SUSFS_KO_NAME"
        else
            log "❌ 重新加载失败"
            RC=1
        fi
        ;;
    update|*)
        log "================= SUSFS LKM 更新 ================="
        log "内核版本: $(uname -r)"
        if update_from_upstream "$MODS_DIR"; then
            log "✅ 完成"
        else
            log "❌ 更新失败"
            RC=1
        fi
        status_report "$MODS_DIR"
        log "================================================"
        ;;
esac

exit $RC
