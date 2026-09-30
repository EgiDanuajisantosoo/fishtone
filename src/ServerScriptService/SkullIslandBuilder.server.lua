--[[
	SkullIslandBuilder (ServerScript)
	FISH!TUNE — 3D Procedural World Builder for "Skull Island" (Pulau Tengkorak Musikal)
	
	Membangun pulau musikal 3D megah berskala penuh di workspace:
	- Tier 1: Port Harmony, Dermaga Kayu Pelabuhan, Perahu, Pantai Pasir & Kapal Karam (Shipwreck)
	- Tier 2: Gua Tengkorak (Skull Cave Amphitheater) dengan Panggung Neon G-Clef & Equalizer
	- Tier 3: Danau Mata Kembar (Twin Eye Lagoons) dengan 2 Air Terjun Deras & Jembatan Kayu
	- Tier 4: Tangga Batu Agung Menuju Puncak & Menara Pantau Kuno
	- Tier 5: Panggung Konser Festival Puncak (Apex Concert Citadel) & Speaker Subwoofer Raksasa
	- Atmosfer Pencahayaan Sunset Tropis (Sky, Bloom, SunRays, ColorCorrection)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Hapus instance SkullIsland lama jika ada agar tidak tumpuk
local existing = Workspace:FindFirstChild("SkullIsland")
if existing then
	existing:Destroy()
end

local mapFolder = Instance.new("Folder")
mapFolder.Name = "SkullIsland"
mapFolder.Parent = Workspace

-- ============ UTILITY BUILDER FUNCTIONS ============
local function createPart(name, size, cf, color, material, parent, anchored, canCollide, shape)
	local p = Instance.new("Part")
	p.Name = name or "Part"
	p.Size = size
	p.CFrame = cf
	p.Color = color or Color3.fromRGB(160, 160, 160)
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = (anchored == nil) and true or anchored
	p.CanCollide = (canCollide == nil) and true or canCollide
	if shape then p.Shape = shape end
	p.Parent = parent or mapFolder
	return p
end

local function createCylinder(name, size, cf, color, material, parent)
	local p = createPart(name, size, cf, color, material, parent, true, true, Enum.PartType.Cylinder)
	return p
end

local function createWedge(name, size, cf, color, material, parent)
	local p = Instance.new("WedgePart")
	p.Name = name or "Wedge"
	p.Size = size
	p.CFrame = cf
	p.Color = color or Color3.fromRGB(140, 140, 140)
	p.Material = material or Enum.Material.Slate
	p.Anchored = true
	p.CanCollide = true
	p.Parent = parent or mapFolder
	return p
end

-- ============ 1. ATMOSFER LIGHTING & SUNSET FESTIVAL ============
local function setupAtmosphere()
	Lighting.ClockTime = 17.65 -- Waktu senja keemasan (Golden Hour Sunset)
	Lighting.GeographicLatitude = 18
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 85, 115)
	Lighting.Ambient = Color3.fromRGB(75, 60, 85)
	Lighting.FogColor = Color3.fromRGB(255, 140, 95)
	Lighting.FogStart = 200
	Lighting.FogEnd = 1600

	-- Bersihkan efek lighting lama
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") or child:IsA("SunRaysEffect") or child:IsA("Atmosphere") then
			child:Destroy()
		end
	end

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 1.25
	bloom.Size = 24
	bloom.Threshold = 1.8
	bloom.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0.04
	colorCorrection.Contrast = 0.12
	colorCorrection.Saturation = 0.28
	colorCorrection.TintColor = Color3.fromRGB(255, 242, 230)
	colorCorrection.Parent = Lighting

	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.22
	sunRays.Spread = 0.85
	sunRays.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(215, 130, 110)
	atmosphere.Decay = Color3.fromRGB(105, 55, 95)
	atmosphere.Glare = 0.45
	atmosphere.Haze = 1.6
	atmosphere.Parent = Lighting
end

-- ============ 2. PROPS: POHON PALEM, OBOR, BENDERA MUSIK, ROCK ISLETS ============
local function createPalmTree(cf, parent)
	local trunkColor = Color3.fromRGB(120, 85, 55)
	local leafColor = Color3.fromRGB(45, 160, 65)

	local trunkBottom = createPart("PalmTrunk1", Vector3.new(1.8, 12, 1.8), cf * CFrame.Angles(math.rad(6), 0, 0) * CFrame.new(0, 6, 0), trunkColor, Enum.Material.Wood, parent)
	local trunkTop = createPart("PalmTrunk2", Vector3.new(1.4, 10, 1.4), trunkBottom.CFrame * CFrame.new(0, 8, 0) * CFrame.Angles(math.rad(-10), math.rad(15), 0), trunkColor, Enum.Material.Wood, parent)

	local topCF = trunkTop.CFrame * CFrame.new(0, 5, 0)
	for i = 1, 6 do
		local angle = math.rad((i - 1) * 60)
		local leafCF = topCF * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.new(0, 0, 4)
		local leaf = createWedge("PalmLeaf", Vector3.new(2.8, 0.4, 8), leafCF, leafColor, Enum.Material.Grass, parent)
	end
end

local function createTorch(cf, parent)
	local post = createPart("TorchPost", Vector3.new(0.8, 7, 0.8), cf * CFrame.new(0, 3.5, 0), Color3.fromRGB(90, 60, 40), Enum.Material.Wood, parent)
	local bowl = createPart("TorchBowl", Vector3.new(1.4, 1.0, 1.4), post.CFrame * CFrame.new(0, 3.8, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Metal, parent)
	local firePart = createPart("FirePart", Vector3.new(0.6, 0.6, 0.6), bowl.CFrame * CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 140, 30), Enum.Material.Neon, parent)
	firePart.Transparency = 0.5

	local fire = Instance.new("Fire")
	fire.Color = Color3.fromRGB(255, 160, 40)
	fire.SecondaryColor = Color3.fromRGB(255, 60, 20)
	fire.Size = 3.5
	fire.Heat = 6
	fire.Parent = firePart

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 170, 70)
	light.Range = 22
	light.Brightness = 2.2
	light.Parent = firePart
