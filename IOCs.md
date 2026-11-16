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
