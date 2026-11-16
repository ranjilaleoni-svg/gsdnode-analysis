# gsdnode: un agent de control la distanță / proxy rezidențial rulând ca root, găsit preinstalat pe un box Android TV cu chipset Rockchip RK3528

**Status:** neconfirmat de niciun vendor sau firmă de securitate — analiză independentă, realizată de proprietarul device-ului.
**Data:** 2026-11-16
**Device:** Box Android TV, etichetat `HS86UI`, placă `rockchip,rk3518-hugsun-x88pro-ddr4-v10` (chip-ul e de fapt RK3528A; „RK3518" pare o eticheta greșită folosită de acest vendor), Android 14, fingerprint de build `HS86UI.E160320.667.FE`, 1GB RAM, ~8GB eMMC, build userdebug, SELinux **Permissive**, bootloader deblocat, proprietăți de device/model Google falsificate ca Pixel 5 ("redfin").

## Cum a început

Auzisem că boxurile chinezești ieftine sunt renumite pentru malware sau cod de botnet ascuns în ele, așa că atunci când am luat unul, am bănuit că probabil are și al meu ceva ascuns. N-am vrut să scormonesc manual prin firmware, așa că am folosit un asistent AI (Claude, prin acces ADB wireless la box) ca să investighez: am scos un raport complet de hardware, am testat redarea, apoi am cerut un scan activ pentru orice e suspect. Scanarea a scos la iveală un proces cu privilegii root (`gsdnode_android`) care n-avea ce căuta într-un simplu media player. De acolo, am mers mai adânc — analiză statică a binarului, corelare cu un repository public care analizase fișiere identice byte-cu-byte de pe un alt box rebranduit, captură de trafic live ca să confirm că serverul de comandă-control chiar e activ, și în final, tot ce vezi aici, plus un script care neutralizează agentul direct pe device. Bănuiala inițială s-a confirmat; acest raport e rezultatul verificării efective.

## Informații despre achiziție

Exact acest device (fingerprint de build `HS86UI.E160320.667.FE`) a fost cumpărat din România prin **eMag Marketplace**, listat sub numele „Player Media 8K HDR" (TV Box Android, HS86UI Pro X88), vândut și livrat de comerciantul de pe marketplace **UWOT GERMANY GMBH**, cu 233,17 Lei, în noiembrie 2026.

Această informație e menționată ca alți cumpărători să poată recunoaște același anunț/comerciant și să-l evite, sau să verifice un device pe care îl au deja. **Nu** e o acuzație că acest reseller anume ar fi instalat sau ar fi știut în mod conștient despre agentul descris mai jos — firmware-ul în cauză e aproape sigur furnizat în amonte de producătorul/ODM-ul real al device-ului din China (vezi secțiunea „Lucrări conexe" pentru alți vendori cu același tipar), iar resellerii de pe platforme precum eMag de obicei nu au vizibilitate asupra a ceea ce rulează efectiv în interiorul device-ului pe care îl listează. S-a depus o reclamație formală către vânzător și o sesizare către Autoritatea Națională pentru Protecția Consumatorilor (ANPC) legat de această achiziție specifică.

## Rezumat

Boxul a fost achiziționat ca un device generic, ieftin, de streaming Android TV. Depanarea ADB wireless a fost lăsată activă de vendor. Analiza sistemului în funcțiune a găsit un binar nativ cu privilegii root, `gsdnode_android`, pornit direct de `init.rc`-ul propriu al vendor-ului, care:

- rulează ca root, repornit la fiecare ~10s de un script shell de tip watchdog dacă se oprește;
- interoghează `api.ipify.org` la fiecare pornire ca să-și afle IP-ul public (descoperire NAT);
- conține referințe hardcodate către un endpoint de comandă-control `tws.gsda.com.cn:7704`, confirmat activ și acceptând conexiuni TCP, găzduit pe Alibaba Cloud (Hangzhou, AS37963);
- expune capabilități de tip shell la distanță (`gsdshell`, `persist_shell`, `installapk`) și identificatori de plugin care corespund unor SDK-uri cunoscute de PCDN/proxy rezidențial (`niulink`, `wxedge`, `dianxin`, `ksc-kepler`, `ross_atv`, `airship-agent`);
- este însoțit de alte trei aplicații de sistem semnate din fabrică, ce oferă canale de update FOTA/OTA (`com.amediatech.update` / Adups, `com.chihi.fota`, `android.rockchip.update.service` / RKUpdateService), capabile de instalare silențioasă de APK-uri, toate cu aceeași semnătură de platformă;
- vine cu Google Play Protect dezactivat printr-un script `preinstall.sh` al vendor-ului (`package_verifier_enable=0`);
- include un loader (în interiorul `RKUpdateService.apk`) pentru o cale ascunsă de payload secundar (`/data/blueberry/blueberry.sh`), inexistentă la momentul analizei, dar referențiată în cod.

Tiparul se potrivește cu ce s-a documentat public pentru **BADBOX / BADBOX 2.0** (Human Security, Google), **Vo1d** (Dr.Web) și, cel mai apropiat, **Operation Fuyao** (Bitsight, iulie 2026) — boxuri Android TV ieftine, preîncărcate din fabrică cu agenți care transformă banda de internet a proprietarului într-un releu proxy rezidențial/PCDN și/sau rulează sarcini de fraudă publicitară, fără știrea sau consimțământul proprietarului. Autorul acestui raport nu a găsit nicio documentare publică legată explicit de domeniile `gsda.com.cn`, `rupa.tv` sau `hugsun.com.cn`, sau de acest build exact de firmware — cu excepția unui singur repository GitHub independent (`rk3518-malware-quarantine`), care analizează copii identice byte-cu-byte a două dintre aceleași APK-uri, pe un box cu alt brand, ceea ce sugerează firmware comun pe mai multe produse rebranduite.

## De ce contează

Nimic din toate astea nu cere utilizatorului să instaleze ceva sau să dea click pe ceva. E inclus direct în imaginea de firmware din fabrică (timestamp-urile fișierelor din partițiile `/system` și `/vendor` arată data epoch de reproducibilitate a build-ului Android, `2009-01-01` — adică fac parte din imaginea de sistem originală, nu au fost adăugate ulterior). Un consumator care conectează boxul ăsta la Wi-Fi-ul de acasă donează, prin proiectare, o parte din banda sa de upload și din reputația IP-ului său unor terți necunoscuți, fără niciun ecran de consimțământ, fără politică de confidențialitate afișată și fără nicio opțiune de renunțare din firmware-ul standard.

## Dovezi tehnice

### 1. Execuția ca root e definită de vendor, nu injectată ulterior

`/vendor/etc/init/hw/init.rk30board.rc`, linia 410-413 (sha256 `8bb2c3d369a6ae934be68618632076c0876562fe7fd2ca441697f8a4b53d2aac`, timestamp fișier `2009-01-01` = timp de build):

```
service init /system/bin/init.sh
    class main
    user root
    group root
```

### 2. Scriptul watchdog (`/system/bin/init.sh`, sha256 `f65a73500363126d083568818890ef7c4e056e1b9575cc102ba7f7ec93af0617`)

Copiază `/system/bin/gsdnode_android` în `/data/gsdnode/` la prima pornire (condiționat de `persist.gsdnode.init.copy`), derivă un ID de device din adresa MAC (eth0 → wlan0 → fallback pe serial), apoi intră într-o buclă infinită:

```sh
while true; do
  pgrep -f 'gsdnode_android*' || $DATA_DIR/gsdnode_android $mac_address &
  sleep 10
done
```

### 3. Binarul (`gsdnode_android`, 2.836.728 bytes, sha256 `2d919a92d2e548d5ce433f79eda1b939e7b57f0381f570da02fe9ae94b3ef801`)

Un ELF Go ARM32 împachetat cu UPX (dezambalat la 7.797.780 bytes). Analiza statică a string-urilor/simbolurilor arată funcțiile `GsdAgentMain`, `GsdNodeMain`, `GsdInstallMain`, `checkServerTaskLists`, `doUpdateTasksHttpRequest`, `startLocalTasks`, `runPersistentTasks`, `savePersistentShell`, `dealSystemAction`, și endpoint-urile HTTP `/box/powerOn`, `/box/heartbeat`, `/box/uploadNodeTasks`, `/box/uploadResult`, `/box/api/dispatch/updateDeviceNIC`.

### 4. Confirmare live a endpoint-ului C2 (realizată de pe alt dispozitiv din aceeași rețea, nu de pe box)

```
ping tws.gsda.com.cn
  -> rezolvă la 115.29.212.137, răspunde la ICMP (~216ms RTT)

whois/geo: AS37963 Hangzhou Alibaba Advertising Co., Ltd., Hangzhou, China

Test-NetConnection -ComputerName 115.29.212.137 -Port 7704
  -> TcpTestSucceeded: True
```

### 5. Captură de trafic live

O captură de pachete realizată pe device (`tcpdump`, root) în timpul unei reporniri forțate a agentului arată, în clar, în interiorul SNI-ului TLS ClientHello, un prim apel extern către `api.ipify.org` (descoperire IP public) printr-un IP mascat de Cloudflare, consistent cu logica `natType` găsită în binar. Nicio conexiune directă către `tws.gsda.com.cn:7704` nu a fost surprinsă în fereastra de observare de ~2 minute, dintr-o rețea rezidențială din România; asta e consistent fie cu un interval rar de check-in, fie cu diferențe de accesibilitate regională — nu cu faptul că serverul ar fi inactiv (vezi punctul 4).

### 6. Refuzuri SELinux (Permissive — logate, nu blocate)

```
avc: denied { read } for name="gsdnode" ... scontext=u:r:shell:s0 tcontext=u:object_r:system_data_root_file:s0 tclass=dir permissive=1
avc: denied { execute } for name="gsdnode_android" ... tclass=file permissive=1
avc: denied { dac_read_search } for capability=2 scontext=u:r:shell:s0 tcontext=u:r:shell:s0 tclass=capability permissive=1
```

### 7. Semnătură comună pentru cele trei aplicații FOTA/update

```
com.amediatech.update            codePath=/system/app/Abupdate_new       semnatura=b1a1812f  firstInstallTime=2009-01-01
com.chihi.fota                    codePath=/system/app/FotaUpdate          semnatura=b1a1812f  firstInstallTime=2009-01-01
android.rockchip.update.service   codePath=/system/app/RKUpdateService     semnatura=b1a1812f  firstInstallTime=2009-01-01
```

Semnătură identică, timp de instalare identic (epoch), cale de sistem identică — toate trei fac parte din același build de fabrică, semnat cu aceeași cheie.

### 8. Persistență dincolo de „dezactivare"

Dezactivarea celor trei aplicații FOTA prin `pm disable-user` și oprirea lor forțată cu `am force-stop` **nu** le-a împiedicat să fie relansate de sistem — sunt marcate `persistent` în firmware și sunt repornite de `system_server` indiferent. Eliminarea lor completă ar necesita remontarea `/system` ca read-write, ceea ce riscă să declanșeze dm-verity (au fost observate thread-uri kernel `kverityd` active) și să facă boxul nefuncțional ("brick"); acest pas nu a fost încercat intenționat.

## Indicatori de compromitere (IOC)

| Tip | Valoare | Observații |
|---|---|---|
| Domeniu | `tws.gsda.com.cn` | C2, port 7704, confirmat activ |
| Domeniu | `gsda.com.cn` | domeniul părinte |
| Domeniu | `api.fota.rupa.tv`, `fota.rupa.tv`, `ota.rupa.tv` | client FOTA (`com.chihi.fota`) |
| Domeniu | `api.hugsun.com.cn`, `fota.hugsun.com.cn`, `erp.hugsun.com.cn` | telemetrie/update vendor (neverificat dincolo de domeniul vendor-ului însuși) |
| IP | `115.29.212.137` | rezoluția curentă a `tws.gsda.com.cn`, Alibaba Cloud Hangzhou |
| Fișier (SHA256) | `2d919a92d2e548d5ce433f79eda1b939e7b57f0381f570da02fe9ae94b3ef801` | `/system/bin/gsdnode_android` și `/data/gsdnode/gsdnode_android` |
| Fișier (SHA256) | `f65a73500363126d083568818890ef7c4e056e1b9575cc102ba7f7ec93af0617` | `/system/bin/init.sh` |
| Hash semnătură APK | `b1a1812f` | comun pentru Abupdate_new, FotaUpdate, RKUpdateService |
| Fingerprint build | `HS86UI.E160320.667.FE` | acest build exact de firmware |

## Remediere (testată pe acest device)

Scriptul atașat `neutralize_gsdnode.sh`, rulat o singură dată prin `adb root` + `adb shell`:

1. Face backup la binarul original al agentului și la scriptul watchdog, în `/sdcard/`.
2. Oprește agentul activ.
3. Setează `persist.gsdnode.init.copy=1` ca watchdog-ul să nu mai recopieze binarul real din `/system/bin`.
4. Înlocuiește `/data/gsdnode/gsdnode_android` cu un stub inofensiv (`exit 0`) — watchdog-ul tot „îl pornește" la 10s, dar nu face nimic.
5. Dezactivează cele trei aplicații FOTA/update și le șterge datele.
6. Reactivează Google Play Protect.

Asta oprește agentul fără să atingă partiția `/system` (risc mai mic de brick decât reflash-area sau remontarea read-write a sistemului). **Nu** supraviețuiește unui factory reset sau unui reflash OTA/firmware — payload-ul e în imaginea de sistem.

Se recomandă oricum o atenuare la nivel de rețea (blocklist DNS pe router/Pi-hole/AdGuard Home, blocând `gsda.com.cn`, `rupa.tv`, `hugsun.com.cn`) ca strat suplimentar de apărare, din moment ce aplicațiile FOTA nu pot fi eliminate complet fără remontarea sistemului.

## Notă de divulgare

Nu s-a încercat niciun contact cu vendor-ul înainte de această publicare; device-ul a fost cumpărat printr-un canal de retail obișnuit, fără o relație directă clară cu vendor-ul, iar comportamentul descris se potrivește cu un tipar deja raportat public de alți cercetători pentru alți vendori (Bitsight/Fuyao, Human Security/BADBOX), fără un ciclu formal de răspuns din partea vendor-ului. Acest raport e publicat ca să ajute alți proprietari de boxuri identice vizual sau branduite similar să recunoască și să atenueze aceeași problemă.

## Lucrări conexe

- Bitsight, "The Fuyao Enterprise" (iulie 2026) — cel mai apropiat paralelism cunoscut (proxy rezidențial SOCKS5 + fraudă publicitară, dependent de starea HDMI).
- Human Security / Google, BADBOX și BADBOX 2.0.
- Dr.Web, botnet-ul Vo1d.
- GitHub: `freddy-newandyke/rk3518-malware-quarantine` — analiză independentă a unor `RKUpdateService.apk` / `FotaUpdate.apk` identice byte-cu-byte, pe un alt rebrand al aparent aceluiași firmware de bază.
