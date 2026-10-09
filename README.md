# susfs4ksu-lkm-module

[inforcqb/susfs4ksu-lkm](https://github.com/inforcqb/susfs4ksu-lkm) 的自动安装器

- 刷入时识别设备的信息（`<Android 版本>-<内核版本>`），下载对应的 `susfs_guard_lkm-<变体>.ko`
- 开机时自动用 `ksud insmod` 加载
- 在 KSU 管理器点击 Action 按钮可以从上游更新 `.ko` 文件

## 要求

- KernelSU（或任何提供 `ksud` 的兼容管理器），arm64，GKI 内核。
- 内核版本：main 5.10 / 5.15 / 6.1 / 6.6，dev 6.12 / 6.18。
- 刷入时需要联网。`.ko` 会自动从上游下载。

## 打包

```sh
./build.sh
```

## 许可

GPL-2.0，见 [LICENSE](LICENSE)。
