#!/system/bin/sh
# 常量定义

# KernelSU 的工具路径
PATH="$PATH:/data/adb/ksu/bin"

SUSFS_REPO="inforcqb/susfs4ksu-lkm"
SUSFS_MODNAME="susfs_guard_lkm"
SUSFS_KO_NAME="susfs_guard_lkm.ko"
SUSFS_JSON_NAME="susfs_guard_lkm.json"
SUSFS_STATE_NAME="state.json"

SUSFS_SYSFS="${SUSFS_SYSFS:-/sys/module/$SUSFS_MODNAME}"
SUSFS_UA="susfs4ksu-lkm-module"
SUSFS_LOG="${SUSFS_LOG:-}"

TMP_DIR="${TMP_DIR:-/data/local/tmp}"

# 调用方在 source 之前设好的模块目录
SUSFS_MODS_DIR="$SUSFS_MODDIR/mods"
SUSFS_LOG_DIR="$SUSFS_MODDIR/log"
SUSFS_WEBROOT="$SUSFS_MODDIR/webroot"

# 驱动状态。state.json 里存右边的词，module.prop 里显示左边这句
SUSFS_STATE_OK="ok"
SUSFS_STATE_FAIL="error"
SUSFS_LABEL_OK="内核安装成功😋"
SUSFS_LABEL_FAIL="遇到了错误😭"

# 上游发布的 GKI 变体。main 的只发正式版；dev(6.12/6.18) 只发在 prerelease
SUSFS_VARIANTS_STABLE="android12-5.10 android13-5.10 android13-5.15 android14-5.15 android14-6.1 android15-6.6"
SUSFS_VARIANTS_DEV="android16-6.12 android17-6.18"
SUSFS_VARIANTS_ALL="$SUSFS_VARIANTS_STABLE $SUSFS_VARIANTS_DEV"
