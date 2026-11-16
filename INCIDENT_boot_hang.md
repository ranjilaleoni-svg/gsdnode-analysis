# Incident: boot hang after neutralizing `preinstall.sh`, and how we recovered / Incident: blocaj de boot după neutralizarea `preinstall.sh`, și cum am recuperat

🇬🇧 **English below** · 🇷🇴 **Română mai jos**

---

## 🇬🇧 English

### What happened

After applying [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) Part 1 (truncating `/system/bin/preinstall.sh` to empty, as part of removing the malicious agent and its factory bloatware), the device appeared stuck: it would briefly show the home screen/launcher after boot, then an overlay would take over showing:

```
WARNING: During the initializing of set-top box, pls be patient and pls don't unplug the power supply.
1. App installation status: installing.....
2. App addons installation status: installing for boot.....
```

...forever. Power-cycling repeatedly just returned to the same state (sometimes showing an earlier vendor boot splash first, which is just the normal start of each boot cycle, not a sign of deeper failure).

### Root cause

`preinstall.sh` (see the full script dump in [REPORT_EN.md](REPORT_EN.md)) is invoked by vendor code with an `install` argument on first boot. Besides doing the things we wanted to stop (disabling Play Protect, silently installing bundled APKs), on success it also sends:

```sh
am broadcast -a com.android.PreInstall -e apk_install true
```

A separate vendor component (likely the launcher or a dedicated first-boot wizard activity) **blocks on this broadcast**, showing the "installing..." overlay until it receives it. By truncating the script to empty, we also removed the one thing that was supposed to signal "done" — so the wizard waited forever for a signal that would now never come.

