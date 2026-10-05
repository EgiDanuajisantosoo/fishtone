--[[
    InstrumentDefinitions (ModuleScript)
    FISH!TUNE — Central Instrument & Rhythm Gameplay Mechanics Registry

    Menetapkan:
    1. Instrument Types (PIANO, GUITAR, DRUM).
    2. Instrument Mechanics:
       - PIANO : Scrolling Tiles / Precision multi-lane timing.
       - GUITAR: Fretboard Pattern / Sequence combo rhythm.
       - DRUM  : Concentric Beat Pulse / Reaction timing.
    3. Rod to Instrument Mapping (StarterRod, BambooRod, CarbonFiberRod, dll).
]]

local InstrumentDefinitions = {}

-- ============ INSTRUMENT TYPES ============
InstrumentDefinitions.Types = {
	PIANO = "PIANO",
	GUITAR = "GUITAR",
	DRUM = "DRUM",
}

-- ============ INSTRUMENT METADATA & MECHANICS ============
InstrumentDefinitions.Instruments = {
	[InstrumentDefinitions.Types.PIANO] = {
		id = "PIANO",
		name = "Piano Tiles",
		displayName = "Piano Klasik Harmoni",
		icon = "🎹",
		badge = "🎹 PIANO",
		mechanic = "SCROLLING_TILES",
		description = "Tekan tuts piano saat not jatuh melintasi garis target presisi.",
		color = Color3.fromRGB(0, 210, 255),
		glowColor = Color3.fromRGB(180, 245, 255),
		basePitch = 0.85,
		volume = 0.85,
	},

	[InstrumentDefinitions.Types.GUITAR] = {
		id = "GUITAR",
		name = "Guitar Fretboard",
		displayName = "Gitar Akustik & Elektrik",
		icon = "🎸",
		badge = "🎸 GUITAR",
		mechanic = "PATTERN_SEQUENCE",
		description = "Ikuti pola petikan senar dan ritem fretboard untuk menghasilkan melodi.",
		color = Color3.fromRGB(245, 158, 11),
		glowColor = Color3.fromRGB(253, 230, 138),
		basePitch = 1.0,
		volume = 0.90,
	},

	[InstrumentDefinitions.Types.DRUM] = {
		id = "DRUM",
		name = "Drum Rhythm Beat",
		displayName = "Drum Perkusi Resonansi",
		icon = "🥁",
		badge = "🥁 DRUM",
		mechanic = "BEAT_TIMING",
		description = "Pukul pad drum tepat saat gelombang ketukan lingkaran menyatu.",
		color = Color3.fromRGB(239, 68, 68),
		glowColor = Color3.fromRGB(254, 202, 202),
		basePitch = 1.0,
		volume = 0.95,
	},
}

-- ============ ROD TO INSTRUMENT MAPPING ============
-- Joran menentukan jenis instrumen & mekanisme minigame
InstrumentDefinitions.RodMapping = {
	-- Starting / Classic Rods -> Piano
	StarterRod = {
		instrumentType = InstrumentDefinitions.Types.PIANO,
		instrumentVariant = "CLASSIC_PIANO",
		name = "Starter Bamboo Piano",
	},
	HarmonicTuningRod = {
		instrumentType = InstrumentDefinitions.Types.PIANO,
		instrumentVariant = "GRAND_PIANO",
		name = "Harmonic Tuning Grand Piano",
	},

	-- Acoustic & Electric String Rods -> Guitar
	BambooRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ACOUSTIC_GUITAR",
		name = "Acoustic Fingerstyle Bamboo",
	},
	CarbonFiberRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ELECTRIC_GUITAR",
		name = "Carbon Overdrive Electric",
	},
	AbyssalTridentRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ABYSSAL_METAL",
		name = "Abyssal Heavy Metal Riff",
	},

	-- Beat / Celestial Percussion Rods -> Drum
	CelestialMelodyRod = {
		instrumentType = InstrumentDefinitions.Types.DRUM,
		instrumentVariant = "CELESTIAL_BEAT",
		name = "Celestial Beat Drum",
	},
}

-- ============ HELPER METHODS ============
function InstrumentDefinitions.GetInstrumentTypeForRod(rodId)
	rodId = tostring(rodId or "StarterRod")
	local mapping = InstrumentDefinitions.RodMapping[rodId]
	if mapping and mapping.instrumentType then
		return mapping.instrumentType
	end

	-- Fallback heuristic by name
	local lower = rodId:lower()
	if lower:find("guitar") or lower:find("gitar") or lower:find("carbon") or lower:find("bamboo") or lower:find("abyssal") then
		return InstrumentDefinitions.Types.GUITAR
	elseif lower:find("drum") or lower:find("beat") or lower:find("celestial") then
		return InstrumentDefinitions.Types.DRUM
	end

	return InstrumentDefinitions.Types.PIANO
end

function InstrumentDefinitions.GetInstrumentData(instrumentType)
	return InstrumentDefinitions.Instruments[instrumentType] or InstrumentDefinitions.Instruments[InstrumentDefinitions.Types.PIANO]
end

function InstrumentDefinitions.GetRodMapping(rodId)
	rodId = tostring(rodId or "StarterRod")
	return InstrumentDefinitions.RodMapping[rodId] or {
		instrumentType = InstrumentDefinitions.Types.PIANO,
		instrumentVariant = "CLASSIC_PIANO",
		name = "Default Rod",
	}
end

return InstrumentDefinitions
