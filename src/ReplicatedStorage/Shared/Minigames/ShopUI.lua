--[[
	ShopUI (ModuleScript)
	FISH!TUNE — Oceanic Merchant & Equipment Shop UI (FISH-024)

	Desain Glassmorphism Modern Toko Samudra:
	1. Top Header: Ikon Toko + "TOKO SAMUDRA" + Saldo Koin Real-time + Tombol Tutup.
	2. Category Tabs: [🎣 Joran Pancing], [🪱 Umpan & Pakan], [🎒 Perluasan Tas].
	3. Halaman Joran: Kartu joran lengkap dengan stat Luck, Cast Power, Reel Speed, Level Req, Tombol Beli / Pasang.
	4. Halaman Umpan: Kartu umpan dengan stok dimiliki, tombol pasang, tombol beli satuan & paket diskon.
	5. Halaman Perluasan Tas: Visualisasi tier saat ini, penambahan slot, dan tombol upgrade instan.
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))

local player = Players.LocalPlayer

local ShopUI = {}
local activeModal = nil
local activeOverlay = nil
local isClosing = false

-- State
local currentTab = "RODS" -- "RODS" | "BAITS" | "BAG"
local cachedCatalog = nil
local cachedCoins = 0

-- UI Component References
local contentContainer = nil
local coinHeaderLabel = nil
local tabButtons = {}

-- ============ SOUND HELPER ============
local function playLocalSound(soundId, volume, speed)
	task.spawn(function()
		local snd = Instance.new("Sound")
		snd.SoundId = soundId
		snd.Volume = volume or 0.8
		snd.PlaybackSpeed = speed or 1.0
		snd.Parent = SoundService
		snd:Play()
		snd.Ended:Connect(function()
			snd:Destroy()
		end)
		task.delay(4, function()
			if snd and snd.Parent then snd:Destroy() end
		end)
	end)
end

-- ============ CLOSE / HIDE ============
function ShopUI.Hide(callback)
	if isClosing or not activeModal or not activeOverlay then
		if callback then callback() end
		return
	end

	isClosing = true
	local card = activeModal
	local overlay = activeOverlay

	local closeTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 720, 0, 500),
		Position = UDim2.new(0.5, 0, 0.54, 0),
		BackgroundTransparency = 1,
	})
	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})

	closeTween:Play()
	overlayTween:Play()

	closeTween.Completed:Connect(function()
		if overlay and overlay.Parent then
			overlay:Destroy()
		end
		activeModal = nil
		activeOverlay = nil
		isClosing = false
		if callback then callback() end
	end)
end

function ShopUI.IsOpen()
	return activeOverlay ~= nil and activeOverlay.Parent ~= nil
end

-- ============ UPDATE CATALOG DATA ============
function ShopUI.UpdateCatalogData(catalogData)
	if not catalogData then return end
	cachedCatalog = catalogData
	cachedCoins = catalogData.coins or cachedCoins

	if coinHeaderLabel then
		coinHeaderLabel.Text = string.format("💰 <b>%d</b> Koin", cachedCoins)
	end

	if ShopUI.IsOpen() then
		ShopUI.RenderContent()
	end
end

