# Step-by-step removal guide / Ghid pas cu pas de eliminare

🇬🇧 **English below** · 🇷🇴 **Română mai jos**

---

## 🇬🇧 English

### Before you start

- This works on Windows, Mac, or Linux. You need a computer and the box on the **same Wi-Fi network**.
- This does **not** require root, unlocking anything, or voiding any warranty step beyond what the vendor already shipped (the box already ships with `adb root` working — see [REPORT_EN.md](REPORT_EN.md)).
- This removes the malicious agent without touching the `/system` partition, so it's low-risk. It does **not** survive a factory reset — see the warning at the bottom.

### Step 1 — Install ADB (Android Debug Bridge)

- **Windows:** download "platform-tools" from Google: https://developer.android.com/tools/releases/platform-tools , unzip it anywhere (e.g. `C:\platform-tools`).
- **Mac:** `brew install android-platform-tools`
- **Linux:** `sudo apt install adb` (Debian/Ubuntu) or your distro's equivalent.

Open a terminal (PowerShell on Windows, Terminal on Mac/Linux) and `cd` into the folder where `adb.exe`/`adb` is, unless you added it to your PATH.

### Step 2 — Enable Wireless Debugging on the box

On the Android TV box, go to **Settings → Device Preferences → About** and tap the build number several times to unlock **Developer Options**. Then go to **Settings → Device Preferences → Developer Options** and turn on:
- **USB debugging** (some boxes require this too)
- **Wireless debugging** (Android 11+) — this will show a **pairing code** and an **IP address : port**.

### Step 3 — Pair and connect