end

local function createMusicBanner(cf, color, parent)
	color = color or Color3.fromRGB(170, 45, 215)
	local pole = createPart("BannerPole", Vector3.new(0.6, 16, 0.6), cf * CFrame.new(0, 8, 0), Color3.fromRGB(80, 55, 35), Enum.Material.Wood, parent)
	local cloth = createPart("BannerCloth", Vector3.new(0.2, 8, 4), pole.CFrame * CFrame.new(0, 2, 2.2), color, Enum.Material.Fabric, parent)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 36, 0, 72)
	bb.AlwaysOnTop = false
	bb.Adornee = cloth
	bb.Parent = cloth

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = "𝄞\n🎵"
	txt.TextColor3 = Color3.fromRGB(255, 235, 120)
	txt.Font = Enum.Font.GothamBlack
	txt.TextSize = 24
	txt.Parent = bb
end

local function createWaterfall(topPos, bottomPos, width, parent)
	local height = topPos.Y - bottomPos.Y
	local midPos = (topPos + bottomPos) / 2
	local dir = (bottomPos - topPos).Unit

	local waterPart = createPart("WaterfallSheet", Vector3.new(width, height, 1.2), CFrame.new(midPos, midPos + Vector3.new(0, 0, 1)), Color3.fromRGB(130, 225, 255), Enum.Material.Glass, parent)
	waterPart.Transparency = 0.35

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(210, 245, 255), Color3.fromRGB(255, 255, 255))
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 4.5) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.8) })
	emitter.Speed = NumberRange.new(12, 18)
	emitter.Acceleration = Vector3.new(0, -35, 0)
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Rate = 45
	emitter.SpreadAngle = Vector2.new(15, 15)
	emitter.Parent = waterPart

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/water_loop.wav"
	sound.Looped = true
	sound.Volume = 0.5
	sound.RollOffMaxDistance = 80
	sound.RollOffMinDistance = 10
	sound.Parent = waterPart
	sound:Play()
end

