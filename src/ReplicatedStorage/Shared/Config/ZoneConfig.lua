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
