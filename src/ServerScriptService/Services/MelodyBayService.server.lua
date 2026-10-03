--[[
	MelodyBayService (ServerScript)
	FISH!TUNE — Melody Bay 3D World Prototype Builder (FISH-006)

	Membangun dan mengelola lingkungan 3D zona awal "Melody Bay":
	1. Pembangunan Teluk & Dermaga Utama (Main Promenade, Fishing Piers & Piles).
	2. Badan Air Laut Luas (Ocean & Bay Water Body dengan deteksi pancing 360°).
	3. Plaza Kedatangan & SpawnLocation dengan Welcome Archway bernuansa musik.
	4. Kios Pedagang Ikan ("Marina Melody Merchant") dengan ProximityPrompt Jual Ikan.
	5. Dekorasi Musikal (Treble Clef, Floating Musical Notes, Ambient Lighting Sunset).
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZoneConfig = require(Shared:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))

-- ============ ROOT FOLDER ============
local oldMap = Workspace:FindFirstChild("MelodyBay_Map")
if oldMap then
	oldMap:Destroy()
end

local mapFolder = Instance.new("Model")
mapFolder.Name = "MelodyBay_Map"
mapFolder.Parent = Workspace

-- ============ HELPER BUILDERS ============
local function createPart(name, size, cframe, color, material, parent, anchored, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color or Color3.fromRGB(150, 150, 150)
	part.Material = material or Enum.Material.Plastic
	part.Anchored = if anchored ~= nil then anchored else true
	part.CanCollide = if canCollide ~= nil then canCollide else true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or mapFolder
	return part
end

local function createLantern(cf, parent)
	local post = createPart("LanternPost", Vector3.new(0.6, 6, 0.6), cf * CFrame.new(0, 3, 0), Color3.fromRGB(45, 45, 50), Enum.Material.Metal, parent)
	local lamp = createPart("LanternBulb", Vector3.new(1.2, 1.4, 1.2), cf * CFrame.new(0, 6.2, 0), Color3.fromRGB(255, 200, 100), Enum.Material.Neon, parent)
	
	local light = Instance.new("PointLight")
	light.Name = "WarmGlow"
	light.Color = Color3.fromRGB(255, 195, 110)
	light.Brightness = 2.5
	light.Range = 22
	light.Parent = lamp
	return post
end

local function createPalmTree(cf, parent)
	local trunk = createPart("PalmTrunk", Vector3.new(1.8, 14, 1.8), cf * CFrame.new(0, 7, 0) * CFrame.Angles(math.rad(4), 0, math.rad(-3)), Color3.fromRGB(110, 80, 50), Enum.Material.Wood, parent)
	
	-- Daun Palem
	for i = 0, 5 do
		local angle = math.rad(i * 60)
		local leafCF = cf * CFrame.new(0, 13.5, 0) * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-25), 0, 0) * CFrame.new(0, 0, 4.5)
		local leaf = createPart("PalmLeaf_" .. i, Vector3.new(2.5, 0.4, 9), leafCF, Color3.fromRGB(40, 140, 55), Enum.Material.Grass, parent)
	end
end

-- ============ 1. PENATAAN LIGHTING & ATMOSPHERE ============
local function setupLighting()
	Lighting.ClockTime = 17.4
	Lighting.GeographicLatitude = 22
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(135, 115, 145)
	Lighting.Ambient = Color3.fromRGB(90, 80, 100)
	Lighting.ShadowSoftness = 0.3

	-- Sky & Atmosphere
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Name = "SunsetSky"
		sky.SkyboxBk = "rbxassetid://600830446"
		sky.SkyboxDn = "rbxassetid://600831635"
		sky.SkyboxFt = "rbxassetid://600832720"
		sky.SkyboxLf = "rbxassetid://600833863"
		sky.SkyboxRt = "rbxassetid://600835106"
		sky.SkyboxUp = "rbxassetid://600836177"
		sky.CelestialBodiesShown = true
		sky.Parent = Lighting
	end

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 0.85

	local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
	sunRays.Intensity = 0.15
	sunRays.Spread = 0.7