-- ============ RENDER RODS TAB ============
local function renderRodsTab(parent)
	local rods = (cachedCatalog and cachedCatalog.rods) or {}
	local pCoins = cachedCatalog and cachedCatalog.coins or 0
	local pLevel = cachedCatalog and cachedCatalog.level or 1
	local equippedRod = cachedCatalog and cachedCatalog.equippedRod or "StarterRod"

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(2, 132, 199)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	for idx, rod in ipairs(rods) do
		local isEquipped = (equippedRod == rod.id)
		local isOwned = rod.isOwned
		local isLevelMet = (pLevel >= rod.levelReq)
		local canAfford = (pCoins >= rod.price)

		local card = Instance.new("Frame")
		card.Name = "RodCard_" .. rod.id
		card.Size = UDim2.new(1, -10, 0, 106)
		card.BackgroundColor3 = Color3.fromRGB(18, 27, 43)
		card.BorderSizePixel = 0
		card.LayoutOrder = idx
		card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = isEquipped and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(30, 45, 68)
		cStroke.Thickness = isEquipped and 1.8 or 1
		cStroke.Parent = card

		-- Left Icon Area
		local iconBox = Instance.new("Frame")
		iconBox.Size = UDim2.new(0, 80, 0, 80)
		iconBox.Position = UDim2.new(0, 12, 0.5, -40)
		iconBox.BackgroundColor3 = Color3.fromRGB(10, 17, 29)
		iconBox.BorderSizePixel = 0
		iconBox.Parent = card
		Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 10)

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = "🎣"
		iconLabel.Font = Enum.Font.GothamBlack
		iconLabel.TextSize = 34
		iconLabel.Parent = iconBox

		-- Rod Info
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.55, 0, 0, 20)
		title.Position = UDim2.new(0, 104, 0, 12)
		title.BackgroundTransparency = 1
		title.Text = rod.name
		title.TextColor3 = isEquipped and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card

		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0, 80, 0, 16)
		badge.Position = UDim2.new(0, 104, 0, 34)
		badge.BackgroundColor3 = Color3.fromRGB(25, 36, 56)
		badge.BorderSizePixel = 0
		badge.Text = rod.badge or "JORAN"
		badge.TextColor3 = Color3.fromRGB(251, 191, 36)
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 9
		badge.Parent = card
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(0.55, 0, 0, 18)
		statsLabel.Position = UDim2.new(0, 104, 0, 54)
		statsLabel.BackgroundTransparency = 1
		statsLabel.RichText = true
		statsLabel.Text = string.format("🍀 <font color=\"#4ADE80\"><b>+%d Luck</b></font>  •  ⚡ <b>%.2fx Lemparan</b>  •  ⭐ <b>Req. Lv. %d</b>", rod.luckBonus or 5, rod.castPowerMultiplier or 1.0, rod.levelReq or 1)
		statsLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
		statsLabel.Font = Enum.Font.GothamMedium
		statsLabel.TextSize = 11
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = card

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.55, 0, 0, 24)
		descLabel.Position = UDim2.new(0, 104, 0, 74)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = rod.description or ""
		descLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
		descLabel.Font = Enum.Font.GothamMedium
		descLabel.TextSize = 10
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
		descLabel.Parent = card

		-- Action Button on Right
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(0, 140, 0, 38)
		actionBtn.Position = UDim2.new(1, -152, 0.5, -19)
		actionBtn.BorderSizePixel = 0
		actionBtn.Font = Enum.Font.GothamBlack
		actionBtn.TextSize = 11
		actionBtn.Parent = card
		Instance.new("UICorner", actionBtn).CornerRadius = UDim.new(0, 8)

		if isEquipped then
			actionBtn.BackgroundColor3 = Color3.fromRGB(15, 60, 45)
			actionBtn.Text = "✅ DIGUNAKAN"
			actionBtn.TextColor3 = Color3.fromRGB(74, 222, 128)
		elseif isOwned then
			actionBtn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
			actionBtn.Text = "🎣 GUNAKAN"
			actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			actionBtn.MouseButton1Click:Connect(function()
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
				RemoteContract.Client.EquipRod(rod.id)
			end)
		elseif not isLevelMet then
			actionBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 30)
			actionBtn.Text = string.format("🔒 BUTUH LV. %d", rod.levelReq)
			actionBtn.TextColor3 = Color3.fromRGB(248, 113, 113)
		else
			actionBtn.BackgroundColor3 = canAfford and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(45, 38, 25)
			actionBtn.Text = string.format("💰 %d KOIN", rod.price)
			actionBtn.TextColor3 = canAfford and Color3.fromRGB(15, 23, 42) or Color3.fromRGB(200, 160, 80)

			if canAfford then
				actionBtn.MouseButton1Click:Connect(function()
					playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
					RemoteContract.Client.BuyRod(rod.id)
				end)
			end
		end
	end
end