-- ============ 3. MEMBANGUN STRUKTUR BASE ISLAND & CLIFFS ============
local function buildIslandBase()
	local rockColor = Color3.fromRGB(125, 125, 130)
	local sandColor = Color3.fromRGB(235, 205, 145)
	local grassColor = Color3.fromRGB(90, 145, 75)

	-- 1. Pantai Pasir Bawah (Y = 38 to 43, Lingkar Luar)
	local sandBase = createCylinder("IslandBeachBase", Vector3.new(6, 320, 320), CFrame.new(0, 40.5, 0) * CFrame.Angles(0, 0, math.rad(90)), sandColor, Enum.Material.Sand, mapFolder)

	-- 2. Tebing Batu Lingkar Bawah (Tier 1: Y = 41 to 65)
	local cliff1 = createCylinder("CliffTier1", Vector3.new(24, 260, 260), CFrame.new(0, 52, -15) * CFrame.Angles(0, 0, math.rad(90)), rockColor, Enum.Material.Slate, mapFolder)
	local grassTier1 = createCylinder("GrassTier1", Vector3.new(1.5, 250, 250), CFrame.new(0, 64.5, -15) * CFrame.Angles(0, 0, math.rad(90)), grassColor, Enum.Material.Grass, mapFolder)

	-- 3. Tebing Batu Tengah (Tier 2/3: Y = 65 to 95)
	local cliff2 = createCylinder("CliffTier2", Vector3.new(30, 200, 190), CFrame.new(0, 78, -35) * CFrame.Angles(0, 0, math.rad(90)), rockColor, Enum.Material.Slate, mapFolder)
	local grassTier2 = createCylinder("GrassTier2", Vector3.new(1.5, 190, 180), CFrame.new(0, 93.5, -35) * CFrame.Angles(0, 0, math.rad(90)), grassColor, Enum.Material.Grass, mapFolder)

	-- 4. Tebing Batu Puncak Benteng (Tier 4/5: Y = 95 to 135)
	local cliff3 = createCylinder("CliffTier3", Vector3.new(40, 140, 130), CFrame.new(0, 112, -60) * CFrame.Angles(0, 0, math.rad(90)), rockColor, Enum.Material.Rock, mapFolder)
	local grassTier3 = createCylinder("GrassTier3", Vector3.new(1.5, 130, 120), CFrame.new(0, 132.5, -60) * CFrame.Angles(0, 0, math.rad(90)), grassColor, Enum.Material.Grass, mapFolder)

	-- 5. Batuan Karang Laut di Sekitar Pulau (Ocean Sea Stacks)
	local rockPositions = {
		Vector3.new(-160, 42, 60), Vector3.new(-140, 44, 120), Vector3.new(-170, 46, -40),
		Vector3.new(160, 42, 60), Vector3.new(140, 44, 120), Vector3.new(170, 46, -40),
		Vector3.new(-90, 45, 160), Vector3.new(90, 45, 160), Vector3.new(0, 48, -170),
		Vector3.new(-110, 48, -130), Vector3.new(110, 48, -130),
	}
	for i, pos in ipairs(rockPositions) do
		local rH = math.random(18, 38)
		local rW = math.random(14, 26)
		local rock = createPart("SeaRock_" .. i, Vector3.new(rW, rH, rW), CFrame.new(pos) * CFrame.Angles(math.rad(math.random(-8, 8)), math.rad(math.random(0, 360)), math.rad(math.random(-8, 8))), rockColor, Enum.Material.Rock, mapFolder)
		createPalmTree(rock.CFrame * CFrame.new(0, rH / 2, 0), mapFolder)
	end
end

