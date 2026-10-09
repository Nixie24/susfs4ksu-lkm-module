#!/system/bin/sh
# =============================================================================
# common.sh - shared helpers for the SUSFS LKM KernelSU module.
#
# Sourced by customize.sh (install) and action.sh (manual update), and by the
# boot loader that customize.sh drops into /data/adb/post-fs-data.d/.  POSIX sh
# only: KernelSU runs these under Android's sh (mksh), so no bash-isms.
#
# Every function that assigns working variables marks them `local`.  Without it
# they share one global scope and a helper silently stomps its caller's
# variables - which is exactly how an earlier version ended up moving the
# staged .ko onto itself.  mksh/ash/dash all support `local`.
#
# The upstream (inforcqb/susfs4ksu-lkm) ships one .ko per GKI pair
# "<android release>-<kernel version>", named susfs_guard_lkm-<pair>.ko, plus a
# freestanding loader "susfs_insmod" for kernels without ksud.  The module's
# registered name is susfs_guard_lkm and it hides itself from /proc/modules for
# every caller including root, so the loaded check is /sys/module/<name>.
# =============================================================================

# KernelSU / APatch / Magisk tool locations (busybox, ksud).
PATH="$PATH:/data/adb/ksu/bin:/data/adb/ap/bin:/data/adb/magisk"

SUSFS_REPO="inforcqb/susfs4ksu-lkm"
SUSFS_MODNAME="susfs_guard_lkm"
SUSFS_KO_NAME="susfs_guard_lkm.ko"
SUSFS_LOADER_NAME="susfs_insmod"
SUSFS_SYSFS="${SUSFS_SYSFS:-/sys/module/$SUSFS_MODNAME}"
SUSFS_UA="susfs4ksu-lkm-module"
SUSFS_LOG="${SUSFS_LOG:-}"
TMP_DIR="${TMP_DIR:-/data/local/tmp}"
LOADER_DIR="${LOADER_DIR:-}"

# GKI variants upstream publishes.  main (stable) + dev (preview, 6.12/6.18).
SUSFS_VARIANTS_STABLE="android12-5.10 android13-5.10 android13-5.15 android14-5.15 android14-6.1 android15-6.6"
SUSFS_VARIANTS_DEV="android16-6.12 android17-6.18"
SUSFS_VARIANTS_ALL="$SUSFS_VARIANTS_STABLE $SUSFS_VARIANTS_DEV"

# -----------------------------------------------------------------------------
# Output
# -----------------------------------------------------------------------------
# ui_print exists only inside KernelSU's installer (customize.sh).  Everywhere
# else (the boot loader, action.sh) fall back to plain echo.
say() {
    if command -v ui_print >/dev/null 2>&1; then
        ui_print "$@"
    else
        echo "$@"
    fi
}

log() {
    say "$@"
    if [ -n "$SUSFS_LOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$SUSFS_LOG" 2>/dev/null
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Workspace
# -----------------------------------------------------------------------------
# Pick a writable scratch dir.  /data/local/tmp is the usual choice but is not
# guaranteed writable (and does not exist at all off-device), so this probes it
# by actually writing a file, then falls back to <fallback>/.tmp.  Returns
# non-zero only when neither is usable.
prepare_tmp() {
    local _fb="${1:-}"

    mkdir -p "$TMP_DIR" 2>/dev/null
    if [ -d "$TMP_DIR" ] && ( : >"$TMP_DIR/.wtest" ) 2>/dev/null; then
        rm -f "$TMP_DIR/.wtest" 2>/dev/null
        return 0
    fi

    if [ -n "$_fb" ]; then
        mkdir -p "$_fb/.tmp" 2>/dev/null
        if [ -d "$_fb/.tmp" ] && ( : >"$_fb/.tmp/.wtest" ) 2>/dev/null; then
            rm -f "$_fb/.tmp/.wtest" 2>/dev/null
            TMP_DIR="$_fb/.tmp"
            return 0
        fi
    fi

    return 1
}

# -----------------------------------------------------------------------------
# Device / variant detection
# -----------------------------------------------------------------------------
# "6.1" from uname -r ("6.1.75-android14-11-g...-ab123" -> "6.1").
kernel_kver() {
    uname -r 2>/dev/null | cut -d. -f1,2
}

# Android release from the kernel release string ("...-android14-11-..." -> "14").
android_rel_kernel() {
    uname -r 2>/dev/null | sed -n 's/.*-android\([0-9][0-9]*\)-.*/\1/p'
}

# API level -> Android release.  Fallback for when uname -r carries no
# -androidNN- tag (common on custom/unsigned kernels).
android_rel_api() {
    case "$1" in
        30) echo 11 ;;
        31|32) echo 12 ;;
        33) echo 13 ;;
        34) echo 14 ;;
        35) echo 15 ;;
        36) echo 16 ;;
        37) echo 17 ;;
        *) echo "" ;;
    esac
}

