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

-- Note Event Types (FISH-045)
SongChartCatalog.NoteTypes = {
	TAP = "TAP",
	HOLD = "HOLD",
	CHORD = "CHORD",
}

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
				events = {
					{ type = "CHORD", lanes = { 1, 3 }, startBeat = 1.0, notes = { 2, 7 } },
					{ type = "TAP", lane = 2, startBeat = 2.0, note = 9 },
					{ type = "TAP", lane = 4, startBeat = 3.0, note = 6 },
					{ type = "HOLD", lane = 1, startBeat = 4.0, durationBeats = 2.0, note = 4 },
					{ type = "TAP", lane = 3, startBeat = 5.0, note = 11 },
					{ type = "CHORD", lanes = { 2, 4 }, startBeat = 6.5, notes = { 9, 14 } },
					{ type = "TAP", lane = 1, startBeat = 7.5, note = 7 },
					{ type = "HOLD", lane = 3, startBeat = 8.5, durationBeats = 1.8, note = 6 },
					{ type = "TAP", lane = 2, startBeat = 10.5, note = 2 },
					{ type = "CHORD", lanes = { 1, 4 }, startBeat = 11.5, notes = { 4, 12 } },
					{ type = "TAP", lane = 3, startBeat = 12.5, note = 7 },
					{ type = "HOLD", lane = 2, startBeat = 13.5, durationBeats = 2.0, note = 9 },
					{ type = "TAP", lane = 4, startBeat = 14.5, note = 14 },
					{ type = "TAP", lane = 1, startBeat = 16.0, note = 11 },
					{ type = "CHORD", lanes = { 2, 3 }, startBeat = 17.0, notes = { 9, 6 } },
					{ type = "TAP", lane = 4, startBeat = 18.0, note = 14 },
					{ type = "HOLD", lane = 1, startBeat = 19.0, durationBeats = 2.5, note = 2 },
				},
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
				events = {
					{ type = "TAP", lane = 3, startBeat = 1.0, note = 7 },
					{ type = "TAP", lane = 2, startBeat = 1.8, note = 6 },
					{ type = "TAP", lane = 3, startBeat = 2.6, note = 7 },
					{ type = "TAP", lane = 2, startBeat = 3.4, note = 6 },
					{ type = "HOLD", lane = 3, startBeat = 4.2, durationBeats = 1.8, note = 7 },
					{ type = "CHORD", lanes = { 1, 4 }, startBeat = 6.2, notes = { 0, 5 } },
					{ type = "TAP", lane = 2, startBeat = 7.2, note = 3 },
					{ type = "HOLD", lane = 1, startBeat = 8.2, durationBeats = 2.0, note = -5 },
					{ type = "TAP", lane = 3, startBeat = 9.2, note = 2 },
					{ type = "CHORD", lanes = { 2, 4 }, startBeat = 10.4, notes = { 0, 7 } },
					{ type = "TAP", lane = 1, startBeat = 11.4, note = -1 },
					{ type = "HOLD", lane = 2, startBeat = 12.4, durationBeats = 2.2, note = 3 },
				},
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
				events = {
					{ type = "TAP", lane = 3, startBeat = 1.0, note = 9 },
					{ type = "TAP", lane = 4, startBeat = 2.0, note = 11 },
					{ type = "HOLD", lane = 2, startBeat = 3.0, durationBeats = 2.0, note = 12 },
					{ type = "TAP", lane = 1, startBeat = 4.0, note = 7 },
					{ type = "CHORD", lanes = { 1, 4 }, startBeat = 5.5, notes = { 4, 14 } },
					{ type = "TAP", lane = 2, startBeat = 6.5, note = 2 },
					{ type = "HOLD", lane = 3, startBeat = 7.5, durationBeats = 2.0, note = 9 },
					{ type = "TAP", lane = 4, startBeat = 8.5, note = 16 },
					{ type = "CHORD", lanes = { 2, 3 }, startBeat = 10.0, notes = { 7, 12 } },
					{ type = "HOLD", lane = 1, startBeat = 11.2, durationBeats = 2.5, note = 0 },
				},
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
				events = {
					{ type = "TAP", lane = 1, startBeat = 1.0, note = 0 },
					{ type = "TAP", lane = 2, startBeat = 1.8, note = 3 },
					{ type = "HOLD", lane = 4, startBeat = 2.6, durationBeats = 2.0, note = 7 },
					{ type = "TAP", lane = 1, startBeat = 3.6, note = 0 },
					{ type = "CHORD", lanes = { 2, 3 }, startBeat = 5.0, notes = { 3, 7 } },
					{ type = "TAP", lane = 1, startBeat = 6.0, note = -2 },
					{ type = "HOLD", lane = 3, startBeat = 7.0, durationBeats = 2.2, note = 7 },
					{ type = "TAP", lane = 4, startBeat = 8.0, note = 5 },
					{ type = "CHORD", lanes = { 1, 2 }, startBeat = 9.6, notes = { -5, 0 } },
					{ type = "TAP", lane = 4, startBeat = 10.6, note = 7 },
					{ type = "HOLD", lane = 2, startBeat = 11.6, durationBeats = 2.5, note = 3 },
				},
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
				events = {
					{ type = "TAP", lane = 1, startBeat = 1.0, note = 1 },
					{ type = "TAP", lane = 3, startBeat = 2.0, note = 8 },
					{ type = "HOLD", lane = 2, startBeat = 3.0, durationBeats = 2.0, note = 5 },
					{ type = "TAP", lane = 4, startBeat = 4.0, note = 8 },
					{ type = "CHORD", lanes = { 1, 4 }, startBeat = 5.5, notes = { 1, 6 } },
					{ type = "TAP", lane = 2, startBeat = 6.5, note = 5 },
					{ type = "HOLD", lane = 3, startBeat = 7.5, durationBeats = 2.0, note = 6 },
					{ type = "TAP", lane = 1, startBeat = 8.5, note = 8 },
					{ type = "CHORD", lanes = { 2, 4 }, startBeat = 10.0, notes = { 10, 15 } },
					{ type = "TAP", lane = 3, startBeat = 11.2, note = 13 },
					{ type = "HOLD", lane = 1, startBeat = 12.2, durationBeats = 2.5, note = 1 },
				},
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
				events = {
					{ type = "TAP", lane = 4, startBeat = 1.0, note = 12 },
					{ type = "TAP", lane = 3, startBeat = 1.6, note = 11 },
					{ type = "TAP", lane = 2, startBeat = 2.2, note = 10 },
					{ type = "TAP", lane = 1, startBeat = 2.8, note = 9 },
					{ type = "HOLD", lane = 3, startBeat = 3.4, durationBeats = 1.6, note = 8 },
					{ type = "TAP", lane = 2, startBeat = 4.2, note = 7 },
					{ type = "CHORD", lanes = { 1, 4 }, startBeat = 5.4, notes = { 6, 12 } },
					{ type = "TAP", lane = 3, startBeat = 6.2, note = 5 },
					{ type = "TAP", lane = 2, startBeat = 6.8, note = 4 },
					{ type = "HOLD", lane = 4, startBeat = 7.4, durationBeats = 1.8, note = 3 },
					{ type = "TAP", lane = 1, startBeat = 8.2, note = 2 },
					{ type = "CHORD", lanes = { 2, 3 }, startBeat = 9.6, notes = { 1, 7 } },
					{ type = "TAP", lane = 4, startBeat = 10.4, note = 12 },
					{ type = "HOLD", lane = 1, startBeat = 11.2, durationBeats = 2.0, note = 0 },
				},
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

