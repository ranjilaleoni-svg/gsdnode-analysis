# Full optimization & permanent removal guide / Ghid complet de optimizare și eliminare permanentă

🇬🇧 **English below** · 🇷🇴 **Română mai jos**

This guide covers everything beyond the basic [REMOVAL_GUIDE.md](REMOVAL_GUIDE.md) (the `/data`-only stub, safe for everyone): permanent firmware-level removal, bloatware cleanup, performance tweaks, and what was tried and abandoned. **The firmware-level section is advanced and carries real risk of bricking the device — read the warnings.**

---

## 🇬🇧 English

### Who this is for

- **[REMOVAL_GUIDE.md](REMOVAL_GUIDE.md)** (the basic one) is enough for almost everyone: it stops the agent with near-zero risk, but must be redone after every factory reset.
- **This guide's "Permanent removal" section** actually deletes the malicious files from the read-only system partition itself, so it survives factory resets — but it requires remounting the system partition read-write, which on this device means bypassing a device-mapper read-only flag. **If something goes wrong, recovery requires physical access to the device and a Rockchip flashing tool (RKDevTool) via USB in Maskrom mode.** Only do this if you're comfortable with that risk, have a full firmware backup (see [IOCs.md](IOCs.md) → "Full firmware dump"), and ideally still have a warranty or don't mind replacing the device.

### Part 1 — Permanent removal (firmware-level, advanced)

All commands via `adb shell` with `adb root` already active (`adb -s <ip>:5555 root`).

**1. Check your partition layout first** — this guide's exact numbers (`system`, `2754640`, `179:13`, `2048`) are specific to this exact firmware build. Don't blindly copy them onto a different device/build without checking:

```
adb shell "mount | grep ' / '"
adb shell "dmctl list devices"
adb shell "dmctl table system"
```

If your root (`/`) mount shows as a `dm-X` device with a name like `system` in `dmctl list devices`, and the `ro` flag is set (`cat /sys/block/dm-X/ro` returns `1`), you have the same read-only-at-device-mapper-level situation.

**2. Make the underlying block device writable** (replace `system`, `0`, `2754640`, `179:13`, `2048` with *your* values from step 1):

```
adb shell "dmctl replace system linear 0 2754640 179:13 2048"
adb shell "cat /sys/block/dm-0/ro"    # should now print 0
adb shell "mount -o remount,rw /"
```

**3. Delete the malicious files directly from the system partition:**

```
adb shell "rm /system/bin/gsdnode_android"
adb shell ": > /system/bin/init.sh"
adb shell ": > /system/bin/preinstall.sh"
adb shell "rm -rf /system/app/Abupdate_new /system/app/FotaUpdate /system/app/RKUpdateService"
adb shell "rm -rf /system/preinstall/*"
```

(Using `: > file` to truncate to empty instead of writing new content — on a dynamic/logical partition sized with little free space, even writing a few bytes of *new* content can fail with "No space left on device" even though `df` shows free space; truncating only frees blocks, it never needs new ones.)

**4. Reboot and verify:**

```
adb reboot
# wait ~30-60s
adb connect <ip>:5555
adb shell "ps -A | grep gsd"              # should print nothing
adb shell "pm list packages | grep -E 'amediatech|chihi|rockchip.update'"  # should print nothing
```

### Part 2 — Bloatware cleanup (safe, no risk)

Remove whatever you don't need, via `pm uninstall --user 0 <package>` (reversible by reinstalling) or `pm disable-user --user 0 <package>` for stubborn/persistent system apps:

| App | Package | Why |
|---|---|---|
| Aptoide TV | `cm.aptoidetv.pt` | third-party app store, sideloading risk |
| APKPure | `com.apkpure.aegon` | same |
| AirScreen | `com.ionitech.airscreen` | unused casting app |
| Chrome | `com.android.chrome` | optional, if you don't use a browser on TV |
| Vendor media player | `com.rockchips.mediacenter` | redundant if you use VLC/your own player |
| FactoryTest | `com.francis.wifitest` | leftover factory diagnostic tool, installed as `priv-app` (elevated privileges) — shouldn't ship on retail units |
| SkyReinstall | `com.example.staticistall2` | the IPTV/APK silent-reinstaller |

### Part 3 — Performance tweaks (safe)

```
adb shell "settings put global window_animation_scale 0"
adb shell "settings put global transition_animation_scale 0"
adb shell "settings put global animator_duration_scale 0"
adb shell "settings put global always_finish_activities 1"
```

The last one aggressively frees memory when you leave an app (destroys the activity instead of pausing it) — meaningful on a 1GB RAM device, at the cost of apps needing to fully reload when you switch back to them.

### Part 4 — Boot splash removal (cosmetic, safe once `/` is already rw from Part 1)