# Deduplicated, best-first list of candidate GKI variants for this device.
# Priority: exact uname tag -> API-derived -> every published pair for this
# kernel version.  Ordering is a hint only: each candidate is verified by
# actually loading it, because the kernel is the only authority on KMI.
device_variants() {
    local _kv _seen _v _rel _api_rel

    _kv=$(kernel_kver)
    [ -n "$_kv" ] || return 1
    _seen=" "

    # Suggested prefix for this kernel version, e.g. "android14-6.1".
    _rel=$(android_rel_kernel)
    if [ -n "$_rel" ]; then
        case "$_seen" in
            *" android${_rel}-${_kv} "*) ;;
            *) _seen="$_seen"android"${_rel}-${_kv} "; echo "android${_rel}-${_kv}" ;;
        esac
    fi

    _api_rel=$(android_rel_api "$(getprop ro.build.version.sdk 2>/dev/null)")
    if [ -n "$_api_rel" ]; then
        case "$_seen" in
            *" android${_api_rel}-${_kv} "*) ;;
            *) _seen="$_seen"android"${_api_rel}-${_kv} "; echo "android${_api_rel}-${_kv}" ;;
        esac
    fi

    for _v in $SUSFS_VARIANTS_ALL; do
        case "$_v" in
            *"-${_kv}")
                case "$_seen" in
                    *" $_v "*) ;;
                    *) _seen="$_seen$_v "; echo "$_v" ;;
                esac
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
# fetch <url> <outfile>.  curl -> wget -> busybox wget.
fetch() {
    local _url="$1" _out="$2"
    rm -f "$_out" 2>/dev/null
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 15 --retry 3 -A "$SUSFS_UA" -o "$_out" "$_url" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$_out" "$_url" 2>/dev/null
    elif command -v busybox >/dev/null 2>&1; then
        busybox wget -q -O "$_out" "$_url" 2>/dev/null
    else
        return 127
    fi
}

is_elf() {
    local _magic
    [ -s "$1" ] || return 1
    _magic=$(head -c 4 "$1" 2>/dev/null | od -An -tx1 2>/dev/null | tr -d ' \n')
    [ "$_magic" = "7f454c46" ]
}

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" 2>/dev/null | cut -d' ' -f1
    elif command -v busybox >/dev/null 2>&1; then
        busybox sha256sum "$1" 2>/dev/null | cut -d' ' -f1
    else
        echo ""
    fi
}

# Resolve the newest release asset URL for a variant via the GitHub API.
# Needed only for the 6.12/6.18 dev variants, which live on prereleases that
# /releases/latest never points at.
api_asset_url() {
    local _v="$1" _json
    _json="$TMP_DIR/.susfs_releases.json"
    fetch "https://api.github.com/repos/${SUSFS_REPO}/releases?per_page=30" "$_json" || return 1
    [ -s "$_json" ] || return 1
    grep -oE '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]+"' "$_json" \
        | sed 's/.*"\(https[^"]*\)".*/\1/' \
        | grep -E "/susfs_guard_lkm-${_v}\.ko\$" \
        | head -n1
}

is_dev_variant() {
    case " $SUSFS_VARIANTS_DEV " in
        *" $1 "*) return 0 ;;
    esac
    return 1
}

# download_variant <variant> <outfile> : stage a matching .ko, verified as ELF.
# Stable variants ship on the newest non-prerelease, so the direct
# releases/latest/download URL hits without an API call.  Dev variants
# (6.12/6.18) only ever land on prereleases, so they go straight to the API to
# avoid a guaranteed 404 round trip.
download_variant() {
    local _v="$1" _out="$2" _url
    if ! is_dev_variant "$_v"; then
        _url="https://github.com/${SUSFS_REPO}/releases/latest/download/susfs_guard_lkm-${_v}.ko"
        if fetch "$_url" "$_out" && is_elf "$_out"; then
            return 0
        fi
    fi
    _url=$(api_asset_url "$_v")
    [ -n "$_url" ] || return 1
    fetch "$_url" "$_out" && is_elf "$_out"
}

# Best-effort fetch of the freestanding loader (fallback when ksud insmod is
# unavailable).  Failure is not fatal - ksud is the primary path.
ensure_loader() {
    local _dir="$1" _ldr _url
    _ldr="$_dir/$SUSFS_LOADER_NAME"
    [ -s "$_ldr" ] && return 0
    _url="https://github.com/${SUSFS_REPO}/releases/latest/download/${SUSFS_LOADER_NAME}"
    if fetch "$_url" "$_ldr" && is_elf "$_ldr"; then
        chmod 0755 "$_ldr"
        return 0
    fi
    rm -f "$_ldr" 2>/dev/null
    return 1
}

