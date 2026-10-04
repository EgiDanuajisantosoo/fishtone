--[[
	FishDexUI (ModuleScript)
	FISH!TUNE — Oceanic FishDex & Discovery Encyclopedia (FISH-023 / Premium Redesign)

	Sistem Sentral Katalog & Ensiklopedia Ikan (FishDex) Berbasis Glassmorphism:
	1. Progress Koleksi Real-Time dengan bar gradien bercahaya & counter pill per tier.
	2. Filter Tab Rarity Kapsul Modern dengan indikator counter (misal: LEGENDARY 2/4).
	3. Filter Zona Habitat & Mode Tampilan (Semua, Terkoleksi, Belum Ditemukan).
	4. Kotak Pencarian Instan (Live Name Search Box).
	5. Kartu Spesies dengan Efek Hover Micro-Animation & Glow Rarity.
	6. Modal Inspeksi Spesies Lengkap dengan Gauge Bar Rekor Bobot (Min - Rekor - Max).
	7. Sinkronisasi Data Real-Time dengan Jurnal Player & Audio Interaktif.
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

-- State Filters
local currentRarityFilter = "ALL"
local currentZoneFilter = "ALL"
local currentDiscoveryFilter = "ALL" -- "ALL", "DISCOVERED", "MISSING"
local searchKeyword = ""
local cachedJournal = {}

-- UI Component References
local gridContainer = nil
local progressSummaryLabel = nil
local progressFillBar = nil
local progressPercentBadge = nil
local rarityTabWidgets = {}
local zoneTabWidgets = {}
local modeTabWidgets = {}

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
	{ id = "ALL", label = "✨ SEMUA", color = Color3.fromRGB(0, 210, 255) },
	{ id = "COMMON", label = "⭐ COMMON", color = Color3.fromRGB(150, 160, 175) },
	{ id = "RARE", label = "⭐⭐ RARE", color = Color3.fromRGB(0, 160, 255) },
	{ id = "SUPER_RARE", label = "⭐⭐⭐ S.RARE", color = Color3.fromRGB(180, 70, 255) },
	{ id = "LEGENDARY", label = "⭐⭐⭐⭐ LEGEND", color = Color3.fromRGB(255, 195, 30) },
	{ id = "MYTHIC", label = "⭐⭐⭐⭐⭐ MYTHIC", color = Color3.fromRGB(255, 55, 55) },
	{ id = "SPECIAL", label = "⭐⭐⭐⭐⭐⭐ SPECIAL", color = Color3.fromRGB(255, 75, 210) },
}

local ZONE_FILTERS = {
	{ id = "ALL", label = "🌊 Semua Habitat" },
	{ id = "MELODY_BAY", label = "🏖️ Melody Bay" },
	{ id = "TWIN_EYE_LAGOON", label = "🏝️ Twin Eye Lagoon" },
	{ id = "SUMMIT_ABYSS", label = "⚡ Summit Abyss" },
}

local DISCOVERY_MODES = {
	{ id = "ALL", label = "📋 Semua" },
	{ id = "DISCOVERED", label = "✅ Terkoleksi" },
	{ id = "MISSING", label = "❓ Belum Ada" },
}

-- ============ JOURNAL & PROGRESS HELPERS ============
function FishDexUI.UpdateJournalData(journal)
	cachedJournal = journal or {}
	if FishDexUI.IsOpen() then
		FishDexUI.UpdateFilterTabCounters()
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
		Size = UDim2.new(0, 660, 0, 500),
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

-- ============ DETAIL POPUP MODAL (INSPECT SCREEN) ============
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
	detailOverlay.BackgroundColor3 = Color3.fromRGB(3, 6, 12)
	detailOverlay.BackgroundTransparency = 0.35
	detailOverlay.BorderSizePixel = 0
	detailOverlay.ZIndex = 60
	detailOverlay.Parent = parentContainer
	activeDetailModal = detailOverlay

	local modal = Instance.new("Frame")
	modal.Name = "DetailCard"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Size = UDim2.new(0, 520, 0, 480)
	modal.Position = UDim2.new(0.5, 0, 0.5, 0)
	modal.BackgroundColor3 = Color3.fromRGB(13, 18, 30)
	modal.BackgroundTransparency = 0.1
	modal.BorderSizePixel = 0
	modal.ZIndex = 61
	modal.Parent = detailOverlay
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 18)

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = isDiscovered and rColor or Color3.fromRGB(70, 85, 110)
	mStroke.Thickness = 2
	mStroke.Transparency = 0.2
	mStroke.Parent = modal

	local mGradient = Instance.new("UIGradient")
	mGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 28, 48)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24)),
	})
	mGradient.Rotation = 45
	mGradient.Parent = modal

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.ZIndex = 62
	header.Parent = modal

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(0.8, 0, 1, 0)
	headerTitle.Position = UDim2.new(0, 22, 0, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = isDiscovered and "🔍 INFORMASI SPESIES IKAN" or "🔒 SPESIES MISTERIUS"
	headerTitle.TextColor3 = isDiscovered and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 195, 215)
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextSize = 16
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.ZIndex = 63
	headerTitle.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -44, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextSize = 15
	closeBtn.ZIndex = 63
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
		FishDexUI.HideDetail()
	end)

	-- Top Showcase Row (Icon + Name + Rarity Banner)
	local showcaseRow = Instance.new("Frame")
	showcaseRow.Size = UDim2.new(1, -44, 0, 86)
	showcaseRow.Position = UDim2.new(0, 22, 0, 52)
	showcaseRow.BackgroundColor3 = Color3.fromRGB(18, 25, 42)
	showcaseRow.BackgroundTransparency = 0.4
	showcaseRow.BorderSizePixel = 0
	showcaseRow.ZIndex = 62
	showcaseRow.Parent = modal
	Instance.new("UICorner", showcaseRow).CornerRadius = UDim.new(0, 12)

	local sRowStroke = Instance.new("UIStroke")
	sRowStroke.Color = isDiscovered and rColor or Color3.fromRGB(50, 65, 85)
	sRowStroke.Thickness = 1.5
	sRowStroke.Transparency = 0.4
	sRowStroke.Parent = showcaseRow

	-- Icon Portal
	local iconCircle = Instance.new("Frame")
	iconCircle.Size = UDim2.new(0, 66, 0, 66)
	iconCircle.Position = UDim2.new(0, 10, 0.5, -33)
	iconCircle.BackgroundColor3 = Color3.fromRGB(24, 32, 52)
	iconCircle.BorderSizePixel = 0
	iconCircle.ZIndex = 63
	iconCircle.Parent = showcaseRow
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
	iconLabel.TextSize = 34
	iconLabel.ZIndex = 64
	iconLabel.Parent = iconCircle

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -95, 0, 24)
	titleLabel.Position = UDim2.new(0, 86, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = isDiscovered and fish.name or "??? [Spesies Misterius]"
	titleLabel.TextColor3 = isDiscovered and rColor or Color3.fromRGB(160, 180, 205)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 63
	titleLabel.Parent = showcaseRow

	local tierSubLabel = Instance.new("TextLabel")
	tierSubLabel.Size = UDim2.new(1, -95, 0, 20)
	tierSubLabel.Position = UDim2.new(0, 86, 0, 36)
	tierSubLabel.BackgroundTransparency = 1
	tierSubLabel.Text = string.format("TIER: %s  •  %s", tierData.displayName, tierData.stars)
	tierSubLabel.TextColor3 = rColor
	tierSubLabel.Font = Enum.Font.GothamBold
	tierSubLabel.TextSize = 12
	tierSubLabel.TextXAlignment = Enum.TextXAlignment.Left
	tierSubLabel.ZIndex = 63
	tierSubLabel.Parent = showcaseRow

	local statusPill = Instance.new("TextLabel")
	statusPill.Size = UDim2.new(0, 120, 0, 18)
	statusPill.Position = UDim2.new(0, 86, 0, 58)
	statusPill.BackgroundColor3 = isDiscovered and Color3.fromRGB(15, 60, 40) or Color3.fromRGB(45, 30, 20)
	statusPill.BorderSizePixel = 0
	statusPill.Text = isDiscovered and "✅ SUDAH DITEMUKAN" or "🔒 BELUM DITEMUKAN"
	statusPill.TextColor3 = isDiscovered and Color3.fromRGB(80, 240, 140) or Color3.fromRGB(255, 180, 80)
	statusPill.Font = Enum.Font.GothamBold
	statusPill.TextSize = 9
	statusPill.ZIndex = 63
	statusPill.Parent = showcaseRow
	Instance.new("UICorner", statusPill).CornerRadius = UDim.new(0, 4)

	-- Lore Description Frame
	local descFrame = Instance.new("Frame")
	descFrame.Size = UDim2.new(1, -44, 0, 58)
	descFrame.Position = UDim2.new(0, 22, 0, 146)
	descFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
	descFrame.BackgroundTransparency = 0.5
	descFrame.BorderSizePixel = 0
	descFrame.ZIndex = 62
	descFrame.Parent = modal
	Instance.new("UICorner", descFrame).CornerRadius = UDim.new(0, 10)

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -16, 1, -8)
	descLabel.Position = UDim2.new(0, 8, 0, 4)
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

	-- Weight Gauge / Spectrum Bar
	local gaugeFrame = Instance.new("Frame")
	gaugeFrame.Size = UDim2.new(1, -44, 0, 54)
	gaugeFrame.Position = UDim2.new(0, 22, 0, 212)
	gaugeFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
	gaugeFrame.BackgroundTransparency = 0.5
	gaugeFrame.BorderSizePixel = 0
	gaugeFrame.ZIndex = 62
	gaugeFrame.Parent = modal
	Instance.new("UICorner", gaugeFrame).CornerRadius = UDim.new(0, 10)

	local gaugeTitle = Instance.new("TextLabel")
	gaugeTitle.Size = UDim2.new(0.5, 0, 0, 16)
	gaugeTitle.Position = UDim2.new(0, 10, 0, 6)
	gaugeTitle.BackgroundTransparency = 1
	gaugeTitle.Text = "⚖️ SPEKTRUM BOBOT IKAN"
	gaugeTitle.TextColor3 = Color3.fromRGB(140, 165, 195)
	gaugeTitle.Font = Enum.Font.GothamBold
	gaugeTitle.TextSize = 10
	gaugeTitle.TextXAlignment = Enum.TextXAlignment.Left
	gaugeTitle.ZIndex = 63
	gaugeTitle.Parent = gaugeFrame

	local maxRecord = isDiscovered and (entry.maxWeight or fish.minWeight) or 0
	local gaugeRecord = Instance.new("TextLabel")
	gaugeRecord.Size = UDim2.new(0.48, 0, 0, 16)
	gaugeRecord.Position = UDim2.new(0.5, 0, 0, 6)
	gaugeRecord.BackgroundTransparency = 1
	gaugeRecord.Text = isDiscovered and string.format("👑 Rekor Kamu: %.1f Kg", maxRecord) or "🔒 Belum Ada Rekor"
	gaugeRecord.TextColor3 = isDiscovered and Color3.fromRGB(255, 215, 60) or Color3.fromRGB(140, 160, 185)
	gaugeRecord.Font = Enum.Font.GothamBold
	gaugeRecord.TextSize = 10
	gaugeRecord.TextXAlignment = Enum.TextXAlignment.Right
	gaugeRecord.ZIndex = 63
	gaugeRecord.Parent = gaugeFrame

	local trackBg = Instance.new("Frame")
	trackBg.Size = UDim2.new(1, -20, 0, 8)
	trackBg.Position = UDim2.new(0, 10, 0, 26)
	trackBg.BackgroundColor3 = Color3.fromRGB(25, 34, 52)
	trackBg.BorderSizePixel = 0
	trackBg.ZIndex = 63
	trackBg.Parent = gaugeFrame
	Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1, 0)

	local minW = fish.minWeight or 0.5
	local maxW = fish.maxWeight or 5.0
	local fillFrac = 0
	if isDiscovered and maxW > minW then
		fillFrac = math.clamp((maxRecord - minW) / (maxW - minW), 0.05, 1.0)
	end

	local trackFill = Instance.new("Frame")
	trackFill.Size = UDim2.new(fillFrac, 0, 1, 0)
	trackFill.BackgroundColor3 = isDiscovered and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(60, 75, 100)
	trackFill.BorderSizePixel = 0
	trackFill.ZIndex = 64
	trackFill.Parent = trackBg
	Instance.new("UICorner", trackFill).CornerRadius = UDim.new(1, 0)

	local trackLabels = Instance.new("TextLabel")
	trackLabels.Size = UDim2.new(1, -20, 0, 14)
	trackLabels.Position = UDim2.new(0, 10, 0, 36)
	trackLabels.BackgroundTransparency = 1
	trackLabels.Text = string.format("Min: %.1f Kg                                                   Max: %.1f Kg", minW, maxW)
	trackLabels.TextColor3 = Color3.fromRGB(130, 150, 175)
	trackLabels.Font = Enum.Font.GothamMedium
	trackLabels.TextSize = 9
	trackLabels.ZIndex = 63
	trackLabels.Parent = gaugeFrame

	-- Stats Grid (2 Columns x 2 Rows)
	local statsGrid = Instance.new("Frame")
	statsGrid.Size = UDim2.new(1, -44, 0, 136)
	statsGrid.Position = UDim2.new(0, 22, 0, 274)
	statsGrid.BackgroundTransparency = 1
	statsGrid.ZIndex = 62
	statsGrid.Parent = modal

	local sLayout = Instance.new("UIGridLayout")
	sLayout.CellSize = UDim2.new(0.485, 0, 0, 62)
	sLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
	sLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sLayout.Parent = statsGrid

	local function addDetailCard(title, mainVal, subVal, valColor, order)
		local c = Instance.new("Frame")
		c.BackgroundColor3 = Color3.fromRGB(18, 25, 40)
		c.BackgroundTransparency = 0.35
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
		tLbl.Size = UDim2.new(1, -12, 0, 14)
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
		vLbl.Size = UDim2.new(1, -12, 0, 20)
		vLbl.Position = UDim2.new(0, 8, 0, 20)
		vLbl.BackgroundTransparency = 1
		vLbl.Text = mainVal
		vLbl.TextColor3 = valColor or Color3.fromRGB(255, 255, 255)
		vLbl.Font = Enum.Font.GothamBlack
		vLbl.TextSize = 13
		vLbl.TextXAlignment = Enum.TextXAlignment.Left
		vLbl.ZIndex = 64
		vLbl.Parent = c

		local sLbl = Instance.new("TextLabel")
		sLbl.Size = UDim2.new(1, -12, 0, 14)
		sLbl.Position = UDim2.new(0, 8, 0, 42)
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
	addDetailCard("🎣 TOTAL DITANGKAP", string.format("%d Ekor", catchCount), isDiscovered and "Tercatat di Jurnal" or "Belum Ditemukan", Color3.fromRGB(0, 220, 255), 1)

	-- 2. Nilai Koin & EXP
	local coinVal = isDiscovered and string.format("💰 %d Koin", fish.baseCoins or 15) or "??? Koin"
	local expVal = isDiscovered and string.format("⭐ %d EXP", fish.baseExp or 10) or "??? EXP"
	addDetailCard("💎 NILAI DASAR", coinVal, expVal, Color3.fromRGB(255, 220, 80), 2)

	-- 3. Habitat Zona
	addDetailCard("🗺️ HABITAT UTAMA", zoneName, string.format("Skala Model 3D: %.2f", fish.scale or 1.0), Color3.fromRGB(80, 240, 140), 3)

	-- 4. Mutasi Khusus
	local mutCount = 0
	if isDiscovered and entry.mutations then
		for _ in pairs(entry.mutations) do mutCount += 1 end
	end
	local mutText = (mutCount > 0) and string.format("%d Varian Mutasi", mutCount) or "Belum Ada Mutasi"
	addDetailCard("🌠 VARIAN MUTASI", mutText, (mutCount > 0) and "Tercatat di Buku Koleksi" or "Dapatkan varian langka!", Color3.fromRGB(240, 180, 255), 4)

	-- Bottom Close Button
	local dismissBtn = Instance.new("TextButton")
	dismissBtn.Size = UDim2.new(1, -44, 0, 40)
	dismissBtn.Position = UDim2.new(0, 22, 1, -50)
	dismissBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
	dismissBtn.BorderSizePixel = 0
	dismissBtn.Text = "KEMBALI KE FISHDEX"
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
	modal.Size = UDim2.new(0, 480, 0, 440)
	TweenService:Create(modal, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 520, 0, 480)
	}):Play()