-- ============ 5. CHART NORMALIZATION & VALIDATION (FISH-045) ============
--[[
    Menormalisasi chart lagu menjadi format terstruktur standar:
    Mendukung event TAP, HOLD, CHORD, serta kompatibel ke belakang
    dengan array flat legacy (notes, lanes, durations).
]]
function SongChartCatalog.NormalizeChart(chart)
	if not chart or type(chart) ~= "table" then
		return {
			events = {},
			bpm = 120,
			baseSpeed = 0.38,
		}
	end

	local bpm = chart.bpm or 120
	local baseSpeed = chart.baseSpeed or 0.38

	-- 1. Format eksplisit terstruktur (FISH-045)
	if chart.events and type(chart.events) == "table" and #chart.events > 0 then
		local normalizedEvents = {}
		for i, ev in ipairs(chart.events) do
			local evType = tostring(ev.type or "TAP"):upper()
			local startBeat = math.max(0, tonumber(ev.startBeat) or (i * 1.0))
			local durBeats = math.max(0.5, tonumber(ev.durationBeats or ev.duration) or 1.0)

			if evType == "CHORD" then
				local lanes = ev.lanes or { ev.lane or 1 }
				local cleanLanes = {}
				for _, l in ipairs(lanes) do
					table.insert(cleanLanes, math.clamp(tonumber(l) or 1, 1, 4))
				end
				local notes = ev.notes or { ev.note or 0 }
				table.insert(normalizedEvents, {
					id = i,
					type = "CHORD",
					lanes = cleanLanes,
					startBeat = startBeat,
					durationBeats = durBeats,
					notes = notes,
				})
			elseif evType == "HOLD" then
				table.insert(normalizedEvents, {
					id = i,
					type = "HOLD",
					lane = math.clamp(tonumber(ev.lane) or 1, 1, 4),
					startBeat = startBeat,
					durationBeats = math.max(1.2, durBeats),
					note = tonumber(ev.note) or 0,
				})
			else -- "TAP"
				table.insert(normalizedEvents, {
					id = i,
					type = "TAP",
					lane = math.clamp(tonumber(ev.lane) or 1, 1, 4),
					startBeat = startBeat,
					durationBeats = 1.0,
					note = tonumber(ev.note) or 0,
				})
			end
		end

		return {
			events = normalizedEvents,
			bpm = bpm,
			baseSpeed = baseSpeed,
			name = chart.name,
		}
	end

	-- 2. Format legacy flat arrays (notes, lanes, durations) -> Konversi otomatis
	local notes = chart.notes or { 0, 2, 4, 5, 7, 9, 11, 12 }
	local lanes = chart.lanes
	local durations = chart.durations

	local minPitch, maxPitch = math.huge, -math.huge
	for _, p in ipairs(notes) do
		if p < minPitch then minPitch = p end
		if p > maxPitch then maxPitch = p end
	end
	if minPitch == maxPitch then
		minPitch = minPitch - 1
		maxPitch = maxPitch + 1
	end

	local normalizedEvents = {}
	local currentBeat = 1.0

	for i, pitch in ipairs(notes) do
		local lane = 1
		if lanes and lanes[i] then
			lane = math.clamp(tonumber(lanes[i]) or 1, 1, 4)
		else
			local norm = math.clamp((pitch - minPitch) / (maxPitch - minPitch), 0, 1)
			lane = math.clamp(math.floor(norm * 3.99) + 1, 1, 4)
		end

		local dur = 1.0
		if durations and durations[i] then
			dur = math.max(0.5, tonumber(durations[i]) or 1.0)
		end

		local evType = (dur >= 1.4) and "HOLD" or "TAP"

		table.insert(normalizedEvents, {
			id = i,
			type = evType,
			lane = lane,
			startBeat = currentBeat,
			durationBeats = dur,
			note = pitch,
		})

		currentBeat = currentBeat + dur
	end

	return {
		events = normalizedEvents,
		bpm = bpm,
		baseSpeed = baseSpeed,
		name = chart.name,
	}