```
adb shell "rm /system/media/bootanimation.zip"
```

Android falls back to a plain screen instead of the vendor animation.

### Part 5 — Storage: using a USB drive as internal storage (Adoptable Storage)

```
adb shell "sm set-force-adoptable true"
```

Then, with a USB drive plugged in, go to **Settings → Storage**, select the drive, and choose "Format as internal" (**this erases the drive**). Apps can then be moved onto it from **Settings → Apps → [app] → Storage**.

### Part 6 — What we tried and gave up on

We attempted to turn the box into a lightweight home-automation hub (Node-RED, to control Wi-Fi smart plugs like Tasmota/Shelly from a phone browser) via Termux. We hit a **reproducible, unresolved `apt` bug** on this specific build: `apt-get update` always fails with `Clearsigned file isn't valid, got 'NOSPLIT'` / `getline (22: Invalid argument)`, regardless of mirror, IP version, HTTP pipelining settings, or `apt`/`libc++` version (we upgraded both — no change). `curl` downloads the exact same file perfectly, and `gpgv` validates that cleanly-downloaded copy without issue — so the bug is specifically in `apt`'s own fetch-and-parse path on this device, not in the network, the signature, or the file itself. We did not try to bypass package signature verification to work around it.

**If you want simple on/off control of Wi-Fi smart plugs from your phone, skip Termux entirely**: install [HTTP Shortcuts](https://github.com/Waboodoo/HTTP-Shortcuts) (open source) on your **phone**, and create one button per device calling its local HTTP API directly (e.g. `http://<plug-ip>/cm?cmnd=Power%20Toggle` for Tasmota, `http://<plug-ip>/relay/0?turn=toggle` for Shelly). No hub, no server, no `apt` bug to fight.

We also decided against running Home Assistant Core or any hub software *on this box* at all — 1GB of RAM is genuinely too little for it to run reliably, even before hitting the `apt` issue.

---

## 🇷🇴 Română

### Pentru cine e acest ghid

- **[REMOVAL_GUIDE.md](REMOVAL_GUIDE.md)** (cel de bază) e suficient pentru aproape oricine: oprește agentul cu risc aproape zero, dar trebuie refăcut după fiecare factory reset.
- **Secțiunea „Eliminare permanentă" din acest ghid** chiar șterge fișierele malițioase din partiția de sistem (read-only), deci supraviețuiește unui factory reset — dar necesită remontarea partiției de sistem ca read-write, ceea ce pe acest device înseamnă ocolirea unui flag read-only la nivel de device-mapper. **Dacă ceva merge prost, recuperarea necesită acces fizic la device și un tool de flashare Rockchip (RKDevTool) prin USB, în mod Maskrom.** Fă asta doar dacă îți asumi riscul, ai un backup complet al firmware-ului (vezi [IOCs.md](IOCs.md) → „Full firmware dump") și, ideal, mai ai garanție sau nu te deranjează să înlocuiești device-ul.

### Partea 1 — Eliminare permanentă (la nivel de firmware, avansat)

Toate comenzile prin `adb shell`, cu `adb root` deja activ (`adb -s <ip>:5555 root`).

**1. Verifică-ți mai întâi propriul layout de partiții** — numerele exacte din acest ghid (`system`, `2754640`, `179:13`, `2048`) sunt specifice acestui build exact de firmware. Nu le copia orbește pe alt device/build fără verificare:

```
adb shell "mount | grep ' / '"
adb shell "dmctl list devices"
adb shell "dmctl table system"
```

Dacă mount-ul rădăcinii (`/`) arată ca un device `dm-X` cu un nume gen `system` în `dmctl list devices`, și flag-ul `ro` e setat (`cat /sys/block/dm-X/ro` returnează `1`), ai aceeași situație de read-only la nivel de device-mapper.

**2. Fă block device-ul de bază scriptibil** (înlocuiește `system`, `0`, `2754640`, `179:13`, `2048` cu valorile *tale* din pasul 1):

```
adb shell "dmctl replace system linear 0 2754640 179:13 2048"
adb shell "cat /sys/block/dm-0/ro"    # ar trebui sa arate acum 0
adb shell "mount -o remount,rw /"
```

**3. Șterge fișierele malițioase direct din partiția de sistem:**

```
adb shell "rm /system/bin/gsdnode_android"
adb shell ": > /system/bin/init.sh"
adb shell ": > /system/bin/preinstall.sh"
adb shell "rm -rf /system/app/Abupdate_new /system/app/FotaUpdate /system/app/RKUpdateService"
adb shell "rm -rf /system/preinstall/*"
```