end

-- ============ UPDATE TAB BUTTON COUNTERS & STYLES ============
function FishDexUI.UpdateFilterTabCounters()
	local stats = calculateDiscoveryStats()

	for catId, widget in pairs(rarityTabWidgets) do
		local isSel = (catId == currentRarityFilter)
		local countStr = ""
		if catId == "ALL" then
			countStr = string.format(" (%d/%d)", stats.discovered, stats.total)
		elseif stats.tierStats[catId] then
			local t = stats.tierStats[catId]
			countStr = string.format(" (%d/%d)", t.discovered, t.total)
		end

		for _, tab in ipairs(RARITY_TABS) do
			if tab.id == catId then
				widget.button.Text = tab.label .. countStr
				break
			end
		end

		if isSel then
			widget.button.BackgroundColor3 = widget.baseColor or Color3.fromRGB(0, 150, 220)
			widget.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			widget.stroke.Color = Color3.fromRGB(255, 255, 255)
			widget.stroke.Transparency = 0.1
			widget.stroke.Thickness = 1.8
		else
			widget.button.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
			widget.button.TextColor3 = Color3.fromRGB(150, 175, 205)
			widget.stroke.Color = Color3.fromRGB(50, 70, 100)
			widget.stroke.Transparency = 0.6
			widget.stroke.Thickness = 1
		end
	end

	for zoneId, widget in pairs(zoneTabWidgets) do
		local isSel = (zoneId == currentZoneFilter)
		if isSel then
			widget.button.BackgroundColor3 = Color3.fromRGB(25, 130, 200)
			widget.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			widget.stroke.Color = Color3.fromRGB(0, 230, 255)
			widget.stroke.Transparency = 0.1
		else
			widget.button.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
			widget.button.TextColor3 = Color3.fromRGB(140, 160, 190)
			widget.stroke.Color = Color3.fromRGB(45, 60, 85)
			widget.stroke.Transparency = 0.7
		end
	end

	for modeId, widget in pairs(modeTabWidgets) do
		local isSel = (modeId == currentDiscoveryFilter)
		if isSel then
			widget.button.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
			widget.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			widget.stroke.Color = Color3.fromRGB(80, 255, 140)
			widget.stroke.Transparency = 0.1
		else
			widget.button.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
			widget.button.TextColor3 = Color3.fromRGB(140, 160, 190)
			widget.stroke.Color = Color3.fromRGB(45, 60, 85)
			widget.stroke.Transparency = 0.7
		end
	end
