--[[
	MerchantNpcService (ModuleScript)
	FISH!TUNE — World Merchant NPC & Fish Market Spawner (FISH-025)

	Layanan Sentral Spawner NPC Pedagang Ikan & Pasar Samudra:
	1. Auto-spawn NPC Nelayan Pedagang Ikan ("Paman Samudra") di Dermaga Melody Bay.
	2. Model 3D Stylized (Karakter Nelayan, Meja Lapak Ikan, Keranjang Tangkapan, & Peti Kayu).
	3. ProximityPrompt Ganda Terintegrasi:
	   - [E] Jual Semua Tangkapan (Sell All Fish & Loot).
	   - [F] Buka Toko Joran & Umpan (Equipment Shop).
	4. BillboardGui Overhead Interaktif dengan Status Animasi & Jarak Pandang Dinamis.
	5. Deteksi Interaksi Real-Time & Integrasi dengan InventoryService & EconomyService.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local InventoryService = require(script.Parent.InventoryService)
local EconomyService = require(script.Parent.EconomyService)

local MerchantNpcService = {}

local MERCHANT_POSITION = Vector3.new(16, 5.5, 30)
local MERCHANT_ROTATION = -75 -- Derajat menghadap jalan dermaga

-- ============ SPAWN STYLIZED MERCHANT 3D MODEL ============
function MerchantNpcService.SpawnMerchant()
	local existing = Workspace:FindFirstChild("FishMerchantNPC")
	if existing then
		existing:Destroy()
	end

	local npcModel = Instance.new("Model")
	npcModel.Name = "FishMerchantNPC"

	-- 1. Stand / Lapak Meja Nelayan
	local tableTop = Instance.new("Part")
	tableTop.Name = "FishTableTop"
	tableTop.Size = Vector3.new(6, 0.6, 3.2)
	tableTop.Position = MERCHANT_POSITION + Vector3.new(0, 1.8, 0)
	tableTop.Anchored = true
	tableTop.CanCollide = true
	tableTop.Color = Color3.fromRGB(120, 85, 50)
	tableTop.Material = Enum.Material.WoodPlanks
	tableTop.Orientation = Vector3.new(0, MERCHANT_ROTATION, 0)
	tableTop.Parent = npcModel

	local leg1 = Instance.new("Part")
	leg1.Size = Vector3.new(0.5, 2.0, 0.5)
	leg1.Position = tableTop.Position + Vector3.new(2.4, -1.0, 1.1)
	leg1.Anchored = true
	leg1.CanCollide = true
	leg1.Color = Color3.fromRGB(80, 55, 35)
	leg1.Material = Enum.Material.Wood
	leg1.Parent = npcModel

	local leg2 = leg1:Clone()
	leg2.Position = tableTop.Position + Vector3.new(-2.4, -1.0, 1.1)
	leg2.Parent = npcModel

	local leg3 = leg1:Clone()
	leg3.Position = tableTop.Position + Vector3.new(2.4, -1.0, -1.1)
	leg3.Parent = npcModel

	local leg4 = leg1:Clone()
	leg4.Position = tableTop.Position + Vector3.new(-2.4, -1.0, -1.1)
	leg4.Parent = npcModel

	-- Tumpukan Ikan Hiasan di Atas Meja (Decorative Props)
	local decoFish1 = Instance.new("Part")
	decoFish1.Name = "DecoFish1"
	decoFish1.Shape = Enum.PartType.Ball
	decoFish1.Size = Vector3.new(1.2, 0.5, 2.2)
	decoFish1.Position = tableTop.Position + Vector3.new(-1.2, 0.45, 0.2)
	decoFish1.Color = Color3.fromRGB(0, 180, 240)
	decoFish1.Material = Enum.Material.SmoothPlastic
	decoFish1.Anchored = true
	decoFish1.CanCollide = false
	decoFish1.Orientation = Vector3.new(0, MERCHANT_ROTATION + 25, 0)
	decoFish1.Parent = npcModel

	local decoFish2 = Instance.new("Part")
	decoFish2.Name = "DecoFish2"
	decoFish2.Shape = Enum.PartType.Ball
	decoFish2.Size = Vector3.new(1.0, 0.4, 1.8)
	decoFish2.Position = tableTop.Position + Vector3.new(1.0, 0.4, -0.3)
	decoFish2.Color = Color3.fromRGB(255, 170, 50)
	decoFish2.Material = Enum.Material.SmoothPlastic
	decoFish2.Anchored = true
	decoFish2.CanCollide = false
	decoFish2.Orientation = Vector3.new(0, MERCHANT_ROTATION - 30, 0)
	decoFish2.Parent = npcModel

	-- 2. Tubuh Karakter Nelayan (Stylized NPC)
	local npcTorso = Instance.new("Part")
	npcTorso.Name = "Torso"
	npcTorso.Size = Vector3.new(2.0, 2.2, 1.1)
	npcTorso.Position = tableTop.Position + Vector3.new(0, 1.6, -1.8)
	npcTorso.Anchored = true
	npcTorso.CanCollide = true
	npcTorso.Color = Color3.fromRGB(240, 190, 40) -- Jas hujan nelayan kuning
	npcTorso.Material = Enum.Material.SmoothPlastic
	npcTorso.Orientation = Vector3.new(0, MERCHANT_ROTATION, 0)
	npcTorso.Parent = npcModel

	npcModel.PrimaryPart = npcTorso

	local npcHead = Instance.new("Part")
	npcHead.Name = "Head"
	npcHead.Shape = Enum.PartType.Ball
	npcHead.Size = Vector3.new(1.3, 1.3, 1.3)
	npcHead.Position = npcTorso.Position + Vector3.new(0, 1.7, 0)
	npcHead.Anchored = true
	npcHead.CanCollide = false
	npcHead.Color = Color3.fromRGB(255, 215, 175)
	npcHead.Material = Enum.Material.SmoothPlastic
	npcHead.Parent = npcModel

	-- Topi Nelayan (Sou'wester Hat)
	local npcHat = Instance.new("Part")
	npcHat.Name = "Hat"
	npcHat.Shape = Enum.PartType.Cylinder
	npcHat.Size = Vector3.new(0.4, 2.4, 2.4)
	npcHat.Position = npcHead.Position + Vector3.new(0, 0.7, 0)
	npcHat.Orientation = Vector3.new(0, 0, 90)
	npcHat.Anchored = true
	npcHat.CanCollide = false
	npcHat.Color = Color3.fromRGB(230, 170, 30)
	npcHat.Material = Enum.Material.SmoothPlastic
	npcHat.Parent = npcModel

	-- ============ 3. BILLBOARD GUI OVERHEAD ============
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MerchantTag"
	billboard.Size = UDim2.new(0, 240, 0, 75)
	billboard.StudsOffset = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 50
	billboard.Adornee = npcHead
	billboard.Parent = npcHead

	local bFrame = Instance.new("Frame")
	bFrame.Size = UDim2.new(1, 0, 1, 0)
	bFrame.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	bFrame.BackgroundTransparency = 0.2
	bFrame.BorderSizePixel = 0
	bFrame.Parent = billboard
	Instance.new("UICorner", bFrame).CornerRadius = UDim.new(0, 10)

	local bStroke = Instance.new("UIStroke")
	bStroke.Color = Color3.fromRGB(0, 220, 255)
	bStroke.Thickness = 1.6
	bStroke.Parent = bFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 26)
	titleLabel.Position = UDim2.new(0, 0, 0, 4)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🐟 PAMAN SAMUDRA"
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 14
	titleLabel.Parent = bFrame

	local subLabel = Instance.new("TextLabel")
	subLabel.Size = UDim2.new(1, 0, 0, 18)
	subLabel.Position = UDim2.new(0, 0, 0, 28)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = "Lapak Ikan & Toko Pancing"
	subLabel.TextColor3 = Color3.fromRGB(180, 215, 245)
	subLabel.Font = Enum.Font.GothamMedium
	subLabel.TextSize = 11
	subLabel.Parent = bFrame

	local promptHintLabel = Instance.new("TextLabel")
	promptHintLabel.Size = UDim2.new(1, 0, 0, 18)
	promptHintLabel.Position = UDim2.new(0, 0, 0, 48)
	promptHintLabel.BackgroundTransparency = 1
	promptHintLabel.Text = "Tekan [E] Jual  •  [F] Toko"
	promptHintLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
	promptHintLabel.Font = Enum.Font.GothamBold
	promptHintLabel.TextSize = 11
	promptHintLabel.Parent = bFrame

	-- ============ 4. PROXIMITY PROMPTS INTERAKTIF ============
	-- Prompt 1: JUAL SEMUA IKAN [E]
	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.Name = "SellFishPrompt"
	sellPrompt.ActionText = "Jual Semua Ikan (Sell All)"
	sellPrompt.ObjectText = "💰 Lapak Ikan Samudra"
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.E
	sellPrompt.MaxActivationDistance = 14
	sellPrompt.HoldDuration = 0.2
	sellPrompt.RequiresLineOfSight = false
	sellPrompt.Parent = tableTop

	-- Prompt 2: BUKA TOKO ALAT PANCING [F]
	local shopPrompt = Instance.new("ProximityPrompt")
	shopPrompt.Name = "ShopPrompt"
	shopPrompt.ActionText = "Buka Toko Pancing (Shop)"
	shopPrompt.ObjectText = "🛒 Toko Alat Pancing"
	shopPrompt.KeyboardKeyCode = Enum.KeyCode.F
	shopPrompt.MaxActivationDistance = 14
	shopPrompt.HoldDuration = 0.2
	shopPrompt.RequiresLineOfSight = false
	shopPrompt.Parent = tableTop

	npcModel.Parent = Workspace

	print("[MerchantNpcService] Berhasil men-spawn Pedagang Ikan 'Paman Samudra' di Dermaga Melody Bay.")
	return npcModel
end

-- ============ INIT & EVENT LISTENERS ============
local isInitialized = false
function MerchantNpcService.Init()
	if isInitialized then return end
	isInitialized = true

	MerchantNpcService.SpawnMerchant()

	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local pName = prompt.Name:lower()
		local pAction = prompt.ActionText:lower()

		-- 1. Penjualan Ikan Massal (Sell All Fish & Loot)
		if pName == "sellfishprompt" or pName == "sellallprompt" or pName:find("jual") or pAction:find("jual") or pAction:find("sell") then
			local success, count, totalGained, countLocked = InventoryService.SellAll(player)
			if success then
				print(string.format("[MerchantNpcService] %s berhasil menjual %d ikan ke pedagang (+%d Koin)", player.Name, count, totalGained))
			end

		-- 2. Membuka Toko Peralatan Pancing (Shop Catalog)
		elseif pName == "shopprompt" or pName:find("shop") or pName:find("toko") or pAction:find("beli") or pAction:find("shop") or pAction:find("toko") then
			local catalog = EconomyService.GetShopCatalog(player)
			catalog.openModal = true
			RemoteContract.Server.ShopCatalogData(player, catalog)
		end
	end)

	print("[MerchantNpcService] Inisialisasi MerchantNpcService selesai.")
end

MerchantNpcService.Init()

return MerchantNpcService
