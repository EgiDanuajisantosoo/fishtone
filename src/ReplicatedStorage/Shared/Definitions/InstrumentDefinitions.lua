--[[
    InstrumentDefinitions (ModuleScript)
    FISH!TUNE — Central Instrument & Rhythm Gameplay Mechanics Registry (FISH-029)

    Menetapkan Single Source of Truth untuk:
    1. Instrument Types (PIANO, GUITAR, DRUM).
    2. Instrument Mechanics:
       - PIANO : Scrolling Tiles / Precision multi-lane timing [A, W, S, D].
       - GUITAR: Fretboard Pattern / Sequence combo rhythm [A, S, D / 1, 2, 3].
       - DRUM  : Concentric Beat Pulse / Reaction timing [SPACE / D / K / Click].
    3. Rod to Instrument Mapping (StarterRod, BambooRod, CarbonFiberRod, dll).
    4. Comprehensive Helper Methods untuk validasi, lookup, dan integrasi UI/Gameplay.
]]

local InstrumentDefinitions = {}

-- ============ 1. INSTRUMENT ENUMS ============
InstrumentDefinitions.Types = {
	PIANO = "PIANO",
	GUITAR = "GUITAR",
	DRUM = "DRUM",
}

-- ============ 2. INSTRUMENT METADATA & MECHANICS ============
InstrumentDefinitions.Instruments = {
	[InstrumentDefinitions.Types.PIANO] = {
		id = "PIANO",
		name = "Piano Tiles",
		displayName = "Piano Klasik Harmoni",
		icon = "🎹",
		badge = "🎹 PIANO",
		mechanic = "SCROLLING_TILES",
		mechanicName = "Scrolling Tiles / Multi-Lane Precision",
		description = "Tekan tuts piano saat not jatuh melintasi garis target presisi.",
		hintText = "Tekan [A, W, S, D] / Tuts Piano saat not melintasi garis target!",
		defaultKeybinds = { "A", "W", "S", "D" },
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
		mechanicName = "Fretboard Pattern / Sequence Rhythm",
		description = "Ikuti pola petikan senar dan ritem fretboard untuk menghasilkan melodi.",
		hintText = "Petik senar [A, S, D] / [1, 2, 3] atau klik senar saat not tiba!",
		defaultKeybinds = { "A", "S", "D" },
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
		mechanicName = "Concentric Beat / Reaction Timing",
		description = "Pukul pad drum tepat saat gelombang ketukan lingkaran menyatu.",
		hintText = "Tekan [SPACE / D / K] atau klik Pad Drum saat lingkaran ketukan menyatu!",
		defaultKeybinds = { "Space", "D", "K" },
		color = Color3.fromRGB(239, 68, 68),
		glowColor = Color3.fromRGB(254, 202, 202),
		basePitch = 1.0,
		volume = 0.95,
	},
}

