# Indicators of Compromise

| Type | Value | Notes |
|---|---|---|
| Domain | `tws.gsda.com.cn` | C2, port 7704/tcp, confirmed live 2026-11-16 |
| Domain | `gsda.com.cn` | parent domain |
| Domain | `api.fota.rupa.tv` | FOTA client (com.chihi.fota), confirmed in firmware |
| Domain | `fota.rupa.tv` | related |
| Domain | `ota.rupa.tv` | related |
| Domain | `api.hugsun.com.cn` | vendor domain |
| Domain | `fota.hugsun.com.cn` | vendor domain |
| Domain | `erp.hugsun.com.cn` | vendor domain |
| IP | `115.29.212.137` | current resolution of tws.gsda.com.cn — AS37963 Hangzhou Alibaba Advertising Co., Ltd. |
| SHA256 | `2d919a92d2e548d5ce433f79eda1b939e7b57f0381f570da02fe9ae94b3ef801` | gsdnode_android (packed, 2,836,728 bytes) |
| SHA256 | `f65a73500363126d083568818890ef7c4e056e1b9575cc102ba7f7ec93af0617` | init.sh watchdog script (968 bytes) |
| SHA256 | `8bb2c3d369a6ae934be68618632076c0876562fe7fd2ca441697f8a4b53d2aac` | init.rk30board.rc (vendor init rc defining root service) |
| APK signature hash | `b1a1812f` | shared by com.amediatech.update, com.chihi.fota, android.rockchip.update.service |
| Build fingerprint | `HS86UI.E160320.667.FE` | |
| Board | `rockchip,rk3518-hugsun-x88pro-ddr4-v10` | actual SoC is RK3528A |
| Package names | `com.amediatech.update`, `com.chihi.fota`, `android.rockchip.update.service` | pre-installed, persistent, same signature |
| Native binary path | `/system/bin/gsdnode_android`, `/data/gsdnode/gsdnode_android` | |
| Hidden payload path (referenced, not present at analysis time) | `/data/blueberry/blueberry.sh` | loaded via RKUpdateService.apk |

## Full firmware dump

A complete dump of the device's read-only firmware partitions (`boot`, `recovery`, `dtbo`, `vbmeta`, `uboot`, `trust`, `security`, `misc`, `baseparameter`, and the `super` partition containing `system`/`vendor`/`product`) is available as release assets: **[firmware-dump-v1](https://github.com/ranjilaleoni-svg/gsdnode-analysis/releases/tag/firmware-dump-v1)**. These were pulled directly from the block devices with root, before any modification — they represent the exact factory firmware. `super.img.gz` is gzip-compressed (decompress with `gunzip`); everything else is a raw partition image.

```
1f3500598604e749fb4e51a46ba72f644fca465031c284e788bd69cd0fcea7f4  boot.img
7ba86147f8d2a58c572f0e9491bd3ea8f01f4973549733ce88ff1e94fad4f9a5  recovery.img
c62984c0be63d0b4653db4eaab14fa2fbb0ca8f17ee880a636513695ac3e2ae1  dtbo.img
6fc1e099375b0cbde5b896c918dd36a8fdf126e601ead4e27a4c4ee10423e64e  vbmeta.img
f8f7b5100caac25ebe1f7832ef53c4109ef367fd52378c03731136b45350e8da  uboot.img
7a80f10e7a737ab907ea79be1b87b9e872cab4cf78a7acd02393747bc4b1f6ed  trust.img
324e39d4d0820174f2d8f7f68802d5f537666886972fe7d212a69d193a28f56d  security.img
d28e5c0eb8163ceec10984284798ac7c738bffb80696e35cb44aa43f8e200bd3  misc.img
5e8975d78b4c54e7d12e19e2aa30a8fe644b4e9637d18676c3f0c5195d15cd11  baseparameter.img
3c701d5899ab47889855fed79cd5a84e64360b5a13e2e49c24dc7fc7d87e6aff  super.img.gz
```

Note: `trust.img` and `security.img` were inspected before publishing (byte-level non-zero count) and found to be essentially unprovisioned — no evidence of a real DRM/attestation keybox, consistent with this unit's unlocked bootloader.

## Sample files

Raw samples (`gsdnode_android` binary, `init.sh`, and the three FOTA/update APKs — `Abupdate_new.apk`, `FotaUpdate.apk`, `RKUpdateService.apk`) are provided in [`samples.zip`](samples.zip) as an **AES-256 encrypted, password-protected** archive — standard malware-research convention, to avoid accidental execution and automated scanning/takedown of the raw files.

- Archive: `samples.zip`
- Password: `infected`
- SHA256 of the archive: `b95073c050dc4377934f9558cfe4a2dffc450a013eeeff0511c10746c0555dc6`

Individual file hashes are listed in the table above and should match after extraction.

**⚠️ WARNING / DISCLAIMER:** These files are provided strictly for security research, static analysis, and verification of the hashes above. They are **not** intended to be installed or executed on any device. The authors/publishers of this repository take **no responsibility** for any damage, data loss, security compromise, legal issue, or other consequence resulting from extracting, installing, running, or otherwise using these files. If you choose to install or run any file from `samples.zip`, you do so **entirely at your own risk** and on your own authority — ideally only inside an isolated, disposable analysis environment (e.g. a sandboxed VM or emulator with no network access), never on a personal or production device.