-- ============ RENDER BAITS TAB ============
local function renderBaitsTab(parent)
	local baits = (cachedCatalog and cachedCatalog.baits) or {}
	local pCoins = cachedCatalog and cachedCatalog.coins or 0
	local equippedBait = cachedCatalog and cachedCatalog.equippedBait

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(2, 132, 199)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	for idx, bait in ipairs(baits) do
		local isEquipped = (equippedBait == bait.id)
		local stock = bait.stock or 0
		local canBuySingle = (pCoins >= bait.priceSingle)
		local canBuyPack = (pCoins >= bait.pricePack)

		local card = Instance.new("Frame")
		card.Name = "BaitCard_" .. bait.id
		card.Size = UDim2.new(1, -10, 0, 116)
		card.BackgroundColor3 = Color3.fromRGB(18, 27, 43)
		card.BorderSizePixel = 0
		card.LayoutOrder = idx
		card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = isEquipped and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(30, 45, 68)
		cStroke.Thickness = isEquipped and 1.8 or 1
		cStroke.Parent = card

		-- Icon Area
		local iconBox = Instance.new("Frame")
		iconBox.Size = UDim2.new(0, 80, 0, 80)
		iconBox.Position = UDim2.new(0, 12, 0.5, -40)
		iconBox.BackgroundColor3 = Color3.fromRGB(10, 17, 29)
		iconBox.BorderSizePixel = 0
		iconBox.Parent = card
		Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 10)

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = bait.icon or "🪱"
		iconLabel.Font = Enum.Font.GothamBlack
		iconLabel.TextSize = 34
		iconLabel.Parent = iconBox

		-- Bait Info
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.48, 0, 0, 20)
		title.Position = UDim2.new(0, 104, 0, 12)
		title.BackgroundTransparency = 1
		title.Text = bait.name
		title.TextColor3 = isEquipped and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(255, 255, 255)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card

		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0, 80, 0, 16)
		badge.Position = UDim2.new(0, 104, 0, 34)
		badge.BackgroundColor3 = Color3.fromRGB(25, 36, 56)
		badge.BorderSizePixel = 0
		badge.Text = bait.badge or "UMPAN"
		badge.TextColor3 = Color3.fromRGB(251, 191, 36)
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 9
		badge.Parent = card
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 4)

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(0.48, 0, 0, 18)
		statsLabel.Position = UDim2.new(0, 104, 0, 54)
		statsLabel.BackgroundTransparency = 1
		statsLabel.RichText = true
		statsLabel.Text = string.format("🍀 <font color=\"#4ADE80\"><b>+%d Luck</b></font>  •  📦 Stok: <font color=\"#38BDF8\"><b>%d Ekor</b></font>", bait.luckBonus or 4, stock)
		statsLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
		statsLabel.Font = Enum.Font.GothamMedium
		statsLabel.TextSize = 11
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = card

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(0.48, 0, 0, 32)
		descLabel.Position = UDim2.new(0, 104, 0, 74)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = bait.description or ""
		descLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
		descLabel.Font = Enum.Font.GothamMedium
		descLabel.TextSize = 10
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = card

		-- Action Buttons Container on Right
		local btnGroup = Instance.new("Frame")
		btnGroup.Size = UDim2.new(0, 190, 1, -20)
		btnGroup.Position = UDim2.new(1, -202, 0, 10)
		btnGroup.BackgroundTransparency = 1
		btnGroup.Parent = card

		-- Equip / Unequip Button
		local equipBtn = Instance.new("TextButton")
		equipBtn.Size = UDim2.new(1, 0, 0, 28)
		equipBtn.Position = UDim2.new(0, 0, 0, 0)
		equipBtn.BorderSizePixel = 0
		equipBtn.Font = Enum.Font.GothamBold
		equipBtn.TextSize = 10
		equipBtn.Parent = btnGroup
		Instance.new("UICorner", equipBtn).CornerRadius = UDim.new(0, 6)

		if isEquipped then
			equipBtn.BackgroundColor3 = Color3.fromRGB(15, 60, 45)
			equipBtn.Text = "✅ TERPASANG (KLIK LEPAS)"
			equipBtn.TextColor3 = Color3.fromRGB(74, 222, 128)
			equipBtn.MouseButton1Click:Connect(function()
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
				RemoteContract.Client.EquipBait("NONE")
			end)
		elseif stock > 0 then
			equipBtn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
			equipBtn.Text = "🪱 PASANG UMPAN"
			equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			equipBtn.MouseButton1Click:Connect(function()
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
				RemoteContract.Client.EquipBait(bait.id)
			end)
		else
			equipBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
			equipBtn.Text = "🔒 STOK HABIS"
			equipBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
		end

		-- Buy Single Button
		local buySingleBtn = Instance.new("TextButton")
		buySingleBtn.Size = UDim2.new(0.48, 0, 0, 28)
		buySingleBtn.Position = UDim2.new(0, 0, 0, 34)
		buySingleBtn.BackgroundColor3 = canBuySingle and Color3.fromRGB(30, 45, 68) or Color3.fromRGB(25, 30, 40)
		buySingleBtn.BorderSizePixel = 0
		buySingleBtn.Text = string.format("💰 1x (%d)", bait.priceSingle)
		buySingleBtn.TextColor3 = canBuySingle and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(120, 130, 140)
		buySingleBtn.Font = Enum.Font.GothamBold
		buySingleBtn.TextSize = 10
		buySingleBtn.Parent = btnGroup
		Instance.new("UICorner", buySingleBtn).CornerRadius = UDim.new(0, 6)

		if canBuySingle then
			buySingleBtn.MouseButton1Click:Connect(function()
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
				RemoteContract.Client.BuyBait(bait.id, false)
			end)
		end

		-- Buy Pack Button
		local buyPackBtn = Instance.new("TextButton")
		buyPackBtn.Size = UDim2.new(0.48, 0, 0, 28)
		buyPackBtn.Position = UDim2.new(0.52, 0, 0, 34)
		buyPackBtn.BackgroundColor3 = canBuyPack and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(35, 30, 20)
		buyPackBtn.BorderSizePixel = 0
		buyPackBtn.Text = string.format("📦 %dx (%d)", bait.packQuantity or 10, bait.pricePack)
		buyPackBtn.TextColor3 = canBuyPack and Color3.fromRGB(15, 23, 42) or Color3.fromRGB(160, 140, 80)
		buyPackBtn.Font = Enum.Font.GothamBlack
		buyPackBtn.TextSize = 10
		buyPackBtn.Parent = btnGroup
		Instance.new("UICorner", buyPackBtn).CornerRadius = UDim.new(0, 6)

		if canBuyPack then
			buyPackBtn.MouseButton1Click:Connect(function()
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
				RemoteContract.Client.BuyBait(bait.id, true)
			end)
		end
	end