(Folosim `: > fisier` ca să trunchiem la gol, în loc să scriem conținut nou — pe o partiție dinamică/logică dimensionată cu puțin spațiu liber, chiar și scrierea a câțiva bytes de conținut *nou* poate eșua cu „No space left on device" chiar dacă `df` arată spațiu liber; trunchierea doar eliberează blocuri, nu cere niciodată altele noi.)

**4. Repornește și verifică:**

```
adb reboot
# astepta ~30-60s
adb connect <ip>:5555
adb shell "ps -A | grep gsd"              # ar trebui sa nu arate nimic
adb shell "pm list packages | grep -E 'amediatech|chihi|rockchip.update'"  # ar trebui sa nu arate nimic
```

### Partea 2 — Curățare bloatware (sigur, fără risc)

Elimină ce nu ai nevoie, prin `pm uninstall --user 0 <pachet>` (reversibil, reinstalezi) sau `pm disable-user --user 0 <pachet>` pentru aplicații de sistem persistente/încăpățânate:

| Aplicație | Pachet | De ce |
|---|---|---|
| Aptoide TV | `cm.aptoidetv.pt` | magazin alternativ de aplicații, risc de sideloading |
| APKPure | `com.apkpure.aegon` | la fel |
| AirScreen | `com.ionitech.airscreen` | aplicație de casting nefolosită |
| Chrome | `com.android.chrome` | opțional, dacă nu folosești browser pe TV |
| Media player vendor | `com.rockchips.mediacenter` | redundant dacă folosești VLC/alt player |
| FactoryTest | `com.francis.wifitest` | unealtă de diagnostic de fabrică uitată, instalată ca `priv-app` (privilegii ridicate) — n-ar trebui să existe pe unități de retail |
| SkyReinstall | `com.example.staticistall2` | reinstalatorul silențios de IPTV/APK-uri |

### Partea 3 — Optimizări de performanță (sigur)

```
adb shell "settings put global window_animation_scale 0"
adb shell "settings put global transition_animation_scale 0"
adb shell "settings put global animator_duration_scale 0"
adb shell "settings put global always_finish_activities 1"
```

Ultima eliberează agresiv memoria când ieși dintr-o aplicație (distruge activitatea în loc s-o pună pe pauză) — semnificativ pe un device cu 1GB RAM, cu prețul că aplicațiile trebuie să se reîncarce complet când revii la ele.

### Partea 4 — Eliminare splash screen la boot (cosmetic, sigur odată ce `/` e deja rw din Partea 1)

```
adb shell "rm /system/media/bootanimation.zip"
```

Android revine la un ecran simplu, în loc de animația vendor-ului.

### Partea 5 — Stocare: folosirea unui stick USB ca stocare internă (Adoptable Storage)

```
adb shell "sm set-force-adoptable true"
```

Apoi, cu un stick USB băgat, mergi la **Settings → Storage**, selectează stick-ul, și alege „Format as internal" (**asta șterge stick-ul**). Aplicațiile pot fi apoi mutate pe el din **Settings → Apps → [aplicație] → Storage**.

### Partea 6 — Ce am încercat și am abandonat

Am încercat să transformăm boxul într-un hub ușor de automatizări casnice (Node-RED, pentru a controla prize smart Wi-Fi gen Tasmota/Shelly de pe telefon) prin Termux. Am dat peste un **bug reproductibil, nerezolvat, în `apt`** pe acest build exact: `apt-get update` eșuează mereu cu `Clearsigned file isn't valid, got 'NOSPLIT'` / `getline (22: Invalid argument)`, indiferent de mirror, versiune IP, setări de pipelining HTTP, sau versiune `apt`/`libc++` (am actualizat ambele — fără nicio schimbare). `curl` descarcă exact același fișier perfect, iar `gpgv` validează acea copie curat descărcată fără probleme — deci bug-ul e specific în calea proprie de descărcare-și-parsare a lui `apt` pe acest device, nu în rețea, nu în semnătură, nu în fișier. Nu am încercat să ocolim verificarea semnăturii pachetelor ca să trecem peste asta.

**Dacă vrei control simplu on/off pentru prize smart Wi-Fi de pe telefon, sari peste Termux complet**: instalează [HTTP Shortcuts](https://github.com/Waboodoo/HTTP-Shortcuts) (open source) pe **telefon**, și creează câte un buton pentru fiecare dispozitiv, care apelează direct API-ul lui HTTP local (ex: `http://<ip-priza>/cm?cmnd=Power%20Toggle` pentru Tasmota, `http://<ip-priza>/relay/0?turn=toggle` pentru Shelly). Fără hub, fără server, fără bug de `apt` de luptat.

Am decis și să renunțăm complet la ideea de a rula Home Assistant Core sau orice software de hub *pe acest box* — 1GB de RAM e cu adevărat prea puțin ca să ruleze fiabil, chiar înainte să dăm de problema cu `apt`.
