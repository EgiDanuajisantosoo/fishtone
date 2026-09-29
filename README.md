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

## 📁 Struktur Direktori (Rojo Layout)

```
FishTune-Roblox/
├── default.project.json
├── .gitignore
├── README.md
└── src/
    ├── ReplicatedStorage/
    │   └── PianoTilesGame.lua           -- ModuleScript Mini-game Piano Tiles
    ├── ServerScriptService/
    │   └── FishingServer.server.lua     -- Server validation & leaderstats reward
    └── StarterPlayerScripts/
        └── FishingClient.client.lua     -- Client fishing flow, casting & strike animations
```

---

## 🚀 Lisensi & Kontributor
Dibuat untuk project Roblox **FishTune** oleh Egi Danuajisantoso.
