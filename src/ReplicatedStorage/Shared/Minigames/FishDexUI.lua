--[[
	FishDexUI (ModuleScript)
	FISH!TUNE — Oceanic FishDex & Discovery Encyclopedia (FISH-023)

	Sistem Sentral Katalog & Ensiklopedia Ikan (FishDex) Berbasis Glassmorphism:
	1. Visualisasi Progress Koleksi Lengkap (Persentase penemuan, counter per tier).
	2. Filter Tab Rarity (ALL, COMMON, RARE, SUPER RARE, LEGENDARY, MYTHIC, SPECIAL).
	3. Filter Zona Habitat (SEMUA, MELODY BAY, TWIN EYE LAGOON, SUMMIT ABYSS).
	4. Kartu Spesies Interaktif (Unlocked vs Undiscovered Mystery Silhouette).
	5. Panel Detail Lengkap (Lore, Rekor Berat Terbesar, Catatan Tangkapan, Mutasi, Habitat).
	6. Sinkronisasi Data Real-Time dengan PlayerData & Journal.
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishDefinitions = require(Shared:WaitForChild("Config"):WaitForChild("FishDefinitions"))
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local ZoneConfig = require(Shared:WaitForChild("Config"):WaitForChild("ZoneConfig"))

local player = Players.LocalPlayer

local FishDexUI = {}
local activeModal = nil
local activeOverlay = nil
local activeDetailModal = nil
local isClosing = false

local currentRarityFilter = "ALL"
local currentZoneFilter = "ALL"
local cachedJournal = {}
local rarityTabWidgets = {}
local zoneTabWidgets = {}

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

-- ============ CONFIGURATION ============
local RARITY_TABS = {
	{ id = "ALL", label = "✨ SEMUA" },
	{ id = "COMMON", label = "⭐ COMMON", color = Color3.fromRGB(150, 155, 165) },
	{ id = "RARE", label = "⭐⭐ RARE", color = Color3.fromRGB(0, 140, 255) },
	{ id = "SUPER_RARE", label = "⭐⭐⭐ SUPER RARE", color = Color3.fromRGB(170, 50, 240) },
	{ id = "LEGENDARY", label = "⭐⭐⭐⭐ LEGENDARY", color = Color3.fromRGB(240, 185, 20) },
	{ id = "MYTHIC", label = "⭐⭐⭐⭐⭐ MYTHIC", color = Color3.fromRGB(235, 45, 45) },
	{ id = "SPECIAL", label = "⭐⭐⭐⭐⭐⭐ SPECIAL", color = Color3.fromRGB(255, 60, 200) },
}

local ZONE_FILTERS = {
	{ id = "ALL", label = "🌊 SEMUA HABITAT" },
	{ id = "MELODY_BAY", label = "🏖️ Melody Bay" },
	{ id = "TWIN_EYE_LAGOON", label = "🏝️ Twin Eye Lagoon" },
	{ id = "SUMMIT_ABYSS", label = "⚡ Summit Abyss" },
}

-- ============ JOURNAL & PROGRESS HELPERS ============
function FishDexUI.UpdateJournalData(journal)
	cachedJournal = journal or {}
	if FishDexUI.IsOpen() then
		FishDexUI.RenderGrid()
	end
end

local function getJournalEntry(fishId, fishName)
	if not cachedJournal then return nil end
	return cachedJournal[fishId] or cachedJournal[fishName]
end

local function calculateDiscoveryStats()
	local totalSpecies = #FishDefinitions.CATALOG
	local discoveredCount = 0
	local tierStats = {}

	for _, tab in ipairs(RARITY_TABS) do
		if tab.id ~= "ALL" then
			tierStats[tab.id] = { total = 0, discovered = 0 }
		end
	end

	for _, fish in ipairs(FishDefinitions.CATALOG) do
		local r = fish.rarity
		if tierStats[r] then
			tierStats[r].total += 1
		end

		local entry = getJournalEntry(fish.id, fish.name)
		if entry and (entry.count or 0) > 0 then
			discoveredCount += 1
			if tierStats[r] then
				tierStats[r].discovered += 1
			end
		end
	end

	local percentage = (totalSpecies > 0) and math.floor((discoveredCount / totalSpecies) * 1000) / 10 or 0
	return {
		total = totalSpecies,
		discovered = discoveredCount,
		percentage = percentage,
		tierStats = tierStats,
	}
end

-- ============ CLOSE / HIDE ============
function FishDexUI.HideDetail()
	if activeDetailModal and activeDetailModal.Parent then
		activeDetailModal:Destroy()
		activeDetailModal = nil
	end
end

function FishDexUI.Hide(callback)
	if isClosing or not activeModal or not activeOverlay then
		if callback then callback() end
		return
	end

	isClosing = true
	FishDexUI.HideDetail()

	local card = activeModal
	local overlay = activeOverlay

	local closeTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 580, 0, 480),
		Position = UDim2.new(0.5, 0, 0.55, 0),
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

function FishDexUI.IsOpen()
	return activeOverlay ~= nil and activeOverlay.Parent ~= nil
end

-- ============ DETAIL POPUP MODAL ============
local function showFishDetailModal(parentContainer, fish)
	FishDexUI.HideDetail()

	local entry = getJournalEntry(fish.id, fish.name)
	local isDiscovered = (entry ~= nil and (entry.count or 0) > 0)
	local r = fish.rarity or "COMMON"
	local tierData = FishingRaritySystem.GetTierData(r)
	local rColor = tierData.color or Color3.fromRGB(0, 200, 255)

	local zoneData = ZoneConfig.GetZoneById(fish.favoriteZone)
	local zoneName = zoneData and zoneData.name or fish.favoriteZone or "Samudra Terbuka"

	-- Detail Backdrop
	local detailOverlay = Instance.new("Frame")
	detailOverlay.Name = "DetailOverlay"
	detailOverlay.Size = UDim2.new(1, 0, 1, 0)
	detailOverlay.Position = UDim2.new(0, 0, 0, 0)
	detailOverlay.BackgroundColor3 = Color3.fromRGB(4, 7, 14)
	detailOverlay.BackgroundTransparency = 0.4
	detailOverlay.BorderSizePixel = 0
	detailOverlay.ZIndex = 60
	detailOverlay.Parent = parentContainer
	activeDetailModal = detailOverlay

	local modal = Instance.new("Frame")
	modal.Name = "DetailCard"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Size = UDim2.new(0, 460, 0, 420)
	modal.Position = UDim2.new(0.5, 0, 0.5, 0)
	modal.BackgroundColor3 = Color3.fromRGB(14, 19, 32)
	modal.BackgroundTransparency = 0.1
	modal.BorderSizePixel = 0
	modal.ZIndex = 61
	modal.Parent = detailOverlay
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 16)

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = isDiscovered and rColor or Color3.fromRGB(80, 95, 120)
	mStroke.Thickness = 2
	mStroke.Transparency = 0.2
	mStroke.Parent = modal

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 48)
	header.BackgroundTransparency = 1
	header.ZIndex = 62
	header.Parent = modal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -38, 0, 9)
	closeBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextSize = 14
	closeBtn.ZIndex = 63
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
		FishDexUI.HideDetail()
	end)

	-- Icon & Rarity Badge
	local iconCircle = Instance.new("Frame")
	iconCircle.Size = UDim2.new(0, 72, 0, 72)
	iconCircle.Position = UDim2.new(0, 20, 0, 16)
	iconCircle.BackgroundColor3 = Color3.fromRGB(22, 30, 48)
	iconCircle.BorderSizePixel = 0
	iconCircle.ZIndex = 62
	iconCircle.Parent = modal
	Instance.new("UICorner", iconCircle).CornerRadius = UDim.new(0, 14)

	local iStroke = Instance.new("UIStroke")
	iStroke.Color = isDiscovered and rColor or Color3.fromRGB(70, 85, 110)
	iStroke.Thickness = 1.8
	iStroke.Parent = iconCircle

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = isDiscovered and "🐟" or "❓"
	iconLabel.Font = Enum.Font.GothamBlack
	iconLabel.TextSize = 36
	iconLabel.ZIndex = 63
	iconLabel.Parent = iconCircle

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -150, 0, 24)
	titleLabel.Position = UDim2.new(0, 102, 0, 20)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = isDiscovered and fish.name or "??? [Belum Ditemukan]"
	titleLabel.TextColor3 = isDiscovered and rColor or Color3.fromRGB(160, 180, 205)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 62
	titleLabel.Parent = modal

	local tierSubLabel = Instance.new("TextLabel")
	tierSubLabel.Size = UDim2.new(1, -150, 0, 18)
	tierSubLabel.Position = UDim2.new(0, 102, 0, 46)
	tierSubLabel.BackgroundTransparency = 1
	tierSubLabel.Text = string.format("[%s] %s", tierData.displayName, tierData.stars)
	tierSubLabel.TextColor3 = rColor
	tierSubLabel.Font = Enum.Font.GothamBold
	tierSubLabel.TextSize = 12
	tierSubLabel.TextXAlignment = Enum.TextXAlignment.Left
	tierSubLabel.ZIndex = 62
	tierSubLabel.Parent = modal

	-- Lore Description
	local descFrame = Instance.new("Frame")
	descFrame.Size = UDim2.new(1, -40, 0, 60)
	descFrame.Position = UDim2.new(0, 20, 0, 96)
	descFrame.BackgroundColor3 = Color3.fromRGB(20, 26, 42)
	descFrame.BackgroundTransparency = 0.5
	descFrame.BorderSizePixel = 0
	descFrame.ZIndex = 62
	descFrame.Parent = modal
	Instance.new("UICorner", descFrame).CornerRadius = UDim.new(0, 10)

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -16, 1, -10)
	descLabel.Position = UDim2.new(0, 8, 0, 5)
	descLabel.BackgroundTransparency = 1
	if isDiscovered then
		descLabel.Text = fish.description or "Spesies ikan samudra FishTune yang menakjubkan."
	else
		descLabel.Text = string.format("Spesies misterius yang sering berenang di perairan %s. Lemparkan kailmu dan temukan spesies ini!", zoneName)
	end
	descLabel.TextColor3 = Color3.fromRGB(180, 205, 230)
	descLabel.Font = Enum.Font.GothamMedium
	descLabel.TextSize = 11
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.ZIndex = 63
	descLabel.Parent = descFrame

	-- Stats Grid (2 Columns x 2 Rows)
	local statsGrid = Instance.new("Frame")
	statsGrid.Size = UDim2.new(1, -40, 0, 150)
	statsGrid.Position = UDim2.new(0, 20, 0, 164)
	statsGrid.BackgroundTransparency = 1
	statsGrid.ZIndex = 62
	statsGrid.Parent = modal

	local sLayout = Instance.new("UIGridLayout")
	sLayout.CellSize = UDim2.new(0.485, 0, 0, 68)
	sLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
	sLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sLayout.Parent = statsGrid

	local function addDetailCard(title, mainVal, subVal, valColor, order)
		local c = Instance.new("Frame")
		c.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
		c.BackgroundTransparency = 0.3
		c.BorderSizePixel = 0
		c.LayoutOrder = order
		c.ZIndex = 63
		c.Parent = statsGrid
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 8)

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Color3.fromRGB(40, 55, 80)
		cStroke.Thickness = 1
		cStroke.Parent = c

		local tLbl = Instance.new("TextLabel")
		tLbl.Size = UDim2.new(1, -12, 0, 16)
		tLbl.Position = UDim2.new(0, 8, 0, 6)
		tLbl.BackgroundTransparency = 1
		tLbl.Text = title
		tLbl.TextColor3 = Color3.fromRGB(140, 165, 195)
		tLbl.Font = Enum.Font.GothamMedium
		tLbl.TextSize = 10
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.ZIndex = 64
		tLbl.Parent = c

		local vLbl = Instance.new("TextLabel")
		vLbl.Size = UDim2.new(1, -12, 0, 22)
		vLbl.Position = UDim2.new(0, 8, 0, 22)
		vLbl.BackgroundTransparency = 1
		vLbl.Text = mainVal
		vLbl.TextColor3 = valColor or Color3.fromRGB(255, 255, 255)
		vLbl.Font = Enum.Font.GothamBlack
		vLbl.TextSize = 14
		vLbl.TextXAlignment = Enum.TextXAlignment.Left
		vLbl.ZIndex = 64
		vLbl.Parent = c

		local sLbl = Instance.new("TextLabel")
		sLbl.Size = UDim2.new(1, -12, 0, 16)
		sLbl.Position = UDim2.new(0, 8, 0, 44)
		sLbl.BackgroundTransparency = 1
		sLbl.Text = subVal
		sLbl.TextColor3 = Color3.fromRGB(160, 185, 210)
		sLbl.Font = Enum.Font.GothamMedium
		sLbl.TextSize = 9
		sLbl.TextXAlignment = Enum.TextXAlignment.Left
		sLbl.ZIndex = 64
		sLbl.Parent = c
	end

	-- 1. Rekor Tangkapan
	local catchCount = isDiscovered and (entry.count or 1) or 0
	local firstTimeStr = "Belum Ditemukan"
	if isDiscovered and entry.firstCaught and entry.firstCaught > 0 then
		firstTimeStr = "Tercatat di Jurnal"
	end
	addDetailCard("🎣 TOTAL DITANGKAP", string.format("%d Ekor", catchCount), firstTimeStr, Color3.fromRGB(0, 220, 255), 1)

	-- 2. Rekor Bobot Terbesar
	local maxWeight = isDiscovered and (entry.maxWeight or fish.minWeight) or 0
	local weightRangeStr = string.format("Rentang: %.1f - %.1f Kg", fish.minWeight or 0.5, fish.maxWeight or 2.0)
	addDetailCard("⚖️ REKOR BOBOT", isDiscovered and string.format("%.1f Kg", maxWeight) or "??? Kg", weightRangeStr, Color3.fromRGB(255, 220, 80), 2)

	-- 3. Nilai & EXP
	local coinVal = isDiscovered and string.format("💰 %d Koin", fish.baseCoins or 15) or "??? Koin"
	local expVal = isDiscovered and string.format("⭐ %d EXP", fish.baseExp or 10) or "??? EXP"
	addDetailCard("💎 NILAI DASAR", coinVal, expVal, Color3.fromRGB(80, 240, 140), 3)

	-- 4. Habitat Zona
	addDetailCard("🗺️ HABITAT UTAMA", zoneName, string.format("Skala Ukuran Model: %.2f", fish.scale or 1.0), Color3.fromRGB(240, 180, 255), 4)

	-- Bottom Close Button
	local dismissBtn = Instance.new("TextButton")
	dismissBtn.Size = UDim2.new(1, -40, 0, 38)
	dismissBtn.Position = UDim2.new(0, 20, 1, -48)
	dismissBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
	dismissBtn.BorderSizePixel = 0
	dismissBtn.Text = "TUTUP DETAIL"
	dismissBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	dismissBtn.Font = Enum.Font.GothamBlack
	dismissBtn.TextSize = 13
	dismissBtn.ZIndex = 64
	dismissBtn.Parent = modal
	Instance.new("UICorner", dismissBtn).CornerRadius = UDim.new(0, 10)

	dismissBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
		FishDexUI.HideDetail()
	end)

	-- Modal Pop-in Tween
	modal.Size = UDim2.new(0, 420, 0, 380)
	TweenService:Create(modal, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 460, 0, 420)
	}):Play()
