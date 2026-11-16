# gsdnode-analysis

Independent analysis of a root-privileged remote-control / residential-proxy agent (`gsdnode_android`) found pre-installed in the factory firmware of a cheap Rockchip RK3528-based Android TV box sold under the `HS86UI` / `hugsun x88pro` branding.

🇷🇴 *Analiză independentă a unui agent de control la distanță / proxy rezidențial, cu privilegii root, găsit preinstalat în firmware-ul de fabrică al unui box Android TV ieftin, cu chipset Rockchip RK3528, vândut sub brandul `HS86UI` / `hugsun x88pro`.*

---

## How this started

I'd heard that cheap Chinese Android TV boxes are notorious for shipping with malware or botnet code, so when I got one, I suspected it probably had something hidden in it too. I didn't want to dig through firmware internals by hand, so I used an AI assistant (Claude, via wireless ADB access to the box) to help investigate: pull a full hardware report, test playback, then actively scan for anything suspicious. That scan turned up a root-privileged process (`gsdnode_android`) that didn't belong in a normal media player. From there, the AI and I went deeper — static analysis of the binary, correlating it with a public repository that had analyzed byte-identical files from a different rebranded box, capturing live network traffic to confirm the command-and-control server was actually active, and finally writing all of it up here, plus a script to neutralize the agent on the device itself. The suspicion going in was right; this repo is what came out of actually checking.

## Cum a început 🇷🇴

Auzisem că boxurile chinezești ieftine sunt renumite pentru malware sau cod de botnet ascuns în ele, așa că atunci când am luat unul, am bănuit că probabil are și al meu ceva ascuns. N-am vrut să scormonesc manual prin firmware, așa că am folosit un asistent AI (Claude, prin acces ADB wireless la box) ca să investighez: am scos un raport complet de hardware, am testat redarea, apoi am cerut un scan activ pentru orice e suspect. Scanarea a scos la iveală un proces cu privilegii root (`gsdnode_android`) care n-avea ce căuta într-un simplu media player. De acolo, am mers mai adânc — analiză statică a binarului, corelare cu un repository public care analizase fișiere identice byte-cu-byte de pe un alt box rebranduit, captură de trafic live ca să confirm că serverul de comandă-control chiar e activ, și în final, tot ce vezi aici, plus un script care neutralizează agentul direct pe device. Bănuiala inițială s-a confirmat; acest raport e rezultatul verificării efective.

- 🇬🇧 Full report: [REPORT_EN.md](REPORT_EN.md)
- 🇷🇴 Raport complet (română): [RAPORT_RO.md](RAPORT_RO.md)
- **🛠️ Step-by-step removal guide / Ghid pas cu pas de eliminare: [REMOVAL_GUIDE.md](REMOVAL_GUIDE.md)**
- Indicators of Compromise: [IOCs.md](IOCs.md)
- Removal script (tested, non-destructive — stubs the agent, does not touch `/system`): [neutralize_gsdnode.sh](neutralize_gsdnode.sh)
- Router-level domain blocklist: [blocklist.txt](blocklist.txt)

---

## Where this unit was bought

Purchased in Romania via **eMag Marketplace**, listing "Player Media 8K HDR" (TV Box Android, HS86UI Pro X88), sold/shipped by marketplace seller **UWOT GERMANY GMBH**. This is reported so other buyers can recognize the listing — it is not a claim that this specific reseller was aware of what ships inside the device (see the full report for why).

## De unde a fost cumpărată această unitate 🇷🇴

Cumpărată din România prin **eMag Marketplace**, anunțul „Player Media 8K HDR" (TV Box Android, HS86UI Pro X88), vândut/livrat de comerciantul de pe marketplace **UWOT GERMANY GMBH**. Menționat ca alți cumpărători să poată recunoaște anunțul — nu e o acuzație că acest reseller anume ar fi știut ce rulează în interiorul device-ului (vezi raportul complet pentru detalii).

---

## TL;DR

A $20-30 Android TV box ships with a root-privileged agent that phones home to a server on Alibaba Cloud (`tws.gsda.com.cn:7704`, confirmed live) and carries plugin identifiers matching known PCDN/residential-proxy SDKs. This is the same pattern publicly reported for other vendors under names like **BADBOX**, **BADBOX 2.0**, **Vo1d** and **Operation Fuyao** — except this specific build doesn't appear to have been documented publicly before. If you own a box with build fingerprint `HS86UI.E160320.667.FE` (or similar `rockchip,rk3518-hugsun-*` board strings), you are very likely affected.

## Pe scurt 🇷🇴

Un box Android TV de 20-30$ vine cu un agent cu privilegii root care sună acasă către un server pe Alibaba Cloud (`tws.gsda.com.cn:7704`, confirmat activ) și conține identificatori de plugin care corespund unor SDK-uri cunoscute de PCDN/proxy rezidențial. E același tipar raportat public pentru alți vendori, sub nume ca **BADBOX**, **BADBOX 2.0**, **Vo1d** și **Operation Fuyao** — doar că acest build specific nu pare să fi fost documentat public înainte. Dacă ai un box cu fingerprint de build `HS86UI.E160320.667.FE` (sau string-uri de placă similare `rockchip,rk3518-hugsun-*`), foarte probabil ești afectat.

---

## Disclaimer

This is independent, best-effort research by a device owner, not a professional security audit. No vendor was contacted prior to publication (see the report for why). Use the removal script at your own risk — it was tested on one device only. This repository does not encourage or provide instructions for attacking the C2 infrastructure described; it documents it for defensive/informational purposes only.

**Sample files (`samples.zip`) are for research/verification only.** They are password-protected precisely so they are not run by accident. The authors/publishers of this repository accept **no responsibility whatsoever** for any damage, compromise, data loss, or legal consequence arising from extracting, installing, or executing any file from that archive, or from running `neutralize_gsdnode.sh`. Everything in this repository is provided "as is", without warranty of any kind (see [LICENSE](LICENSE)). You are solely responsible for what you choose to run on your own hardware.

## Declinare de răspundere 🇷🇴

Aceasta e o cercetare independentă, făcută pe cât de bine s-a putut de către proprietarul device-ului, nu un audit profesional de securitate. Niciun vendor n-a fost contactat înainte de publicare (vezi raportul pentru motiv). Folosești scriptul de eliminare pe propriul risc — a fost testat doar pe un singur device. Acest repository nu încurajează și nu oferă instrucțiuni pentru atacarea infrastructurii C2 descrise; o documentează strict în scop defensiv/informativ.

**Fișierele eșantion (`samples.zip`) sunt doar pentru cercetare/verificare.** Sunt protejate cu parolă exact ca să nu fie rulate accidental. Autorii/publicatorii acestui repository nu își asumă **nicio răspundere** pentru vreo daună, compromitere, pierdere de date sau consecință legală rezultată din extragerea, instalarea sau rularea vreunui fișier din acea arhivă, sau din rularea `neutralize_gsdnode.sh`. Tot ce e în acest repository e oferit „ca atare", fără nicio garanție (vezi [LICENSE](LICENSE)). Ești singurul responsabil pentru ce alegi să rulezi pe propriul hardware.