end

-- ============ 6. CHART PLAYABILITY VALIDATION (FISH-045) ============
--[[
	Memvalidasi apakah chart ritme valid dan dapat dimainkan (playable).
	Menolak pola yang mustahil dimainkan (Acceptance Criteria 7):
	1. Pola chord dengan > 3 tuts simultan (mustahil/tidak ergonomis untuk mobile touch & keyboard).
	2. Pola chord dengan tuts duplikat (misal {1, 1}).
	3. Tuts di luar rentang 1-4.
	4. Overlap tuts yang sama saat Hold masih berlangsung.
	5. Jeda waktu antar-not di tuts yang sama kurang dari toleransi fisik reaksi jari (0.08 detik).
	6. Nilai durasi atau beat negatif.
	@param chart table
	@return boolean isValid, table errors
]]
function SongChartCatalog.ValidateChart(chart)
	if not chart or type(chart) ~= "table" then
		return false, { "Chart kosong atau bukan tabel" }
	end

	local errors = {}
	local bpm = tonumber(chart.bpm) or 0
	if bpm <= 0 then
		table.insert(errors, "BPM harus lebih besar dari 0")
	end

	local secondsPerBeat = 60.0 / math.max(1, bpm)
	local normalized = SongChartCatalog.NormalizeChart(chart)
	local events = normalized.events or {}

	if #events == 0 then
		table.insert(errors, "Chart tidak memiliki event notasi")
		return false, errors
	end

	-- Validasi rentang data mentah sebelum normalisasi
	if chart.events and type(chart.events) == "table" then
		for i, ev in ipairs(chart.events) do
			if ev.lane ~= nil then
				local l = tonumber(ev.lane)
				if not l or l < 1 or l > 4 then
					table.insert(errors, string.format("Event #%d: Jalur %s di luar rentang tuts 1-4", i, tostring(ev.lane)))
				end
			end
			if ev.lanes and type(ev.lanes) == "table" then
				for _, l in ipairs(ev.lanes) do
					local ln = tonumber(l)
					if not ln or ln < 1 or ln > 4 then
						table.insert(errors, string.format("Event #%d: Jalur %s di luar rentang tuts 1-4", i, tostring(l)))
					end
				end
			end
		end
	end

	-- Timeline playability tracking
	local lastLaneEndTime = { [1] = -999, [2] = -999, [3] = -999, [4] = -999 }
	local activeHolds = {} -- [lane] = endBeat

	for i, ev in ipairs(events) do
		local evType = ev.type or "TAP"
		local startBeat = ev.startBeat or 0
		local durBeats = ev.durationBeats or 1.0

		if startBeat < 0 then
			table.insert(errors, string.format("Event #%d memiliki startBeat negatif: %.2f", i, startBeat))
		end

		if evType == "CHORD" then
			local lanes = ev.lanes or {}
			if #lanes < 2 then
				table.insert(errors, string.format("Event #%d: CHORD harus memiliki minimal 2 jalur tuts", i))
			elseif #lanes > 3 then
				table.insert(errors, string.format("Event #%d: CHORD melebihi batas ergonomis 3 tuts simultan (%d tuts diberikan)", i, #lanes))
			end

			local seenLanes = {}
			for _, l in ipairs(lanes) do
				if l < 1 or l > 4 then
					table.insert(errors, string.format("Event #%d: Jalur %s di luar rentang tuts 1-4", i, tostring(l)))
				elseif seenLanes[l] then
					table.insert(errors, string.format("Event #%d: Jalur %d duplikat dalam satu chord", i, l))
				end
				seenLanes[l] = true

				-- Cek apakah jalur ini sedang di-HOLD
				if (activeHolds[l] or -999) > startBeat then
					table.insert(errors, string.format("Event #%d: Jalur %d dimainkan saat masih aktif di-HOLD oleh not sebelumnya", i, l))
				end

				-- Cek gap waktu
				local timeGapSec = (startBeat - (lastLaneEndTime[l] or -999)) * secondsPerBeat
				if timeGapSec < 0.08 and lastLaneEndTime[l] ~= -999 then
					table.insert(errors, string.format("Event #%d: Jeda waktu tuts %d terlalu rapat (%.3fs) untuk reaksi manusia", i, l, timeGapSec))
				end
				lastLaneEndTime[l] = startBeat
			end

		elseif evType == "HOLD" then
			local lane = ev.lane or 1
			if lane < 1 or lane > 4 then
				table.insert(errors, string.format("Event #%d: Jalur %s di luar rentang tuts 1-4", i, tostring(lane)))
			end
			if durBeats < 0.5 then
				table.insert(errors, string.format("Event #%d: Durasi HOLD terlalu pendek (%.2f beat)", i, durBeats))
			end

			if (activeHolds[lane] or -999) > startBeat then
				table.insert(errors, string.format("Event #%d: Jalur %d bertumpuk dengan HOLD sebelumnya", i, lane))
			end

			local timeGapSec = (startBeat - (lastLaneEndTime[lane] or -999)) * secondsPerBeat
			if timeGapSec < 0.08 and lastLaneEndTime[lane] ~= -999 then
				table.insert(errors, string.format("Event #%d: Jeda waktu tuts %d terlalu rapat (%.3fs)", i, lane, timeGapSec))
			end

			activeHolds[lane] = startBeat + durBeats
			lastLaneEndTime[lane] = startBeat + durBeats

		else -- TAP
			local lane = ev.lane or 1
			if lane < 1 or lane > 4 then
				table.insert(errors, string.format("Event #%d: Jalur %s di luar rentang tuts 1-4", i, tostring(lane)))
			end

			if (activeHolds[lane] or -999) > startBeat then
				table.insert(errors, string.format("Event #%d: Jalur %d ditekan saat tuts masih di-HOLD", i, lane))
			end

			local timeGapSec = (startBeat - (lastLaneEndTime[lane] or -999)) * secondsPerBeat
			if timeGapSec < 0.08 and lastLaneEndTime[lane] ~= -999 then
				table.insert(errors, string.format("Event #%d: Jeda waktu tuts %d terlalu rapat (%.3fs)", i, lane, timeGapSec))
			end

			lastLaneEndTime[lane] = startBeat
		end
	end

	return (#errors == 0), errors
end

return SongChartCatalog
