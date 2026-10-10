#!/system/bin/sh
# 通用入口

#   SUSFS_MODDIR="$MODDIR";
#   . "$MODDIR/lib/common.sh"

_SUSFS_LIB="${SUSFS_MODDIR:?SUSFS_MODDIR 未设置}/lib"

for _f in config output fs verify state device net release kmod prop; do
    [ -f "$_SUSFS_LIB/$_f.sh" ] || continue
    . "$_SUSFS_LIB/$_f.sh"
done
unset _f