```bash
adb pair <IP>:<pairing-port>
```
It will ask for the 6-digit pairing code shown on the TV screen. Then connect:
```bash
adb connect <IP>:<connect-port>
```
(The connect port is usually shown right below/next to the pairing code screen, often `5555` on older Android TV builds — check what your box's wireless debugging screen shows.)

Confirm it worked:
```bash
adb devices
```
You should see your box listed as `device`.

### Step 4 — Get root access

```bash
adb root
```
If it says `adbd is already running as root` or `restarting adbd as root`, you're good. Wait 2-3 seconds and reconnect if needed:
```bash
adb connect <IP>:<connect-port>
```

### Step 5 — Download and run the removal script

Download [`neutralize_gsdnode.sh`](neutralize_gsdnode.sh) from this repository to your computer.

**On Windows (PowerShell), `<` redirection doesn't work — use this instead:**
```bash
Get-Content neutralize_gsdnode.sh -Raw | adb shell
```

**On Mac/Linux:**
```bash
adb shell < neutralize_gsdnode.sh
```

You should see output ending in something like:
```
Verificare finala:
  (niciun proces gsdnode activ - OK)
```
(Romanian text is normal — the script's comments are in Romanian, the logic is the same either way.)

### Step 6 — Reboot

```bash
adb reboot
```

Wait ~30-60 seconds, then reconnect and verify the agent is gone:
```bash
adb connect <IP>:<connect-port>
adb shell "ps -A | grep gsd"
```
If that second command prints nothing, the agent is neutralized. ✅

### ⚠️ Important: this does not survive a factory reset or an OTA update

The malicious agent lives inside the device's **system firmware image**, not just in `/data`. Our fix works by stopping the agent and preventing it from being restored, without touching `/system` (safer, lower risk of bricking the device). But:

- **If you factory-reset the box**, `/data` gets wiped, and the watchdog script (still present in `/system`) will re-copy the original malicious binary from `/system/bin/gsdnode_android` into `/data/gsdnode/` again, undoing the fix. **You will need to run Steps 3-6 again after any factory reset.**
- **If the box installs an OTA/firmware update** (if you haven't disabled that — which this script also does, for the vendor's own update apps, but a full OTA system update could still overwrite everything), the same thing can happen.
- We also strongly recommend blocking the malicious domains at your router level (see [blocklist.txt](blocklist.txt)) as a second layer of defense that survives resets.

### 💡 Future idea

A simple phone/desktop app that automates all of the above (pair, connect, root, push script, verify, remind you to redo it after a reset) would make this accessible to non-technical users. Not built yet — this is a possible follow-up project. If you want to help build it, open an issue or a PR.

---

## 🇷🇴 Română

### Înainte să începi

- Funcționează pe Windows, Mac sau Linux. Ai nevoie de un calculator și de box pe **aceeași rețea Wi-Fi**.
- **Nu** necesită root suplimentar, deblocare sau anularea vreunei garanții, dincolo de ce vine deja activat din fabrică pe box (`adb root` funcționează deja din fabrică — vezi [RAPORT_RO.md](RAPORT_RO.md)).
- Elimină agentul malițios fără să atingă partiția `/system`, deci riscul e mic. **Nu** supraviețuiește unui factory reset — vezi avertismentul de la final.

### Pasul 1 — Instalează ADB (Android Debug Bridge)

- **Windows:** descarcă "platform-tools" de la Google: https://developer.android.com/tools/releases/platform-tools , dezarhivează oriunde (ex: `C:\platform-tools`).
- **Mac:** `brew install android-platform-tools`
- **Linux:** `sudo apt install adb` (Debian/Ubuntu) sau echivalentul distribuției tale.

Deschide un terminal (PowerShell pe Windows, Terminal pe Mac/Linux) și intră (`cd`) în folderul unde e `adb.exe`/`adb`, dacă nu l-ai adăugat la PATH.

### Pasul 2 — Activează Wireless Debugging pe box

Pe boxul Android TV, mergi la **Settings → Device Preferences → About** și apasă de mai multe ori pe numărul de build ca să deblochezi **Developer Options**. Apoi mergi la **Settings → Device Preferences → Developer Options** și activează:
- **USB debugging** (unele boxuri cer și asta)
- **Wireless debugging** (Android 11+) — asta îți arată un **cod de împerechere** și o **adresă IP : port**.

### Pasul 3 — Împerechează și conectează

```bash
adb pair <IP>:<port-impereche>
```
Îți va cere codul de 6 cifre afișat pe ecranul TV-ului. Apoi conectează-te:
```bash
adb connect <IP>:<port-conectare>
```
(Portul de conectare e de obicei afișat chiar sub/lângă ecranul cu codul de împerechere, adesea `5555` pe build-uri mai vechi de Android TV — verifică ce arată ecranul de wireless debugging al boxului tău.)

Confirmă că a mers:
```bash
adb devices
```
Ar trebui să vezi boxul listat ca `device`.

### Pasul 4 — Ia acces root

```bash
adb root
```
Dacă spune `adbd is already running as root` sau `restarting adbd as root`, e bine. Așteaptă 2-3 secunde și reconectează dacă e nevoie:
```bash
adb connect <IP>:<port-conectare>
```

### Pasul 5 — Descarcă și rulează scriptul de eliminare

Descarcă [`neutralize_gsdnode.sh`](neutralize_gsdnode.sh) din acest repository pe calculatorul tău.

**Pe Windows (PowerShell), redirecționarea `<` nu merge — folosește asta în loc:**
```bash
Get-Content neutralize_gsdnode.sh -Raw | adb shell
```

**Pe Mac/Linux:**
```bash
adb shell < neutralize_gsdnode.sh
```

Ar trebui să vezi un output care se termină cu ceva de genul:
```
Verificare finala:
  (niciun proces gsdnode activ - OK)
```

### Pasul 6 — Repornește

```bash
adb reboot
```

Așteaptă ~30-60 secunde, apoi reconectează și verifică faptul că agentul a dispărut:
```bash
adb connect <IP>:<port-conectare>
adb shell "ps -A | grep gsd"
```
Dacă a doua comandă nu afișează nimic, agentul e neutralizat. ✅

### ⚠️ Important: nu supraviețuiește unui factory reset sau unui update OTA

Agentul malițios trăiește în **imaginea de firmware de sistem** a device-ului, nu doar în `/data`. Fix-ul nostru funcționează oprind agentul și împiedicându-l să fie restaurat, fără să atingă `/system` (mai sigur, risc mai mic de a strica boxul). Dar:

- **Dacă faci factory reset la box**, `/data` se șterge, iar scriptul watchdog (încă prezent în `/system`) va recopia binarul original malițios din `/system/bin/gsdnode_android` înapoi în `/data/gsdnode/`, anulând fix-ul. **Va trebui să refaci Pașii 3-6 după orice factory reset.**
- **Dacă boxul instalează un update OTA/firmware** (dacă n-ai dezactivat asta — ceea ce face și scriptul ăsta, pentru aplicațiile de update ale vendor-ului, dar un update complet de sistem OTA tot ar putea suprascrie totul), se poate întâmpla la fel.
- Recomandăm cu tărie și blocarea domeniilor malițioase la nivel de router (vezi [blocklist.txt](blocklist.txt)), ca al doilea strat de apărare care supraviețuiește resetărilor.

### 💡 Idee pentru viitor

O aplicație simplă de telefon/desktop care automatizează tot ce e mai sus (împerechere, conectare, root, trimite scriptul, verifică, îți reamintește să refaci după un reset) ar face asta accesibilă și pentru utilizatori non-tehnici. Nu e construită încă — e un posibil proiect viitor. Dacă vrei să ajuți la construirea ei, deschide un issue sau un PR.