end

-- ============ 2. BADAN AIR LAUT TELUK MELODY (WATER BODY) ============
local function buildWaterBody()
	-- Air Teluk Luas (Memungkinkan pancing dari semua dermaga)
	local water = createPart(
		"MelodyBayWater",
		Vector3.new(450, 12, 450),
		CFrame.new(0, -2, -30),
		Color3.fromRGB(0, 180, 230),
		Enum.Material.Water,
		mapFolder,
		true,
		false
	)
	water.Transparency = 0.35

	-- Dasar Laut Pasir Halus
	local seaBed = createPart(
		"SeaBed",
		Vector3.new(500, 6, 500),
		CFrame.new(0, -11, -30),
		Color3.fromRGB(215, 195, 145),
		Enum.Material.Sand,
		mapFolder
	)
end

-- ============ 3. DERMAGA UTAMA & PLATFORM PANCING ============
local function buildPiersAndPromenade()
	local woodColor = Color3.fromRGB(125, 85, 55)
	local darkWood = Color3.fromRGB(80, 55, 35)

	-- 1. Dermaga Penghubung Utama (Main Pier: Z = 60 to Z = -15)
	local mainPier = createPart(
		"MainPierWalkway",
		Vector3.new(18, 2, 85),
		CFrame.new(0, 5, 20),
		woodColor,
		Enum.Material.WoodPlanks,
		mapFolder
	)

	-- Tiang Kayu Penopang Dermaga di Bawah Air
	for z = -10, 55, 15 do
		for _, x in ipairs({ -8, 8 }) do
			createPart("PierPile", Vector3.new(1.8, 14, 1.8), CFrame.new(x, -1, z), darkWood, Enum.Material.Wood, mapFolder)
		end
	end

	-- 2. T-Platform Ujung Dermaga (Fishing Apex Deck: X = -45 to 45, Z = -22)
	local tDeck = createPart(
		"FishingTDeck",
		Vector3.new(70, 2, 24),
		CFrame.new(0, 5, -22),
		woodColor,
		Enum.Material.WoodPlanks,
		mapFolder
	)

	-- Tiang Kayu T-Deck
	for x = -30, 30, 15 do
		for _, z in ipairs({ -30, -14 }) do
			createPart("TDeckPile", Vector3.new(1.8, 14, 1.8), CFrame.new(x, -1, z), darkWood, Enum.Material.Wood, mapFolder)
		end
	end

	-- 3. Lentera & Pagar Tali Dermaga
	local lanternSpots = {
		Vector3.new(-8.5, 6, 50),
		Vector3.new(8.5, 6, 50),
		Vector3.new(-8.5, 6, 20),
		Vector3.new(8.5, 6, 20),
		Vector3.new(-34, 6, -22),
		Vector3.new(34, 6, -22),
		Vector3.new(-15, 6, -33),
		Vector3.new(15, 6, -33),
	}

	for _, spot in ipairs(lanternSpots) do
		createLantern(CFrame.new(spot), mapFolder)
	end

	-- 4. Bangku Kayu Santai di Dermaga
	local bench1 = createPart("PierBench_1", Vector3.new(8, 1.2, 2.5), CFrame.new(-6, 6.6, 5), darkWood, Enum.Material.WoodPlanks, mapFolder)
	local bench2 = createPart("PierBench_2", Vector3.new(8, 1.2, 2.5), CFrame.new(6, 6.6, 5), darkWood, Enum.Material.WoodPlanks, mapFolder)
end