# -----------------------------------------------------------------------------
# Module load / unload
# -----------------------------------------------------------------------------
# The module filters itself out of /proc/modules for every caller including
# root, so /sys/module/<name> is the only reliable presence check.
ko_loaded() {
    [ -d "$SUSFS_SYSFS" ]
}

# load_ko <path> : ksud insmod -> bundled susfs_insmod -> plain insmod.
load_ko() {
    local _img="$1" _ldr
    [ -s "$_img" ] || return 1

    if command -v ksud >/dev/null 2>&1; then
        ksud insmod "$_img" >/dev/null 2>&1
        ko_loaded && return 0
    fi

    _ldr="$LOADER_DIR/$SUSFS_LOADER_NAME"
    if [ -n "$LOADER_DIR" ] && [ -x "$_ldr" ]; then
        "$_ldr" "$_img" >/dev/null 2>&1
        ko_loaded && return 0
    fi

    # Plain insmod: only works when every imported symbol happens to be in the
    # kernel's export table, which is why the two paths above exist.
    insmod "$_img" >/dev/null 2>&1
    ko_loaded && return 0

    return 1
}

unload_ko() {
    ko_loaded || return 0
    if command -v ksud >/dev/null 2>&1; then
        ksud rmmod "$SUSFS_MODNAME" >/dev/null 2>&1
        ko_loaded || return 0
    fi
    if command -v rmmod >/dev/null 2>&1; then
        rmmod "$SUSFS_MODNAME" >/dev/null 2>&1
    fi
    ko_loaded && return 1
    return 0
}

# -----------------------------------------------------------------------------
# High level flows
# -----------------------------------------------------------------------------
# install_driver <dir> : flash time.  Requires the network: walks the candidate
# variants, downloads each, and accepts the first one the kernel actually takes.
# The accepted image is staged in <dir> so boot can re-load it offline.
#
# Return codes: 0 staged and loaded; 1 could not download anything (no network /
# no usable variant); 2 downloaded fine but nothing loaded (KMI mismatch, i.e.
# the kernel is not a supported GKI variant).
install_driver() {
    local _dir="$1" _target _stage _cand _downloaded
    _target="$_dir/$SUSFS_KO_NAME"
    LOADER_DIR="$_dir"

    if ko_loaded; then
        log "SUSFS LKM 已在内核中（$SUSFS_SYSFS）"
        return 0
    fi

    if ! prepare_tmp "$_dir"; then
        log "❌ 找不到可写的工作目录"
        return 1
    fi

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1 \
        && ! command -v busybox >/dev/null 2>&1; then
        log "❌ 无可用下载工具（curl / wget / busybox 均缺失）"
        return 1
    fi

    _stage="$TMP_DIR/susfs_lkm_stage"
    mkdir -p "$_stage" 2>/dev/null
    _downloaded=0

    for _cand in $(device_variants); do
        log "→ 尝试变体: $_cand"
        if download_variant "$_cand" "$_stage/$SUSFS_KO_NAME"; then
            _downloaded=1
            if load_ko "$_stage/$SUSFS_KO_NAME"; then
                mv -f "$_stage/$SUSFS_KO_NAME" "$_target"
                chmod 0644 "$_target"
                echo "$_cand" >"$_dir/.susfs_variant"
                ensure_loader "$_dir"
                log "✅ 已加载并暂存变体: $_cand"
                return 0
            fi
            log "  $_cand 下载成功但内核拒绝加载（KMI 不匹配），继续"
        else
            log "  $_cand 无可用下载"
        fi
        rm -f "$_stage/$SUSFS_KO_NAME" 2>/dev/null
    done

    if [ "$_downloaded" = "0" ]; then
        log "❌ 无法从上游下载任何驱动，请检查网络后重试。"
        return 1
    fi

    log "❌ 没有任何变体能被本机内核加载。上游支持的组合:"
    log "   $SUSFS_VARIANTS_STABLE"
    log "   dev: $SUSFS_VARIANTS_DEV"
    return 2
}

# boot_load <dir> : post-fs-data.d.  Offline only - never touches the network,
# so it cannot stall boot.  Loads the image staged at install time; if there is
# none, or the kernel rejects it (e.g. after a kernel update), it gives up
# quietly and leaves the manager's Action button to fetch a fresh one.
boot_load() {
    local _dir="$1" _target _v
    _target="$_dir/$SUSFS_KO_NAME"
    LOADER_DIR="$_dir"

    ko_loaded && return 0

    if [ ! -s "$_target" ]; then
        log "post-fs-data: 无暂存驱动，跳过（请用管理器的『操作』按钮获取）"
        return 1
    fi

    _v=$(cat "$_dir/.susfs_variant" 2>/dev/null)
    log "post-fs-data: 加载暂存驱动 (${_v:-未知})"
    if load_ko "$_target"; then
        log "post-fs-data: ✅ 已加载"
        return 0
    fi
    log "post-fs-data: 暂存驱动加载失败（可能内核已更新），请用『操作』按钮更新"
    return 1
}