end

-- ============ RENDER BAG UPGRADE TAB ============
local function renderBagTab(parent)
	local pCoins = cachedCatalog and cachedCatalog.coins or 0
	local pLevel = cachedCatalog and cachedCatalog.level or 1
	local currentSlots = cachedCatalog and cachedCatalog.maxSlots or 35
	local bagTier = cachedCatalog and cachedCatalog.bagTier or 0
	local nextUpgrade = cachedCatalog and cachedCatalog.nextBagUpgrade

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	-- Card 1: Current Capacity
	local currentCard = Instance.new("Frame")
	currentCard.Size = UDim2.new(1, -10, 0, 130)
	currentCard.Position = UDim2.new(0, 0, 0, 0)
	currentCard.BackgroundColor3 = Color3.fromRGB(18, 27, 43)
	currentCard.BorderSizePixel = 0
	currentCard.Parent = container
	Instance.new("UICorner", currentCard).CornerRadius = UDim.new(0, 14)

	local curTitle = Instance.new("TextLabel")
	curTitle.Size = UDim2.new(1, -24, 0, 24)
	curTitle.Position = UDim2.new(0, 16, 0, 14)
	curTitle.BackgroundTransparency = 1
	curTitle.Text = "🎒 KAPASITAS TAS SAAT INI"
	curTitle.TextColor3 = Color3.fromRGB(148, 163, 184)
	curTitle.Font = Enum.Font.GothamBold
	curTitle.TextSize = 12
	curTitle.TextXAlignment = Enum.TextXAlignment.Left
	curTitle.Parent = currentCard

	local curValue = Instance.new("TextLabel")
	curValue.Size = UDim2.new(1, -24, 0, 36)
	curValue.Position = UDim2.new(0, 16, 0, 42)
	curValue.BackgroundTransparency = 1
	curValue.RichText = true
	curValue.Text = string.format("<font color=\"#38BDF8\"><b>%d SLOT</b></font> <font color=\"#94A3B8\">(Tier %d)</font>", currentSlots, bagTier)
	curValue.TextColor3 = Color3.fromRGB(255, 255, 255)
	curValue.Font = Enum.Font.GothamBlack
	curValue.TextSize = 28
	curValue.TextXAlignment = Enum.TextXAlignment.Left
	curValue.Parent = currentCard

	local curDesc = Instance.new("TextLabel")
	curDesc.Size = UDim2.new(1, -24, 0, 20)
	curDesc.Position = UDim2.new(0, 16, 0, 88)
	curDesc.BackgroundTransparency = 1
	curDesc.Text = "Kapasitas tas menentukan berapa banyak ikan, harta karun, dan relik yang dapat kamu bawa sekaligus."
	curDesc.TextColor3 = Color3.fromRGB(148, 163, 184)
	curDesc.Font = Enum.Font.GothamMedium
	curDesc.TextSize = 11
	curDesc.TextXAlignment = Enum.TextXAlignment.Left
	curDesc.Parent = currentCard

	-- Card 2: Next Upgrade
	local nextCard = Instance.new("Frame")
	nextCard.Size = UDim2.new(1, -10, 0, 220)
	nextCard.Position = UDim2.new(0, 0, 0, 145)
	nextCard.BackgroundColor3 = Color3.fromRGB(18, 27, 43)
	nextCard.BorderSizePixel = 0
	nextCard.Parent = container
	Instance.new("UICorner", nextCard).CornerRadius = UDim.new(0, 14)

	local nStroke = Instance.new("UIStroke")
	nStroke.Color = Color3.fromRGB(234, 179, 8)
	nStroke.Thickness = 1.5
	nStroke.Transparency = 0.4
	nStroke.Parent = nextCard

	if nextUpgrade then
		local isLevelMet = (pLevel >= nextUpgrade.levelReq)
		local canAfford = (pCoins >= nextUpgrade.price)

		local nextHeader = Instance.new("TextLabel")
		nextHeader.Size = UDim2.new(1, -24, 0, 24)
		nextHeader.Position = UDim2.new(0, 16, 0, 16)
		nextHeader.BackgroundTransparency = 1
		nextHeader.Text = "✨ TINGKAT UPGRADE BERIKUTNYA"
		nextHeader.TextColor3 = Color3.fromRGB(251, 191, 36)
		nextHeader.Font = Enum.Font.GothamBold
		nextHeader.TextSize = 13
		nextHeader.TextXAlignment = Enum.TextXAlignment.Left
		nextHeader.Parent = nextCard

		local nextName = Instance.new("TextLabel")
		nextName.Size = UDim2.new(1, -24, 0, 28)
		nextName.Position = UDim2.new(0, 16, 0, 44)
		nextName.BackgroundTransparency = 1
		nextName.Text = string.format("%s (%s)", nextUpgrade.name, nextUpgrade.badge or "UPGRADE")
		nextName.TextColor3 = Color3.fromRGB(255, 255, 255)
		nextName.Font = Enum.Font.GothamBlack
		nextName.TextSize = 18
		nextName.TextXAlignment = Enum.TextXAlignment.Left
		nextName.Parent = nextCard

		local nextPerk = Instance.new("TextLabel")
		nextPerk.Size = UDim2.new(1, -24, 0, 22)
		nextPerk.Position = UDim2.new(0, 16, 0, 76)
		nextPerk.BackgroundTransparency = 1
		nextPerk.RichText = true
		nextPerk.Text = string.format("🎁 Ekspansi: <font color=\"#4ADE80\"><b>+%d Slot</b></font>  ➔  Total Baru: <font color=\"#38BDF8\"><b>%d Slot</b></font>", nextUpgrade.extraSlots, nextUpgrade.totalSlots)
		nextPerk.TextColor3 = Color3.fromRGB(203, 213, 225)
		nextPerk.Font = Enum.Font.GothamBold
		nextPerk.TextSize = 13
		nextPerk.TextXAlignment = Enum.TextXAlignment.Left
		nextPerk.Parent = nextCard

		local nextReq = Instance.new("TextLabel")
		nextReq.Size = UDim2.new(1, -24, 0, 20)
		nextReq.Position = UDim2.new(0, 16, 0, 102)
		nextReq.BackgroundTransparency = 1
		nextReq.RichText = true
		nextReq.Text = string.format("⭐ Syarat Level: <b>Lv. %d</b> (Level Kamu: %d)  •  💰 Biaya: <font color=\"#F59E0B\"><b>%d Koin</b></font>", nextUpgrade.levelReq, pLevel, nextUpgrade.price)
		nextReq.TextColor3 = Color3.fromRGB(148, 163, 184)
		nextReq.Font = Enum.Font.GothamMedium
		nextReq.TextSize = 11
		nextReq.TextXAlignment = Enum.TextXAlignment.Left
		nextReq.Parent = nextCard

		local upBtn = Instance.new("TextButton")
		upBtn.Size = UDim2.new(1, -32, 0, 44)
		upBtn.Position = UDim2.new(0, 16, 1, -58)
		upBtn.BorderSizePixel = 0
		upBtn.Font = Enum.Font.GothamBlack
		upBtn.TextSize = 13
		upBtn.Parent = nextCard
		Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 10)

		if not isLevelMet then
			upBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
			upBtn.Text = string.format("🔒 BUTUH LEVEL %d UNTUK UPGRADE", nextUpgrade.levelReq)
			upBtn.TextColor3 = Color3.fromRGB(248, 113, 113)
		elseif not canAfford then
			upBtn.BackgroundColor3 = Color3.fromRGB(45, 38, 25)
			upBtn.Text = string.format("💰 KOIN TIDAK CUKUP (%d / %d KOIN)", pCoins, nextUpgrade.price)
			upBtn.TextColor3 = Color3.fromRGB(200, 160, 80)
		else
			upBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
			upBtn.Text = string.format("🚀 UPGRADE SEKARANG (%d KOIN)", nextUpgrade.price)
			upBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
			upBtn.MouseButton1Click:Connect(function()
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
				RemoteContract.Client.UpgradeBag()
			end)
		end
	else
		local maxLabel = Instance.new("TextLabel")
		maxLabel.Size = UDim2.new(1, 0, 1, 0)
		maxLabel.BackgroundTransparency = 1
		maxLabel.Text = "👑 KAPASITAS TAS SUDAH MENCAPAI TINGKAT MAKSIMUM (MAX TIER)"
		maxLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
		maxLabel.Font = Enum.Font.GothamBlack
		maxLabel.TextSize = 14
		maxLabel.Parent = nextCard
	end
