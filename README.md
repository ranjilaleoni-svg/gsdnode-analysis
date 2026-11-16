# gsdnode-analysis

Independent analysis of a root-privileged remote-control / residential-proxy agent (`gsdnode_android`) found pre-installed in the factory firmware of a cheap Rockchip RK3528-based Android TV box sold under the `HS86UI` / `hugsun x88pro` branding.

- 🇬🇧 Full report: [REPORT_EN.md](REPORT_EN.md)
- 🇷🇴 Raport complet (română): [RAPORT_RO.md](RAPORT_RO.md)
- Indicators of Compromise: [IOCs.md](IOCs.md)
- Removal script (tested, non-destructive — stubs the agent, does not touch `/system`): [neutralize_gsdnode.sh](neutralize_gsdnode.sh)
- Router-level domain blocklist: [blocklist.txt](blocklist.txt)

## TL;DR

A $20-30 Android TV box ships with a root-privileged agent that phones home to a server on Alibaba Cloud (`tws.gsda.com.cn:7704`, confirmed live) and carries plugin identifiers matching known PCDN/residential-proxy SDKs. This is the same pattern publicly reported for other vendors under names like **BADBOX**, **BADBOX 2.0**, **Vo1d** and **Operation Fuyao** — except this specific build doesn't appear to have been documented publicly before. If you own a box with build fingerprint `HS86UI.E160320.667.FE` (or similar `rockchip,rk3518-hugsun-*` board strings), you are very likely affected.

## Disclaimer

This is independent, best-effort research by a device owner, not a professional security audit. No vendor was contacted prior to publication (see the report for why). Use the removal script at your own risk — it was tested on one device only. This repository does not encourage or provide instructions for attacking the C2 infrastructure described; it documents it for defensive/informational purposes only.