-- ============ 4. TIER 1: PORT HARMONY, DERMAGA, PERAHU & SHIPWRECK ============
local function buildPortHarmony()
	local woodColor = Color3.fromRGB(115, 80, 50)
	local plankColor = Color3.fromRGB(140, 100, 65)

	-- Dermaga Tengah Utama (Panjang 130 studs, Y = 42)
	local mainPier = createPart("MainPierPlank", Vector3.new(14, 1.2, 130), CFrame.new(0, 42, 95), plankColor, Enum.Material.WoodPlanks, mapFolder)
	
	-- Tiang Penyangga Dermaga
	for z = 35, 155, 15 do
		createPart("PierPostL", Vector3.new(1.4, 12, 1.4), CFrame.new(-6, 38, z), woodColor, Enum.Material.Wood, mapFolder)
		createPart("PierPostR", Vector3.new(1.4, 12, 1.4), CFrame.new(6, 38, z), woodColor, Enum.Material.Wood, mapFolder)
		createTorch(CFrame.new(-6.5, 42.6, z), mapFolder)
		createTorch(CFrame.new(6.5, 42.6, z), mapFolder)
	end

	-- Bendera Musikal di Ujung Dermaga
	createMusicBanner(CFrame.new(-7.5, 42, 150) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(235, 60, 60), mapFolder)
	createMusicBanner(CFrame.new(7.5, 42, 150) * CFrame.Angles(0, math.rad(-90), 0), Color3.fromRGB(235, 60, 60), mapFolder)

	-- Dermaga Cabang Kiri (Menuju Kapal Karam)
	local leftPier = createPart("LeftPier", Vector3.new(60, 1.2, 10), CFrame.new(-38, 42, 75) * CFrame.Angles(0, math.rad(-25), 0), plankColor, Enum.Material.WoodPlanks, mapFolder)
	
	-- Dermaga Cabang Kanan (Menuju Karang Ikan)
	local rightPier = createPart("RightPier", Vector3.new(60, 1.2, 10), CFrame.new(38, 42, 75) * CFrame.Angles(0, math.rad(25), 0), plankColor, Enum.Material.WoodPlanks, mapFolder)

	-- Kapal Karam Bajak Laut (Shipwreck Galleon di Kiri: X = -75, Z = 85)
	local shipCF = CFrame.new(-78, 45, 88) * CFrame.Angles(math.rad(14), math.rad(-35), math.rad(-18))
	local hull = createPart("ShipHull", Vector3.new(18, 14, 45), shipCF, Color3.fromRGB(85, 55, 35), Enum.Material.Wood, mapFolder)
	local mast1 = createPart("ShipMast1", Vector3.new(2, 36, 2), shipCF * CFrame.new(0, 18, -6), Color3.fromRGB(70, 45, 25), Enum.Material.Wood, mapFolder)
	local mast2 = createPart("ShipMast2", Vector3.new(1.8, 28, 1.8), shipCF * CFrame.new(0, 14, 12) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(70, 45, 25), Enum.Material.Wood, mapFolder)
	createTorch(shipCF * CFrame.new(0, 8, -18), mapFolder)

	-- Spawn Location di Ujung Dermaga Pelabuhan
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PortHarmonySpawn"
	spawn.Size = Vector3.new(10, 1.2, 10)
	spawn.CFrame = CFrame.new(0, 42.8, 110)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Color = Color3.fromRGB(150, 110, 75)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Duration = 0
	spawn.Parent = mapFolder

	-- Pondok Pedagang & Pohon Palem Pantai
	for x = -50, 50, 25 do
		if math.abs(x) > 10 then
			createPalmTree(CFrame.new(x, 41, 45) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0), mapFolder)
		end
	end
end

