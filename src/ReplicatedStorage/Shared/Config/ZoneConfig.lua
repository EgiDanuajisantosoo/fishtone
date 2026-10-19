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
			ambientId = "", -- Pure natural ambient / custom atmospheric tracks
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
			ambientId = "", -- Pure natural ambient / custom atmospheric tracks
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
			ambientId = "", -- Pure natural ambient / custom atmospheric tracks
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

local Workspace = game:GetService("Workspace")

-- Helper untuk mengecek apakah titik Vector3 berada di dalam volume BasePart (memperhitungkan rotasi & ukuran)
local function isPointInsidePart(pos, part, margin)
	if not part or not part:IsA("BasePart") then return false end
	margin = margin or 15 -- Toleransi 15 studs di sekeliling part (bibir danau, pinggiran pantai, dermaga)
	local localPos = part.CFrame:PointToObjectSpace(pos)
	local halfSize = part.Size * 0.5

	-- Cek horizontal X dan Z sesuai rotasi part + margin horizontal
	local inX = math.abs(localPos.X) <= (halfSize.X + margin)
	local inZ = math.abs(localPos.Z) <= (halfSize.Z + margin)

	-- Cek vertikal Y:
	-- Karakter sering berjalan di atas dermaga, daratan berbukit, atau melompat di atas air.
	-- Beri toleransi vertikal leluasa (minimal 200 studs) agar part tipis di air tetap mendeteksi karakter di atasnya.
	local vertTolerance = math.max(halfSize.Y, 200)
	local inY = math.abs(localPos.Y) <= vertTolerance

	return inX and inZ and inY
end

-- Helper untuk mencari konfigurasi zona berdasarkan ID, nama display, atau alias (dengan prefix matching)
function ZoneConfig.GetZoneById(zoneId)
	if not zoneId then return nil end
	local clean = string.upper(tostring(zoneId)):gsub("[%s%-]+", "_")
	for id, zone in pairs(ZoneConfig.ZONES) do
		local cleanId = string.upper(tostring(id)):gsub("[%s%-]+", "_")
		local cleanZoneId = string.upper(tostring(zone.id)):gsub("[%s%-]+", "_")
		local cleanDisplayName = string.upper(tostring(zone.displayName)):gsub("[%s%-]+", "_")

		if clean == cleanId or clean == cleanZoneId or clean == cleanDisplayName
			or clean:find(cleanId, 1, true) or cleanId:find(clean, 1, true) then
			return zone
		end
	end
	return nil
end

-- ============ ZONE DETECTION WITH LIGHTWEIGHT CACHE (NO LAG) ============
local cachedZoneParts = {}
local lastCacheRefresh = 0
local CACHE_TTL = 3.0 -- Refresh cache struktur setiap 3 detik, evaluasi posisi 100% instan

local function getActiveZoneParts()
	local now = os.clock()
	if (now - lastCacheRefresh) < CACHE_TTL and #cachedZoneParts > 0 then
		return cachedZoneParts
	end

	lastCacheRefresh = now
	table.clear(cachedZoneParts)

	-- 1. Cek container terorganisir (OceanMap & Zones) - Cepat (hanya 2-5 part)
	local containers = {
		Workspace:FindFirstChild("OceanMap"),
		Workspace:FindFirstChild("Zones"),
	}

	for _, container in ipairs(containers) do
		if container then
			for _, item in ipairs(container:GetChildren()) do
				local targetPart = nil
				if item:IsA("BasePart") then
					targetPart = item
				elseif item:IsA("Model") then
					targetPart = item.PrimaryPart or item:FindFirstChild("Zone") or item:FindFirstChild("Bounds") or item:FindFirstChildWhichIsA("BasePart")
				end

				if targetPart then
					local zoneKey = item:GetAttribute("ZoneId") or targetPart:GetAttribute("ZoneId") or item.Name
					local zone = ZoneConfig.GetZoneById(zoneKey)
					if zone and zone.id ~= "MELODY_BAY" then
						table.insert(cachedZoneParts, { part = targetPart, zone = zone })
					end
				end
			end
		end
	end

	-- 2. Cek anak langsung Workspace (O(1) hash lookup instan, TIDAK REKURSIF agar 0% lag)
	for id, zone in pairs(ZoneConfig.ZONES) do
		if id ~= "MELODY_BAY" then
			local directPart = Workspace:FindFirstChild(id) or Workspace:FindFirstChild(zone.id)
			if directPart and directPart:IsA("BasePart") then
				table.insert(cachedZoneParts, { part = directPart, zone = zone })
			end
		end
	end

	return cachedZoneParts
end

-- Helper untuk mendeteksi zona secara dinamis berdasarkan Part fisik yang dibuat di Roblox Studio
-- Ringan, di-cache, dan 100% bebas lag (0% CPU overhead).
function ZoneConfig.GetZoneAtPosition(pos)
	if not pos then return ZoneConfig.ZONES.MELODY_BAY end

	local activeParts = getActiveZoneParts()
	for _, entry in ipairs(activeParts) do
		if entry.part and entry.part.Parent and isPointInsidePart(pos, entry.part) then
			return entry.zone
		end
	end

	-- Default fallback jika pemain berada di luar part zona khusus (Melody Bay)
	return ZoneConfig.ZONES.MELODY_BAY
end

return ZoneConfig
