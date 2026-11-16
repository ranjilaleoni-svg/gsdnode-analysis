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

### Part 7 — Replacing the factory launcher

The stock launcher (`com.android.box.tvlauncher`) is closed-source; don't try to decompile/patch it. Install an open-source alternative instead and switch to it cleanly:

```
adb install <launcher.apk>
adb shell "cmd package set-home-activity <package>/<LauncherActivityClass>"
adb shell "pm disable-user --user 0 com.android.box.tvlauncher"
```

We settled on [ChillHub](https://github.com/AppleChillVibez/ChillHub) (`app.lumoslabs.chillhub`, also on Google Play) after trying and rejecting [Projectivy Launcher](https://github.com/spocky/miproja1). Find the exact launcher activity name first with:

```
adb shell "pm dump <package> | grep -A3 'android.intent.category.HOME'"
```

### Part 8 — Fixing fabricated hardware properties (display, storage, RAM)

This device's factory firmware reports fake specs in the Settings UI itself — not just in hidden `getprop` values, but in what **Settings → Storage** actually displays to the user:

```
adb shell "getprop | grep -iE 'storage.total|storage.size|mem.size'"
# persist.skytest.storage.total: 256GB (real eMMC: ~8GB)
# persist.storage.size: 256 GB
# persist.mem.size: 16 GB (real RAM: ~1GB)

adb shell "setprop persist.skytest.storage.total '8GB'"
adb shell "setprop persist.storage.size '8 GB'"
adb shell "setprop persist.mem.size '1 GB'"
adb shell "am force-stop com.android.tv.settings"
```

These are `persist.*` properties, so they survive reboot. Verify in **Settings → Device Preferences → Storage**.

Separately, we found a **display resolution override** forcing apps to render at 3840×2160 while the real panel is 1280×720 (density override 640 vs. real 213) — this causes visibly wrong UI scaling in some apps:

```
adb shell "wm size"       # shows "Override size: 3840x2160" if affected
adb shell "wm size reset"
adb shell "wm density reset"
```

### Part 9 — Streaming app buffering: a real hardware limit, not a bug

If a torrent-based streaming app (e.g. Stremio) buffers badly even on a decent connection, check memory pressure first:

```
adb shell "cat /proc/meminfo | head -3"
adb shell "top -b -n 1 | head -15"    # look for high %CPU on [kswapd0] and the app's own server process
```

On this 1GB RAM device, we measured 95%+ RAM used and `kswapd0` (kernel memory reclaim) at 40% CPU **even at idle**, and during active torrent playback the app's embedded streaming-server process plus its main process together used roughly half the entire CPU. This is a genuine hardware ceiling, not something a setting fixes:

- Prefer addons/sources that give **direct HTTP links** (including debrid services) over torrent-based ones — this moves all the heavy piece-management work off the device entirely.
- `am force-stop <package>` between viewing sessions for a clean restart.
- **Caution**: we triggered a full system hang (unresponsive to ADB, had to power-cycle) by restarting a torrent-streaming app while RAM was already critically low. No data was lost (it only affects running apps, not the firmware changes from Part 1), but don't be surprised if it happens to you too under the same conditions.

### Part 10 — Round two: more factory/tracking services safe to disable

Beyond Part 2's list, these are safe to `pm disable-user --user 0` on a personal device (not an enterprise-managed one):

```
com.android.adservices.api  com.android.ext.adservices.api  com.android.sdksandbox
com.android.federatedcompute.services  com.android.ondevicepersonalization.services
com.android.healthconnect.controller  com.android.health.connect.backuprestore
com.android.virtualmachine.res  com.android.uwb.resources  com.android.dynsystem
com.android.nearby.halfsheet  com.google.android.feedback
com.google.android.marvin.talkback      # TalkBack screen reader — skip if you need accessibility
com.android.music  com.android.calculator2
com.google.android.apps.mediashell      # Chromecast built-in — skip if you want casting to work
com.google.android.tvrecommendations  com.google.android.katniss   # voice search/assistant
```

Two things to watch for:
- `com.android.devicelockcontroller` is a **protected package** — `pm disable-user` throws `SecurityException: Cannot disable a protected package`. It's harmless and inactive anyway; not worth removing it at the firmware level just for this.
- **Double-check `com.google.android.gms` (Google Play Services) stays enabled** after a batch-disable loop. We found it unexpectedly disabled once during this process (cause unconfirmed — possibly a pre-existing state, not necessarily caused by the batch itself) and had to re-enable it with `pm enable --user 0 com.google.android.gms`. Disabling it breaks Play Store, sign-in, and push notifications for most apps.

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

### Partea 7 — Înlocuirea launcher-ului din fabrică

Launcher-ul stock (`com.android.box.tvlauncher`) e closed-source; nu încerca să-l decompilezi/patch-uiești. În schimb, instalează o alternativă open-source și comută curat pe ea:

```
adb install <launcher.apk>
adb shell "cmd package set-home-activity <pachet>/<NumeClasaLauncherActivity>"
adb shell "pm disable-user --user 0 com.android.box.tvlauncher"
```

Am ales [ChillHub](https://github.com/AppleChillVibez/ChillHub) (`app.lumoslabs.chillhub`, și pe Google Play) după ce am testat și respins [Projectivy Launcher](https://github.com/spocky/miproja1). Găsește numele exact al activității de launcher întâi cu:

```
adb shell "pm dump <pachet> | grep -A3 'android.intent.category.HOME'"
```

### Partea 8 — Corectarea proprietăților de hardware fabricate (display, stocare, RAM)

Firmware-ul de fabrică al acestui device raportează specificații false chiar în interfața Settings — nu doar în valori ascunse `getprop`, ci în ce afișează efectiv **Settings → Storage** utilizatorului:

```
adb shell "getprop | grep -iE 'storage.total|storage.size|mem.size'"
# persist.skytest.storage.total: 256GB (eMMC real: ~8GB)
# persist.storage.size: 256 GB
# persist.mem.size: 16 GB (RAM real: ~1GB)

adb shell "setprop persist.skytest.storage.total '8GB'"
adb shell "setprop persist.storage.size '8 GB'"
adb shell "setprop persist.mem.size '1 GB'"
adb shell "am force-stop com.android.tv.settings"
```

Astea sunt proprietăți `persist.*`, deci supraviețuiesc unui reboot. Verifică în **Settings → Device Preferences → Storage**.

Separat, am găsit un **override de rezoluție de display** care forța aplicațiile să randeze la 3840×2160 deși panelul real e 1280×720 (densitate override 640 vs. reală 213) — asta cauzează scalare vizibil greșită a UI-ului în unele aplicații:

```
adb shell "wm size"       # arata "Override size: 3840x2160" daca e afectat
adb shell "wm size reset"
adb shell "wm density reset"
```

### Partea 9 — Buffering la aplicații de streaming: o limitare reală de hardware, nu un bug

Dacă o aplicație de streaming bazată pe torrent (ex: Stremio) face buffer prost chiar și pe o conexiune decentă, verifică întâi presiunea de memorie:

```
adb shell "cat /proc/meminfo | head -3"
adb shell "top -b -n 1 | head -15"    # cauta %CPU mare la [kswapd0] si la procesul propriu de server al aplicatiei
```

Pe acest device cu 1GB RAM, am măsurat 95%+ RAM folosit și `kswapd0` (recuperare memorie din kernel) la 40% CPU **chiar la idle**, iar în timpul redării active prin torrent, procesul serverului intern de streaming al aplicației plus procesul principal foloseau împreună aproximativ jumătate din tot CPU-ul. E un plafon real de hardware, nu ceva ce o setare rezolvă:

- Preferă addon-uri/surse cu **linkuri HTTP directe** (inclusiv servicii debrid) în loc de cele bazate pe torrent — asta mută toată munca grea de gestionare a pieselor în afara device-ului complet.
- `am force-stop <pachet>` între sesiunile de vizionare, pentru o pornire curată.
- **Atenție**: am declanșat un blocaj complet de sistem (nerăspunzător la ADB, a trebuit power-cycle fizic) repornind o aplicație de streaming torrent cât timp RAM-ul era deja critic de puțin. Nicio dată n-a fost pierdută (afectează doar aplicațiile care rulau, nu modificările de firmware din Partea 1), dar nu te surprinde dacă ți se întâmplă și ție în condiții similare.

### Partea 10 — Runda a doua: mai multe servicii factory/tracking sigure de dezactivat

Dincolo de lista din Partea 2, astea sunt sigure de dezactivat cu `pm disable-user --user 0` pe un device personal (nu unul administrat enterprise):

```
com.android.adservices.api  com.android.ext.adservices.api  com.android.sdksandbox
com.android.federatedcompute.services  com.android.ondevicepersonalization.services
com.android.healthconnect.controller  com.android.health.connect.backuprestore
com.android.virtualmachine.res  com.android.uwb.resources  com.android.dynsystem
com.android.nearby.halfsheet  com.google.android.feedback
com.google.android.marvin.talkback      # cititorul de ecran TalkBack — sari peste daca ai nevoie de accesibilitate
com.android.music  com.android.calculator2
com.google.android.apps.mediashell      # Chromecast built-in — sari peste daca vrei sa mearga casting-ul
com.google.android.tvrecommendations  com.google.android.katniss   # cautare vocala/asistent
```

Două lucruri de urmărit:
- `com.android.devicelockcontroller` e un **pachet protejat** — `pm disable-user` aruncă `SecurityException: Cannot disable a protected package`. E inofensiv și oricum inactiv; nu merită eliminat la nivel de firmware doar pentru atât.
- **Verifică de două ori că `com.google.android.gms` (Google Play Services) rămâne activat** după o buclă de dezactivări în masă. Noi l-am găsit dezactivat pe neașteptate o dată în timpul acestui proces (cauza neconfirmată — posibil o stare preexistentă, nu neapărat cauzată de buclă în sine) și a trebuit să-l reactivăm cu `pm enable --user 0 com.google.android.gms`. Dezactivarea lui strică Play Store, autentificarea și notificările push pentru majoritatea aplicațiilor.

### Partea 11 — Setup complet fără cont Google (sideload direct)

Dacă nu vrei deloc cont Google pe device (niciun sign-in, telemetrie minimă) și instalezi orice aplicație prin sideload direct (fără Play Store), poți dezactiva complet stiva Google:

```
adb shell "pm disable-user --user 0 com.google.android.gms"
adb shell "pm disable-user --user 0 com.android.vending"
adb shell "pm disable-user --user 0 com.google.android.gsf"
```

Pe acest device, asta a eliberat ~260MB RAM (cele două procese GMS, `com.google.android.gms` și `com.google.android.gms.persistent`, foloseau împreună atât) — semnificativ pe un device cu doar 1GB total.

Pentru a instala aplicații fără Play Store, descarcă APK-ul oficial direct de la dezvoltator (nu de pe mirror-uri terțe necunoscute) și instalează-l prin ADB:

```
adb install nume_aplicatie.apk
```

Surse oficiale verificate, folosite în acest proiect: [videolan.org](https://www.videolan.org/vlc/download-android.html) pentru VLC, [stremio.com/downloads](https://www.stremio.com/downloads) pentru Stremio (secțiunea „Android TV" → „Manual install"), [buildbot.libretro.com](https://buildbot.libretro.com/stable/) pentru RetroArch.

### Partea 12 — Emulare retro (RetroArch) pe acest hardware

Chipset-ul (RK3528A, GPU Mali-450, 1GB RAM) e suficient pentru console retro pe 8/16-biți (NES, SNES, Mega Drive/Genesis, Game Boy/GBA) — rulează fără probleme prin **RetroArch** (open source), instalat prin sideload de pe buildbot-ul oficial Libretro (link mai sus, varianta `RetroArch.apk` pentru ARM32).

Console mai pretențioase (PlayStation 1, N64) sunt la limită — GPU-ul slab și RAM-ul puțin fac jocurile 3D intensive greu de rulat stabil; merită testat per caz, nu garantat.

**Important despre ROM-uri**: RetroArch în sine e legal (software open source). ROM-urile jocurilor comerciale (Nintendo, Sega etc.) sunt protejate de drepturi de autor — folosește doar ROM-uri pe care le deții legal (dump-uri proprii de pe cartușe fizice deținute) sau ROM-uri homebrew cu licență liberă (ex: [pdroms.de](https://pdroms.de)). Nu descărca pachete de ROM-uri de pe site-uri de arhivă.

### Partea 13 — Maparea telecomenzii stock pentru emulatoare (referință hardware)

Telecomanda standard a acestui box (model generic „TV98") se comportă ca o **tastatură HID Bluetooth standard** la nivel de kernel Linux — apare ca device-ul `/dev/input/eventX` cu numele **„TV98 Keyboard"** (plus un al doilea device, "TV98 Mouse", pentru funcția de pointer). Codurile exacte confirmate prin `adb shell getevent -lt`:

| Buton fizic | Cod Linux (evdev) |
|---|---|
| Sus / Jos / Stânga / Dreapta (D-pad) | `KEY_UP` / `KEY_DOWN` / `KEY_LEFT` / `KEY_RIGHT` |
| OK | `KEY_ENTER` |
| Back | `KEY_BACK` |
| Menu (≡) | `KEY_MENU` |
| APPS | `KEY_PROPS` |
| Volum + / − | `KEY_VOLUMEUP` / `KEY_VOLUMEDOWN` |
| Mute | `KEY_MUTE` |
| Canal ∧ / ∨ | **`KEY_UNKNOWN`** — nefuncțional |

**Observație importantă**: butoanele de Canal (∧/∨) trimit coduri HID Consumer Page (`0x00de`/`0x00df` pe scan code-ul raw) pentru care driverul de kernel al acestui device **nu are un mapping definit** — ajung ca `KEY_UNKNOWN` și Android le ignoră complet, indiferent de aplicație sau configurare. Singura reparare ar fi un fișier `.kl` (keylayout) custom la nivel de `/system`/`/vendor`, netestat în acest proiect.

Pentru emulatoare ca RetroArch, asta înseamnă: D-pad, OK, Back, Menu, Mute, APPS, Volum+/− sunt toate utilizabile ca bind-uri de taste fizice (prin Quick Menu → Controls → Port 1 Controls → apasă fizic tasta când ești întrebat), dar telecomanda stock, singură, nu poate acoperi toate funcțiile unui controller complet (ex: butoanele C de la N64) — un gamepad Bluetooth extern (ex: DualShock 4, recunoscut nativ de RetroArch) rămâne soluția practică pentru console cu mai multe butoane.