-- ============ 5. TIER 2: SKULL CAVE AMPHITHEATER & LOWER STAGE ============
local function buildSkullCaveStage()
	local caveCF = CFrame.new(0, 56, 10)

	-- Mulut Gua Tengkorak Raksasa (Skull Mouth Arch)
	local mouthArchL = createPart("CaveArchL", Vector3.new(12, 34, 18), caveCF * CFrame.new(-26, 6, 0) * CFrame.Angles(0, 0, math.rad(-22)), Color3.fromRGB(115, 115, 120), Enum.Material.Slate, mapFolder)
	local mouthArchR = createPart("CaveArchR", Vector3.new(12, 34, 18), caveCF * CFrame.new(26, 6, 0) * CFrame.Angles(0, 0, math.rad(22)), Color3.fromRGB(115, 115, 120), Enum.Material.Slate, mapFolder)
	local mouthArchTop = createPart("CaveArchTop", Vector3.new(38, 12, 20), caveCF * CFrame.new(0, 22, 0), Color3.fromRGB(110, 110, 115), Enum.Material.Slate, mapFolder)

	-- Panggung Konser Ungu Neon di Dalam Mulut Gua (Y = 48)
	local stage = createPart("CaveStageFloor", Vector3.new(44, 3, 28), caveCF * CFrame.new(0, -6, -4), Color3.fromRGB(30, 20, 45), Enum.Material.WoodPlanks, mapFolder)
	local stageBorder = createPart("CaveStageGlow", Vector3.new(45, 0.4, 29), stage.CFrame * CFrame.new(0, 1.6, 0), Color3.fromRGB(180, 50, 255), Enum.Material.Neon, mapFolder)

	-- Lambang Kunci G (Treble Clef 𝄞) Neon Raksasa di Dinding Belakang Gua
	local gClefSign = createPart("TrebleClefSign", Vector3.new(16, 24, 0.5), caveCF * CFrame.new(0, 10, -17), Color3.fromRGB(255, 60, 230), Enum.Material.Neon, mapFolder)
	local gClefLight = Instance.new("PointLight")
	gClefLight.Color = Color3.fromRGB(220, 60, 255)
	gClefLight.Range = 40
	gClefLight.Brightness = 3.5
	gClefLight.Parent = gClefSign

	local bbClef = Instance.new("BillboardGui")
	bbClef.Size = UDim2.new(0, 90, 0, 140)
	bbClef.AlwaysOnTop = true
	bbClef.Adornee = gClefSign
	bbClef.Parent = gClefSign

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "𝄞"
	lbl.TextColor3 = Color3.fromRGB(255, 220, 255)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 90
	lbl.Parent = bbClef

	-- Equalizer Light Bars di Kiri-Kanan Panggung
	for i = -4, 4 do
		local eqH = math.random(6, 16)
		local bar = createPart("EQBar_" .. i, Vector3.new(1.8, eqH, 0.8), caveCF * CFrame.new(i * 3.5, -5 + (eqH / 2), -15), Color3.fromRGB(120 + i * 15, 60, 255), Enum.Material.Neon, mapFolder)
	end

	-- Tangga Kayu Menuju Panggung dari Port Harmony
	for s = 1, 6 do
		createPart("CaveStep_" .. s, Vector3.new(24, 1, 3.5), CFrame.new(0, 42 + s * 0.9, 20 - s * 3), Color3.fromRGB(130, 90, 60), Enum.Material.WoodPlanks, mapFolder)
	end
end

-- ============ 6. TIER 3: TWIN EYE LAGOONS & WATERFALLS ============
local function buildTwinEyeLagoons()
	local lagoonWaterColor = Color3.fromRGB(0, 220, 245)

	-- 1. Danau Mata Kiri (Left Eye Lagoon: X = -65, Y = 68, Z = -25)
	local leftBasin = createPart("LeftLagoonWater", Vector3.new(50, 4, 45), CFrame.new(-65, 68, -25), lagoonWaterColor, Enum.Material.Water, mapFolder)
	leftBasin.Transparency = 0.3

	-- Jembatan / Dermaga Pancing Danau Kiri
	local leftDeck = createPart("LeftLagoonDeck", Vector3.new(8, 1, 40), CFrame.new(-42, 69, -25), Color3.fromRGB(135, 95, 60), Enum.Material.WoodPlanks, mapFolder)
	createTorch(CFrame.new(-42, 69.5, -40), mapFolder)
	createTorch(CFrame.new(-42, 69.5, -10), mapFolder)

	-- Air Terjun Mata Kiri
	createWaterfall(Vector3.new(-65, 105, -45), Vector3.new(-65, 70, -45), 18, mapFolder)

	-- 2. Danau Mata Kanan (Right Eye Lagoon: X = 65, Y = 68, Z = -25)
	local rightBasin = createPart("RightLagoonWater", Vector3.new(50, 4, 45), CFrame.new(65, 68, -25), lagoonWaterColor, Enum.Material.Water, mapFolder)
	rightBasin.Transparency = 0.3

	-- Jembatan / Dermaga Pancing Danau Kanan
	local rightDeck = createPart("RightLagoonDeck", Vector3.new(8, 1, 40), CFrame.new(42, 69, -25), Color3.fromRGB(135, 95, 60), Enum.Material.WoodPlanks, mapFolder)
	createTorch(CFrame.new(42, 69.5, -40), mapFolder)
	createTorch(CFrame.new(42, 69.5, -10), mapFolder)

	-- Air Terjun Mata Kanan
	createWaterfall(Vector3.new(65, 105, -45), Vector3.new(65, 70, -45), 18, mapFolder)

	-- Pohon Palem Sekitar Danau
	createPalmTree(CFrame.new(-85, 70, -15), mapFolder)
	createPalmTree(CFrame.new(85, 70, -15), mapFolder)