This was **not** actually a boot loop in the usual sense (the system wasn't crash-rebooting) — it was a legitimate boot that completed successfully, immediately followed by a first-run wizard overlay stuck waiting on a broadcast.

### How we fixed it (no reflashing, no data loss)

1. Got ADB access again. We initially struggled because wireless debugging only works once the device has joined Wi-Fi, and our device's "Wireless debugging" toggle had reset to disabled. The fix: connect via **Ethernet** instead (find the device's wired IP in **Settings → Network & Internet → Ethernet → Connected**, shown right there on screen even with the overlay up — the remote still worked, it wasn't a true modal lock), then:
   ```
   adb connect <ethernet-ip>:5555
   ```
2. Sent the missing completion broadcast manually:
   ```
   adb shell "am broadcast -a com.android.PreInstall -e apk_install true"
   adb shell "am broadcast -a com.android.PreInstall_kodi -e kodi_install true"
   ```
3. The overlay disappeared immediately, replaced by a normal first-run step (Bluetooth remote pairing wizard).

### The real root cause: this was an actual factory reset, not just a stuck wizard

After getting past the broadcast issue above, we found Chrome, Calculator, and the vendor's media center app back, the launcher reverted to stock, and Stremio/VLC/our custom launcher completely gone (not just disabled — uninstalled). `persist.*` properties we had corrected earlier (fake RAM/storage sizes, swappiness) were all back to their original fake factory values, and a backup folder we had placed on `/sdcard` earlier in the session was gone entirely.

That combination only makes sense if **`/data` was wiped completely** — a real factory reset, not just an app/package state hiccup. The actual trigger: *before* we fixed the broadcast issue, we had deployed a flawed autostart script (meant to launch Stremio automatically) that didn't guard against Android's default service-restart behavior — it exited after launching the app once, so `init` kept relaunching it in a tight loop. Across repeated power cycles while we were still diagnosing, this crash-looped the system enough times that **Android's own built-in safety mechanism (triggered after too many boot failures) performed an automatic factory data reset** as a last-resort recovery action. That reset happened to also re-trigger the first-boot provisioning wizard, which is what then got stuck on the broadcast described above (because `preinstall.sh` was already empty at the firmware level).

Confirming this mattered a lot: **the firmware-level changes (Part 1 of the optimization guide) survived completely intact** through the factory reset — `gsdnode_android` was still deleted, `init.sh` still held our own content (not the original malware watchdog), the FOTA apps and `/system/preinstall/` cache were still gone. A factory reset only wipes `/data`; it never touches `/system`. This is the whole point of doing the removal at the firmware level instead of just the `/data`-level stub from the basic guide — it's the one thing that came out of this unscathed.

Everything that lived in `/data` had to be redone: reinstalling the launcher/Stremio/VLC (this time via direct APK sideload, no Play Store — see below), re-applying the `persist.*` property fixes and swappiness tweak, and re-disabling the bloat/tracking packages.

### Fixing the autostart script properly

The original autostart script (added to `/system/bin/init.sh`, replacing the gsdnode watchdog it used to hold) looked like this:

```sh
#!/system/bin/sh
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done
sleep 5
am start -n com.stremio.one/com.stremio.tv.MainActivity
```

The bug: it **exits** after starting the app. Since the vendor's `init.rc` entry for this service has no `oneshot` flag, `init` treats any exit as a crash and restarts the service — which runs the whole script again, relaunching the app in an infinite loop, hammering memory until the system can't recover.

The fix — use a marker file to only act once, then never let the script exit:

```sh
#!/system/bin/sh
MARKER=/data/local/tmp/.stremio_autostart_done
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done
if [ ! -f "$MARKER" ]; then
  sleep 5
  am start -n com.stremio.one/com.stremio.tv.MainActivity
  touch "$MARKER" 2>/dev/null
fi
while true; do
  sleep 3600
done
```

Tested with a full reboot afterward: the app launched exactly once, and the system stayed stable (checked memory and process list repeatedly — no duplicate/respawning processes, no runaway memory pressure).

**If you add any autostart logic to this vendor's `init.sh` mechanism, make sure the script never exits** (end it with an infinite sleep loop) — otherwise you will hit this exact failure mode.

### Going further: no Google account, minimal footprint

Since everything now installs via direct APK sideload (no Play Store needed), and we didn't want a Google account on the device at all, we also disabled `com.google.android.gms`, `com.android.vending` (Play Store), and `com.google.android.gsf` — these alone were using roughly 260MB of RAM between the two GMS processes, which matters a lot on a 1GB device. `pm disable-user` worked fine for this (the earlier `SecurityException` was specific to *enabling* GMS from whatever odd state the factory reset had left it in — disabling from a normal state has no such issue).

### Takeaway for anyone following the optimization guide

- **Do the app-level cleanup (Parts 2, 10) and launcher replacement (Part 7) *after* confirming the device has fully completed its first-boot wizard at least once** (or re-check them after this incident's fix if you also hit it) — not before, and expect to possibly redo them if you touch `preinstall.sh` on this exact build.
- If you lose ADB access after a reboot and "Wireless debugging" looks disabled, try connecting via Ethernet (if available) instead of assuming the device is unreachable — the current IP is visible right in **Settings → Network & Internet**, even on an overlay-stuck screen, since the remote often still works.
- A screen showing "please wait, installing" that never finishes, right after you've modified `preinstall.sh`, points straight at this broadcast — sending it manually is a far smaller intervention than reflashing.

---

## 🇷🇴 Română

### Ce s-a întâmplat

După aplicarea Părții 1 din [OPTIMIZATION_GUIDE.md](OPTIMIZATION_GUIDE.md) (trunchierea `/system/bin/preinstall.sh` la gol, ca parte din eliminarea agentului malițios și a bloatware-ului de fabrică), device-ul a părut blocat: arăta scurt home screen-ul/launcher-ul după boot, apoi un overlay prelua ecranul, afișând:

```
WARNING: During the initializing of set-top box, pls be patient and pls don't unplug the power supply.
1. App installation status: installing.....
2. App addons installation status: installing for boot.....
```

...la infinit. Power-cycle repetat revenea tot la aceeași stare (uneori arătând mai întâi splash-ul vendor-ului de boot, care e doar startul normal al fiecărui ciclu de boot, nu semn de eșec mai adânc).

### Cauza reală

`preinstall.sh` (vezi dump-ul complet al scriptului în [RAPORT_RO.md](RAPORT_RO.md)) e invocat de codul vendor-ului cu argumentul `install` la prima pornire. Pe lângă lucrurile pe care voiam să le oprim (dezactivarea Play Protect, instalarea silențioasă de APK-uri incluse), la succes trimite și:

```sh
am broadcast -a com.android.PreInstall -e apk_install true
```

O componentă separată a vendor-ului (probabil launcher-ul sau o activitate dedicată de wizard la prima pornire) **blochează așteptând acest broadcast**, afișând overlay-ul "installing..." până îl primește. Trunchiind scriptul la gol, am eliminat și singurul lucru care trebuia să semnaleze "gata" — deci wizard-ul a așteptat la infinit un semnal care acum nu mai venea niciodată.

Asta **nu** a fost de fapt un boot loop în sensul obișnuit (sistemul nu repornea din cauza unui crash) — a fost un boot legitim, finalizat cu succes, urmat imediat de un overlay de wizard la prima rulare, blocat așteptând un broadcast.

### Cum am reparat (fără reflash, fără pierdere de date)

1. Am recăpătat acces ADB. Inițial am avut probleme pentru că depanarea wireless merge doar odată ce device-ul s-a conectat la Wi-Fi, iar toggle-ul "Wireless debugging" al device-ului nostru revenise la dezactivat. Soluția: conectare prin **Ethernet** în loc (găsești IP-ul cablat al device-ului în **Settings → Network & Internet → Ethernet → Connected**, afișat chiar acolo pe ecran chiar și cu overlay-ul activ — telecomanda tot funcționa, nu era un blocaj modal real), apoi:
   ```
   adb connect <ip-ethernet>:5555
   ```
2. Am trimis manual broadcast-ul de finalizare care lipsea:
   ```
   adb shell "am broadcast -a com.android.PreInstall -e apk_install true"
   adb shell "am broadcast -a com.android.PreInstall_kodi -e kodi_install true"
   ```
3. Overlay-ul a dispărut imediat, înlocuit de un pas normal de prima rulare (wizard de împerechere telecomandă Bluetooth).

### Cauza reală: a fost chiar un factory reset, nu doar un wizard blocat

După ce am trecut de problema cu broadcast-ul de mai sus, am găsit Chrome, Calculator și aplicația media center a vendor-ului înapoi, launcher-ul revenit la stock, iar Stremio/VLC/launcher-ul nostru custom complet dispărute (nu doar dezactivate — dezinstalate). Proprietățile `persist.*` pe care le corectasem mai devreme (dimensiuni false de RAM/stocare, swappiness) erau toate revenite la valorile false originale de fabrică, iar un folder de backup pe care-l pusesem pe `/sdcard` mai devreme în sesiune dispăruse complet.

Combinația asta are sens doar dacă **`/data` a fost șters complet** — un factory reset real, nu doar un hiccup de stare a aplicațiilor/pachetelor. Declanșatorul real: *înainte* să reparăm problema cu broadcast-ul de mai sus, implementasem un script de auto-pornire defect (menit să lanseze Stremio automat) care nu se proteja împotriva comportamentului implicit al Android de a reporni serviciile — se termina după ce lansa aplicația o dată, deci `init` îl relansa într-o buclă strânsă. De-a lungul reporniri repetate cât încă diagnosticam problema, asta a făcut sistemul să intre în crash-loop de suficiente ori încât **mecanismul propriu de siguranță al Android (declanșat după prea multe eșecuri de boot) a făcut un factory data reset automat**, ca acțiune de recuperare de ultimă instanță. Acel reset a redeclanșat și wizard-ul de provisioning la prima pornire, care apoi s-a blocat exact pe broadcast-ul descris mai sus (pentru că `preinstall.sh` era deja gol la nivel de firmware).

A fost important să confirmăm asta: **schimbările la nivel de firmware (Partea 1 din ghidul de optimizare) au supraviețuit complet intacte** prin factory reset — `gsdnode_android` tot era șters, `init.sh` tot avea conținutul nostru propriu (nu watchdog-ul original malițios), aplicațiile FOTA și cache-ul `/system/preinstall/` tot lipseau. Un factory reset șterge doar `/data`; nu atinge niciodată `/system`. Ăsta e tot rostul de a face eliminarea la nivel de firmware în loc de stub-ul la nivel de `/data` din ghidul de bază — e singurul lucru care a ieșit neatins din asta.

Tot ce trăia în `/data` a trebuit refăcut: reinstalarea launcher-ului/Stremio/VLC (de data asta prin sideload direct de APK, fără Play Store — vezi mai jos), re-aplicarea fix-urilor de proprietăți `persist.*` și a ajustării swappiness, și re-dezactivarea pachetelor de bloat/tracking.

### Repararea corectă a scriptului de auto-pornire

Scriptul original de auto-pornire (adăugat în `/system/bin/init.sh`, înlocuind watchdog-ul gsdnode pe care-l ținea înainte) arăta așa:

```sh
#!/system/bin/sh
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done
sleep 5
am start -n com.stremio.one/com.stremio.tv.MainActivity
```

Bug-ul: **se termină** după ce pornește aplicația. Din moment ce intrarea din `init.rc` a vendor-ului pentru acest serviciu n-are flag-ul `oneshot`, `init` tratează orice terminare ca un crash și repornește serviciul — ceea ce rulează tot scriptul din nou, relansând aplicația într-o buclă infinită, lovind memoria până când sistemul nu se mai poate recupera.

Fix-ul — folosește un fișier marker ca să acționezi o singură dată, apoi nu mai lăsa scriptul să se termine niciodată:

```sh
#!/system/bin/sh
MARKER=/data/local/tmp/.stremio_autostart_done
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 1
done
if [ ! -f "$MARKER" ]; then
  sleep 5
  am start -n com.stremio.one/com.stremio.tv.MainActivity
  touch "$MARKER" 2>/dev/null
fi
while true; do
  sleep 3600
done
```

Testat cu un reboot complet după: aplicația a pornit exact o dată, iar sistemul a rămas stabil (am verificat memoria și lista de procese repetat — niciun proces duplicat/relansat, nicio presiune de memorie scăpată de sub control).

**Dacă adaugi orice logică de auto-pornire în mecanismul `init.sh` al acestui vendor, asigură-te că scriptul nu se termină niciodată** (termină-l cu o buclă infinită de sleep) — altfel vei da exact peste acest mod de eșec.

### Mergând mai departe: fără cont Google, consum minim

Din moment ce acum totul se instalează prin sideload direct de APK (fără nevoie de Play Store), și n-am vrut deloc un cont Google pe device, am dezactivat și `com.google.android.gms`, `com.android.vending` (Play Store) și `com.google.android.gsf` — astea singure foloseau aproximativ 260MB RAM între cele două procese GMS, ceea ce contează mult pe un device cu 1GB. `pm disable-user` a mers fără probleme pentru asta (`SecurityException`-ul de mai devreme era specific pentru *activarea* GMS din orice stare ciudată în care-l lăsase factory reset-ul — dezactivarea dintr-o stare normală nu are această problemă).

### Concluzie pentru oricine urmează ghidul de optimizare

- **Fă curățarea la nivel de aplicații (Părțile 2, 10) și înlocuirea launcher-ului (Partea 7) *după* ce confirmi că device-ul și-a finalizat complet wizard-ul de prima pornire măcar o dată** (sau reverifică-le după fix-ul acestui incident dacă-l întâlnești și tu) — nu înainte, și așteaptă-te posibil să le refaci dacă umbli la `preinstall.sh` pe acest build exact.
- Dacă pierzi accesul ADB după un reboot și "Wireless debugging" pare dezactivat, încearcă conectarea prin Ethernet (dacă e disponibil) în loc să presupui că device-ul e inaccesibil — IP-ul curent e vizibil chiar în **Settings → Network & Internet**, chiar și pe un ecran blocat de overlay, pentru că telecomanda funcționează adesea tot.
- Un ecran care arată "te rog așteaptă, se instalează" și nu se termină niciodată, chiar după ce ai modificat `preinstall.sh`, indică direct spre acest broadcast — trimiterea lui manuală e o intervenție mult mai mică decât un reflash.