end

-- ============ RENDER TAB CONTENT ============
function ShopUI.RenderContent()
	if not contentContainer then return end

	for _, child in ipairs(contentContainer:GetChildren()) do
		child:Destroy()
	end

	-- Update tab buttons styling
	for tabId, btn in pairs(tabButtons) do
		local isSel = (tabId == currentTab)
		if isSel then
			btn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(19, 29, 46)
			btn.TextColor3 = Color3.fromRGB(203, 213, 225)
		end
	end

	if currentTab == "RODS" then
		renderRodsTab(contentContainer)
	elseif currentTab == "BAITS" then
		renderBaitsTab(contentContainer)
	elseif currentTab == "BAG" then
		renderBagTab(contentContainer)
	end
end

-- ============ SHOW SHOP MODAL ============
function ShopUI.Show(targetGui, catalogData)
	if not targetGui then return end

	if activeOverlay then
		activeOverlay:Destroy()
		activeOverlay = nil
		activeModal = nil
		isClosing = false
	end

	if catalogData then
		cachedCatalog = catalogData
		cachedCoins = catalogData.coins or cachedCoins
	end

	-- 1. Fullscreen Dark Backdrop
	local overlay = Instance.new("Frame")
	overlay.Name = "ShopOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(2, 6, 12)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 40
	overlay.Parent = targetGui
	activeOverlay = overlay

	-- 2. Main Card Container
	local card = Instance.new("Frame")
	card.Name = "ShopCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.new(0, 800, 0, 580)
	card.Position = UDim2.new(0.5, 0, 0.54, 0)
	card.BackgroundColor3 = Color3.fromRGB(13, 21, 32)
	card.BorderSizePixel = 0
	card.ZIndex = 41
	card.Parent = overlay
	activeModal = card
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(26, 40, 60)
	cardStroke.Thickness = 1.8
	cardStroke.Parent = card

	-- Header Bar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.ZIndex = 42
	header.Parent = card

	local shopIcon = Instance.new("TextLabel")
	shopIcon.Size = UDim2.new(0, 36, 0, 36)
	shopIcon.Position = UDim2.new(0, 24, 0, 10)
	shopIcon.BackgroundTransparency = 1
	shopIcon.Text = "🛒"
	shopIcon.Font = Enum.Font.GothamBlack
	shopIcon.TextSize = 28
	shopIcon.ZIndex = 43
	shopIcon.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.5, 0, 0, 24)
	titleLabel.Position = UDim2.new(0, 66, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.RichText = true
	titleLabel.Text = "<font color=\"#FFFFFF\"><b>TOKO</b></font> <font color=\"#38BDF8\"><b>SAMUDRA</b></font>"
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 43
	titleLabel.Parent = header

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(0.5, 0, 0, 16)
	subtitleLabel.Position = UDim2.new(0, 66, 0, 34)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Peralatan joran, umpan bernada, dan ekspansi tas nelayan."
	subtitleLabel.TextColor3 = Color3.fromRGB(143, 160, 181)
	subtitleLabel.Font = Enum.Font.GothamMedium
	subtitleLabel.TextSize = 12
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.ZIndex = 43
	subtitleLabel.Parent = header

	-- Wallet Badge in Header
	local coinBox = Instance.new("Frame")
	coinBox.Size = UDim2.new(0, 150, 0, 34)
	coinBox.Position = UDim2.new(1, -214, 0, 12)
	coinBox.BackgroundColor3 = Color3.fromRGB(19, 29, 46)
	coinBox.BorderSizePixel = 0
	coinBox.ZIndex = 43
	coinBox.Parent = header
	Instance.new("UICorner", coinBox).CornerRadius = UDim.new(0, 8)

	local cbStroke = Instance.new("UIStroke")
	cbStroke.Color = Color3.fromRGB(234, 179, 8)
	cbStroke.Thickness = 1.2
	cbStroke.Transparency = 0.5
	cbStroke.Parent = coinBox

	coinHeaderLabel = Instance.new("TextLabel")
	coinHeaderLabel.Size = UDim2.new(1, -12, 1, 0)
	coinHeaderLabel.Position = UDim2.new(0, 6, 0, 0)
	coinHeaderLabel.BackgroundTransparency = 1
	coinHeaderLabel.RichText = true
	coinHeaderLabel.Text = string.format("💰 <b>%d</b> Koin", cachedCoins)
	coinHeaderLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
	coinHeaderLabel.Font = Enum.Font.GothamBold
	coinHeaderLabel.TextSize = 12
	coinHeaderLabel.ZIndex = 44
	coinHeaderLabel.Parent = coinBox

	-- Close Button Top-Right
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -54, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(19, 29, 46)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "🗙"
	closeBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.ZIndex = 43
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
		ShopUI.Hide()
	end)

	-- Tabs Bar (Row 1)
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "Tabs"
	tabContainer.Size = UDim2.new(1, -48, 0, 38)
	tabContainer.Position = UDim2.new(0, 24, 0, 64)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 42
	tabContainer.Parent = card

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 10)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabContainer

	local TABS = {
		{ id = "RODS", label = "🎣 Joran Pancing" },
		{ id = "BAITS", label = "🪱 Umpan & Pakan" },
		{ id = "BAG", label = "🎒 Perluasan Tas" },
	}

	tabButtons = {}
	for idx, t in ipairs(TABS) do
		local tBtn = Instance.new("TextButton")
		tBtn.Name = "Tab_" .. t.id
		tBtn.Size = UDim2.new(0, 160, 1, 0)
		tBtn.LayoutOrder = idx
		tBtn.BackgroundColor3 = Color3.fromRGB(19, 29, 46)
		tBtn.BorderSizePixel = 0
		tBtn.Text = t.label
		tBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
		tBtn.Font = Enum.Font.GothamBold
		tBtn.TextSize = 12
		tBtn.ZIndex = 43
		tBtn.Parent = tabContainer
		Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 8)

		local tStroke = Instance.new("UIStroke")
		tStroke.Color = Color3.fromRGB(30, 45, 68)
		tStroke.Thickness = 1
		tStroke.Parent = tBtn

		tabButtons[t.id] = tBtn

		tBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			currentTab = t.id
			ShopUI.RenderContent()
		end)
	end

	-- Content Container Frame
	contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -48, 1, -124)
	contentContainer.Position = UDim2.new(0, 24, 0, 112)
	contentContainer.BackgroundTransparency = 1
	contentContainer.ZIndex = 42
	contentContainer.Parent = card

	ShopUI.RenderContent()

	-- Request fresh catalog data from server
	RemoteContract.Client.GetShopCatalog()

	-- Entrance Animation
	local overlayIn = TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.35,
	})
	local cardIn = TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 800, 0, 580),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0,
	})

	overlayIn:Play()
	cardIn:Play()

	return overlay
end

return ShopUI