end

-- ============ 7. TIER 4: GRAND STAIRCASE & MENARA PANTAU KUNO ============
local function buildGrandStairsAndWatchtowers()
	-- Tangga Batu Tengah Menanjak (Y = 66 to 110, Z = -5 to -55)
	for s = 1, 28 do
		local y = 66 + (s * 1.5)
		local z = -5 - (s * 1.8)
		local step = createPart("GrandStep_" .. s, Vector3.new(16, 1.6, 2.5), CFrame.new(0, y, z), Color3.fromRGB(145, 145, 150), Enum.Material.Cobblestone, mapFolder)
		if s % 7 == 0 then
			createTorch(CFrame.new(-9, y + 0.8, z), mapFolder)
			createTorch(CFrame.new(9, y + 0.8, z), mapFolder)
		end
	end

	-- Menara Pantau Kiri (Left Watchtower: X = -95, Z = 15)
	local towerL_Base = createPart("TowerL_Base", Vector3.new(14, 35, 14), CFrame.new(-95, 75, 15), Color3.fromRGB(120, 120, 125), Enum.Material.Cobblestone, mapFolder)
	local towerL_Top = createPart("TowerL_Top", Vector3.new(18, 8, 18), CFrame.new(-95, 96, 15), Color3.fromRGB(110, 80, 55), Enum.Material.WoodPlanks, mapFolder)
	createTorch(CFrame.new(-95, 100, 15), mapFolder)
	createMusicBanner(CFrame.new(-95, 100, 20), Color3.fromRGB(235, 180, 20), mapFolder)

	-- Menara Pantau Kanan (Right Watchtower: X = 95, Z = 15)
	local towerR_Base = createPart("TowerR_Base", Vector3.new(14, 35, 14), CFrame.new(95, 75, 15), Color3.fromRGB(120, 120, 125), Enum.Material.Cobblestone, mapFolder)
	local towerR_Top = createPart("TowerR_Top", Vector3.new(18, 8, 18), CFrame.new(95, 96, 15), Color3.fromRGB(110, 80, 55), Enum.Material.WoodPlanks, mapFolder)
	createTorch(CFrame.new(95, 100, 15), mapFolder)
	createMusicBanner(CFrame.new(95, 100, 20), Color3.fromRGB(235, 180, 20), mapFolder)
end

