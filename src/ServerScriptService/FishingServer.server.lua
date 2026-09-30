--[[
	FishingServer (Universal Water Fishing System with Server-Authoritative Sessions, Fish Economy, Progression & 3D Map Builder)
	FISH!TUNE — Game Balance Specification v1.0
	
	Fitur:
	1. Pembangunan Otomatis 3D Map "Skull Island" (Port Harmony, Skull Cave, Twin Eye Lagoons, Apex Concert Stage).
	2. Validasi Sesi Memancing Server-Authoritative (Anti-Exploit).
	3. Server-Side RNG, Soft Level Gating, dan Hierarchical Pity System.
	4. Sistem Ekonomi: Ikan harus dijual (Sell / Sell All) agar Koin bertambah.
	5. Sistem Level, EXP Non-linear, Koin, dan Leaderstats Lengkap.
	6. Generator Item Ikan 3D Tool dengan Metadata Lengkap & Visual Aura.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local FishingRaritySystem = require(ReplicatedStorage:WaitForChild("FishingRaritySystem"))

local remote = ReplicatedStorage:FindFirstChild("FishingRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "FishingRemote"
	remote.Parent = ReplicatedStorage
end

-- =========================================================================
-- 🏝️ PEMBANGUN PROSEDURAL 3D MAP "SKULL ISLAND" (PULAU TENGKORAK MUSIKAL)
-- =========================================================================
local function buildSkullIsland()
	local existing = Workspace:FindFirstChild("SkullIsland")
	if existing then
		existing:Destroy()
	end

	-- Sembunyikan default baseplate jika ada agar pemandangan laut bersih
	local defaultBaseplate = Workspace:FindFirstChild("Baseplate")
	if defaultBaseplate and defaultBaseplate:IsA("BasePart") then
		defaultBaseplate.Transparency = 1
		defaultBaseplate.CanCollide = false
	end

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "SkullIsland"
	mapFolder.Parent = Workspace

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
		return createPart(name, size, cf, color, material, parent, true, true, Enum.PartType.Cylinder)
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

	-- 1. Atmosfer Lighting Sunset
	Lighting.ClockTime = 17.65
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(110, 85, 115)
	Lighting.Ambient = Color3.fromRGB(75, 60, 85)
	Lighting.FogColor = Color3.fromRGB(255, 140, 95)
	Lighting.FogStart = 200
	Lighting.FogEnd = 1600

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 1.25
	bloom.Size = 24
	bloom.Threshold = 1.8
	bloom.Parent = Lighting

	local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0.04
	colorCorrection.Contrast = 0.12
	colorCorrection.Saturation = 0.28
	colorCorrection.TintColor = Color3.fromRGB(255, 242, 230)
	colorCorrection.Parent = Lighting

	-- 2. Props Utility
	local function createPalmTree(cf, parent)
		local trunkColor = Color3.fromRGB(120, 85, 55)
		local leafColor = Color3.fromRGB(45, 160, 65)
		local trunkBottom = createPart("PalmTrunk1", Vector3.new(1.8, 12, 1.8), cf * CFrame.Angles(math.rad(6), 0, 0) * CFrame.new(0, 6, 0), trunkColor, Enum.Material.Wood, parent)
		local trunkTop = createPart("PalmTrunk2", Vector3.new(1.4, 10, 1.4), trunkBottom.CFrame * CFrame.new(0, 8, 0) * CFrame.Angles(math.rad(-10), math.rad(15), 0), trunkColor, Enum.Material.Wood, parent)
		local topCF = trunkTop.CFrame * CFrame.new(0, 5, 0)
		for i = 1, 6 do
			local angle = math.rad((i - 1) * 60)
			local leafCF = topCF * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.new(0, 0, 4)
			createWedge("PalmLeaf", Vector3.new(2.8, 0.4, 8), leafCF, leafColor, Enum.Material.Grass, parent)
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
	end

	-- 3. Membangun Struktur Dasar Pulau & Tebing
	local rockColor = Color3.fromRGB(125, 125, 130)
	local sandColor = Color3.fromRGB(235, 205, 145)
	local grassColor = Color3.fromRGB(90, 145, 75)

	createCylinder("IslandBeachBase", Vector3.new(6, 320, 320), CFrame.new(0, 40.5, 0) * CFrame.Angles(0, 0, math.rad(90)), sandColor, Enum.Material.Sand, mapFolder)
	createCylinder("CliffTier1", Vector3.new(24, 260, 260), CFrame.new(0, 52, -15) * CFrame.Angles(0, 0, math.rad(90)), rockColor, Enum.Material.Slate, mapFolder)
	createCylinder("GrassTier1", Vector3.new(1.5, 250, 250), CFrame.new(0, 64.5, -15) * CFrame.Angles(0, 0, math.rad(90)), grassColor, Enum.Material.Grass, mapFolder)
	createCylinder("CliffTier2", Vector3.new(30, 200, 190), CFrame.new(0, 78, -35) * CFrame.Angles(0, 0, math.rad(90)), rockColor, Enum.Material.Slate, mapFolder)
	createCylinder("GrassTier2", Vector3.new(1.5, 190, 180), CFrame.new(0, 93.5, -35) * CFrame.Angles(0, 0, math.rad(90)), grassColor, Enum.Material.Grass, mapFolder)
	createCylinder("CliffTier3", Vector3.new(40, 140, 130), CFrame.new(0, 112, -60) * CFrame.Angles(0, 0, math.rad(90)), rockColor, Enum.Material.Rock, mapFolder)
	createCylinder("GrassTier3", Vector3.new(1.5, 130, 120), CFrame.new(0, 132.5, -60) * CFrame.Angles(0, 0, math.rad(90)), grassColor, Enum.Material.Grass, mapFolder)

	-- Batuan Karang di Laut Sekitar
	local rockPositions = {
		Vector3.new(-160, 42, 60), Vector3.new(-140, 44, 120), Vector3.new(-170, 46, -40),
		Vector3.new(160, 42, 60), Vector3.new(140, 44, 120), Vector3.new(170, 46, -40),
		Vector3.new(-90, 45, 160), Vector3.new(90, 45, 160), Vector3.new(0, 48, -170),
	}
	for i, pos in ipairs(rockPositions) do
		local rH = math.random(18, 38)
		local rW = math.random(14, 26)
		local rock = createPart("SeaRock_" .. i, Vector3.new(rW, rH, rW), CFrame.new(pos), rockColor, Enum.Material.Rock, mapFolder)
		createPalmTree(rock.CFrame * CFrame.new(0, rH / 2, 0), mapFolder)
	end

	-- 4. Tier 1: Port Harmony & Dermaga
	local woodColor = Color3.fromRGB(115, 80, 50)
	local plankColor = Color3.fromRGB(140, 100, 65)

	createPart("MainPierPlank", Vector3.new(14, 1.2, 130), CFrame.new(0, 42, 95), plankColor, Enum.Material.WoodPlanks, mapFolder)
	for z = 35, 155, 15 do
		createPart("PierPostL", Vector3.new(1.4, 12, 1.4), CFrame.new(-6, 38, z), woodColor, Enum.Material.Wood, mapFolder)
		createPart("PierPostR", Vector3.new(1.4, 12, 1.4), CFrame.new(6, 38, z), woodColor, Enum.Material.Wood, mapFolder)
		createTorch(CFrame.new(-6.5, 42.6, z), mapFolder)
		createTorch(CFrame.new(6.5, 42.6, z), mapFolder)
	end

	createMusicBanner(CFrame.new(-7.5, 42, 150) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(235, 60, 60), mapFolder)
	createMusicBanner(CFrame.new(7.5, 42, 150) * CFrame.Angles(0, math.rad(-90), 0), Color3.fromRGB(235, 60, 60), mapFolder)
	createPart("LeftPier", Vector3.new(60, 1.2, 10), CFrame.new(-38, 42, 75) * CFrame.Angles(0, math.rad(-25), 0), plankColor, Enum.Material.WoodPlanks, mapFolder)
	createPart("RightPier", Vector3.new(60, 1.2, 10), CFrame.new(38, 42, 75) * CFrame.Angles(0, math.rad(25), 0), plankColor, Enum.Material.WoodPlanks, mapFolder)

	-- Kapal Karam di Kiri
	local shipCF = CFrame.new(-78, 45, 88) * CFrame.Angles(math.rad(14), math.rad(-35), math.rad(-18))
	createPart("ShipHull", Vector3.new(18, 14, 45), shipCF, Color3.fromRGB(85, 55, 35), Enum.Material.Wood, mapFolder)
	createPart("ShipMast1", Vector3.new(2, 36, 2), shipCF * CFrame.new(0, 18, -6), Color3.fromRGB(70, 45, 25), Enum.Material.Wood, mapFolder)
	createPart("ShipMast2", Vector3.new(1.8, 28, 1.8), shipCF * CFrame.new(0, 14, 12) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(70, 45, 25), Enum.Material.Wood, mapFolder)

	-- Spawn Location
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PortHarmonySpawn"
	spawn.Size = Vector3.new(10, 1.2, 10)
	spawn.CFrame = CFrame.new(0, 43.5, 110)
	spawn.Material = Enum.Material.WoodPlanks
	spawn.Color = Color3.fromRGB(150, 110, 75)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Duration = 0
	spawn.Parent = mapFolder

	for x = -50, 50, 25 do
		if math.abs(x) > 10 then
			createPalmTree(CFrame.new(x, 41, 45) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0), mapFolder)
		end
	end

	-- 5. Tier 2: Gua Tengkorak & Panggung Neon
	local caveCF = CFrame.new(0, 56, 10)
	createPart("CaveArchL", Vector3.new(12, 34, 18), caveCF * CFrame.new(-26, 6, 0) * CFrame.Angles(0, 0, math.rad(-22)), Color3.fromRGB(115, 115, 120), Enum.Material.Slate, mapFolder)
	createPart("CaveArchR", Vector3.new(12, 34, 18), caveCF * CFrame.new(26, 6, 0) * CFrame.Angles(0, 0, math.rad(22)), Color3.fromRGB(115, 115, 120), Enum.Material.Slate, mapFolder)
	createPart("CaveArchTop", Vector3.new(38, 12, 20), caveCF * CFrame.new(0, 22, 0), Color3.fromRGB(110, 110, 115), Enum.Material.Slate, mapFolder)

	local stage = createPart("CaveStageFloor", Vector3.new(44, 3, 28), caveCF * CFrame.new(0, -6, -4), Color3.fromRGB(30, 20, 45), Enum.Material.WoodPlanks, mapFolder)
	createPart("CaveStageGlow", Vector3.new(45, 0.4, 29), stage.CFrame * CFrame.new(0, 1.6, 0), Color3.fromRGB(180, 50, 255), Enum.Material.Neon, mapFolder)

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

	for i = -4, 4 do
		local eqH = math.random(6, 16)
		createPart("EQBar_" .. i, Vector3.new(1.8, eqH, 0.8), caveCF * CFrame.new(i * 3.5, -5 + (eqH / 2), -15), Color3.fromRGB(120 + i * 15, 60, 255), Enum.Material.Neon, mapFolder)
	end
	for s = 1, 6 do
		createPart("CaveStep_" .. s, Vector3.new(24, 1, 3.5), CFrame.new(0, 42 + s * 0.9, 20 - s * 3), Color3.fromRGB(130, 90, 60), Enum.Material.WoodPlanks, mapFolder)
	end

	-- 6. Tier 3: Danau Mata Kembar & Air Terjun
	local lagoonWaterColor = Color3.fromRGB(0, 220, 245)
	local leftBasin = createPart("LeftLagoonWater", Vector3.new(50, 4, 45), CFrame.new(-65, 68, -25), lagoonWaterColor, Enum.Material.Water, mapFolder)
	leftBasin.Transparency = 0.3
	createPart("LeftLagoonDeck", Vector3.new(8, 1, 40), CFrame.new(-42, 69, -25), Color3.fromRGB(135, 95, 60), Enum.Material.WoodPlanks, mapFolder)
	createTorch(CFrame.new(-42, 69.5, -40), mapFolder)
	createTorch(CFrame.new(-42, 69.5, -10), mapFolder)
	createWaterfall(Vector3.new(-65, 105, -45), Vector3.new(-65, 70, -45), 18, mapFolder)

	local rightBasin = createPart("RightLagoonWater", Vector3.new(50, 4, 45), CFrame.new(65, 68, -25), lagoonWaterColor, Enum.Material.Water, mapFolder)
	rightBasin.Transparency = 0.3
	createPart("RightLagoonDeck", Vector3.new(8, 1, 40), CFrame.new(42, 69, -25), Color3.fromRGB(135, 95, 60), Enum.Material.WoodPlanks, mapFolder)
	createTorch(CFrame.new(42, 69.5, -40), mapFolder)
	createTorch(CFrame.new(42, 69.5, -10), mapFolder)
	createWaterfall(Vector3.new(65, 105, -45), Vector3.new(65, 70, -45), 18, mapFolder)

	createPalmTree(CFrame.new(-85, 70, -15), mapFolder)
	createPalmTree(CFrame.new(85, 70, -15), mapFolder)

	-- 7. Tier 4: Tangga Batu & Menara Pantau
	for s = 1, 28 do
		local y = 66 + (s * 1.5)
		local z = -5 - (s * 1.8)
		createPart("GrandStep_" .. s, Vector3.new(16, 1.6, 2.5), CFrame.new(0, y, z), Color3.fromRGB(145, 145, 150), Enum.Material.Cobblestone, mapFolder)
		if s % 7 == 0 then
			createTorch(CFrame.new(-9, y + 0.8, z), mapFolder)
			createTorch(CFrame.new(9, y + 0.8, z), mapFolder)
		end
	end

	createPart("TowerL_Base", Vector3.new(14, 35, 14), CFrame.new(-95, 75, 15), Color3.fromRGB(120, 120, 125), Enum.Material.Cobblestone, mapFolder)
	createPart("TowerL_Top", Vector3.new(18, 8, 18), CFrame.new(-95, 96, 15), Color3.fromRGB(110, 80, 55), Enum.Material.WoodPlanks, mapFolder)
	createTorch(CFrame.new(-95, 100, 15), mapFolder)
	createMusicBanner(CFrame.new(-95, 100, 20), Color3.fromRGB(235, 180, 20), mapFolder)

	createPart("TowerR_Base", Vector3.new(14, 35, 14), CFrame.new(95, 75, 15), Color3.fromRGB(120, 120, 125), Enum.Material.Cobblestone, mapFolder)
	createPart("TowerR_Top", Vector3.new(18, 8, 18), CFrame.new(95, 96, 15), Color3.fromRGB(110, 80, 55), Enum.Material.WoodPlanks, mapFolder)
	createTorch(CFrame.new(95, 100, 15), mapFolder)
	createMusicBanner(CFrame.new(95, 100, 20), Color3.fromRGB(235, 180, 20), mapFolder)

	-- 8. Tier 5: Apex Concert Citadel & Speaker Raksasa
	local apexCF = CFrame.new(0, 134, -75)
	createPart("ApexStageFloor", Vector3.new(70, 3, 40), apexCF, Color3.fromRGB(35, 25, 50), Enum.Material.WoodPlanks, mapFolder)
	createPart("ApexStageGlow", Vector3.new(72, 0.5, 42), apexCF * CFrame.new(0, 1.6, 0), Color3.fromRGB(255, 190, 40), Enum.Material.Neon, mapFolder)

	createPart("ApexSkullWall", Vector3.new(38, 30, 8), apexCF * CFrame.new(0, 16, -18), Color3.fromRGB(235, 230, 220), Enum.Material.Concrete, mapFolder)
	createPart("SkullEyeL", Vector3.new(7, 8, 2), apexCF * CFrame.new(-9, 18, -13.5), Color3.fromRGB(10, 10, 15), Enum.Material.Neon, mapFolder)
	createPart("SkullEyeR", Vector3.new(7, 8, 2), apexCF * CFrame.new(9, 18, -13.5), Color3.fromRGB(10, 10, 15), Enum.Material.Neon, mapFolder)
	createPart("SkullNose", Vector3.new(4, 5, 2), apexCF * CFrame.new(0, 12, -13.5), Color3.fromRGB(10, 10, 15), Enum.Material.Neon, mapFolder)

	for c = -3, 3 do
		local spireH = 8 + (3 - math.abs(c)) * 3
		createWedge("CrownSpire_" .. c, Vector3.new(4, spireH, 4), apexCF * CFrame.new(c * 5.5, 30 + (spireH / 2), -18), Color3.fromRGB(245, 195, 30), Enum.Material.Metal, mapFolder)
	end

	local spkL = createPart("SpeakerTowerL", Vector3.new(14, 28, 10), apexCF * CFrame.new(-38, 14, -12), Color3.fromRGB(20, 20, 25), Enum.Material.Metal, mapFolder)
	for w = 1, 3 do
		createCylinder("WooferL_" .. w, Vector3.new(0.6, 7, 7), spkL.CFrame * CFrame.new(0, -9 + (w * 7), 5.2) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 50, 255), Enum.Material.Neon, mapFolder)
	end

	local spkR = createPart("SpeakerTowerR", Vector3.new(14, 28, 10), apexCF * CFrame.new(38, 14, -12), Color3.fromRGB(20, 20, 25), Enum.Material.Metal, mapFolder)
	for w = 1, 3 do
		createCylinder("WooferR_" .. w, Vector3.new(0.6, 7, 7), spkR.CFrame * CFrame.new(0, -9 + (w * 7), 5.2) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(180, 50, 255), Enum.Material.Neon, mapFolder)
	end

	local spotPositions = { Vector3.new(-28, 136, -85), Vector3.new(-12, 136, -90), Vector3.new(12, 136, -90), Vector3.new(28, 136, -85) }
	for i, sPos in ipairs(spotPositions) do
		local beamPart = createCylinder("SkyBeam_" .. i, Vector3.new(180, 2.5, 2.5), CFrame.new(sPos) * CFrame.Angles(math.rad(75), math.rad((i - 2.5) * 15), 0) * CFrame.new(0, 90, 0), Color3.fromRGB(200, 60, 255), Enum.Material.Neon, mapFolder)
		beamPart.Transparency = 0.4
		beamPart.CanCollide = false
	end

	local abyssWater = createPart("SummitAbyssWater", Vector3.new(35, 3, 30), apexCF * CFrame.new(0, -2, -45), Color3.fromRGB(140, 20, 220), Enum.Material.Water, mapFolder)
	abyssWater.Transparency = 0.25

	print("✨ [SkullIsland] 3D World Skull Island Berhasil Dibangun Lengkap!")
end

-- Panggil pembangkitan 3D map saat server menyala
task.spawn(function()
	buildSkullIsland()
end)

-- =========================================================================
-- 🎮 LOGIKA SERVER UTAMA (FISHING SESSIONS, PROGRESSION & INVENTORY)
-- =========================================================================

local playerData = {}
local activeSessions = {}
local playerSessions = {}

local function getPlayerData(player)
	if not playerData[player.UserId] then
		playerData[player.UserId] = {
			level = 1,
			exp = 0,
			coins = 0,
			totalFish = 0,
			pity = { LEGENDARY = 0, MYTHIC = 0, SPECIAL = 0 }
		}
	end
	return playerData[player.UserId]
end

local function syncLeaderstats(player)
	local pData = getPlayerData(player)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then return end

	local lvlVal = stats:FindFirstChild("Level")
	if lvlVal then lvlVal.Value = pData.level end

	local coinVal = stats:FindFirstChild("Koin")
	if coinVal then coinVal.Value = pData.coins end

	local fishVal = stats:FindFirstChild("Ikan")
	if fishVal then fishVal.Value = pData.totalFish end

	local expVal = stats:FindFirstChild("Exp")
	if expVal then expVal.Value = pData.exp end
end

local function addExp(player, amount)
	local pData = getPlayerData(player)
	pData.exp += amount
	local leveledUp = false

	while true do
		local reqExp = FishingRaritySystem.GetExpRequiredForLevel(pData.level)
		if pData.exp >= reqExp then
			pData.exp -= reqExp
			pData.level += 1
			leveledUp = true
		else
			break
		end
	end

	syncLeaderstats(player)
	if leveledUp and remote then
		remote:FireClient(player, "LevelUp", pData.level)
	end
	return leveledUp
end

local function hasFishingRod(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local inBackpack = backpack and (backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan"))
	local inChar = character and (character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan"))
	return (inBackpack or inChar) ~= nil
end

local function getRodLuck(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local rod = (character and (character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan")))
		or (backpack and (backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan")))
	if rod and rod:IsA("Tool") then
		return rod:GetAttribute("Luck") or 5
	end
	return 5
end

local function createFishTool(fishData)
	local r = fishData.rarity
	local color = fishData.color or Color3.fromRGB(150, 155, 165)

	local tool = Instance.new("Tool")
	tool.Name = fishData.name .. " [" .. fishData.displayName .. "]"
	tool.ToolTip = string.format("Tangkapan: %s (%s %s | %.1f Kg | Nilai: %d Koin)", fishData.name, fishData.displayName, fishData.stars, fishData.weight, fishData.coins)
	tool.RequiresHandle = true
	tool.CanBeDropped = true

	tool:SetAttribute("IsFish", true)
	tool:SetAttribute("FishName", fishData.name)
	tool:SetAttribute("DisplayName", fishData.displayName)
	tool:SetAttribute("Rarity", r)
	tool:SetAttribute("Stars", fishData.stars)
	tool:SetAttribute("Weight", fishData.weight)
	tool:SetAttribute("Coins", fishData.coins)
	tool:SetAttribute("Exp", fishData.exp)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Shape = Enum.PartType.Ball
	handle.Size = Vector3.new(0.65, 0.5, 1.5)
	handle.Color = color
	handle.Material = (r == "SPECIAL" or r == "MYTHIC" or r == "LEGENDARY") and Enum.Material.Neon or Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Parent = tool

	local tail = Instance.new("WedgePart")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.2, 0.65, 0.65)
	tail.Color = color
	tail.Material = handle.Material
	tail.CanCollide = false
	tail.CFrame = handle.CFrame * CFrame.new(0, 0, 0.8) * CFrame.Angles(0, math.pi, 0)
	tail.Parent = tool

	local wcTail = Instance.new("WeldConstraint")
	wcTail.Part0 = handle
	wcTail.Part1 = tail
	wcTail.Parent = handle

	local fin = Instance.new("WedgePart")
	fin.Name = "Fin"
	fin.Size = Vector3.new(0.12, 0.35, 0.5)
	fin.Color = color
	fin.Material = handle.Material
	fin.CanCollide = false
	fin.CFrame = handle.CFrame * CFrame.new(0, 0.35, -0.1) * CFrame.Angles(0, math.pi, 0)
	fin.Parent = tool

	local wcFin = Instance.new("WeldConstraint")
	wcFin.Part0 = handle
	wcFin.Part1 = fin
	wcFin.Parent = handle

	if r ~= "COMMON" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = color
		sparkles.Parent = handle

		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = (r == "SPECIAL" and 14) or (r == "MYTHIC" and 10) or (r == "LEGENDARY" and 8) or (r == "SUPER_RARE" and 6) or 5
		light.Brightness = (r == "SPECIAL" and 3.2) or (r == "MYTHIC" and 2.4) or (r == "LEGENDARY" and 1.8) or 1.2
		light.Parent = handle
	end

	if r == "SPECIAL" then
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 60, 200)
		fire.SecondaryColor = Color3.fromRGB(0, 255, 255)
		fire.Size = 3.5
		fire.Heat = 5
		fire.Parent = handle
	elseif r == "MYTHIC" then
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(235, 45, 45)
		fire.SecondaryColor = Color3.fromRGB(255, 200, 50)
		fire.Size = 2.8
		fire.Heat = 4
		fire.Parent = handle
	end

	local equipSound = Instance.new("Sound")
	equipSound.Name = "EquipSound"
	equipSound.SoundId = "rbxasset://sounds/splat.wav"
	equipSound.Volume = 0.4
	equipSound.PlaybackSpeed = 1.4
	equipSound.Parent = handle

	local clickSound = Instance.new("Sound")
	clickSound.Name = "ClickSound"
	clickSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	clickSound.Volume = 0.6
	clickSound.PlaybackSpeed = 1.3
	clickSound.Parent = handle

	tool.Equipped:Connect(function()
		equipSound:Play()
	end)
	tool.Activated:Connect(function()
		clickSound:Play()
	end)

	return tool
end

local function giveStarterRod(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	local hasRod = backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan")
	local char = player.Character
	if char and (char:FindFirstChild("FishingRod") or char:FindFirstChild("Pancingan")) then
		hasRod = true
	end

	if not hasRod then
		local rod = Instance.new("Tool")
		rod.Name = "FishingRod"
		rod.ToolTip = "Joran Pancing Pemula (Luck +5)"
		rod.RequiresHandle = true
		rod.CanBeDropped = false
		rod:SetAttribute("Luck", 5)

		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.4, 4.5, 0.4)
		handle.Color = Color3.fromRGB(115, 75, 45)
		handle.Material = Enum.Material.Wood
		handle.CanCollide = false
		handle.Parent = rod

		rod.Parent = backpack
	end
end

local function onPlayerAdded(player)
	getPlayerData(player)

	if not player:FindFirstChild("leaderstats") then
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"

		local lvl = Instance.new("IntValue")
		lvl.Name = "Level"
		lvl.Value = 1
		lvl.Parent = stats

		local koin = Instance.new("IntValue")
		koin.Name = "Koin"
		koin.Value = 0
		koin.Parent = stats

		local fish = Instance.new("IntValue")
		fish.Name = "Ikan"
		fish.Value = 0
		fish.Parent = stats

		local exp = Instance.new("IntValue")
		exp.Name = "Exp"
		exp.Value = 0
		exp.Parent = stats

		stats.Parent = player
	end

	syncLeaderstats(player)

	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		giveStarterRod(player)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(0, 45, 110)
		end
	end)

	if player.Character then
		task.spawn(function()
			giveStarterRod(player)
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(0, 45, 110)
			end
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

Players.PlayerRemoving:Connect(function(player)
	local activeSess = playerSessions[player.UserId]
	if activeSess then
		activeSessions[activeSess] = nil
	end
	playerSessions[player.UserId] = nil
	playerData[player.UserId] = nil
end)

if remote then
	remote.OnServerEvent:Connect(function(player, action, arg1, arg2, arg3)
		local pData = getPlayerData(player)

		if action == "StartFishing" then
			if not hasFishingRod(player) then
				remote:FireClient(player, "Notification", "⚠️ Kamu membutuhkan Joran Pancing di inventory!")
				return
			end

			local oldSess = playerSessions[player.UserId]
			if oldSess then
				activeSessions[oldSess] = nil
			end

			local waterPos = arg1
			local castQuality = tostring(arg2 or "GOOD"):upper()
			local castPower = tonumber(arg3) or 0.5

			local waitDuration = math.random(28, 42) / 10
			if castQuality == "PERFECT" then
				waitDuration = math.random(12, 20) / 10
			elseif castQuality == "GREAT" then
				waitDuration = math.random(18, 28) / 10
			end

			local sessionId = tostring(player.UserId) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
			local sessionData = {
				player = player,
				userId = player.UserId,
				waterPos = waterPos,
				castQuality = castQuality,
				castPower = castPower,
				startTime = os.clock(),
				waitDuration = waitDuration,
				status = "Active",
			}

			activeSessions[sessionId] = sessionData
			playerSessions[player.UserId] = sessionId

			remote:FireClient(player, "SessionStarted", sessionId, waitDuration, castQuality)
			return
		end

		if action == "SubmitCatch" then
			local sessionId = tostring(arg1 or "")
			local metrics = arg2 or {}
			local session = activeSessions[sessionId]

			if not session or session.userId ~= player.UserId or session.status ~= "Active" then
				remote:FireClient(player, "Notification", "❌ Sesi memancing tidak valid atau sudah kadaluarsa.")
				return
			end

			session.status = "Completed"
			activeSessions[sessionId] = nil
			playerSessions[player.UserId] = nil

			if not hasFishingRod(player) then
				remote:FireClient(player, "Notification", "⚠️ Kamu tidak memiliki Joran Pancing di inventory!")
				return
			end

			local rodLuck = getRodLuck(player)
			local baseLuck = math.clamp(math.floor(pData.level / 5), 0, 10)
			local castLuck = 0
			if session.castQuality == "PERFECT" then
				castLuck = 35
			elseif session.castQuality == "GREAT" then
				castLuck = 15
			end

			local accuracy = tonumber(metrics.accuracy) or 80
			local performanceScore = accuracy
			local performanceLuck = performanceScore * FishingRaritySystem.CONFIG.LUCK.PERFORMANCE_COEFF

			local effectiveLuck = FishingRaritySystem.CalculateEffectiveLuck(baseLuck + rodLuck, castLuck, performanceLuck, 0)

			local rolledRarity, wasPity = FishingRaritySystem.EvaluateWithPity(effectiveLuck, pData.level, pData.pity)
			local fishData = FishingRaritySystem.GenerateFish(rolledRarity, pData.level, performanceScore)

			pData.pity = FishingRaritySystem.UpdatePityOnCatch(pData.pity, rolledRarity)

			pData.totalFish += 1
			addExp(player, fishData.exp)
			syncLeaderstats(player)

			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				local fishTool = createFishTool(fishData)
				fishTool.Parent = backpack
			end

			local rewardInfo = {
				coins = fishData.coins,
				exp = fishData.exp,
				wasPity = wasPity,
				effectiveLuck = effectiveLuck,
			}

			remote:FireClient(player, "CatchSuccess", fishData, rewardInfo, pData, pData.pity)
			return
		end

		if action == "SellFish" then
			local targetArg = arg1
			local foundTool = nil
			local backpack = player:FindFirstChild("Backpack")
			local char = player.Character

			if typeof(targetArg) == "Instance" and targetArg:IsA("Tool") then
				if (backpack and targetArg.Parent == backpack) or (char and targetArg.Parent == char) then
					foundTool = targetArg
				end
			elseif typeof(targetArg) == "string" then
				if backpack and backpack:FindFirstChild(targetArg) then
					foundTool = backpack:FindFirstChild(targetArg)
				elseif char and char:FindFirstChild(targetArg) then
					foundTool = char:FindFirstChild(targetArg)
				end
			end

			if foundTool and (foundTool:GetAttribute("IsFish") == true or (foundTool.Name ~= "FishingRod" and foundTool.Name ~= "Pancingan")) then
				local coins = foundTool:GetAttribute("Coins") or 15
				local fishName = foundTool:GetAttribute("FishName") or foundTool.Name
				foundTool:Destroy()

				pData.coins += coins
				syncLeaderstats(player)

				remote:FireClient(player, "FishSold", fishName, coins, pData.coins)
			else
				remote:FireClient(player, "Notification", "⚠️ Ikan tidak ditemukan atau sudah terjual!")
			end
			return
		end

		if action == "SellAllFish" then
			local backpack = player:FindFirstChild("Backpack")
			local char = player.Character

			local totalGained = 0
			local count = 0
			local toolsToSell = {}

			if backpack then
				for _, item in ipairs(backpack:GetChildren()) do
					if item:IsA("Tool") and (item:GetAttribute("IsFish") == true or (item.Name ~= "FishingRod" and item.Name ~= "Pancingan")) then
						table.insert(toolsToSell, item)
					end
				end
			end
			if char then
				for _, item in ipairs(char:GetChildren()) do
					if item:IsA("Tool") and (item:GetAttribute("IsFish") == true or (item.Name ~= "FishingRod" and item.Name ~= "Pancingan")) then
						table.insert(toolsToSell, item)
					end
				end
			end

			for _, tool in ipairs(toolsToSell) do
				local val = tool:GetAttribute("Coins") or 15
				totalGained += val
				count += 1
				tool:Destroy()
			end

			if count > 0 then
				pData.coins += totalGained
				syncLeaderstats(player)
				remote:FireClient(player, "AllFishSold", count, totalGained, pData.coins)
			else
				remote:FireClient(player, "Notification", "⚠️ Tidak ada ikan di inventory untuk dijual!")
			end
			return
		end

		if action == "CancelFishing" then
			local sessionId = tostring(arg1 or "")
			if activeSessions[sessionId] and activeSessions[sessionId].userId == player.UserId then
				activeSessions[sessionId] = nil
			end
			if playerSessions[player.UserId] == sessionId then
				playerSessions[player.UserId] = nil
			end
			return
		end

		if action == "GetPlayerData" then
			remote:FireClient(player, "PlayerDataUpdate", pData, pData.pity)
			return
		end
	end)
else
	warn("FishingServer: FishingRemote tidak ditemukan di ReplicatedStorage")
end