-- ============ 4. PLAZA KEDATANGAN, SPAWN & WELCOME ARCHWAY ============
local function buildArrivalPlaza()
	-- Lantai Plaza Pantai
	local plaza = createPart(
		"ArrivalPlazaFloor",
		Vector3.new(60, 3, 40),
		CFrame.new(0, 5, 75),
		Color3.fromRGB(165, 155, 145),
		Enum.Material.Cobblestone,
		mapFolder
	)

	-- Pesisir Rumput Hijau & Pasir di Sekitar Plaza
	local bermL = createPart("CoastBerm_L", Vector3.new(45, 5, 60), CFrame.new(-50, 5.5, 75), Color3.fromRGB(85, 150, 60), Enum.Material.Grass, mapFolder)
	local bermR = createPart("CoastBerm_R", Vector3.new(45, 5, 60), CFrame.new(50, 5.5, 75), Color3.fromRGB(85, 150, 60), Enum.Material.Grass, mapFolder)

	createPalmTree(CFrame.new(-45, 8, 65), mapFolder)
	createPalmTree(CFrame.new(-55, 8, 85), mapFolder)
	createPalmTree(CFrame.new(45, 8, 65), mapFolder)
	createPalmTree(CFrame.new(55, 8, 85), mapFolder)

	-- SpawnLocation Bersih & Transparan
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MelodyBaySpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 6.6, 75)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = mapFolder

	-- Welcome Archway ("⚓ MELODY BAY ⚓")
	local archL = createPart("ArchPillar_L", Vector3.new(2.5, 14, 2.5), CFrame.new(-12, 13, 62), Color3.fromRGB(90, 60, 40), Enum.Material.Wood, mapFolder)
	local archR = createPart("ArchPillar_R", Vector3.new(2.5, 14, 2.5), CFrame.new(12, 13, 62), Color3.fromRGB(90, 60, 40), Enum.Material.Wood, mapFolder)
	local archBeam = createPart("ArchBeam", Vector3.new(28, 2.5, 3), CFrame.new(0, 20.5, 62), Color3.fromRGB(90, 60, 40), Enum.Material.Wood, mapFolder)

	-- Billboard Sign
	local bb = Instance.new("BillboardGui")
	bb.Name = "WelcomeSign"
	bb.Size = UDim2.new(0, 280, 0, 70)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = false
	bb.Adornee = archBeam
	bb.Parent = archBeam

	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Text = "⚓ MELODY BAY ⚓"
	signLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	signLabel.Font = Enum.Font.GothamBlack
	signLabel.TextSize = 26
	signLabel.TextStrokeTransparency = 0.2
	signLabel.TextStrokeColor3 = Color3.fromRGB(30, 20, 10)
	signLabel.Parent = bb
end

-- ============ 5. KIOS PEDAGANG IKAN (MARINA MERCHANT SHACK) ============
local function buildMerchantStall()
	local stallCF = CFrame.new(-18, 6.5, 48)

	-- Pondasi & Meja Kios
	local stallBase = createPart("MerchantCounter", Vector3.new(10, 3.5, 6), stallCF * CFrame.new(0, 1.75, 0), Color3.fromRGB(110, 75, 45), Enum.Material.WoodPlanks, mapFolder)
	
	-- Tiang Atap Kios
	createPart("AwningPole_1", Vector3.new(0.6, 7, 0.6), stallCF * CFrame.new(-4.5, 5, -2.5), Color3.fromRGB(60, 45, 30), Enum.Material.Wood, mapFolder)
	createPart("AwningPole_2", Vector3.new(0.6, 7, 0.6), stallCF * CFrame.new(4.5, 5, -2.5), Color3.fromRGB(60, 45, 30), Enum.Material.Wood, mapFolder)
	createPart("AwningPole_3", Vector3.new(0.6, 7, 0.6), stallCF * CFrame.new(-4.5, 5, 2.5), Color3.fromRGB(60, 45, 30), Enum.Material.Wood, mapFolder)
	createPart("AwningPole_4", Vector3.new(0.6, 7, 0.6), stallCF * CFrame.new(4.5, 5, 2.5), Color3.fromRGB(60, 45, 30), Enum.Material.Wood, mapFolder)

	-- Atap Terpal Belang Biru-Putih (Canopy Awning)
	local roof = createPart("MerchantRoof", Vector3.new(12, 1, 8), stallCF * CFrame.new(0, 8.8, 0) * CFrame.Angles(0, 0, math.rad(-5)), Color3.fromRGB(0, 160, 230), Enum.Material.Fabric, mapFolder)

	-- Peti & Ember Ikan Display
	local crate = createPart("FishCrate", Vector3.new(3, 2, 2.5), stallCF * CFrame.new(-2.5, 4.5, 0), Color3.fromRGB(140, 100, 60), Enum.Material.Wood, mapFolder)
	local barrel = createPart("FishBarrel", Vector3.new(2.5, 3.5, 2.5), stallCF * CFrame.new(5.5, 1.75, 0), Color3.fromRGB(100, 70, 40), Enum.Material.Wood, mapFolder)

	-- ProximityPrompt Interaksi Penjualan Ikan
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SellFishPrompt"
	prompt.ActionText = "Jual Semua Ikan (Koin)"
	prompt.ObjectText = "Tukang Ikan Melody"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = stallBase

	prompt.Triggered:Connect(function(player)
		local PlayerDataService = require(script.Parent.PlayerDataService)
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
			PlayerDataService.AddCoins(player, totalGained)
			local pData = PlayerDataService.Get(player)
			RemoteContract.Server.AllFishSold(player, count, totalGained, pData.coins)
		else
			RemoteContract.Server.Notify(player, "⚠️ Kamu belum memiliki ikan untuk dijual!")
		end
	end)
