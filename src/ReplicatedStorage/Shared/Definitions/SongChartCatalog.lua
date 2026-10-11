--[[
    SongChartCatalog (ModuleScript)
    FISH!TUNE — Central Rhythm Song & Chart Catalog System (FISH-043)

    Satu Sumber Kebenaran (Single Source of Truth) untuk Seluruh Melodi, Lagu, dan Chart Ritme:
    1. Katalog Terpadu untuk 3 Instrumen (PIANO, GUITAR, DRUM).
    2. Metadata Lengkap: ID, Judul, Komponis, Genre, BPM, Rating Kesulitan (1-5 Bintang).
    3. Afinitas Zona Dunia (Melody Bay, Twin Eye Lagoon, Summit Abyss) & Rarity Ikan.
    4. Struktur Chart Spesifik per Instrumen:
       - PIANO : Notasi Tangga Nada Semitone, Kecepatan Jatuh, Kerapatan Not.
       - GUITAR: Pola Petikan Senar Fretboard, Urutan Senar, Vibrasi Harmonik.
       - DRUM  : Ketukan Percussion, Concentric Timing, Groove BPM.
    5. Seleksi Cerdas & Deterministik untuk Sesi Memancing (Mematuhi Rule 2).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))

local SongChartCatalog = {}

-- ============ 1. CATALOG DEFINITIONS ============
SongChartCatalog.SONGS = {
	-- ==================== 🎹 PIANO CLASSICAL & CONTEMPORARY ====================
	CANON_IN_D = {
		id = "CANON_IN_D",
		title = "Canon in D",
		artist = "Johann Pachelbel",
		genre = "Classical",
		bpm = 120,
		difficulty = 2,
		starRating = "★★☆☆☆",
		zoneAffinities = { "MELODY_BAY" },
		rarityAffinities = { "COMMON", "RARE" },
		charts = {
			[InstrumentDefinitions.Types.PIANO] = {
				name = "Canon in D (Piano Classic)",
				notes = { 2, 9, 7, 6, 4, 11, 9, 7, 6, 2, 4, 6, 7, 9, 11, 14, 12, 11, 9, 7, 6, 4, 6, 7, 9, 11, 14 },
				lanes = { 1, 3, 2, 4, 1, 4, 3, 2, 1, 3, 2, 4, 1, 3, 4, 2, 3, 1, 2, 4, 1, 3, 2, 4, 1, 3, 4 },
				durations = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.5 },
				baseSpeed = 0.38,
				bpm = 120,
			},
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Canon in D (Fingerstyle Acoustic)",
				notes = { 2, 9, 7, 6, 4, 11, 9, 7, 6, 2, 4, 6, 7, 9, 11, 14, 12, 11, 9, 7, 6, 4, 6, 7, 9, 11, 14 },
				patterns = { {1, 2, 3}, {2, 3, 4}, {1, 3, 2}, {4, 3, 2, 1} },
				baseSpeed = 0.38,
				bpm = 120,
			},
		},
	},

	FUR_ELISE = {
		id = "FUR_ELISE",
		title = "Für Elise",
		artist = "Ludwig van Beethoven",
		genre = "Classical",
		bpm = 130,
		difficulty = 3,
		starRating = "★★★☆☆",
		zoneAffinities = { "MELODY_BAY", "TWIN_EYE_LAGOON" },
		rarityAffinities = { "RARE", "SUPER_RARE" },
		charts = {
			[InstrumentDefinitions.Types.PIANO] = {
				name = "Für Elise (Harmonic Piano)",
				notes = { 7, 6, 7, 6, 7, 2, 5, 3, 0, -5, -1, 0, 2, -1, 0, 2, 3, 7, 6, 7, 6, 7, 2, 5, 3, 0 },
				lanes = { 3, 2, 3, 2, 3, 1, 4, 2, 1, 3, 2, 1, 4, 2, 1, 3, 4, 3, 2, 3, 2, 3, 1, 4, 2, 1 },
				durations = { 0.8, 0.8, 0.8, 0.8, 0.8, 1.0, 1.0, 1.0, 1.2, 0.8, 0.8, 1.0, 1.2, 0.8, 0.8, 1.0, 1.2, 0.8, 0.8, 0.8, 0.8, 0.8, 1.0, 1.0, 1.0, 1.5 },
				baseSpeed = 0.40,
				bpm = 130,
			},
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Für Elise (Nylon Acoustic)",
				notes = { 7, 6, 7, 6, 7, 2, 5, 3, 0, -5, -1, 0, 2, -1, 0, 2, 3, 7, 6, 7, 6, 7, 2, 5, 3, 0 },
				patterns = { {2, 3, 4}, {1, 2, 3}, {4, 3, 1}, {2, 1, 3} },
				baseSpeed = 0.40,
				bpm = 130,
			},
		},
	},

	RIVER_FLOWS_IN_YOU = {
		id = "RIVER_FLOWS_IN_YOU",
		title = "River Flows in You",
		artist = "Yiruma",
		genre = "Contemporary Piano",
		bpm = 110,
		difficulty = 2,
		starRating = "★★☆☆☆",
		zoneAffinities = { "MELODY_BAY", "TWIN_EYE_LAGOON" },
		rarityAffinities = { "COMMON", "RARE", "SUPER_RARE" },
		charts = {
			[InstrumentDefinitions.Types.PIANO] = {
				name = "River Flows in You (Original)",
				notes = { 9, 11, 12, 11, 9, 7, 4, 2, 0, 4, 7, 9, 12, 14, 16, 14, 12, 9, 7, 4, 2, 0 },
				lanes = { 3, 4, 2, 3, 1, 2, 4, 3, 1, 2, 3, 4, 2, 3, 4, 2, 3, 1, 2, 4, 1, 3 },
				durations = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.2, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.5 },
				baseSpeed = 0.36,
				bpm = 110,
			},
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "River Flow (Acoustic Folk)",
				notes = { 0, 2, 4, 7, 9, 12, 14, 12, 9, 7, 4, 2, 4, 7, 9, 12, 16, 14, 12, 9, 7, 4, 2, 0 },
				patterns = { {1, 2, 3}, {3, 2, 1}, {2, 3, 4}, {1, 4, 3} },
				baseSpeed = 0.36,
				bpm = 110,
			},
		},
	},

	MOONLIGHT_SONATA = {
		id = "MOONLIGHT_SONATA",
		title = "Moonlight Sonata (Adagio)",
		artist = "Ludwig van Beethoven",
		genre = "Classical Romance",
		bpm = 105,
		difficulty = 3,
		starRating = "★★★☆☆",
		zoneAffinities = { "TWIN_EYE_LAGOON", "SUMMIT_ABYSS" },
		rarityAffinities = { "SUPER_RARE", "LEGENDARY" },
		charts = {
			[InstrumentDefinitions.Types.PIANO] = {
				name = "Moonlight Sonata (Adagio)",
				notes = { 0, 3, 7, 0, 3, 7, 0, 3, 7, -2, 3, 7, -2, 3, 7, -4, 2, 5, -5, 0, 3, 0, 3, 7 },
				lanes = { 1, 2, 4, 1, 2, 3, 1, 2, 4, 1, 3, 4, 1, 2, 4, 1, 3, 4, 1, 2, 3, 1, 2, 4 },
				durations = { 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 1.2 },
				baseSpeed = 0.34,
				bpm = 105,
			},
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Moonlight Sonata (Arpeggio)",
				notes = { 0, 3, 7, 0, 3, 7, -2, 3, 7, -4, 2, 5, -5, 0, 3, 0, 3, 7, 12, 7, 3, 0 },
				patterns = { {1, 2, 3}, {1, 2, 3}, {2, 3, 4}, {1, 3, 4} },
				baseSpeed = 0.35,
				bpm = 105,
			},
		},
	},

	CLAIR_DE_LUNE = {
		id = "CLAIR_DE_LUNE",
		title = "Clair de Lune",
		artist = "Claude Debussy",
		genre = "Impressionist",
		bpm = 98,
		difficulty = 4,
		starRating = "★★★★☆",
		zoneAffinities = { "TWIN_EYE_LAGOON" },
		rarityAffinities = { "SUPER_RARE", "LEGENDARY", "MYTHIC" },
		charts = {
			[InstrumentDefinitions.Types.PIANO] = {
				name = "Clair de Lune (Ethereal)",
				notes = { 1, 8, 5, 8, 5, 8, 1, 6, 5, 6, 5, 6, 8, 10, 13, 15, 13, 10, 8, 5, 1, 5, 8 },
				lanes = { 1, 3, 2, 4, 2, 3, 1, 4, 2, 3, 1, 4, 3, 2, 4, 3, 4, 2, 3, 1, 2, 4, 3 },
				durations = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.5 },
				baseSpeed = 0.35,
				bpm = 98,
			},
		},
	},

	FLIGHT_OF_THE_BUMBLEBEE = {
		id = "FLIGHT_OF_THE_BUMBLEBEE",
		title = "Flight of the Bumblebee",
		artist = "Nikolai Rimsky-Korsakov",
		genre = "Virtuoso Speed",
		bpm = 160,
		difficulty = 5,
		starRating = "★★★★★",
		zoneAffinities = { "SUMMIT_ABYSS" },
		rarityAffinities = { "LEGENDARY", "MYTHIC", "SPECIAL" },
		charts = {
			[InstrumentDefinitions.Types.PIANO] = {
				name = "Flight of the Bumblebee (Rapid)",
				notes = { 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 11, 10, 9, 8, 7 },
				lanes = { 4, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3 },
				durations = { 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6, 1.0 },
				baseSpeed = 0.46,
				bpm = 160,
			},
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Bumblebee Shred (Electric)",
				notes = { 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
				patterns = { {4, 3, 2, 1}, {1, 2, 3, 4}, {4, 2, 3, 1}, {3, 1, 4, 2} },
				baseSpeed = 0.48,
				bpm = 160,
			},
		},
	},

	-- ==================== 🎸 GUITAR FINGERSTYLE & OVERDRIVE ====================
	SPANISH_ROMANCE = {
		id = "SPANISH_ROMANCE",
		title = "Spanish Romance",
		artist = "Traditional / Narciso Yepes",
		genre = "Classical Fingerstyle",
		bpm = 115,
		difficulty = 2,
		starRating = "★★☆☆☆",
		zoneAffinities = { "MELODY_BAY" },
		rarityAffinities = { "COMMON", "RARE" },
		charts = {
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Spanish Romance (Fingerstyle)",
				notes = { 7, 7, 7, 7, 5, 3, 3, 2, 0, 0, 3, 7, 12, 12, 12, 12, 10, 8, 8, 7, 5, 5, 7, 8, 7, 8, 7, 7, 5, 3, 2, 0 },
				patterns = { {1, 2, 3}, {4, 3, 2, 1}, {2, 3, 4}, {1, 3, 2, 4} },
				baseSpeed = 0.38,
				bpm = 115,
			},
			[InstrumentDefinitions.Types.PIANO] = {
				name = "Spanish Romance (Piano Melody)",
				notes = { 7, 7, 7, 7, 5, 3, 3, 2, 0, 0, 3, 7, 12, 12, 12, 12, 10, 8, 8, 7, 5, 5, 7, 8, 7, 8, 7, 7, 5, 3, 2, 0 },
				lanes = { 3, 2, 4, 1, 3, 2, 4, 1, 2, 3, 1, 4, 3, 2, 4, 1, 3, 2, 4, 1, 2, 3, 4, 1, 3, 2, 4, 1, 3, 2, 4, 1 },
				durations = { 0.8, 0.8, 0.8, 1.0, 1.0, 0.8, 0.8, 1.0, 1.0, 1.0, 1.0, 1.0, 0.8, 0.8, 0.8, 1.0, 1.0, 0.8, 0.8, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.8, 0.8, 0.8, 1.0, 1.0, 1.5 },
				baseSpeed = 0.37,
				bpm = 115,
			},
		},
	},

	SUNSET_FINGERSTYLE = {
		id = "SUNSET_FINGERSTYLE",
		title = "Sunset Fingerstyle Lick",
		artist = "FishTune Studio",
		genre = "Acoustic Folk",
		bpm = 120,
		difficulty = 2,
		starRating = "★★☆☆☆",
		zoneAffinities = { "MELODY_BAY", "TWIN_EYE_LAGOON" },
		rarityAffinities = { "COMMON", "RARE" },
		charts = {
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Sunset Fingerstyle Lick",
				notes = { 0, 4, 7, 11, 12, 11, 7, 4, 2, 6, 9, 13, 14, 13, 9, 6, 0, 4, 7, 11, 12, 16, 14, 12, 11, 9, 7, 4, 2, 0 },
				patterns = { {1, 2, 4}, {2, 3, 1}, {4, 3, 2}, {1, 4, 2, 3} },
				baseSpeed = 0.40,
				bpm = 120,
			},
		},
	},

	ABYSSAL_ROCK_RIFF = {
		id = "ABYSSAL_ROCK_RIFF",
		title = "Abyssal Rock Heavy Riff",
		artist = "FishTune Studio",
		genre = "Heavy Metal",
		bpm = 140,
		difficulty = 4,
		starRating = "★★★★☆",
		zoneAffinities = { "SUMMIT_ABYSS" },
		rarityAffinities = { "SUPER_RARE", "LEGENDARY", "MYTHIC" },
		charts = {
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Abyssal Rock Heavy Riff",
				notes = { -5, -5, -2, 0, -2, -5, 0, 3, 2, 0, -2, -5, -5, -5, -2, 0, 3, 5, 3, 0, -2, -5, 0, 2 },
				patterns = { {1, 1, 2}, {3, 2, 1}, {4, 4, 3}, {2, 1, 3, 4} },
				baseSpeed = 0.44,
				bpm = 140,
			},
			[InstrumentDefinitions.Types.DRUM] = {
				name = "Abyssal Metal Double Kick",
				notes = { -12, -12, 0, -12, 0, 7, -12, -12, 0, -12, 7, 12, -12, -12, 0, 7 },
				bpm = 140,
				baseSpeed = 0.44,
			},
		},
	},

	COSMIC_ASTRAL_MELODY = {
		id = "COSMIC_ASTRAL_MELODY",
		title = "Cosmic Astral Melody",
		artist = "FishTune Studio",
		genre = "Synthwave / Astral",
		bpm = 135,
		difficulty = 4,
		starRating = "★★★★☆",
		zoneAffinities = { "TWIN_EYE_LAGOON", "SUMMIT_ABYSS" },
		rarityAffinities = { "LEGENDARY", "MYTHIC", "SPECIAL" },
		charts = {
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Cosmic Astral Melody",
				notes = { 4, 7, 11, 16, 14, 11, 7, 4, 6, 9, 13, 18, 16, 13, 9, 6, 7, 11, 14, 19, 18, 14, 11, 7, 12, 16, 19, 24 },
				patterns = { {1, 3, 4}, {2, 4, 1}, {3, 2, 4}, {4, 1, 3, 2} },
				baseSpeed = 0.42,
				bpm = 135,
			},
			[InstrumentDefinitions.Types.PIANO] = {
				name = "Cosmic Astral Synth",
				notes = { 4, 7, 11, 16, 14, 11, 7, 4, 6, 9, 13, 18, 16, 13, 9, 6, 7, 11, 14, 19, 18, 14, 11, 7, 12, 16, 19, 24 },
				lanes = { 1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 3, 2, 1, 2, 3, 4 },
				durations = { 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 1.2 },
				baseSpeed = 0.42,
				bpm = 135,
			},
		},
	},

	FLAMENCO_FIRE_STORM = {
		id = "FLAMENCO_FIRE_STORM",
		title = "Flamenco Tide Storm",
		artist = "FishTune Studio",
		genre = "Flamenco Virtuoso",
		bpm = 155,
		difficulty = 5,
		starRating = "★★★★★",
		zoneAffinities = { "SUMMIT_ABYSS" },
		rarityAffinities = { "MYTHIC", "SPECIAL" },
		charts = {
			[InstrumentDefinitions.Types.GUITAR] = {
				name = "Flamenco Fire Storm",
				notes = { 0, 1, 4, 5, 7, 8, 11, 12, 11, 8, 7, 5, 4, 1, 0, 4, 7, 12, 16, 17, 16, 12, 7, 4, 0 },
				patterns = { {1, 2, 3, 4}, {4, 3, 2, 1}, {1, 3, 2, 4}, {2, 4, 1, 3} },
				baseSpeed = 0.46,
				bpm = 155,
			},
		},
	},

	-- ==================== 🥁 DRUM PERCUSSION & BEAT GROOVES ====================
	TROPICAL_BONGO_PULSE = {
		id = "TROPICAL_BONGO_PULSE",
		title = "Tropical Island Bongo Tempo",
		artist = "FishTune Studio",
		genre = "Island Percussion",
		bpm = 115,
		difficulty = 1,
		starRating = "★☆☆☆☆",
		zoneAffinities = { "MELODY_BAY" },
		rarityAffinities = { "COMMON", "RARE" },
		charts = {
			[InstrumentDefinitions.Types.DRUM] = {
				name = "Tropical Island Bongo Tempo",
				notes = { 0, 4, 7, 0, 4, 7, 12, 7, 4, 0, 7, 4, 0, 4, 7, 12 },
				bpm = 115,
				baseSpeed = 0.38,
			},
		},
	},

	CELESTIAL_BEAT_PULSE = {
		id = "CELESTIAL_BEAT_PULSE",
		title = "Celestial Beat Kick Groove",
		artist = "FishTune Studio",
		genre = "Electronic Beat",
		bpm = 128,
		difficulty = 2,
		starRating = "★★☆☆☆",
		zoneAffinities = { "MELODY_BAY", "TWIN_EYE_LAGOON" },
		rarityAffinities = { "COMMON", "RARE", "SUPER_RARE" },
		charts = {
			[InstrumentDefinitions.Types.DRUM] = {
				name = "Celestial Beat Kick Groove",
				notes = { -12, 0, -12, 0, 7, -12, 0, -12, 7, 0, -12, 0, 12, 7, 0, -12 },
				bpm = 128,
				baseSpeed = 0.42,
			},
		},
	},

	THUNDER_ROCK_BEAT = {
		id = "THUNDER_ROCK_BEAT",
		title = "Thunder Heavy Rock Beat",
		artist = "FishTune Studio",
		genre = "Hard Rock Percussion",
		bpm = 140,
		difficulty = 3,
		starRating = "★★★☆☆",
		zoneAffinities = { "TWIN_EYE_LAGOON", "SUMMIT_ABYSS" },
		rarityAffinities = { "SUPER_RARE", "LEGENDARY" },
		charts = {
			[InstrumentDefinitions.Types.DRUM] = {
				name = "Thunder Heavy Rock Beat",
				notes = { -12, -12, 0, -12, 0, 7, -12, 0, -12, -12, 0, 7, 12, 0, -12, 0 },
				bpm = 140,
				baseSpeed = 0.45,
			},
		},
	},

	KRAKEN_DEEP_PULSE = {
		id = "KRAKEN_DEEP_PULSE",
		title = "Kraken Deep Sea Pulse",
		artist = "FishTune Studio",
		genre = "Tribal Sub-Bass",
		bpm = 150,
		difficulty = 4,
		starRating = "★★★★☆",
		zoneAffinities = { "SUMMIT_ABYSS" },
		rarityAffinities = { "LEGENDARY", "MYTHIC" },
		charts = {
			[InstrumentDefinitions.Types.DRUM] = {
				name = "Kraken Deep Sea Pulse",
				notes = { -12, -12, -12, 0, 7, 0, -12, 12, -12, -12, 0, 7, 12, 7, 0, -12 },
				bpm = 150,
				baseSpeed = 0.47,
			},
		},
	},

	SKULL_SUMMIT_OVERDRIVE = {
		id = "SKULL_SUMMIT_OVERDRIVE",
		title = "Skull Summit Apex Overdrive",
		artist = "FishTune Studio",
		genre = "Double-Bass Metal Beat",
		bpm = 165,
		difficulty = 5,
		starRating = "★★★★★",
		zoneAffinities = { "SUMMIT_ABYSS" },
		rarityAffinities = { "MYTHIC", "SPECIAL" },
		charts = {
			[InstrumentDefinitions.Types.DRUM] = {
				name = "Skull Summit Apex Overdrive",
				notes = { -12, -12, 0, -12, -12, 0, 7, -12, -12, 0, 12, 7, 0, -12, -12, 12 },
				bpm = 165,
				baseSpeed = 0.50,
			},
		},
	},
}

