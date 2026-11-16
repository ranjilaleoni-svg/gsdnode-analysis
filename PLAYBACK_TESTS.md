# Advertised specs vs. actual hardware / Specificații publicitate vs. hardware real

🇬🇧 **English below** · 🇷🇴 **Română mai jos**

---

## 🇬🇧 English

### What the listing advertised

The eMag listing for this box was titled **"Player Media 8K HDR"**. The product branding (`x88pro`) and typical marketing for this family of boxes implies 8K-capable playback and generous RAM/storage.

### What the hardware actually is

| Spec | Advertised (implied by listing name/branding) | Measured on the actual device |
|---|---|---|
| Video decode | "8K HDR" | SoC is Rockchip **RK3528A**. This chip's real hardware decode ceiling is **4K**, not 8K. There is no way for this specific SoC to decode 8K content in hardware. |
| RAM | Not explicitly stated, but boxes in this price/branding tier are often listed as 2-4 GB | **~1 GB** actual (`MemTotal` 1,003,740 kB), with zRAM swap (735 MB) almost full under normal use |
| Storage | Device software reports **256 GB** (`persist.skytest.storage.total=256GB`, `persist.storage.size=256 GB`) | Actual eMMC is **~8 GB**. This is a software property, not real capacity — the UI/settings screen would show a number that is simply false. |
| Device identity | N/A | The device spoofs itself as a **Google Pixel 5** (`google/redfin/redfin:13/TQ2A.230305.008.F1`, `user/release-keys`), while the real build is `userdebug` Android 14 from 2026. This is almost certainly to pass Google Play Integrity checks it would otherwise fail. |

**None of the fake storage, fake device fingerprint, or implied-but-unsupported 8K claim are disclosed anywhere on the listing or in the device UI.**

### Playback test methodology and results

Tests were run using VLC 3.7.1 (armv7), with synthetic 3840×2160 (4K) @30fps test clips, 10 seconds each, generated locally (not downloaded, to avoid any tampered sample). Hardware decode confirmed via MediaCodec, output to Surface. Results read from VLC's own logcat timing events ("too late" / "displayed late" frames = frames that missed their intended display deadline).

| Codec / Bitrate | Decode path | Result |
|---|---|---|
| HEVC (H.265), 20 Mbps | MediaCodec (hardware) | First frame in ~0.2–0.5s, 0 "too late" frames, 1 "displayed late" frame — essentially clean playback |
| VP9, 15 Mbps | MediaCodec (hardware) | 1 "too late" frame — essentially clean |
| H.264 (AVC), 35 Mbps | MediaCodec (hardware) | **14 "too late" frames** at startup (up to ~357ms late), likely due to the high bitrate relative to this SoC's decode headroom |

