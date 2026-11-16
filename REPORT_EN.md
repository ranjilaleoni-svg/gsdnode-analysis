# gsdnode: a root-level remote-control / residential-proxy agent found pre-installed on a Rockchip RK3528-based Android TV box

**Status:** unconfirmed by any vendor or security firm — independent analysis by the device owner.
**Date:** 2026-11-16
**Device:** Android TV box, labeled `HS86UI`, board `rockchip,rk3518-hugsun-x88pro-ddr4-v10` (chip is actually RK3528A; "RK3518" appears to be a mislabel used by this vendor), Android 14, build fingerprint `HS86UI.E160320.667.FE`, 1GB RAM, ~8GB eMMC, userdebug build, SELinux **Permissive**, bootloader unlocked, Google device/model properties spoofed to a Pixel 5 ("redfin").

## Summary

This box was acquired as a generic cheap Android TV streaming device. Wireless ADB debugging was left enabled by the vendor. Analysis of the running system found a root-privileged native binary, `gsdnode_android`, started directly by the vendor's own `init.rc`, which:

- runs as root, restarted every ~10s by a watchdog shell script if it dies;
- queries `api.ipify.org` on every start to learn its public IP (NAT discovery);
- contains hardcoded references to a command-and-control endpoint `tws.gsda.com.cn:7704`, confirmed live and accepting TCP connections, hosted on Alibaba Cloud (Hangzhou, AS37963);
- exposes remote-shell-like capabilities (`gsdshell`, `persist_shell`, `installapk`) and plugin identifiers matching known PCDN/residential-proxy SDKs (`niulink`, `wxedge`, `dianxin`, `ksc-kepler`, `ross_atv`, `airship-agent`);
- is accompanied by three other factory-signed system apps providing FOTA/OTA update channels (`com.amediatech.update` / Adups, `com.chihi.fota`, `android.rockchip.update.service` / RKUpdateService) capable of silent APK installation, all sharing the same platform signature;
- ships with Google Play Protect disabled by a vendor `preinstall.sh` script (`package_verifier_enable=0`);
- includes a loader (inside `RKUpdateService.apk`) for a hidden secondary payload path (`/data/blueberry/blueberry.sh`), not present at analysis time but referenced in code.

This matches the general pattern publicly documented for **BADBOX / BADBOX 2.0** (Human Security, Google), **Vo1d** (Dr.Web) and most closely **Operation Fuyao** (Bitsight, July 2026) — cheap Android TV boxes, preloaded at the factory with agents that turn the owner's home bandwidth into a residential proxy / PCDN relay, and/or run ad-fraud tasks, without the owner's knowledge or consent. No report found by this author ties specifically to the `gsda.com.cn`, `rupa.tv` or `hugsun.com.cn` domains, or to this exact firmware build, before this write-up — except one independent GitHub repository (`rk3518-malware-quarantine`) analyzing byte-identical copies of two of the same APKs on a differently-branded box, suggesting shared firmware across multiple rebadged products.

## Why this matters

None of this requires the user to install anything or click anything. It is baked into the firmware image at the factory (file timestamps on `/system` and `/vendor` partitions show the Android build-reproducibility epoch date `2009-01-01`, i.e. these files were part of the original system image, not added later). A consumer plugging in this box and connecting it to home Wi-Fi is, by design, donating a slice of their upload bandwidth and IP reputation to unknown third parties, with no consent screen, no privacy policy shown, and no way to opt out from the stock firmware.

## Technical evidence

### 1. Root execution is vendor-defined, not injected

`/vendor/etc/init/hw/init.rk30board.rc`, line 410-413 (sha256 `8bb2c3d369a6ae934be68618632076c0876562fe7fd2ca441697f8a4b53d2aac`, file timestamp `2009-01-01` = build-time):

```
service init /system/bin/init.sh
    class main
    user root
    group root
```

### 2. The watchdog script (`/system/bin/init.sh`, sha256 `f65a73500363126d083568818890ef7c4e056e1b9575cc102ba7f7ec93af0617`)

Copies `/system/bin/gsdnode_android` into `/data/gsdnode/` on first boot (guarded by `persist.gsdnode.init.copy`), derives a device ID from the MAC address (eth0 → wlan0 → serial fallback), then loops forever:

```sh
while true; do
  pgrep -f 'gsdnode_android*' || $DATA_DIR/gsdnode_android $mac_address &
  sleep 10
done
```

### 3. The binary (`gsdnode_android`, 2,836,728 bytes, sha256 `2d919a92d2e548d5ce433f79eda1b939e7b57f0381f570da02fe9ae94b3ef801`)

A UPX-packed Go ARM32 ELF (unpacks to 7,797,780 bytes). Static string/symbol analysis shows functions `GsdAgentMain`, `GsdNodeMain`, `GsdInstallMain`, `checkServerTaskLists`, `doUpdateTasksHttpRequest`, `startLocalTasks`, `runPersistentTasks`, `savePersistentShell`, `dealSystemAction`, and HTTP endpoints `/box/powerOn`, `/box/heartbeat`, `/box/uploadNodeTasks`, `/box/uploadResult`, `/box/api/dispatch/updateDeviceNIC`.

### 4. Live confirmation of the C2 endpoint (done from a separate machine on the same LAN, not from the box)