end

-- ============ RENDER GRID ============
local gridContainer = nil
local progressSummaryLabel = nil
local progressFillBar = nil

function FishDexUI.RenderGrid()
	if not gridContainer then return end

	for _, child in ipairs(gridContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Update Progress Header
	local stats = calculateDiscoveryStats()
	if progressSummaryLabel then
		progressSummaryLabel.Text = string.format("📖 Koleksi Samudra: %d / %d Spesies (%s%%)", stats.discovered, stats.total, tostring(stats.percentage))
	end
	if progressFillBar then
		local frac = math.clamp(stats.discovered / math.max(1, stats.total), 0, 1)
		TweenService:Create(progressFillBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(frac, 0, 1, 0)
		}):Play()
	end

	-- Filter Species
	local displayList = {}
	for _, fish in ipairs(FishDefinitions.CATALOG) do
		local matchRarity = (currentRarityFilter == "ALL" or fish.rarity == currentRarityFilter)
		local matchZone = (currentZoneFilter == "ALL" or fish.favoriteZone == currentZoneFilter)
		if matchRarity and matchZone then
			table.insert(displayList, fish)
		end
	end

	if #displayList == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 120)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "🔍 Tidak ada spesies yang cocok dengan filter yang dipilih."
		emptyLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
		emptyLabel.Font = Enum.Font.GothamMedium
		emptyLabel.TextSize = 14
		emptyLabel.ZIndex = 50
		emptyLabel.Parent = gridContainer
		return
	end

	for idx, fish in ipairs(displayList) do
		local entry = getJournalEntry(fish.id, fish.name)
		local isDiscovered = (entry ~= nil and (entry.count or 0) > 0)
		local r = fish.rarity or "COMMON"
		local tierData = FishingRaritySystem.GetTierData(r)
		local rColor = tierData.color or Color3.fromRGB(0, 200, 255)

		local card = Instance.new("Frame")
		card.Name = "FishCard_" .. fish.id
		card.Size = UDim2.new(0, 160, 0, 140)
		card.BackgroundColor3 = isDiscovered and Color3.fromRGB(18, 25, 40) or Color3.fromRGB(14, 18, 28)
		card.BackgroundTransparency = isDiscovered and 0.25 or 0.5
		card.BorderSizePixel = 0
		card.LayoutOrder = idx
		card.ZIndex = 50
		card.Parent = gridContainer
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = isDiscovered and rColor or Color3.fromRGB(50, 65, 85)
		cardStroke.Thickness = isDiscovered and 1.5 or 1
		cardStroke.Transparency = isDiscovered and 0.25 or 0.6
		cardStroke.Parent = card

		-- Icon Box
		local iconFrame = Instance.new("Frame")
		iconFrame.Size = UDim2.new(0, 44, 0, 44)
		iconFrame.Position = UDim2.new(0.5, -22, 0, 10)
		iconFrame.BackgroundColor3 = Color3.fromRGB(24, 32, 48)
		iconFrame.BorderSizePixel = 0
		iconFrame.ZIndex = 51
		iconFrame.Parent = card
		Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 10)

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(1, 0, 1, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text = isDiscovered and "🐟" or "❓"
		iconLbl.Font = Enum.Font.GothamBlack
		iconLbl.TextSize = 24
		iconLbl.ZIndex = 52
		iconLbl.Parent = iconFrame

		-- Species Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -12, 0, 20)
		nameLbl.Position = UDim2.new(0, 6, 0, 58)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = isDiscovered and fish.name or "??? [Misterius]"
		nameLbl.TextColor3 = isDiscovered and rColor or Color3.fromRGB(140, 160, 185)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 12
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.ZIndex = 51
		nameLbl.Parent = card

		-- Rarity Tier Tag
		local tierLbl = Instance.new("TextLabel")
		tierLbl.Size = UDim2.new(1, -12, 0, 16)
		tierLbl.Position = UDim2.new(0, 6, 0, 78)
		tierLbl.BackgroundTransparency = 1
		tierLbl.Text = string.format("[%s] %s", tierData.displayName, tierData.stars)
		tierLbl.TextColor3 = rColor
		tierLbl.Font = Enum.Font.GothamMedium
		tierLbl.TextSize = 10
		tierLbl.ZIndex = 51
		tierLbl.Parent = card

		-- Bottom Info
		local infoLbl = Instance.new("TextLabel")
		infoLbl.Size = UDim2.new(1, -12, 0, 18)
		infoLbl.Position = UDim2.new(0, 6, 0, 96)
		infoLbl.BackgroundTransparency = 1
		if isDiscovered then
			infoLbl.Text = string.format("🎣 %dx  |  ⚖️ %.1f Kg", entry.count or 1, entry.maxWeight or fish.minWeight)
			infoLbl.TextColor3 = Color3.fromRGB(220, 235, 255)
		else
			local zShort = (fish.favoriteZone == "TWIN_EYE_LAGOON" and "Twin Eye") or (fish.favoriteZone == "SUMMIT_ABYSS" and "Summit") or "Melody Bay"
			infoLbl.Text = string.format("📍 %s", zShort)
			infoLbl.TextColor3 = Color3.fromRGB(130, 150, 175)
		end
		infoLbl.Font = Enum.Font.GothamMedium
		infoLbl.TextSize = 10
		infoLbl.ZIndex = 51
		infoLbl.Parent = card

		-- Click / Touch Button to View Detail
		local clickBtn = Instance.new("TextButton")
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.ZIndex = 53
		clickBtn.Parent = card

		clickBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
			showFishDetailModal(activeModal, fish)
		end)
	end
