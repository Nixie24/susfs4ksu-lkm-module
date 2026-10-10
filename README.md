# susfs4ksu-lkm-module

[inforcqb/susfs4ksu-lkm](https://github.com/inforcqb/susfs4ksu-lkm) 的自动安装器。
不在本地编译内核模块，只按设备指纹去上游拉预编译好的 `.ko`。

- 刷入时识别设备（`<Android 版本>-<内核版本>`），逐个下载候选 `susfs_guard_lkm-<变体>.ko`，
  用内核实际试载，第一个能加载的就被暂存到 `mods/`
- 同时生成一份 `mods/susfs_guard_lkm.json`，记下变体、上游版本和 sha256
- 开机时由 post-fs-data 脚本离线加载暂存好的 `.ko`（不联网，不会卡开机），
  并把结果写进 `module.prop` 的 description
- 想更新就在设备上手动跑 `update.sh`

## 要求

- KernelSU，arm64，GKI 内核。
- 内核版本：main 5.10 / 5.15 / 6.1 / 6.6，dev 6.12 / 6.18。
- 刷入时需要联网，`.ko` 自动从上游下载。

## 更新驱动

```sh
sh /data/adb/modules/susfs4ksu_lkm/update.sh
```

## 打包

```sh
# 等价于 ./src/module/build.sh
pnpm module:build
```

产物在 `dist/`。`module.prop` 是生成物，源文件是 `module.prop.template`。

## 许可

GPL-2.0，见 [LICENSE](LICENSE)。
