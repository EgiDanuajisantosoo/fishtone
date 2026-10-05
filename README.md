# 🎣 FishTune - Roblox Piano Tiles Fishing System

Mekanik memancing inovatif untuk Roblox dengan integrasi mini-game **Piano Tiles** berlatar belakang semi-transparan (*glassmorphism*), melodi harmonis seirama dengan ketukan nada, sistem inventaris alat pancing (*FishingRod Tool*), animasi melempar kail, efek lompatan ikan 3D saat menyambar, serta mekanisme anti-gerak karakter saat menggunakan keyboard.

---

## 🌟 Fitur Utama

1. **Joran Pancing di Inventory (`FishingRod`)**:
   - Terdaftar sebagai item `Tool` di `StarterPack` dan `ServerStorage`.
   - Tersedia model `FishingRodPickup` di dekat spot memancing dengan `ProximityPrompt`.
   - Pengecekan otomatis kepemilikan alat pancing sebelum memancing di Danau.

2. **Animasi & Efek Visual Imersif**:
   - **Animasi Melempar Kail (*Casting*)**: Karakter berputar menghadap danau, mengayunkan joran ke belakang lalu melempar ke depan disertai partikel cipratan air (*water splash*).
   - **Animasi Ikan Menyambar (*Strike*)**: Indikator `[ ! ]`, cipratan air, dan **ikan 3D melompat melengkung (*parabolic arc*)** keluar dari air.

3. **Mini-Game Piano Tiles Glassmorphism & Melodi Harmonis**:
   - Desain semi-transparan (*frosted glass*) sehingga dunia 3D tetap terlihat di belakang tile.
   - Menggunakan tombol **[D] [F] [J] [K]** atau sentuhan/klik layar.
   - Bank melodi harmonis (*Canon in D, Beethoven's Ode to Joy, River Flow, Für Elise*) dengan tuning semitone akurat.

4. **Sistem Anti-Gerak Karakter**:
   - Menggunakan `ContextActionService` berprioritas tinggi dengan `ContextActionResult.Sink` agar tombol **[D]** (dan WASD) tidak menggerakkan karakter saat bermain.
   - Mengunci `Humanoid.WalkSpeed` & `JumpPower` selama memancing, dan mengembalikannya setelah selesai.

5. **Mekanisme Hasil (Win / Fail)**:
   - **Gagal**: Notifikasi `Ikan terlepas!`, suara gagal, tidak ada penambahan skor di leaderstats.
   - **Berhasil**: Efek jingle kemenangan, **ikan 3D melompat langsung ke tangan player**, server memvalidasi dan menambah **+1 Ikan** di `leaderstats`.

---

## 📁 Struktur Direktori (Knit-Style MVC / Rojo Layout)

```
FishTune-Roblox/
├── default.project.json
├── .gitignore
├── README.md
└── src/
    ├── ReplicatedStorage/
    │   └── Shared/
    │       ├── Config/
    │       │   ├── PianoTilesConfig.lua         -- Konfigurasi terpusat & visual balance
    │       │   ├── PlayerDataSchema.lua         -- Schema, reconciler, validator & migrations (FISH-005)
    │       │   └── ZoneConfig.lua               -- Zona dunia, bioma & persyaratan level (FISH-006)
    │       ├── Minigames/
    │       │   ├── PianoTilesGame.lua           -- Facade & controller gameplay Piano Tiles
    │       │   ├── PianoTilesUI.lua             -- View / Glassmorphism UI manager
    │       │   └── RhythmSession.lua            -- Isolated OOP Rhythm session engine (FISH-012)
    │       ├── Network/
    │       │   └── RemoteContract.lua           -- Single Source of Truth protokol jaringan (FISH-003)
    │       └── Systems/
    │           ├── FishingRaritySystem.lua      -- Balancing, XP, Pity & Rarity formula
    │           ├── FishingStateMachine.lua      -- State Machine siklus hidup pancing (FISH-008)
    │           └── PerformanceCalculator.lua    -- Kalkulator akurasi, rating grade & pengganda hadiah (FISH-013)
    ├── ServerScriptService/
    │   └── Services/
    │       ├── FishingServer.server.lua         -- Server-authoritative session, ProximityPrompt & economy service
    │       ├── FishingSessionService.lua        -- Manajemen sesi pancing terotentikasi & anti-exploit (FISH-009)
    │       └── PlayerDataService.lua            -- DataStore persistence & profile service (FISH-004)
    └── StarterPlayerScripts/
        └── Controllers/
            ├── FishingClient.client.lua         -- Client controller, casting, strike & rhythm input
            └── ZoneController.client.lua        -- Deteksi zona & banner imersif (FISH-006)
```

---