-- ============ 8. TIER 5: APEX SKULL CONCERT CITADEL & GIANT SPEAKERS ============
local function buildApexConcertStage()
	local apexCF = CFrame.new(0, 134, -75)

	-- Lantai Panggung Konser Puncak (Y = 134)
	local stageFloor = createPart("ApexStageFloor", Vector3.new(70, 3, 40), apexCF, Color3.fromRGB(35, 25, 50), Enum.Material.WoodPlanks, mapFolder)
	local stageGlow = createPart("ApexStageGlow", Vector3.new(72, 0.5, 42), apexCF * CFrame.new(0, 1.6, 0), Color3.fromRGB(255, 190, 40), Enum.Material.Neon, mapFolder)

	-- Tengkorak Raksasa Bermahkota di Belakang Panggung (Giant Crowned Skull Wall)
	local skullWall = createPart("ApexSkullWall", Vector3.new(38, 30, 8), apexCF * CFrame.new(0, 16, -18), Color3.fromRGB(235, 230, 220), Enum.Material.Concrete, mapFolder)
	local eyeL = createPart("SkullEyeL", Vector3.new(7, 8, 2), apexCF * CFrame.new(-9, 18, -13.5), Color3.fromRGB(10, 10, 15), Enum.Material.Neon, mapFolder)
	local eyeR = createPart("SkullEyeR", Vector3.new(7, 8, 2), apexCF * CFrame.new(9, 18, -13.5), Color3.fromRGB(10, 10, 15), Enum.Material.Neon, mapFolder)
	local nose = createPart("SkullNose", Vector3.new(4, 5, 2), apexCF * CFrame.new(0, 12, -13.5), Color3.fromRGB(10, 10, 15), Enum.Material.Neon, mapFolder)

	-- Mahkota Emas Puncak (Golden Crown Spires)
	for c = -3, 3 do
		local spireH = 8 + (3 - math.abs(c)) * 3
		local spire = createWedge("CrownSpire_" .. c, Vector3.new(4, spireH, 4), apexCF * CFrame.new(c * 5.5, 30 + (spireH / 2), -18), Color3.fromRGB(245, 195, 30), Enum.Material.Metal, mapFolder)
	end

	-- SPEAKER SUBWOOFER RAKSASA KIRI (Giant Left Speaker Tower: X = -38)
	local spkL = createPart("SpeakerTowerL", Vector3.new(14, 28, 10), apexCF * CFrame.new(-38, 14, -12), Color3.fromRGB(20, 20, 25), Enum.Material.Metal, mapFolder)
	for w = 1, 3 do
		local ring = createCylinder("WooferL_" .. w, Vector3.new(0.6, 7, 7), spkL.CFrame * CFrame.new(0, -9 + (w * 7), 5.2) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 50, 255), Enum.Material.Neon, mapFolder)
	end

	-- SPEAKER SUBWOOFER RAKSASA KANAN (Giant Right Speaker Tower: X = 38)
	local spkR = createPart("SpeakerTowerR", Vector3.new(14, 28, 10), apexCF * CFrame.new(38, 14, -12), Color3.fromRGB(20, 20, 25), Enum.Material.Metal, mapFolder)
	for w = 1, 3 do
		local ring = createCylinder("WooferR_" .. w, Vector3.new(0.6, 7, 7), spkR.CFrame * CFrame.new(0, -9 + (w * 7), 5.2) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 50, 255), Enum.Material.Neon, mapFolder)
	end

	-- SPOTLIGHT FESTIVAL MENEMBUS LANGIT (Purple & Violet Sky Beams)
	local spotPositions = { Vector3.new(-28, 136, -85), Vector3.new(-12, 136, -90), Vector3.new(12, 136, -90), Vector3.new(28, 136, -85) }
	for i, sPos in ipairs(spotPositions) do
		local beamPart = createCylinder("SkyBeam_" .. i, Vector3.new(180, 2.5, 2.5), CFrame.new(sPos) * CFrame.Angles(math.rad(75), math.rad((i - 2.5) * 15), 0) * CFrame.new(0, 90, 0), Color3.fromRGB(200, 60, 255), Enum.Material.Neon, mapFolder)
		beamPart.Transparency = 0.4
		beamPart.CanCollide = false
	end

	-- Spot Pancing Mistis di Balik Puncak (Summit Abyss Fishing Spot: Mythic & Special)
	local abyssWater = createPart("SummitAbyssWater", Vector3.new(35, 3, 30), apexCF * CFrame.new(0, -2, -45), Color3.fromRGB(140, 20, 220), Enum.Material.Water, mapFolder)
	abyssWater.Transparency = 0.25
end

-- ============ EKSEKUSI PEMBANGUNAN MAP ============
print("🔨 Memulai Pembangunan 3D Map Skull Island (FISH!TUNE)...")
setupAtmosphere()
buildIslandBase()
buildPortHarmony()
buildSkullCaveStage()
buildTwinEyeLagoons()
buildGrandStairsAndWatchtowers()
buildApexConcertStage()
print("✨ 3D Map Skull Island Berhasil Dibangun Lengkap di Workspace!")