-- ============ 2. LOOKUP & QUERY API ============

function SongChartCatalog.GetSong(songId)
	if not songId then return nil end
	return SongChartCatalog.SONGS[tostring(songId):upper()]
end

function SongChartCatalog.GetAllSongs()
	local list = {}
	for _, song in pairs(SongChartCatalog.SONGS) do
		table.insert(list, song)
	end
	table.sort(list, function(a, b)
		if a.difficulty ~= b.difficulty then
			return a.difficulty < b.difficulty
		end
		return a.title < b.title
	end)
	return list
end

function SongChartCatalog.GetSongsForInstrument(instrumentType)
	instrumentType = tostring(instrumentType or InstrumentDefinitions.Types.PIANO):upper()
	local result = {}
	for _, song in pairs(SongChartCatalog.SONGS) do
		if song.charts and song.charts[instrumentType] then
			table.insert(result, song)
		end
	end
	table.sort(result, function(a, b)
		if a.difficulty ~= b.difficulty then
			return a.difficulty < b.difficulty
		end
		return a.title < b.title
	end)
	return result
end

function SongChartCatalog.GetSongsForZone(zoneId, instrumentType)
	zoneId = tostring(zoneId or "MELODY_BAY"):upper()
	local instSongs = SongChartCatalog.GetSongsForInstrument(instrumentType)
	local zoneMatched = {}

	for _, song in ipairs(instSongs) do
		if song.zoneAffinities then
			for _, z in ipairs(song.zoneAffinities) do
				if z:upper() == zoneId then
					table.insert(zoneMatched, song)
					break
				end
			end
		end
	end

	-- Jika tidak ada lagu spesifik zona, fallback ke seluruh lagu instrumen
	return (#zoneMatched > 0) and zoneMatched or instSongs
end

-- ============ 3. SMART WEIGHTED SONG SELECTION (RULE 2 COMPLIANT) ============
-- Memilih lagu secara cerdas berdasarkan instrumen (mutlak), zona (bobot), dan rarity ikan (kesulitan)
function SongChartCatalog.SelectSongForSession(options)
	options = options or {}
	local instrumentType = tostring(options.instrumentType or InstrumentDefinitions.Types.PIANO):upper()
	local zoneId = tostring(options.zoneId or options.island or "MELODY_BAY"):upper()
	local rarity = tostring(options.rarity or options.tier or "COMMON"):upper()

	-- 1. Ambil seluruh lagu yang kompatibel dengan instrumen (Rule 2: Instrumen menentukan mekanik)
	local validSongs = SongChartCatalog.GetSongsForInstrument(instrumentType)
	if #validSongs == 0 then
		-- Fallback darurat ke Piano Canon In D jika instrumen tidak ditemukan
		local fallback = SongChartCatalog.SONGS.CANON_IN_D
		return {
			song = fallback,
			chart = fallback.charts[InstrumentDefinitions.Types.PIANO],
			title = fallback.title,
			starRating = fallback.starRating,
			bpm = fallback.bpm,
		}
	end

	-- 2. Tentukan target kesulitan berdasarkan rarity ikan
	local targetDifficulty = 2
	if rarity == "COMMON" then
		targetDifficulty = 1
	elseif rarity == "RARE" then
		targetDifficulty = 2
	elseif rarity == "SUPER_RARE" then
		targetDifficulty = 3
	elseif rarity == "LEGENDARY" then
		targetDifficulty = 4
	elseif rarity == "MYTHIC" or rarity == "SPECIAL" then
		targetDifficulty = 5
	end

	-- 3. Hitung bobot untuk tiap lagu
	local weightedCandidates = {}
	for _, song in ipairs(validSongs) do
		local weight = 10 -- Base weight

		-- Bonus bobot zona (jika zona cocok, +25)
		if song.zoneAffinities then
			for _, z in ipairs(song.zoneAffinities) do
				if z:upper() == zoneId then
					weight = weight + 25
					break
				end
			end
		end

		-- Bonus bobot rarity (jika selisih kesulitan kecil, bobot lebih tinggi)
		local diffDelta = math.abs(song.difficulty - targetDifficulty)
		if diffDelta == 0 then
			weight = weight + 30
		elseif diffDelta == 1 then
			weight = weight + 15
		elseif diffDelta >= 3 then
			weight = math.max(1, weight - 8)
		end

		-- Bonus jika rarity ada di tabel rarityAffinities
		if song.rarityAffinities then
			for _, r in ipairs(song.rarityAffinities) do
				if r:upper() == rarity then
					weight = weight + 20
					break
				end
			end
		end

		table.insert(weightedCandidates, {
			song = song,
			chart = song.charts[instrumentType],
			weight = math.max(1, weight),
		})
	end

	-- 4. Roll kandidat berdasarkan akumulasi bobot
	local totalWeight = 0
	for _, cand in ipairs(weightedCandidates) do
		totalWeight = totalWeight + cand.weight
	end

	local roll
	if options.seed and type(options.seed) == "number" then
		-- Deterministik LCG generator jika ada seed
		local pseudoRand = ((options.seed * 1103515245 + 12345) % 2147483648) / 2147483648
		roll = pseudoRand * totalWeight
	else
		roll = math.random() * totalWeight
	end

	local selectedCandidate = weightedCandidates[1]
	local accum = 0
	for _, cand in ipairs(weightedCandidates) do
		accum = accum + cand.weight
		if roll <= accum then
			selectedCandidate = cand
			break
		end
	end

	return {
		song = selectedCandidate.song,
		chart = selectedCandidate.chart,
		title = selectedCandidate.song.title,
		starRating = selectedCandidate.song.starRating,
		bpm = selectedCandidate.chart.bpm or selectedCandidate.song.bpm,
		difficulty = selectedCandidate.song.difficulty,
	}
end

-- ============ 4. FORMATTING HELPER ============
function SongChartCatalog.FormatSongDisplay(songOrTitle, instrumentType, bpmOverride, difficultyOverride)
	if type(songOrTitle) == "table" then
		local song = songOrTitle
		local instChart = song.charts and song.charts[instrumentType]
		local bpm = bpmOverride or (instChart and instChart.bpm) or song.bpm or 120
		local stars = song.starRating or "★★☆☆☆"
		return string.format("🎵 %s • %s (%d BPM)", song.title, stars, bpm)
	else
		local title = tostring(songOrTitle or "UNKNOWN MELODY"):upper()
		local stars = difficultyOverride or "★★☆☆☆"
		local bpm = bpmOverride or 120
		return string.format("🎵 %s • %s (%d BPM)", title, stars, bpm)
	end
end

return SongChartCatalog
