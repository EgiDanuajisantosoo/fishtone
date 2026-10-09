--[[
	ZoneConfig (ModuleScript)
	FISH!TUNE — World Zones & Biomes Configuration (FISH-006)

	Konfigurasi Terpusat untuk Zona, Danau & Wilayah Perairan di FishTune:
	1. Definisi Zona (Melody Bay, Twin Eye Lagoon, Apex Summit).
	2. Persyaratan Level Minimal & Bonus Luck Wilayah.
	3. Parameter Visual & Tema Musik Masing-Masing Zona.
]]

local ZoneConfig = {}

ZoneConfig.ZONES = {
	MELODY_BAY = {
		id = "MELODY_BAY",
		displayName = "Melody Bay",
		subtitle = "Dermaga Harmoni & Zona Pemula",
		badgeIcon = "⚓",
		minLevel = 1,
		luckBonus = 0,
		description = "Teluk tenang dengan irama lembut. Tempat sempurna bagi pemancing pemula untuk melatih ritme.",
		themeColor = Color3.fromRGB(0, 200, 255),
		waterColor = Color3.fromRGB(0, 180, 230),
		musicTrack = "CanonInD",
		bounds = {
			min = Vector3.new(-150, -20, -150),
			max = Vector3.new(150, 60, 150),
		},
		dockCenter = Vector3.new(0, 5, 20),
		spawnPosition = Vector3.new(0, 6, 45),

		-- ============ ENHANCED ENVIRONMENT & POLISH (FISH-035) ============
		lighting = {
			outdoorAmbient = Color3.fromRGB(140, 155, 175),
			ambient = Color3.fromRGB(110, 125, 145),
			colorShift_Top = Color3.fromRGB(255, 245, 220),
			colorShift_Bottom = Color3.fromRGB(180, 220, 255),
			brightness = 2.4,
			fogColor = Color3.fromRGB(190, 225, 255),
			fogStart = 80,
			fogEnd = 450,
			exposureCompensation = 0.1,
		},
		postProcessing = {
			bloom = { intensity = 0.45, size = 20, threshold = 0.85 },
			colorCorrection = {
				brightness = 0.03,
				contrast = 0.12,
				saturation = 0.22,
				tintColor = Color3.fromRGB(255, 250, 242),
			},
			sunRays = { intensity = 0.14, spread = 0.75 },
			atmosphere = {
				density = 0.30,
				offset = 0.25,
				color = Color3.fromRGB(185, 215, 245),
				decay = Color3.fromRGB(130, 175, 225),
				glare = 0.35,
				haze = 1.1,
			},
		},
		soundscape = {
			ambientId = "rbxasset://sounds/action_footsteps_plastic.mp3", -- Fallback ocean breeze / water flow
			ambientVolume = 0.4,
			bgmVolume = 0.5,
			reverbType = Enum.ReverbType.StoneRoom,
			environmentalEcho = false,
		},
		vfx = {
			particleType = "MELODIC_NOTES",
			particleColors = {
				Color3.fromRGB(56, 189, 248),
				Color3.fromRGB(251, 191, 36),
				Color3.fromRGB(255, 255, 255),
			},
			waterRippleColor = Color3.fromRGB(120, 220, 255),
			dockLanternColor = Color3.fromRGB(255, 210, 120),
		},
	},
	TWIN_EYE_LAGOON = {
		id = "TWIN_EYE_LAGOON",
		displayName = "Twin Eye Lagoon",
		subtitle = "Danau Kembar Mistis",
		badgeIcon = "🌊",
		minLevel = 5,
		luckBonus = 10,
		description = "Danau air terjun berkilau di lereng bukit. Habitat ikan langka dan bernilai tinggi.",
		themeColor = Color3.fromRGB(80, 220, 120),
		waterColor = Color3.fromRGB(0, 220, 200),
		musicTrack = "RiverFlows",
		bounds = {
			min = Vector3.new(-120, 60, -80),
			max = Vector3.new(120, 110, 0),
		},
		dockCenter = Vector3.new(-42, 69, -25),

		-- ============ ENHANCED ENVIRONMENT & POLISH (FISH-035) ============
		lighting = {
			outdoorAmbient = Color3.fromRGB(100, 145, 125),
			ambient = Color3.fromRGB(80, 125, 105),
			colorShift_Top = Color3.fromRGB(200, 255, 225),
			colorShift_Bottom = Color3.fromRGB(120, 210, 180),
			brightness = 2.0,
			fogColor = Color3.fromRGB(140, 215, 185),
			fogStart = 40,
			fogEnd = 320,
			exposureCompensation = 0.05,
		},
		postProcessing = {
			bloom = { intensity = 0.65, size = 26, threshold = 0.78 },
			colorCorrection = {
				brightness = 0.02,
				contrast = 0.16,
				saturation = 0.35,
				tintColor = Color3.fromRGB(225, 255, 238),
			},
			sunRays = { intensity = 0.22, spread = 0.85 },
			atmosphere = {
				density = 0.45,
				offset = 0.35,
				color = Color3.fromRGB(130, 215, 175),
				decay = Color3.fromRGB(80, 170, 135),
				glare = 0.50,
				haze = 1.8,
			},
		},
		soundscape = {
			ambientId = "rbxasset://sounds/electronicpingshort.wav",
			ambientVolume = 0.45,
			bgmVolume = 0.55,
			reverbType = Enum.ReverbType.Forest,
			environmentalEcho = true,
		},
		vfx = {
			particleType = "BIOLUMINESCENT_SPORES",
			particleColors = {
				Color3.fromRGB(74, 222, 128),
				Color3.fromRGB(45, 212, 191),
				Color3.fromRGB(167, 243, 208),
			},
			waterRippleColor = Color3.fromRGB(52, 211, 153),
			dockLanternColor = Color3.fromRGB(110, 231, 183),
		},
	},
	SUMMIT_ABYSS = {
		id = "SUMMIT_ABYSS",
		displayName = "Summit Abyss",
		subtitle = "Puncak Konser Tengkorak Kuno",
		badgeIcon = "⚡",
		minLevel = 15,
		luckBonus = 25,
		description = "Zona legendaris di puncak pulau bermahkotakan speaker raksasa. Menghasilkan ikan Mythic & Special.",
		themeColor = Color3.fromRGB(220, 60, 255),
		waterColor = Color3.fromRGB(140, 20, 220),
		musicTrack = "FurElise",
		bounds = {
			min = Vector3.new(-80, 120, -120),
			max = Vector3.new(80, 200, -40),
		},
		dockCenter = Vector3.new(0, 134, -75),

		-- ============ ENHANCED ENVIRONMENT & POLISH (FISH-035) ============
		lighting = {
			outdoorAmbient = Color3.fromRGB(95, 60, 120),
			ambient = Color3.fromRGB(70, 40, 95),
			colorShift_Top = Color3.fromRGB(240, 160, 255),
			colorShift_Bottom = Color3.fromRGB(130, 45, 180),
			brightness = 1.8,
			fogColor = Color3.fromRGB(110, 40, 150),
			fogStart = 30,
			fogEnd = 260,
			exposureCompensation = -0.05,
		},
		postProcessing = {
			bloom = { intensity = 0.95, size = 32, threshold = 0.70 },
			colorCorrection = {
				brightness = -0.02,
				contrast = 0.24,
				saturation = 0.45,
				tintColor = Color3.fromRGB(245, 210, 255),
			},
			sunRays = { intensity = 0.35, spread = 0.92 },
			atmosphere = {
				density = 0.55,
				offset = 0.40,
				color = Color3.fromRGB(140, 45, 195),
				decay = Color3.fromRGB(80, 20, 125),
				glare = 0.75,
				haze = 2.4,
			},
		},
		soundscape = {
			ambientId = "rbxasset://sounds/electronicpingshort.wav",
			ambientVolume = 0.5,
			bgmVolume = 0.6,
			reverbType = Enum.ReverbType.ConcertHall,
			environmentalEcho = true,
		},
		vfx = {
			particleType = "CYBER_SYNTH_NEON",
			particleColors = {
				Color3.fromRGB(217, 70, 239),
				Color3.fromRGB(168, 85, 247),
				Color3.fromRGB(236, 72, 153),
			},
			waterRippleColor = Color3.fromRGB(192, 132, 252),
			dockLanternColor = Color3.fromRGB(232, 121, 249),
		},
	},
}

-- Helper untuk mendeteksi zona berdasarkan koordinat Vector3
function ZoneConfig.GetZoneAtPosition(pos)
	if not pos then return ZoneConfig.ZONES.MELODY_BAY end

	for _, zone in pairs(ZoneConfig.ZONES) do
		local b = zone.bounds
		if pos.X >= b.min.X and pos.X <= b.max.X
			and pos.Y >= b.min.Y and pos.Y <= b.max.Y
			and pos.Z >= b.min.Z and pos.Z <= b.max.Z then
			return zone
		end
	end

	-- Default fallback
	return ZoneConfig.ZONES.MELODY_BAY
end

return ZoneConfig