end

-- ============ RENDER GRID ============
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
		progressSummaryLabel.Text = string.format("📖 Koleksi Samudra: %d / %d Spesies Ditemukan", stats.discovered, stats.total)
	end
	if progressPercentBadge then
		progressPercentBadge.Text = string.format("%s%%", tostring(stats.percentage))
	end
	if progressFillBar then
		local frac = math.clamp(stats.discovered / math.max(1, stats.total), 0, 1)
		TweenService:Create(progressFillBar, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(frac, 0, 1, 0)
		}):Play()
	end

	-- Filter Species
	local displayList = {}
	local searchLower = searchKeyword:lower():gsub("^%s+", ""):gsub("%s+$", "")

	for _, fish in ipairs(FishDefinitions.CATALOG) do
		local entry = getJournalEntry(fish.id, fish.name)
		local isDiscovered = (entry ~= nil and (entry.count or 0) > 0)

		local matchRarity = (currentRarityFilter == "ALL" or fish.rarity == currentRarityFilter)
		local matchZone = (currentZoneFilter == "ALL" or fish.favoriteZone == currentZoneFilter)
		local matchDiscovery = (currentDiscoveryFilter == "ALL")
			or (currentDiscoveryFilter == "DISCOVERED" and isDiscovered)
			or (currentDiscoveryFilter == "MISSING" and not isDiscovered)

		local matchSearch = true
		if searchLower ~= "" then
			local n = fish.name:lower()
			local r = (fish.rarity or ""):lower()
			matchSearch = n:find(searchLower) ~= nil or r:find(searchLower) ~= nil
		end

		if matchRarity and matchZone and matchDiscovery and matchSearch then
			table.insert(displayList, fish)
		end
	end

	if #displayList == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 160)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "🔍 Tidak ada spesies yang cocok dengan filter yang dipilih.\nCoba ubah tab kelangkaan atau kata kunci pencarian."
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
		card.Size = UDim2.new(0, 150, 0, 142)
		card.BackgroundColor3 = isDiscovered and Color3.fromRGB(18, 25, 42) or Color3.fromRGB(13, 17, 26)
		card.BackgroundTransparency = isDiscovered and 0.25 or 0.55
		card.BorderSizePixel = 0
		card.LayoutOrder = idx
		card.ZIndex = 50
		card.Parent = gridContainer
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = isDiscovered and rColor or Color3.fromRGB(50, 65, 85)
		cardStroke.Thickness = isDiscovered and 1.6 or 1
		cardStroke.Transparency = isDiscovered and 0.2 or 0.65
		cardStroke.Parent = card

		-- Icon Portal
		local iconFrame = Instance.new("Frame")
		iconFrame.Size = UDim2.new(0, 48, 0, 48)
		iconFrame.Position = UDim2.new(0.5, -24, 0, 10)
		iconFrame.BackgroundColor3 = isDiscovered and Color3.fromRGB(24, 34, 54) or Color3.fromRGB(18, 22, 34)
		iconFrame.BorderSizePixel = 0
		iconFrame.ZIndex = 51
		iconFrame.Parent = card
		Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 12)

		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color = isDiscovered and rColor or Color3.fromRGB(50, 65, 90)
		iconStroke.Thickness = 1.2
		iconStroke.Transparency = isDiscovered and 0.3 or 0.6
		iconStroke.Parent = iconFrame

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.new(1, 0, 1, 0)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text = isDiscovered and "🐟" or "❓"
		iconLbl.Font = Enum.Font.GothamBlack
		iconLbl.TextSize = 26
		iconLbl.ZIndex = 52
		iconLbl.Parent = iconFrame

		-- Species Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -12, 0, 20)
		nameLbl.Position = UDim2.new(0, 6, 0, 62)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = isDiscovered and fish.name or "??? [Misterius]"
		nameLbl.TextColor3 = isDiscovered and rColor or Color3.fromRGB(140, 160, 185)
		nameLbl.Font = Enum.Font.GothamBlack
		nameLbl.TextSize = 11
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.ZIndex = 51
		nameLbl.Parent = card

		-- Rarity Tier Tag
		local tierLbl = Instance.new("TextLabel")
		tierLbl.Size = UDim2.new(1, -12, 0, 16)
		tierLbl.Position = UDim2.new(0, 6, 0, 82)
		tierLbl.BackgroundTransparency = 1
		tierLbl.Text = string.format("[%s] %s", tierData.displayName, tierData.stars)
		tierLbl.TextColor3 = rColor
		tierLbl.Font = Enum.Font.GothamBold
		tierLbl.TextSize = 9
		tierLbl.ZIndex = 51
		tierLbl.Parent = card

		-- Bottom Info Bar (Stats or Zone Hint)
		local infoBar = Instance.new("Frame")
		infoBar.Size = UDim2.new(1, -12, 0, 24)
		infoBar.Position = UDim2.new(0, 6, 0, 106)
		infoBar.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
		infoBar.BackgroundTransparency = 0.4
		infoBar.BorderSizePixel = 0
		infoBar.ZIndex = 51
		infoBar.Parent = card
		Instance.new("UICorner", infoBar).CornerRadius = UDim.new(0, 6)

		local infoLbl = Instance.new("TextLabel")
		infoLbl.Size = UDim2.new(1, -6, 1, 0)
		infoLbl.Position = UDim2.new(0, 3, 0, 0)
		infoLbl.BackgroundTransparency = 1
		if isDiscovered then
			infoLbl.Text = string.format("🎣 %dx  |  ⚖️ %.1f Kg", entry.count or 1, entry.maxWeight or fish.minWeight)
			infoLbl.TextColor3 = Color3.fromRGB(220, 240, 255)
		else
			local zShort = (fish.favoriteZone == "TWIN_EYE_LAGOON" and "Twin Eye") or (fish.favoriteZone == "SUMMIT_ABYSS" and "Summit") or "Melody Bay"
			infoLbl.Text = string.format("📍 %s", zShort)
			infoLbl.TextColor3 = Color3.fromRGB(130, 150, 175)
		end
		infoLbl.Font = Enum.Font.GothamBold
		infoLbl.TextSize = 9
		infoLbl.ZIndex = 52
		infoLbl.Parent = infoBar

		-- Click Button
		local clickBtn = Instance.new("TextButton")
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.ZIndex = 53
		clickBtn.Parent = card

		clickBtn.MouseEnter:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = isDiscovered and Color3.fromRGB(25, 36, 58) or Color3.fromRGB(18, 24, 38),
			}):Play()
		end)

		clickBtn.MouseLeave:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = isDiscovered and Color3.fromRGB(18, 25, 42) or Color3.fromRGB(13, 17, 26),
			}):Play()
		end)

		clickBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
			showFishDetailModal(activeModal, fish)
		end)
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
	overlay.BackgroundColor3 = Color3.fromRGB(4, 7, 14)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 40
	overlay.Parent = targetGui
	activeOverlay = overlay

	-- 2. Main FishDex Card Container
	local card = Instance.new("Frame")
	card.Name = "FishDexCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.new(0, 720, 0, 560)
	card.Position = UDim2.new(0.5, 0, 0.54, 0)
	card.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	card.BackgroundTransparency = 0.12
	card.BorderSizePixel = 0
	card.ZIndex = 41
	card.Parent = overlay
	activeModal = card
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(0, 200, 255)
	cardStroke.Thickness = 2.2
	cardStroke.Transparency = 0.25
	cardStroke.Parent = card

	local cardGradient = Instance.new("UIGradient")
	cardGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 26, 44)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 24)),
	})
	cardGradient.Rotation = 45
	cardGradient.Parent = card

	-- Header Bar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.ZIndex = 42
	header.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.7, 0, 0, 24)
	titleLabel.Position = UDim2.new(0, 22, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📖 FISHDEX SAMUDRA FISHTUNE"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 42
	titleLabel.Parent = header

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(0.7, 0, 0, 16)
	subtitleLabel.Position = UDim2.new(0, 22, 0, 30)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Katalog lengkap spesies ikan, habitat, rekor bobot, dan varian mutasi"
	subtitleLabel.TextColor3 = Color3.fromRGB(160, 200, 235)
	subtitleLabel.Font = Enum.Font.GothamMedium
	subtitleLabel.TextSize = 11
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.ZIndex = 42
	subtitleLabel.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -46, 0, 9)
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

	-- Discovery Progress Summary Bar
	local statsBar = Instance.new("Frame")
	statsBar.Name = "StatsBar"
	statsBar.Size = UDim2.new(1, -44, 0, 36)
	statsBar.Position = UDim2.new(0, 22, 0, 52)
	statsBar.BackgroundColor3 = Color3.fromRGB(18, 26, 42)
	statsBar.BackgroundTransparency = 0.4
	statsBar.BorderSizePixel = 0
	statsBar.ZIndex = 42
	statsBar.Parent = card
	Instance.new("UICorner", statsBar).CornerRadius = UDim.new(0, 10)

	local statsStroke = Instance.new("UIStroke")
	statsStroke.Color = Color3.fromRGB(0, 200, 255)
	statsStroke.Thickness = 1
	statsStroke.Transparency = 0.5
	statsStroke.Parent = statsBar

	progressSummaryLabel = Instance.new("TextLabel")
	progressSummaryLabel.Size = UDim2.new(0.5, 0, 1, 0)
	progressSummaryLabel.Position = UDim2.new(0, 14, 0, 0)
	progressSummaryLabel.BackgroundTransparency = 1
	progressSummaryLabel.Text = "📖 Koleksi Samudra: 0 / 0 Spesies Ditemukan"
	progressSummaryLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	progressSummaryLabel.Font = Enum.Font.GothamBold
	progressSummaryLabel.TextSize = 12
	progressSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	progressSummaryLabel.ZIndex = 43
	progressSummaryLabel.Parent = statsBar

	local barContainer = Instance.new("Frame")
	barContainer.Size = UDim2.new(0.35, 0, 0, 12)
	barContainer.Position = UDim2.new(0.53, 0, 0.5, -6)
	barContainer.BackgroundColor3 = Color3.fromRGB(14, 18, 30)
	barContainer.BorderSizePixel = 0
	barContainer.ZIndex = 43
	barContainer.Parent = statsBar
	Instance.new("UICorner", barContainer).CornerRadius = UDim.new(1, 0)

	progressFillBar = Instance.new("Frame")
	progressFillBar.Size = UDim2.new(0, 0, 1, 0)
	progressFillBar.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	progressFillBar.BorderSizePixel = 0
	progressFillBar.ZIndex = 44
	progressFillBar.Parent = barContainer
	Instance.new("UICorner", progressFillBar).CornerRadius = UDim.new(1, 0)

	progressPercentBadge = Instance.new("TextLabel")
	progressPercentBadge.Size = UDim2.new(0.1, 0, 1, 0)
	progressPercentBadge.Position = UDim2.new(0.89, 0, 0, 0)
	progressPercentBadge.BackgroundTransparency = 1
	progressPercentBadge.Text = "0%"
	progressPercentBadge.TextColor3 = Color3.fromRGB(255, 220, 80)
	progressPercentBadge.Font = Enum.Font.GothamBlack
	progressPercentBadge.TextSize = 12
	progressPercentBadge.ZIndex = 43
	progressPercentBadge.Parent = statsBar

	-- Filter Row 1: Rarity Tabs Bar
	local rarityContainer = Instance.new("Frame")
	rarityContainer.Name = "RarityTabs"
	rarityContainer.Size = UDim2.new(1, -44, 0, 30)
	rarityContainer.Position = UDim2.new(0, 22, 0, 94)
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
		tabBtn.Size = UDim2.new(0, 92, 1, 0)
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

		rarityTabWidgets[tab.id] = { button = tabBtn, stroke = tStroke, baseColor = tab.color }

		tabBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			currentRarityFilter = tab.id
			FishDexUI.UpdateFilterTabCounters()
			FishDexUI.RenderGrid()
		end)
	end

	-- Filter Row 2: Habitat Zone Filters & Discovery Mode
	local secondFilterRow = Instance.new("Frame")
	secondFilterRow.Name = "SecondFilterRow"
	secondFilterRow.Size = UDim2.new(1, -44, 0, 26)
	secondFilterRow.Position = UDim2.new(0, 22, 0, 130)
	secondFilterRow.BackgroundTransparency = 1
	secondFilterRow.ZIndex = 42
	secondFilterRow.Parent = card

	-- Zone Filters on Left
	local zoneContainer = Instance.new("Frame")
	zoneContainer.Size = UDim2.new(0.64, 0, 1, 0)
	zoneContainer.BackgroundTransparency = 1
	zoneContainer.ZIndex = 42
	zoneContainer.Parent = secondFilterRow

	local zLayout = Instance.new("UIListLayout")
	zLayout.FillDirection = Enum.FillDirection.Horizontal
	zLayout.Padding = UDim.new(0, 5)
	zLayout.SortOrder = Enum.SortOrder.LayoutOrder
	zLayout.Parent = zoneContainer

	zoneTabWidgets = {}
	for idx, zone in ipairs(ZONE_FILTERS) do
		local zBtn = Instance.new("TextButton")
		zBtn.Name = "ZoneFilter_" .. zone.id
		zBtn.Size = UDim2.new(0, 105, 1, 0)
		zBtn.LayoutOrder = idx
		zBtn.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
		zBtn.BorderSizePixel = 0
		zBtn.Text = zone.label
		zBtn.TextColor3 = Color3.fromRGB(140, 160, 190)
		zBtn.Font = Enum.Font.GothamBold
		zBtn.TextSize = 9
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
			FishDexUI.UpdateFilterTabCounters()
			FishDexUI.RenderGrid()
		end)
	end

	-- Mode Filters on Right (All vs Discovered vs Missing)
	local modeContainer = Instance.new("Frame")
	modeContainer.Size = UDim2.new(0.35, 0, 1, 0)
	modeContainer.Position = UDim2.new(0.65, 0, 0, 0)
	modeContainer.BackgroundTransparency = 1
	modeContainer.ZIndex = 42
	modeContainer.Parent = secondFilterRow

	local mLayout = Instance.new("UIListLayout")
	mLayout.FillDirection = Enum.FillDirection.Horizontal
	mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	mLayout.Padding = UDim.new(0, 5)
	mLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mLayout.Parent = modeContainer

	modeTabWidgets = {}
	for idx, mode in ipairs(DISCOVERY_MODES) do
		local mBtn = Instance.new("TextButton")
		mBtn.Name = "ModeFilter_" .. mode.id
		mBtn.Size = UDim2.new(0, 74, 1, 0)
		mBtn.LayoutOrder = idx
		mBtn.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
		mBtn.BorderSizePixel = 0
		mBtn.Text = mode.label
		mBtn.TextColor3 = Color3.fromRGB(140, 160, 190)
		mBtn.Font = Enum.Font.GothamBold
		mBtn.TextSize = 9
		mBtn.ZIndex = 43
		mBtn.Parent = modeContainer
		Instance.new("UICorner", mBtn).CornerRadius = UDim.new(0, 6)

		local mStroke = Instance.new("UIStroke")
		mStroke.Color = Color3.fromRGB(45, 60, 85)
		mStroke.Thickness = 1
		mStroke.Transparency = 0.7
		mStroke.Parent = mBtn

		modeTabWidgets[mode.id] = { button = mBtn, stroke = mStroke }

		mBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			currentDiscoveryFilter = mode.id
			FishDexUI.UpdateFilterTabCounters()
			FishDexUI.RenderGrid()
		end)
	end

	-- Scrollable Species Grid
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "SpeciesGrid"
	scrollFrame.Size = UDim2.new(1, -44, 1, -170)
	scrollFrame.Position = UDim2.new(0, 22, 0, 162)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = 42
	scrollFrame.Parent = card
	gridContainer = scrollFrame

	local gLayout = Instance.new("UIGridLayout")
	gLayout.CellSize = UDim2.new(0, 158, 0, 142)
	gLayout.CellPadding = UDim2.new(0, 14, 0, 14)
	gLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gLayout.Parent = scrollFrame

	FishDexUI.UpdateFilterTabCounters()
	FishDexUI.RenderGrid()

	-- Entrance Animation
	local overlayIn = TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.35,
	})
	local cardIn = TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 720, 0, 560),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0.12,
	})

	overlayIn:Play()
	cardIn:Play()

	return overlay
end

return FishDexUI