```
ping tws.gsda.com.cn
  -> resolves to 115.29.212.137, responds to ICMP (~216ms RTT)

whois/geo: AS37963 Hangzhou Alibaba Advertising Co., Ltd., Hangzhou, China

Test-NetConnection -ComputerName 115.29.212.137 -Port 7704
  -> TcpTestSucceeded: True
```

### 5. Live network capture

A packet capture taken on-device (`tcpdump`, root) during a forced respawn of the agent shows, in plaintext inside the TLS ClientHello SNI, a first outbound call to `api.ipify.org` (public-IP discovery) through a Cloudflare-fronted IP, consistent with the `natType` logic found in the binary. No direct connection to `tws.gsda.com.cn:7704` was captured in the ~2-minute observation window from a residential network in Romania; this is consistent with either an infrequent check-in interval or regional reachability differences, not with the server being inactive (see point 4).

### 6. SELinux denials (Permissive — logged, not blocked)

```
avc: denied { read } for name="gsdnode" ... scontext=u:r:shell:s0 tcontext=u:object_r:system_data_root_file:s0 tclass=dir permissive=1
avc: denied { execute } for name="gsdnode_android" ... tclass=file permissive=1
avc: denied { dac_read_search } for capability=2 scontext=u:r:shell:s0 tcontext=u:r:shell:s0 tclass=capability permissive=1
```

### 7. Shared signature across the three FOTA/update apps

```
com.amediatech.update   codePath=/system/app/Abupdate_new       signature=b1a1812f  firstInstallTime=2009-01-01
com.chihi.fota           codePath=/system/app/FotaUpdate          signature=b1a1812f  firstInstallTime=2009-01-01
android.rockchip.update.service  codePath=/system/app/RKUpdateService  signature=b1a1812f  firstInstallTime=2009-01-01
```

Identical signature, identical epoch install time, identical system codePath — all three are part of the same factory build, signed by the same key.

### 8. Persistence beyond "disable"

Disabling the three FOTA apps via `pm disable-user` and killing them with `am force-stop` did **not** stop them from being relaunched by the system — they are marked `persistent` in the firmware and are restarted by `system_server` regardless. Removing them fully would require remounting `/system` read-write, which risks tripping dm-verity (active `kverityd` kernel threads were observed) and bricking the device; this was deliberately not attempted.

## Indicators of Compromise (IOCs)

| Type | Value | Notes |
|---|---|---|
| Domain | `tws.gsda.com.cn` | C2, port 7704, confirmed live |
| Domain | `gsda.com.cn` | parent domain |
| Domain | `api.fota.rupa.tv`, `fota.rupa.tv`, `ota.rupa.tv` | FOTA client (`com.chihi.fota`) |
| Domain | `api.hugsun.com.cn`, `fota.hugsun.com.cn`, `erp.hugsun.com.cn` | vendor telemetry/update (unverified beyond the vendor domain itself) |
| IP | `115.29.212.137` | current resolution of `tws.gsda.com.cn`, Alibaba Cloud Hangzhou |
| File (SHA256) | `2d919a92d2e548d5ce433f79eda1b939e7b57f0381f570da02fe9ae94b3ef801` | `/system/bin/gsdnode_android` and `/data/gsdnode/gsdnode_android` |
| File (SHA256) | `f65a73500363126d083568818890ef7c4e056e1b9575cc102ba7f7ec93af0617` | `/system/bin/init.sh` |
| APK signature hash | `b1a1812f` | shared by Abupdate_new, FotaUpdate, RKUpdateService |
| Build fingerprint | `HS86UI.E160320.667.FE` | this exact firmware build |

## Remediation (tested on this device)

The attached `neutralize_gsdnode.sh` script, run once via `adb root` + `adb shell`:

1. Backs up the original agent binary and watchdog script to `/sdcard/`.
2. Kills the running agent.
3. Sets `persist.gsdnode.init.copy=1` so the watchdog never re-copies the real binary from `/system/bin`.
4. Replaces `/data/gsdnode/gsdnode_android` with a no-op stub (`exit 0`) — the watchdog keeps "starting" it every 10s, but it does nothing.
5. Disables the three FOTA/update apps and clears their data.
6. Re-enables Google Play Protect.

This stops the agent without touching the read-only `/system` partition (lower brick risk than reflashing or remounting system read-write). It does **not** survive a factory reset or an OTA/firmware reflash — the payload is in the system image.

A network-level mitigation (DNS blocklist on the router/Pi-hole/AdGuard Home, blocking `gsda.com.cn`, `rupa.tv`, `hugsun.com.cn`) is recommended as defense-in-depth regardless, since the FOTA apps cannot be fully removed without system remount.

## Disclosure note

No vendor contact was attempted before this publication; the device was bought through an ordinary retail channel with no clear direct vendor relationship, and the behavior described matches a pattern other researchers have already reported publicly for other vendors (Bitsight/Fuyao, Human Security/BADBOX) without a formal vendor response cycle. This write-up is published to help other owners of visually identical or similarly-branded boxes recognize and mitigate the same issue.

## Related work

- Bitsight, "The Fuyao Enterprise" (July 2026) — closest known parallel (SOCKS5 residential proxy + ad fraud, HDMI-state-aware).
- Human Security / Google, BADBOX and BADBOX 2.0.
- Dr.Web, Vo1d botnet.
- GitHub: `freddy-newandyke/rk3518-malware-quarantine` — independent analysis of byte-identical `RKUpdateService.apk` / `FotaUpdate.apk` on a different rebrand of what appears to be the same base firmware.