-- ============ 3. ROD TO INSTRUMENT MAPPING ============
-- Joran menentukan jenis instrumen & mekanisme minigame
InstrumentDefinitions.RodMapping = {
	-- ==================== 🎹 PIANO RODS ====================
	StarterRod = {
		instrumentType = InstrumentDefinitions.Types.PIANO,
		instrumentVariant = "CLASSIC_PIANO",
		name = "Starter Bamboo Piano",
	},
	HarmonicTuningRod = {
		instrumentType = InstrumentDefinitions.Types.PIANO,
		instrumentVariant = "GRAND_PIANO",
		name = "Harmonic Grand Piano",
	},
	HarmonicGrandRod = {
		instrumentType = InstrumentDefinitions.Types.PIANO,
		instrumentVariant = "GRAND_PIANO",
		name = "Harmonic Grand Piano",
	},
	CrystalSonataRod = {
		instrumentType = InstrumentDefinitions.Types.PIANO,
		instrumentVariant = "CRYSTAL_SONATA",
		name = "Crystal Sonata Resonant Piano",
	},

	-- ==================== 🎸 GUITAR RODS ====================
	BambooRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ACOUSTIC_GUITAR",
		name = "Acoustic Fingerstyle Mahogany",
	},
	AcousticGuitarRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ACOUSTIC_GUITAR",
		name = "Acoustic Fingerstyle Mahogany",
	},
	CarbonFiberRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ELECTRIC_GUITAR",
		name = "Carbon Overdrive Electric",
	},
	ElectricOverdriveRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ELECTRIC_GUITAR",
		name = "Electric Overdrive Guitar",
	},
	AbyssalTridentRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ABYSSAL_METAL",
		name = "Abyssal Heavy Metal Riff",
	},
	AbyssalMetalRod = {
		instrumentType = InstrumentDefinitions.Types.GUITAR,
		instrumentVariant = "ABYSSAL_METAL",
		name = "Abyssal Heavy Metal Riff",
	},

	-- ==================== 🥁 DRUM RODS ====================
	TribalPercussionRod = {
		instrumentType = InstrumentDefinitions.Types.DRUM,
		instrumentVariant = "TRIBAL_PERCUSSION",
		name = "Tribal Rhythm Percussion",
	},
	SynthwaveDrumRod = {
		instrumentType = InstrumentDefinitions.Types.DRUM,
		instrumentVariant = "SYNTHWAVE_DRUM",
		name = "Synthwave Neon Drum Pad",
	},
	CelestialMelodyRod = {
		instrumentType = InstrumentDefinitions.Types.DRUM,
		instrumentVariant = "CELESTIAL_BEAT",
		name = "Celestial Cosmic Beat Drum",
	},
	CelestialCosmicRod = {
		instrumentType = InstrumentDefinitions.Types.DRUM,
		instrumentVariant = "CELESTIAL_BEAT",
		name = "Celestial Cosmic Beat Drum",
	},
}

-- ============ 4. HELPER METHODS ============

function InstrumentDefinitions.IsValidInstrumentType(instrumentType)
	return instrumentType ~= nil and InstrumentDefinitions.Instruments[instrumentType] ~= nil
end

function InstrumentDefinitions.GetInstrumentData(instrumentType)
	return InstrumentDefinitions.Instruments[instrumentType] or InstrumentDefinitions.Instruments[InstrumentDefinitions.Types.PIANO]
end

function InstrumentDefinitions.GetAllInstruments()
	local list = {}
	for _, instType in pairs(InstrumentDefinitions.Types) do
		local data = InstrumentDefinitions.Instruments[instType]
		if data then
			table.insert(list, data)
		end
	end
	return list
end

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
	elseif lower:find("drum") or lower:find("beat") or lower:find("celestial") or lower:find("tribal") or lower:find("synthwave") then
		return InstrumentDefinitions.Types.DRUM
	end

	return InstrumentDefinitions.Types.PIANO
end

function InstrumentDefinitions.GetRodMapping(rodId)
	rodId = tostring(rodId or "StarterRod")
	return InstrumentDefinitions.RodMapping[rodId] or {
		instrumentType = InstrumentDefinitions.Types.PIANO,
		instrumentVariant = "CLASSIC_PIANO",
		name = "Default Rod",
	}
end

function InstrumentDefinitions.GetRodsForInstrument(instrumentType)
	local rods = {}
	for rodId, mapping in pairs(InstrumentDefinitions.RodMapping) do
		if mapping.instrumentType == instrumentType then
			table.insert(rods, rodId)
		end
	end
	table.sort(rods)
	return rods
end

function InstrumentDefinitions.GetMechanicForInstrument(instrumentType)
	local data = InstrumentDefinitions.GetInstrumentData(instrumentType)
	return data and data.mechanic or "SCROLLING_TILES"
end

function InstrumentDefinitions.GetInstrumentBadge(instrumentType)
	local data = InstrumentDefinitions.GetInstrumentData(instrumentType)
	return data and data.badge or "🎹 PIANO"
end

function InstrumentDefinitions.GetInstrumentColor(instrumentType)
	local data = InstrumentDefinitions.GetInstrumentData(instrumentType)
	return data and data.color or Color3.fromRGB(0, 210, 255)
end

function InstrumentDefinitions.GetInstrumentHint(instrumentType)
	local data = InstrumentDefinitions.GetInstrumentData(instrumentType)
	return data and data.hintText or "Mainkan irama musik saat not tiba!"
end

return InstrumentDefinitions