# update_from_upstream <dir> : the manager's Action button.  Re-fetches the
# newest release for the recorded variant and hot-reloads only if the image
# changed.  Rolls back to the previous .ko if the new one will not load.
update_from_upstream() {
    local _dir="$1" _target _stage _picked _cands _cand _new _old _bak
    _target="$_dir/$SUSFS_KO_NAME"
    _picked=""
    LOADER_DIR="$_dir"

    if ! prepare_tmp "$_dir"; then
        log "❌ 找不到可写的工作目录"
        return 1
    fi

    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1 \
        && ! command -v busybox >/dev/null 2>&1; then
        log "❌ 无可用下载工具（curl / wget / busybox 均缺失）"
        return 1
    fi

    _cands=""
    [ -f "$_dir/.susfs_variant" ] && _cands="$(cat "$_dir/.susfs_variant") "
    _cands="$_cands$(device_variants)"

    _stage="$TMP_DIR/susfs_lkm_stage"
    mkdir -p "$_stage" 2>/dev/null

    log "→ 查询上游最新 Release..."
    for _cand in $_cands; do
        if download_variant "$_cand" "$_stage/$SUSFS_KO_NAME"; then
            _picked="$_cand"
            break
        fi
    done

    if [ -z "$_picked" ]; then
        log "❌ 无法从上游获取匹配的驱动，请检查网络"
        return 1
    fi
    log "→ 上游变体: $_picked"

    _new=$(sha256 "$_stage/$SUSFS_KO_NAME")
    _old=""
    [ -s "$_target" ] && _old=$(sha256 "$_target")

    if [ -n "$_new" ] && [ "$_new" = "$_old" ] && ko_loaded; then
        log "✅ 已是最新版本，无需更新"
        rm -f "$_stage/$SUSFS_KO_NAME" 2>/dev/null
        return 0
    fi

    log "→ 发现更新，准备热重载..."
    _bak="$TMP_DIR/$SUSFS_KO_NAME.bak"
    [ -s "$_target" ] && cp -f "$_target" "$_bak" 2>/dev/null

    if ko_loaded; then
        if unload_ko; then
            log "  已卸载旧驱动"
        else
            log "❌ 卸载旧驱动失败，中止更新"
            rm -f "$_stage/$SUSFS_KO_NAME" 2>/dev/null
            return 1
        fi
    fi

    mv -f "$_stage/$SUSFS_KO_NAME" "$_target"
    chmod 0644 "$_target"
    echo "$_picked" >"$_dir/.susfs_variant"
    ensure_loader "$_dir"

    if load_ko "$_target"; then
        log "✅ 更新完成: $_picked"
        rm -f "$_bak" 2>/dev/null
        return 0
    fi

    log "❌ 新驱动加载失败，回滚..."
    if [ -s "$_bak" ]; then
        mv -f "$_bak" "$_target"
        if load_ko "$_target"; then
            log "已回滚到旧驱动"
        else
            log "回滚后仍无法加载"
        fi
    fi
    return 1
}

# status_report <dir>
status_report() {
    local _dir="$1" _sv _sz _nodes _n
    log "================= SUSFS LKM ================="
    log "内核版本 : $(uname -r)"
    log "API 级别 : $(getprop ro.build.version.sdk 2>/dev/null)"
    log "内核主版本: $(kernel_kver)"

    if [ -s "$_dir/$SUSFS_KO_NAME" ]; then
        _sv=$(cat "$_dir/.susfs_variant" 2>/dev/null)
        [ -n "$_sv" ] || _sv="未知"
        _sz=$(wc -c <"$_dir/$SUSFS_KO_NAME" 2>/dev/null | tr -d ' ')
        log "本地驱动 : $_sv (${_sz} 字节)"
    else
        log "本地驱动 : 无"
    fi

    if ko_loaded; then
        log "加载状态 : ✅ 已加载（$SUSFS_SYSFS）"
    else
        log "加载状态 : ❌ 未加载"
    fi

    _nodes=""
    for _n in susfs_kstat susfs_open_redirect susfs_enable_log susfs_avc_spoof \
              susfs_hide_modules susfs_hide_mounts susfs_path; do
        [ -e "/proc/$_n" ] && _nodes="$_nodes $_n"
    done
    if [ -n "$_nodes" ]; then
        log "控制节点 :$_nodes"
    else
        log "控制节点 : （未出现，模块可能未加载）"
    fi
    log "=============================================="
}