end

-- ============ 6. ORNAMEN MUSIK & AMBIENT HARMONIS ============
local function buildMusicalAccents()
	-- Simbol Kunci G (Treble Clef) Neon Mengapung di Atas Teluk
	local clefPart = createPart(
		"MelodyClefBeacon",
		Vector3.new(2, 2, 2),
		CFrame.new(0, 18, -22),
		Color3.fromRGB(0, 220, 255),
		Enum.Material.Neon,
		mapFolder,
		true,
		false
	)
	clefPart.Transparency = 0.4

	local clefLight = Instance.new("PointLight")
	clefLight.Color = Color3.fromRGB(0, 200, 255)
	clefLight.Brightness = 3
	clefLight.Range = 35
	clefLight.Parent = clefPart

	local bbClef = Instance.new("BillboardGui")
	bbClef.Size = UDim2.new(0, 80, 0, 120)
	bbClef.AlwaysOnTop = true
	bbClef.Adornee = clefPart
	bbClef.Parent = clefPart

	local clefLbl = Instance.new("TextLabel")
	clefLbl.Size = UDim2.fromScale(1, 1)
	clefLbl.BackgroundTransparency = 1
	clefLbl.Text = "𝄞"
	clefLbl.TextColor3 = Color3.fromRGB(200, 240, 255)
	clefLbl.Font = Enum.Font.GothamBlack
	clefLbl.TextSize = 75
	clefLbl.Parent = bbClef

	-- Tuts Piano Boardwalk (Piano Keys Step) di Sisi Dermaga
	for i = 1, 8 do
		local isBlack = (i == 2 or i == 3 or i == 5 or i == 6 or i == 7)
		local keyColor = isBlack and Color3.fromRGB(25, 25, 30) or Color3.fromRGB(240, 240, 245)
		local keyZ = 50 - (i * 4)
		local step = createPart(
			"PianoStep_" .. i,
			Vector3.new(3, 0.4, 3.2),
			CFrame.new(10.5, 5.2, keyZ),
			keyColor,
			Enum.Material.SmoothPlastic,
			mapFolder
		)
	end
end

-- ============ EKSEKUSI PEMBANGUNAN ============
print("🔨 [MelodyBayService] Memulai pembangunan 3D Prototype Melody Bay...")
setupLighting()
buildWaterBody()
buildPiersAndPromenade()
buildArrivalPlaza()
buildMerchantStall()
buildMusicalAccents()
print("✨ [MelodyBayService] Melody Bay 3D Prototype berhasil dibangun di Workspace!")
