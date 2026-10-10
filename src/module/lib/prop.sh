#!/system/bin/sh
# module.prop 渲染。

# render_module_prop <状态词>
render_module_prop() {
    local _label _tpl _prop _desc _kver _ver _tmp
    _label=$(state_label "$1")
    _tpl="$SUSFS_MODDIR/module.prop.template"
    _prop="$SUSFS_MODDIR/module.prop"
    [ -f "$_tpl" ] && [ -f "$_prop" ] || return 1

    _desc=$(sed -n 's/^description=//p' "$_tpl" | head -n1)
    [ -n "$_desc" ] || return 1

    _kver=$(uname -r 2> /dev/null)
    _ver=$(upstream_version)
    _desc=$(printf '%s' "$_desc" \
        | sed -e "s|{status}|$_label|g" \
            -e "s|{kernel}|$_kver|g" \
            -e "s|{susfs}|$_ver|g")

    _tmp="$_prop.tmp"
    sed "s|^description=.*|description=$_desc|" "$_prop" > "$_tmp" 2> /dev/null || return 1
    mv -f "$_tmp" "$_prop"
    chmod 0644 "$_prop" 2> /dev/null
    return 0
}