end

-- ============ UPDATE TAB BUTTON STYLES ============
local function updateFilterTabStyles()
	for catId, widget in pairs(rarityTabWidgets) do
		local isSel = (catId == currentRarityFilter)
		if isSel then
			widget.button.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
			widget.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			widget.stroke.Color = Color3.fromRGB(0, 230, 255)
			widget.stroke.Transparency = 0.1
		else
			widget.button.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
			widget.button.TextColor3 = Color3.fromRGB(150, 175, 205)
			widget.stroke.Color = Color3.fromRGB(50, 70, 100)
			widget.stroke.Transparency = 0.6
		end
	end

	for zoneId, widget in pairs(zoneTabWidgets) do
		local isSel = (zoneId == currentZoneFilter)
		if isSel then
			widget.button.BackgroundColor3 = Color3.fromRGB(30, 120, 180)
			widget.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			widget.stroke.Color = Color3.fromRGB(80, 200, 255)
			widget.stroke.Transparency = 0.2
		else
			widget.button.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
			widget.button.TextColor3 = Color3.fromRGB(140, 160, 190)
			widget.stroke.Color = Color3.fromRGB(45, 60, 85)
			widget.stroke.Transparency = 0.7
		end
	end
end

-- ============ SHOW FISHDEX MODAL ============
function FishDexUI.Show(targetGui, pData)
	if not targetGui then return end

	if activeOverlay then
		activeOverlay:Destroy()
		activeOverlay = nil
		activeModal = nil
		isClosing = false
	end

	pData = pData or {}
	cachedJournal = pData.journal or cachedJournal or {}

	-- 1. Fullscreen Backdrop
	local overlay = Instance.new("Frame")
	overlay.Name = "FishDexOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(5, 8, 15)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 40
	overlay.Parent = targetGui
	activeOverlay = overlay

	-- 2. Main FishDex Card
	local card = Instance.new("Frame")
	card.Name = "FishDexCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.new(0, 640, 0, 520)
	card.Position = UDim2.new(0.5, 0, 0.54, 0)
	card.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.ZIndex = 41
	card.Parent = overlay
	activeModal = card
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(0, 200, 255)
	cardStroke.Thickness = 2
	cardStroke.Transparency = 0.3
	cardStroke.Parent = card

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.ZIndex = 42
	header.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.7, 0, 0, 24)
	titleLabel.Position = UDim2.new(0, 20, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📖 FISHDEX SAMUDRA"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 42
	titleLabel.Parent = header

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(0.7, 0, 0, 16)
	subtitleLabel.Position = UDim2.new(0, 20, 0, 30)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Katalog seluruh spesies ikan, habitat, dan catatan rekor pribadi"
	subtitleLabel.TextColor3 = Color3.fromRGB(160, 200, 230)
	subtitleLabel.Font = Enum.Font.GothamMedium
	subtitleLabel.TextSize = 11
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.ZIndex = 42
	subtitleLabel.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -44, 0, 9)
	closeBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextSize = 16
	closeBtn.ZIndex = 43
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
		FishDexUI.Hide()
	end)

	-- Discovery Progress Bar
	local statsBar = Instance.new("Frame")
	statsBar.Name = "StatsBar"
	statsBar.Size = UDim2.new(1, -40, 0, 32)
	statsBar.Position = UDim2.new(0, 20, 0, 54)
	statsBar.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
	statsBar.BackgroundTransparency = 0.5
	statsBar.BorderSizePixel = 0
	statsBar.ZIndex = 42
	statsBar.Parent = card
	Instance.new("UICorner", statsBar).CornerRadius = UDim.new(0, 8)

	progressSummaryLabel = Instance.new("TextLabel")
	progressSummaryLabel.Size = UDim2.new(0.6, 0, 1, 0)
	progressSummaryLabel.Position = UDim2.new(0.02, 0, 0, 0)
	progressSummaryLabel.BackgroundTransparency = 1
	progressSummaryLabel.Text = "📖 Koleksi Samudra: 0 / 0 Spesies (0%)"
	progressSummaryLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	progressSummaryLabel.Font = Enum.Font.GothamBold
	progressSummaryLabel.TextSize = 12
	progressSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	progressSummaryLabel.ZIndex = 43
	progressSummaryLabel.Parent = statsBar

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.35, 0, 0, 10)
	barBg.Position = UDim2.new(0.62, 0, 0.5, -5)
	barBg.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
	barBg.BorderSizePixel = 0
	barBg.ZIndex = 43
	barBg.Parent = statsBar
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

	progressFillBar = Instance.new("Frame")
	progressFillBar.Size = UDim2.new(0, 0, 1, 0)
	progressFillBar.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	progressFillBar.BorderSizePixel = 0
	progressFillBar.ZIndex = 44
	progressFillBar.Parent = barBg
	Instance.new("UICorner", progressFillBar).CornerRadius = UDim.new(1, 0)

	-- Filter Row 1: Rarity Tabs
	local rarityContainer = Instance.new("Frame")
	rarityContainer.Name = "RarityTabs"
	rarityContainer.Size = UDim2.new(1, -40, 0, 28)
	rarityContainer.Position = UDim2.new(0, 20, 0, 92)
	rarityContainer.BackgroundTransparency = 1
	rarityContainer.ZIndex = 42
	rarityContainer.Parent = card

	local rLayout = Instance.new("UIListLayout")
	rLayout.FillDirection = Enum.FillDirection.Horizontal
	rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rLayout.Padding = UDim.new(0, 5)
	rLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rLayout.Parent = rarityContainer

	rarityTabWidgets = {}
	for idx, tab in ipairs(RARITY_TABS) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "RarityTab_" .. tab.id
		tabBtn.Size = UDim2.new(0, 80, 1, 0)
		tabBtn.LayoutOrder = idx
		tabBtn.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
		tabBtn.BorderSizePixel = 0
		tabBtn.Text = tab.label
		tabBtn.TextColor3 = Color3.fromRGB(150, 175, 205)
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.TextSize = 10
		tabBtn.ZIndex = 43
		tabBtn.Parent = rarityContainer
		Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

		local tStroke = Instance.new("UIStroke")
		tStroke.Color = Color3.fromRGB(50, 70, 100)
		tStroke.Thickness = 1
		tStroke.Transparency = 0.6
		tStroke.Parent = tabBtn

		rarityTabWidgets[tab.id] = { button = tabBtn, stroke = tStroke }

		tabBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			currentRarityFilter = tab.id
			updateFilterTabStyles()
			FishDexUI.RenderGrid()
		end)
	end

	-- Filter Row 2: Zone Filters
	local zoneContainer = Instance.new("Frame")
	zoneContainer.Name = "ZoneFilters"
	zoneContainer.Size = UDim2.new(1, -40, 0, 24)
	zoneContainer.Position = UDim2.new(0, 20, 0, 124)
	zoneContainer.BackgroundTransparency = 1
	zoneContainer.ZIndex = 42
	zoneContainer.Parent = card

	local zLayout = Instance.new("UIListLayout")
	zLayout.FillDirection = Enum.FillDirection.Horizontal
	zLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	zLayout.Padding = UDim.new(0, 6)
	zLayout.SortOrder = Enum.SortOrder.LayoutOrder
	zLayout.Parent = zoneContainer

	zoneTabWidgets = {}
	for idx, zone in ipairs(ZONE_FILTERS) do
		local zBtn = Instance.new("TextButton")
		zBtn.Name = "ZoneFilter_" .. zone.id
		zBtn.Size = UDim2.new(0, 140, 1, 0)
		zBtn.LayoutOrder = idx
		zBtn.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
		zBtn.BorderSizePixel = 0
		zBtn.Text = zone.label
		zBtn.TextColor3 = Color3.fromRGB(140, 160, 190)
		zBtn.Font = Enum.Font.GothamBold
		zBtn.TextSize = 10
		zBtn.ZIndex = 43
		zBtn.Parent = zoneContainer
		Instance.new("UICorner", zBtn).CornerRadius = UDim.new(0, 6)

		local zStroke = Instance.new("UIStroke")
		zStroke.Color = Color3.fromRGB(45, 60, 85)
		zStroke.Thickness = 1
		zStroke.Transparency = 0.7
		zStroke.Parent = zBtn

		zoneTabWidgets[zone.id] = { button = zBtn, stroke = zStroke }

		zBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			currentZoneFilter = zone.id
			updateFilterTabStyles()
			FishDexUI.RenderGrid()
		end)
	end

	-- Scrollable Species Grid
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "SpeciesGrid"
	scrollFrame.Size = UDim2.new(1, -40, 1, -164)
	scrollFrame.Position = UDim2.new(0, 20, 0, 154)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 5
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = 42
	scrollFrame.Parent = card
	gridContainer = scrollFrame

	local gLayout = Instance.new("UIGridLayout")
	gLayout.CellSize = UDim2.new(0, 138, 0, 126)
	gLayout.CellPadding = UDim2.new(0, 12, 0, 12)
	gLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gLayout.Parent = scrollFrame

	updateFilterTabStyles()
	FishDexUI.RenderGrid()

	-- Entrance Animation
	local overlayIn = TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.35,
	})
	local cardIn = TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 680, 0, 540),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0.1,
	})

	overlayIn:Play()
	cardIn:Play()

	return overlay
end

return FishDexUI
