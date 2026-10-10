# 🎣 FISH!TUNE — Roblox Rhythm Fishing System

**FISH!TUNE** adalah game pancing ritme inovatif di Roblox yang menggabungkan mekanisme memancing imersif dengan gameplay instrumen musik (**Piano**, **Gitar**, dan **Drum**) berbalut estetika antarmuka *Glassmorphism*.

---

## 📖 DAFTAR ISI
1. [Panduan Setup Roblox Studio (NPC Toko & Pedagang Ikan)](#-1-panduan-setup-roblox-studio)
2. [Panduan Mengganti Joran (Switch Rods)](#-2-panduan-mengganti-joran-switch-rods)
3. [Daftar Joran & Mekanisme Instrumen (Piano, Guitar, Drum)](#-3-daftar-joran--mekanisme-instrumen)
4. [Daftar Tombol & Hotkey Lengkap](#-4-daftar-tombol--hotkey-lengkap)
5. [Mode Testing di Roblox Studio](#-5-mode-testing-di-roblox-studio)
6. [Struktur Folder & Arsitektur](#-6-struktur-folder--arsitektur)

---

## 🛠️ 1. Panduan Setup Roblox Studio

Semua skrip server (`FishingServer.server.lua`) telah dilengkapi dengan **Global ProximityPrompt Listener**. Anda **TIDAK PERLU** menulis skrip baru di dalam NPC atau Part. Cukup buat Model / Part di Workspace Roblox Studio dan pasang `ProximityPrompt` sesuai panduan di bawah ini:

### A. Setup NPC / Stand Toko Peralatan (Joran, Umpan, Tas)

```mermaid
graph LR
    A["Workspace"] --> B["Buat Part / Model Toko"]
    B --> C["Tambahkan ProximityPrompt"]
    C --> D["Ubah Name: 'ShopPrompt' / ActionText: 'Beli'"]
    D --> E["Tekan E di Game -> Toko Otomatis Terbuka!"]
```

1. Di Roblox Studio, letakkan Part / Model NPC untuk Toko Peralatan di pulau/pantai.
2. Klik kanan pada Part / Model tersebut → **Insert Object** → pilih **`ProximityPrompt`**.
3. Di panel **Properties**, atur nilai berikut:
   - **Name**: `ShopPrompt` *(atau `TokoPrompt`)*
   - **ActionText**: `Buka Toko` *(atau `Beli`, `Shop`, `Toko`)*
   - **ObjectText**: `Toko Samudra`
   - **HoldDuration**: `0.5` *(atau `0` untuk instan)*
   - **MaxActivationDistance**: `10`
   - **RequiresLineOfSight**: `false` *(opsional, agar mudah diakses)*

---

### B. Setup NPC / Lapak Pedagang Ikan (Merchant Jual Ikan)

1. Letakkan Part / Model NPC Pedagang Ikan di dekat dermaga / pasar.
2. Klik kanan pada Part / Model tersebut → **Insert Object** → pilih **`ProximityPrompt`**.
3. Di panel **Properties**, atur nilai berikut:
   - **Name**: `SellPrompt` *(atau `MerchantPrompt`)*
   - **ActionText**: `Jual Semua Ikan` *(atau `Jual Ikan`, `Sell All`)*
   - **ObjectText**: `Pedagang Ikan`
   - **HoldDuration**: `0.5`
   - **MaxActivationDistance**: `10`

> 💡 **Info Otomatis**: Ketika pemain memicu prompt pedagang ikan, seluruh ikan di tas pemain akan langsung terjual dengan kalkulasi harga bobot + mutasi, koin pemain bertambah, dan notifikasi perolehan koin muncul di layar.

---

## 🎣 2. Panduan Mengganti Joran (Switch Rods)

Di FISH!TUNE, **joran yang Anda gunakan menentukan jenis instrumen & mekanisme minigame** yang akan dimainkan saat ikan menyambar (*strike*).

### Langkah Mengganti Joran:
1. Tekan tombol **`[K]`** pada keyboard atau klik tombol HUD **`[ 🛍️ TOKO ]`** di layar.
2. Klik tab **`[ 🎣 Joran Pancing ]`**.
3. Cari joran yang ingin Anda gunakan:
   - Jika joran sudah dimiliki: Klik tombol biru **`[ 🎣 GUNAKAN ]`**.
   - Tombol akan berubah menjadi hijau **`[ ✅ DIGUNAKAN ]`**.
   - Jika joran belum dimiliki: Klik tombol kuning **`[ 💰 BELI ]`** (otomatis terbeli jika koin & level mencukupi).
4. Tutup jendela Toko dengan tombol **`[ ✕ ]`** di pojok kanan atas.
5. Joran baru Anda kini aktif dan siap digunakan untuk memancing!

---

## 🎶 3. Daftar Joran & Mekanisme Instrumen

Setiap joran memiliki statistik Luck, Kekuatan Lemparan, serta **Badge Instrumen** khusus:

| Ikon & Nama Joran | Badge Instrumen | Mekanisme Minigame Irama | Kontrol / Keybind |
| :--- | :--- | :--- | :--- |
| 🎣 **Starter Bamboo Rod** | 🎹 `PIANO` | **Piano Tiles Precision (4-Lane)**<br>Not balok jatuh ke bawah melintasi garis target presisi. Cocok untuk pemula. | **`1`**, **`2`**, **`3`**, **`4`** atau **`A`**, **`S`**, **`K`**, **`L`** |
| 🎣 **Harmonic Tuning Rod** | 🎹 `PIANO` | **Grand Piano Melodic Tiles**<br>Tempo lebih dinamis dengan harmoni melodi klasik. | **`1`**, **`2`**, **`3`**, **`4`** atau **`A`**, **`S`**, **`K`**, **`L`** |
| 🎣 **Acoustic Bamboo Rod** | 🎸 `GUITAR` | **Guitar Fretboard Pattern**<br>Not melodi mengalir horizontal di atas senar bergetar (*vibrating strings*). | **`A`**, **`S`**, **`D`**, **`J`**, **`K`**, **`L`** |
| 🎣 **Carbon Overdrive Rod** | 🎸 `GUITAR` | **Electric Guitar Rock Riff**<br>Pola petikan senar elektrik cepat dengan efek distorsi audio visual. | **`A`**, **`S`**, **`D`**, **`J`**, **`K`**, **`L`** |
| 🎣 **Abyssal Trident Rod** | 🎸 `GUITAR` | **Abyssal Heavy Metal Solo**<br>Pola riff cepat untuk memburu ikan langka kedalaman samudra. | **`A`**, **`S`**, **`D`**, **`J`**, **`K`**, **`L`** |
| 🎣 **Celestial Melody Rod** | 🥁 `DRUM` | **Drum Concentric Beat Timing**<br>Lingkaran gelombang ketukan berdenyut menyatu ke pusat target pad drum. | **`Spasi`**, **`E`**, atau **`Q`** tepat saat lingkaran menyatu |

### 🎯 Panduan Posisi Ketukan Not Piano (Hit Zones):
Di dalam mini-game Piano Tiles, arena permainan kini dilengkapi dengan **Indikator Visual Zona Warna** dan **Legend Bar** di bagian atas:
1. ⭐ **Zona PERFECT (Emas / Gold)**:
   - **Posisi**: Tepat di garis laser target tengah (`HitLine`).
   - **Skor**: **+300 Poin** + Bonus Combo Maksimal.
2. ◆ **Zona GREAT (Biru Muda / Cyan)**:
   - **Posisi**: Area di sekitar garis target (sedikit sebelum / sesudah garis target).
   - **Skor**: **+180 Poin** + Melanjutkan Combo.
3. ● **Zona GOOD (Hijau Emerald)**:
   - **Posisi**: Area terluar saat not mulai memasuki bantalan tuts piano (`ReceptorPad`).
   - **Skor**: **+80 Poin** + Menjaga Progres Tangkapan.
4. ✕ **Garis MISS (Merah)**:
   - **Posisi**: Melewati garis bawah arena. Jika not terlewat atau tuts ditekan saat not belum masuk zona, dinilai **MISS** (Combo Reset & Progres berkurang).

---

## 🎮 4. Daftar Tombol & Hotkey Lengkap

| Tombol / Input | Aksi / Fungsi |
| :--- | :--- |
| **`K`** | Membuka / Menutup **Toko Samudra** (Joran, Umpan, Perluasan Tas, Jual Ikan) |
| **`B`** atau **`I`** | Membuka / Menutup **Tas Inventaris** |
| **`J`** | Membuka / Menutup **FishDex (Ensiklopedia Ikan & Mutasi)** |
| **`E`** atau **Klik Kiri** | Melempar Kail (*Casting*) / Interaksi ProximityPrompt / Pukul Beat Minigame |
| **`1, 2, 3, 4`** / **`A, S, K, L`** | Memainkan tuts **Piano Tiles** |
| **`A, S, D, J, K, L`** | Memainkan senar **Gitar Fretboard** |
| **`Spasi`** / **`Q`** / **`E`** | Memukul pad **Drum Beats** |

---

## 🧪 5. Mode Testing di Roblox Studio

Untuk mempermudah pengujian mekanik tanpa harus grinding dari awal, sistem mendeteksi saat dijalankan di **Roblox Studio** dan otomatis memberikan:
- 💰 **50.000 Koin Saldo Awal**
- ⭐ **Level 20 Karakter**
- 🎣 **Semua Joran Terbuka (Unlocked)**: Siap diganti kapan saja via Toko `[K]`.
- 🪱 **20x Seluruh Jenis Umpan**: Standard Worm, Golden Larva, Magnet Shrimp, dan Melody Jelly.

### Cara Cepat Mengetes Ketiga Instrumen:
1. Jalankan game di Roblox Studio (tekan **Play / F5**).
2. Tekan **`[K]`** untuk membuka Toko.
3. Pilih **StarterRod** (Piano) → Lempar kail ke air → Mainkan Piano Tiles.
4. Buka Toko lagi **`[K]`** → Pilih **BambooRod** (Gitar) → Lempar kail → Rasakan petikan senar gitar.
5. Buka Toko lagi **`[K]`** → Pilih **CelestialMelodyRod** (Drum) → Lempar kail → Rasakan ketukan drum beat!

---

## 📁 6. Struktur Folder & Arsitektur

```
FishTune-Roblox/
├── default.project.json
├── README.md
└── src/
    ├── ReplicatedStorage/
    │   └── Shared/
    │       ├── Config/
    │       │   ├── EconomyConfig.lua            -- Katalog joran, umpan & tier tas
    │       │   ├── PianoTilesConfig.lua         -- Konfigurasi not & visual irama
    │       │   ├── PlayerDataSchema.lua         -- Schema, rekonsiliasi & migrasi data
    │       │   └── ZoneConfig.lua               -- Zona bioma & batasan level
    │       ├── Definitions/
    │       │   └── InstrumentDefinitions.lua    -- Single Source of Truth mapping Joran -> Instrumen (Piano/Guitar/Drum)
    │       ├── Minigames/
    │       │   ├── Rhythm/                      -- Modular Rhythm Router & Engines
    │       │   │   ├── RhythmController.lua     -- Router sentral instrumen
    │       │   │   ├── Piano/                   -- Controller, Session, UI Piano Tiles
    │       │   │   ├── Guitar/                  -- Controller, Session, UI Guitar Fretboard
    │       │   │   └── Drum/                    -- Controller, Session, UI Drum Beat
    │       │   ├── FishDexUI.lua                -- UI Jurnal ensiklopedia ikan
    │       │   ├── InventoryUI.lua              -- UI Tas & slot tangkapan
    │       │   └── ShopUI.lua                   -- UI Toko Samudra & upgrade joran
    │       ├── Network/
    │       │   └── RemoteContract.lua           -- Kontrak protokol jaringan RemoteEvent
    │       └── Systems/
    │           ├── FishingRaritySystem.lua      -- Formula Pity, Level & Bobot Ikan
    │           └── FishingStateMachine.lua      -- State Machine siklus memancing
    ├── ServerScriptService/
    │   └── Services/
    │       ├── AntiExploitService.lua           -- Rate-limiting, speedhack & validasi otoritatif server (FISH-039)
    │       ├── EconomyService.lua               -- Transaksi joran, umpan, tas & jual ikan
    │       ├── FishingServer.server.lua         -- Server listener & Global ProximityPrompt handler
    │       ├── FishingSessionService.lua        -- Validasi sesi memancing anti-exploit
    │       └── PlayerDataService.lua            -- DataStore persistence & Studio testing helper
    └── StarterPlayerScripts/
        └── Controllers/
            ├── FishingClient.client.lua         -- Controller utama client, casting & input
            └── ZoneController.client.lua        -- Deteksi zona & banner bioma
```

---

## 📱 7. Optimasi Mobile & Tablet (FISH-037)

Game FISH!TUNE dirancang dengan responsivitas lintas platform (PC, Laptop, Smartphone & Tablet):
1. **Dedicated Touch Action Button**:
   - Tombol sentuh melingkar modern di sisi kanan bawah layar (`🎣 LEMPAR` → `⭐ KUNCI` → `🌊 TUNGGU` → `⚡ TARIK!`).
   - Mencegah lemparan kail yang tidak disengaja saat pemain mobile menggerakkan atau memutar kamera (*camera panning*).
2. **Adaptive HUD & Bersih dari Hotkey PC**:
   - Label tombol HUD otomatis menyembunyikan bracket hotkey PC seperti `[B]`, `[J]`, `[K]`, `[H]` saat mendeteksi layar sentuh.
   - Petunjuk meter lemparan otomatis beradaptasi menjadi *"Sentuh Layar / KUNCI!"*.
3. **Dynamic Viewport Auto-Fitting (`UIScale`)**:
   - Modals & Minigame Arena (`ShopUI`, `FishDexUI`, `FishingResultUI`, `ProgressionRoadmapUI`, `LevelUpUI`, `TutorialUI`, `PianoUI`, `GuitarUI`, `DrumUI`) otomatis menyesuaikan skala secara proporsional sesuai resolusi viewport layar HP/Tablet tanpa terpotong (overflow).
4. **Toleransi Area Sentuh Minigame Irama**:
   - Deteksi sentuhan pada tuts/senar/pad minigame diperluas (-10px s/d +10px horizontal, -20px s/d +80px vertikal) untuk mengakomodasi tap jempol cepat pemain mobile tanpa dropped inputs.

---

## 🌐 8. Integrasi Multiplayer & Kehadiran Visual (FISH-038)

Game FISH!TUNE kini memiliki integrasi multiplayer yang hidup, interaktif, dan terproteksi:
1. **Replikasi Visual Aktivitas Memancing Lintas Pemain**:
   - Pelampung (Bobber) setiap pemain otomatis direplikasi secara server-side di dalam folder `workspace.FishingBobbers`.
   - Tali pancing dinamis berkurva (`Beam`) otomatis terhubung dari joran pemain lain ke pelampung mereka sehingga semua orang di sekitar dapat melihat siapa yang sedang memancing.
   - Hentakan pelampung dan cipratan air saat ikan menyambar kail (`Phase = "Biting"`) tersinkronisasi dan terlihat secara real-time oleh pemain lain.
2. **Kabar Samudra Raya (Global Rare Catch Broadcast)**:
   - Tangkapan ikan langka berkategori `LEGENDARY`, `MYTHIC`, `SPECIAL`, atau varian **Mutasi** disiarkan secara serentak ke seluruh pemain di server.
   - Menampilkan banner pop-up *glassmorphism* modern di bagian atas layar dengan aksen warna rarity, audio fanfare perayaan, dan pesan perayaan di sistem Chat Roblox.
3. **Isolasi Sesi & Integritas Data Pemain (Server-Authoritative)**:
   - Setiap sesi memancing terikat secara absolut dengan `UserId` pemain, mencegah bentrokan atau tumpang tindih sesi di spot pemancingan yang sama.
   - Proteksi anti-hijacking dan anti-duplikasi menolak percobaan pengiriman tangkapan dengan session ID milik pemain lain atau pengiriman berulang.
   - Pembersihan otomatis (*graceful cleanup*) membersihkan pelampung dan sesi saat pemain menyelesaikan kail, membatalkan, atau keluar dari server (`PlayerRemoving`).

---

## 🛡️ 9. Keamanan Server & Anti-Exploit QA (FISH-039)

FISH!TUNE menerapkan arsitektur ketat **"Client requests; server decides"** (Rule 5 & Rule 9):
1. **Per-Player Token Bucket Rate-Limiting & Flood Protection**:
   - Seluruh remote Client-to-Server (`START_FISHING`, `SUBMIT_CATCH`, `SELL_FISH`, `SELL_ALL_FISH`, `BUY_ROD`, dll.) dilindungi oleh algoritma Token Bucket dinamis.
   - Mencegah spam packet/flooding dengan batas global (maks 20 req/s) dan cooldown per-action (misal: SubmitCatch maks 1 per 1.2 detik).
2. **Validasi Fisik & Anti-Teleport Lemparan Kail**:
   - Memeriksa keabsahan koordinat `waterPos` terhadap `NaN` (Not-a-Number) dan nilai tak hingga (`math.huge`).
   - Memastikan karakter hidup dan jarak lemparan berada di dalam rentang wajar (1 s/d 150 studs).
3. **Deteksi Speedhack & Instant-Catch**:
   - Waktu tunggu ikan menyambar divalidasi di server (`elapsed >= waitDuration * 0.75`).
   - Waktu penyelesaian minigame ritme memiliki ambang batas fisik minimum (+0.75 detik setelah gigitan). Tangkapan instan sub-detik langsung ditolak.
4. **Penutupan Total Celah Sesi Palsu (Backdoor Elimination)**:
   - Menghapus pembuatan sesi pemulihan darurat (*recovery fallback*) di `FishingSessionService` yang sebelumnya dapat disalahgunakan oleh exploiter.
   - Pengiriman tangkapan dengan ID sesi yang tidak terdaftar langsung ditolak tanpa memberi ikan atau hadiah.
5. **Sanitasi Metrik Ritme & Anti-Bot/Macro**:
   - Klaim menang (`won = true`) dengan 0 nada ditekan (`hits = 0`) otomatis ditolak sebagai pelanggaran.
   - Input tuts/klik yang melampaui batas wajar manusia (> 28 hits/detik) dideteksi sebagai macro/auto-clicker dan digugurkan.
6. **Logging Pelanggaran & Strike Tracker**:
   - Setiap anomali dicatat dalam memori server dengan timestamp dan jenis pelanggaran (`RATE_LIMIT_EXCEEDED`, `INVALID_CAST_POSITION`, `SPEEDHACK_OR_PREMATURE_CATCH`, `FAKE_OR_EXPIRED_SESSION_SUBMISSION`).
   - Pemain yang mengumpulkan strike agresif diberi peringatan khusus pada server console.
7. **Automated QA Test Suite**:
   - Seluruh skenario pengujian anti-exploit diverifikasi secara otomatis melalui `test_anti_exploit.py` (19/19 pengujian lulus 100%).