SoC temperature: ~50°C before testing, up to ~56.6°C after. No sustained fps was measured with a frame-counter (this method has limits — it relies on VLC's own internal logcat timing, not an external frame-accurate capture); it is good enough to show the box **does** have functioning hardware 4K decode for HEVC/VP9 at a reasonable bitrate, but struggles with a high-bitrate H.264 stream, and that it was configured at 1280×720@60Hz out of the box, not 4K, despite the "8K HDR" branding.

### Takeaway

The device can play back 4K HEVC/VP9 content reasonably well in terms of raw decode (this part of the marketing isn't entirely fictional, chip-wise, even though "8K" specifically is false), but the RAM (1GB) is genuinely very low for a modern Android 14 TV interface with background services — see [REPORT_EN.md](REPORT_EN.md) for how the pre-installed `gsdnode` agent made this worse by also running constantly in the background before it was removed.

---

## 🇷🇴 Română

### Ce promitea anunțul

Anunțul de pe eMag pentru acest box se numea **„Player Media 8K HDR"**. Branding-ul produsului (`x88pro`) și marketingul tipic pentru această familie de boxuri implică redare capabilă de 8K și RAM/stocare generoase.

### Ce e hardware-ul în realitate

| Specificație | Publicitat (implicat de numele/brandingul anunțului) | Măsurat pe device-ul real |
|---|---|---|
| Decodare video | „8K HDR" | Chipset-ul e Rockchip **RK3528A**. Plafonul real de decodare hardware al acestui chip e **4K**, nu 8K. Nu există nicio cale ca acest SoC specific să decodeze conținut 8K în hardware. |
| RAM | Nespecificat explicit, dar boxurile din acest segment de preț/branding sunt adesea listate cu 2-4 GB | **~1 GB** real (`MemTotal` 1.003.740 kB), cu swap zRAM (735 MB) aproape plin în uz normal |
| Stocare | Software-ul device-ului raportează **256 GB** (`persist.skytest.storage.total=256GB`, `persist.storage.size=256 GB`) | eMMC-ul real are **~8 GB**. E o proprietate software, nu capacitate reală — ecranul de setări ar afișa un număr pur și simplu fals. |
| Identitate device | N/A | Device-ul se falsifică drept un **Google Pixel 5** (`google/redfin/redfin:13/TQ2A.230305.008.F1`, `user/release-keys`), deși build-ul real e `userdebug` Android 14 din 2026. Aproape sigur ca să treacă verificările Google Play Integrity pe care altfel le-ar pica. |

**Nici stocarea falsă, nici fingerprint-ul falsificat al device-ului, nici pretenția de 8K (sugerată dar nesusținută) nu sunt menționate nicăieri în anunț sau în interfața device-ului.**

### Metodologie și rezultate teste de redare

Testele au fost rulate cu VLC 3.7.1 (armv7), cu clipuri sintetice de test 3840×2160 (4K) @30fps, de câte 10 secunde, generate local (nu descărcate, ca să evităm orice eșantion modificat). Decodare hardware confirmată prin MediaCodec, ieșire pe Surface. Rezultatele sunt citite din evenimentele proprii de timing din logcat-ul VLC (frame-uri „too late" / „displayed late" = frame-uri care au ratat termenul-limită de afișare).

| Codec / Bitrate | Cale de decodare | Rezultat |
|---|---|---|
| HEVC (H.265), 20 Mbps | MediaCodec (hardware) | Primul frame în ~0,2–0,5s, 0 frame-uri „too late", 1 frame „displayed late" — redare practic curată |
| VP9, 15 Mbps | MediaCodec (hardware) | 1 frame „too late" — practic curat |
| H.264 (AVC), 35 Mbps | MediaCodec (hardware) | **14 frame-uri „too late"** la pornire (până la ~357ms întârziere), probabil din cauza bitrate-ului mare relativ la capacitatea de decodare a acestui SoC |

Temperatura SoC: ~50°C înainte de teste, până la ~56,6°C după. Nu s-a măsurat un fps susținut cu un contor de frame-uri (metoda are limite — se bazează pe timing-ul intern din logcat-ul VLC, nu pe o captură externă frame-accurate); e suficient cât să arate că boxul **chiar are** decodare hardware 4K funcțională pentru HEVC/VP9 la un bitrate rezonabil, dar are dificultăți cu un flux H.264 de bitrate mare, și că venea configurat din fabrică la 1280×720@60Hz, nu 4K, în ciuda brandingului „8K HDR".

### Concluzie

Device-ul poate reda conținut 4K HEVC/VP9 rezonabil de bine în privința decodării brute (această parte din marketing nu e complet fictivă, din punct de vedere al chip-ului, deși pretenția de „8K" specific e falsă), dar RAM-ul (1GB) e cu adevărat foarte puțin pentru o interfață Android TV 14 modernă cu servicii de fundal — vezi [RAPORT_RO.md](RAPORT_RO.md) pentru cum agentul `gsdnode` preinstalat a înrăutățit asta, rulând constant în fundal înainte de a fi eliminat.
