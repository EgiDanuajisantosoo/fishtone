--[[
	FishDexUI (ModuleScript)
	FISH!TUNE — Oceanic FishDex & Discovery Encyclopedia (FISH-023 / Pixel-Perfect UI Redesign)

	Desain Eksak Sesuai Mockup Visual:
	1. Top Header: Icon Buku + "FISHDEX SAMUDRA" (Putih + Cyan Neon) + Subtitle Lore + Tombol Tutup Modern.
	2. Bar Progress Koleksi: "📖 Koleksi Samudra 0 / 35 Spesies (0%)" dengan Track Bar Kapsul.
	3. Bar Filter Rarity (Row 1): [⊞ Semua], [★ Common], [★★ Rare], [★★★ Super Rare], [★★★★ Legendary], [★★★★ Mythic], [◆ Special].
	4. Bar Filter Habitat & Search (Row 2): [🌐 Semua Habitat], [🌴 Melody Bay], [🌊 Twin Eye Lagoon], [⛰️ Summit Abyss] + Kotak Pencarian [🔍 Cari spesies...].
	5. 4-Column Species Grid:
	   - Kartu Misterius: Preview Box gelap dengan Tanda Tanya Merah Terang [ ? ], Nama "??? [Misterius]", Tag [RARITY] ★★★, dan Pin Lokasi [📍 Summit].
	   - Kartu Terbuka: Preview Ikan 3D/Icon dengan aura tier, nama spesies asli, bintang, rekor bobot & jumlah tangkapan.
	6. Detail Popout Modal: Lengkap dengan Spektrum Gauge Bobot & Lore Cerita.
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
local searchKeyword = ""
local cachedJournal = {}

-- UI Component References
local gridContainer = nil
local progressSummaryLabel = nil
local progressFillBar = nil
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
local RARITY_CONFIG = {
	{ id = "ALL", label = "Semua", icon = "⊞", stars = "" },
	{ id = "COMMON", label = "Common", icon = "★", stars = "★", color = Color3.fromRGB(150, 160, 175) },
	{ id = "RARE", label = "Rare", icon = "★★", stars = "★★", color = Color3.fromRGB(56, 189, 248) },
	{ id = "SUPER_RARE", label = "Super Rare", icon = "★★★", stars = "★★★", color = Color3.fromRGB(192, 132, 252) },
	{ id = "LEGENDARY", label = "Legendary", icon = "★★★★", stars = "★★★★", color = Color3.fromRGB(251, 191, 36) },
	{ id = "MYTHIC", label = "Mythic", icon = "★★★★", stars = "★★★★★", color = Color3.fromRGB(248, 113, 113) },
	{ id = "SPECIAL", label = "Special", icon = "◆", stars = "★★★★★★", color = Color3.fromRGB(232, 121, 249) },
}

local ZONE_CONFIG = {
	{ id = "ALL", label = "Semua Habitat", icon = "🌐" },
	{ id = "MELODY_BAY", label = "Melody Bay", icon = "🌴" },
	{ id = "TWIN_EYE_LAGOON", label = "Twin Eye Lagoon", icon = "🌊" },
	{ id = "SUMMIT_ABYSS", label = "Summit Abyss", icon = "⛰️" },
}

-- ============ JOURNAL & PROGRESS HELPERS ============
function FishDexUI.UpdateJournalData(journal)
	cachedJournal = journal or {}
	if FishDexUI.IsOpen() then
		FishDexUI.UpdateProgressHeader()
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

	for _, fish in ipairs(FishDefinitions.CATALOG) do
		local entry = getJournalEntry(fish.id, fish.name)
		if entry and (entry.count or 0) > 0 then
			discoveredCount += 1
		end
	end

	local percentage = (totalSpecies > 0) and math.floor((discoveredCount / totalSpecies) * 100) or 0
	return {
		total = totalSpecies,
		discovered = discoveredCount,
		percentage = percentage,
	}
end

function FishDexUI.UpdateProgressHeader()
	local stats = calculateDiscoveryStats()
	if progressSummaryLabel then
		progressSummaryLabel.Text = string.format("📖 Koleksi Samudra    <font color=\"#38BDF8\"><b>%d / %d Spesies (%d%%)</b></font>", stats.discovered, stats.total, stats.percentage)
	end
	if progressFillBar then
		local frac = math.clamp(stats.discovered / math.max(1, stats.total), 0, 1)
		TweenService:Create(progressFillBar, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(frac, 0, 1, 0)
		}):Play()
	end
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
		Size = UDim2.new(0, 700, 0, 520),
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
	modal.BackgroundColor3 = Color3.fromRGB(15, 23, 38)
	modal.BackgroundTransparency = 0.08
	modal.BorderSizePixel = 0
	modal.ZIndex = 61
	modal.Parent = detailOverlay
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 18)

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = isDiscovered and rColor or Color3.fromRGB(70, 85, 110)
	mStroke.Thickness = 1.8
	mStroke.Transparency = 0.25
	mStroke.Parent = modal

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundTransparency = 1
	header.ZIndex = 62
	header.Parent = modal

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(0.8, 0, 1, 0)
	headerTitle.Position = UDim2.new(0, 22, 0, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = isDiscovered and "🔍 DETAIL SPESIES IKAN" or "🔒 SPESIES MISTERIUS"
	headerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextSize = 15
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.ZIndex = 63
	headerTitle.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -44, 0, 9)
	closeBtn.BackgroundColor3 = Color3.fromRGB(25, 36, 54)
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

	-- Showcase Box
	local showcaseRow = Instance.new("Frame")
	showcaseRow.Size = UDim2.new(1, -44, 0, 86)
	showcaseRow.Position = UDim2.new(0, 22, 0, 52)
	showcaseRow.BackgroundColor3 = Color3.fromRGB(18, 27, 44)
	showcaseRow.BackgroundTransparency = 0.3
	showcaseRow.BorderSizePixel = 0
	showcaseRow.ZIndex = 62
	showcaseRow.Parent = modal
	Instance.new("UICorner", showcaseRow).CornerRadius = UDim.new(0, 12)

	local iconCircle = Instance.new("Frame")
	iconCircle.Size = UDim2.new(0, 66, 0, 66)
	iconCircle.Position = UDim2.new(0, 10, 0.5, -33)
	iconCircle.BackgroundColor3 = Color3.fromRGB(11, 17, 29)
	iconCircle.BorderSizePixel = 0
	iconCircle.ZIndex = 63
	iconCircle.Parent = showcaseRow
	Instance.new("UICorner", iconCircle).CornerRadius = UDim.new(0, 12)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = isDiscovered and "🐟" or "?"
	iconLabel.TextColor3 = isDiscovered and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(244, 63, 94)
	iconLabel.Font = Enum.Font.GothamBlack
	iconLabel.TextSize = isDiscovered and 32 or 36
	iconLabel.ZIndex = 64
	iconLabel.Parent = iconCircle

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -95, 0, 24)
	titleLabel.Position = UDim2.new(0, 86, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = isDiscovered and fish.name or "??? [Misterius]"
	titleLabel.TextColor3 = isDiscovered and rColor or Color3.fromRGB(226, 232, 240)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 15
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 63
	titleLabel.Parent = showcaseRow

	local tierSubLabel = Instance.new("TextLabel")
	tierSubLabel.Size = UDim2.new(1, -95, 0, 20)
	tierSubLabel.Position = UDim2.new(0, 86, 0, 36)
	tierSubLabel.BackgroundTransparency = 1
	tierSubLabel.Text = string.format("[%s]  %s", tierData.displayName, tierData.stars)
	tierSubLabel.TextColor3 = rColor
	tierSubLabel.Font = Enum.Font.GothamBold
	tierSubLabel.TextSize = 12
	tierSubLabel.TextXAlignment = Enum.TextXAlignment.Left
	tierSubLabel.ZIndex = 63
	tierSubLabel.Parent = showcaseRow

	local statusPill = Instance.new("TextLabel")
	statusPill.Size = UDim2.new(0, 125, 0, 18)
	statusPill.Position = UDim2.new(0, 86, 0, 58)
	statusPill.BackgroundColor3 = isDiscovered and Color3.fromRGB(15, 60, 40) or Color3.fromRGB(45, 25, 30)
	statusPill.BorderSizePixel = 0
	statusPill.Text = isDiscovered and "✅ SUDAH DITEMUKAN" or "🔒 BELUM DITEMUKAN"
	statusPill.TextColor3 = isDiscovered and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(248, 113, 113)
	statusPill.Font = Enum.Font.GothamBold
	statusPill.TextSize = 9
	statusPill.ZIndex = 63
	statusPill.Parent = showcaseRow
	Instance.new("UICorner", statusPill).CornerRadius = UDim.new(0, 4)

	-- Lore Description
	local descFrame = Instance.new("Frame")
	descFrame.Size = UDim2.new(1, -44, 0, 56)
	descFrame.Position = UDim2.new(0, 22, 0, 146)
	descFrame.BackgroundColor3 = Color3.fromRGB(18, 27, 44)
	descFrame.BackgroundTransparency = 0.4
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
		descLabel.Text = string.format("Spesies misterius yang hidup di perairan %s. Lemparkan kailmu dan tangkap spesies ini!", zoneName)
	end
	descLabel.TextColor3 = Color3.fromRGB(180, 205, 230)
	descLabel.Font = Enum.Font.GothamMedium
	descLabel.TextSize = 11
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.ZIndex = 63
	descLabel.Parent = descFrame

	-- Weight Spectrum Gauge
	local gaugeFrame = Instance.new("Frame")
	gaugeFrame.Size = UDim2.new(1, -44, 0, 54)
	gaugeFrame.Position = UDim2.new(0, 22, 0, 210)
	gaugeFrame.BackgroundColor3 = Color3.fromRGB(18, 27, 44)
	gaugeFrame.BackgroundTransparency = 0.4
	gaugeFrame.BorderSizePixel = 0
	gaugeFrame.ZIndex = 62
	gaugeFrame.Parent = modal
	Instance.new("UICorner", gaugeFrame).CornerRadius = UDim.new(0, 10)

	local gaugeTitle = Instance.new("TextLabel")
	gaugeTitle.Size = UDim2.new(0.5, 0, 0, 16)
	gaugeTitle.Position = UDim2.new(0, 10, 0, 6)
	gaugeTitle.BackgroundTransparency = 1
	gaugeTitle.Text = "⚖️ SPEKTRUM BOBOT IKAN"
	gaugeTitle.TextColor3 = Color3.fromRGB(148, 163, 184)
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
	gaugeRecord.TextColor3 = isDiscovered and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(148, 163, 184)
	gaugeRecord.Font = Enum.Font.GothamBold
	gaugeRecord.TextSize = 10
	gaugeRecord.TextXAlignment = Enum.TextXAlignment.Right
	gaugeRecord.ZIndex = 63
	gaugeRecord.Parent = gaugeFrame

	local trackBg = Instance.new("Frame")
	trackBg.Size = UDim2.new(1, -20, 0, 8)
	trackBg.Position = UDim2.new(0, 10, 0, 26)
	trackBg.BackgroundColor3 = Color3.fromRGB(11, 17, 29)
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
	trackFill.BackgroundColor3 = isDiscovered and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(56, 189, 248)
	trackFill.BorderSizePixel = 0
	trackFill.ZIndex = 64
	trackFill.Parent = trackBg
	Instance.new("UICorner", trackFill).CornerRadius = UDim.new(1, 0)

	local trackLabels = Instance.new("TextLabel")
	trackLabels.Size = UDim2.new(1, -20, 0, 14)
	trackLabels.Position = UDim2.new(0, 10, 0, 36)
	trackLabels.BackgroundTransparency = 1
	trackLabels.Text = string.format("Min: %.1f Kg                                                   Max: %.1f Kg", minW, maxW)
	trackLabels.TextColor3 = Color3.fromRGB(148, 163, 184)
	trackLabels.Font = Enum.Font.GothamMedium
	trackLabels.TextSize = 9
	trackLabels.ZIndex = 63
	trackLabels.Parent = gaugeFrame

	-- Stats Grid (2x2)
	local statsGrid = Instance.new("Frame")
	statsGrid.Size = UDim2.new(1, -44, 0, 136)
	statsGrid.Position = UDim2.new(0, 22, 0, 272)
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
		c.BackgroundColor3 = Color3.fromRGB(18, 27, 44)
		c.BackgroundTransparency = 0.35
		c.BorderSizePixel = 0
		c.LayoutOrder = order
		c.ZIndex = 63
		c.Parent = statsGrid
		Instance.new("UICorner", c).CornerRadius = UDim.new(0, 8)

		local tLbl = Instance.new("TextLabel")
		tLbl.Size = UDim2.new(1, -12, 0, 14)
		tLbl.Position = UDim2.new(0, 8, 0, 6)
		tLbl.BackgroundTransparency = 1
		tLbl.Text = title
		tLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
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
		sLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
		sLbl.Font = Enum.Font.GothamMedium
		sLbl.TextSize = 9
		sLbl.TextXAlignment = Enum.TextXAlignment.Left
		sLbl.ZIndex = 64
		sLbl.Parent = c
	end

	addDetailCard("🎣 TOTAL DITANGKAP", string.format("%d Ekor", isDiscovered and (entry.count or 1) or 0), isDiscovered and "Tercatat di Jurnal" or "Belum Ditemukan", Color3.fromRGB(56, 189, 248), 1)
	addDetailCard("💎 NILAI DASAR", isDiscovered and string.format("💰 %d Koin", fish.baseCoins or 15) or "??? Koin", isDiscovered and string.format("⭐ %d EXP", fish.baseExp or 10) or "??? EXP", Color3.fromRGB(251, 191, 36), 2)
	addDetailCard("🗺️ HABITAT UTAMA", zoneName, string.format("Skala Model: %.2f", fish.scale or 1.0), Color3.fromRGB(74, 222, 128), 3)

	local mutCount = 0
	if isDiscovered and entry.mutations then
		for _ in pairs(entry.mutations) do mutCount += 1 end
	end
	addDetailCard("🌠 VARIAN MUTASI", (mutCount > 0) and string.format("%d Varian Mutasi", mutCount) or "Belum Ada", "Tercatat di Buku Koleksi", Color3.fromRGB(232, 121, 249), 4)

	-- Bottom Close Button
	local dismissBtn = Instance.new("TextButton")
	dismissBtn.Size = UDim2.new(1, -44, 0, 40)
	dismissBtn.Position = UDim2.new(0, 22, 1, -50)
	dismissBtn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
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

	modal.Size = UDim2.new(0, 480, 0, 440)
	TweenService:Create(modal, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 520, 0, 480)
	}):Play()
end

-- ============ UPDATE TAB BUTTON STYLES ============
local function updateFilterTabStyles()
	for catId, widget in pairs(rarityTabWidgets) do
		local isSel = (catId == currentRarityFilter)
		if isSel then
			widget.button.BackgroundColor3 = Color3.fromRGB(2, 132, 199) -- Bright active blue #0284C7
			widget.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			widget.stroke.Color = Color3.fromRGB(56, 189, 248)
			widget.stroke.Transparency = 0.2
			widget.stroke.Thickness = 1.5
		else
			widget.button.BackgroundColor3 = Color3.fromRGB(19, 29, 46) -- Dark tab #131D2E
			widget.button.TextColor3 = Color3.fromRGB(203, 213, 225)
			widget.stroke.Color = Color3.fromRGB(30, 45, 68)
			widget.stroke.Transparency = 0.6
			widget.stroke.Thickness = 1
		end
	end

	for zoneId, widget in pairs(zoneTabWidgets) do
		local isSel = (zoneId == currentZoneFilter)
		if isSel then
			widget.button.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
			widget.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			widget.stroke.Color = Color3.fromRGB(56, 189, 248)
			widget.stroke.Transparency = 0.2
			widget.stroke.Thickness = 1.5
		else
			widget.button.BackgroundColor3 = Color3.fromRGB(19, 29, 46)
			widget.button.TextColor3 = Color3.fromRGB(203, 213, 225)
			widget.stroke.Color = Color3.fromRGB(30, 45, 68)
			widget.stroke.Transparency = 0.6
			widget.stroke.Thickness = 1
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

	FishDexUI.UpdateProgressHeader()

	-- Filter List
	local displayList = {}
	local searchLower = searchKeyword:lower():gsub("^%s+", ""):gsub("%s+$", "")

	for _, fish in ipairs(FishDefinitions.CATALOG) do
		local matchRarity = (currentRarityFilter == "ALL" or fish.rarity == currentRarityFilter)
		local matchZone = (currentZoneFilter == "ALL" or fish.favoriteZone == currentZoneFilter)

		local matchSearch = true
		if searchLower ~= "" then
			local n = fish.name:lower()
			local r = (fish.rarity or ""):lower()
			matchSearch = n:find(searchLower) ~= nil or r:find(searchLower) ~= nil
		end

		if matchRarity and matchZone and matchSearch then
			table.insert(displayList, fish)
		end
	end

	if #displayList == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 160)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "🔍 Tidak ada spesies yang cocok dengan filter yang dipilih."
		emptyLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
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

		-- Outer Card
		local card = Instance.new("Frame")
		card.Name = "FishCard_" .. fish.id
		card.Size = UDim2.new(0, 182, 0, 160)
		card.BackgroundColor3 = Color3.fromRGB(18, 27, 43) -- Card dark #121B2B
		card.BorderSizePixel = 0
		card.LayoutOrder = idx
		card.ZIndex = 50
		card.Parent = gridContainer
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = Color3.fromRGB(30, 45, 68) -- Border #1E2D44
		cardStroke.Thickness = 1.2
		cardStroke.Parent = card

		-- Top Preview Box with Dark Silhouette Background
		local previewBox = Instance.new("Frame")
		previewBox.Name = "PreviewBox"
		previewBox.Size = UDim2.new(1, -12, 0, 84)
		previewBox.Position = UDim2.new(0, 6, 0, 6)
		previewBox.BackgroundColor3 = Color3.fromRGB(10, 17, 29) -- Dark preview #0A111D
		previewBox.BorderSizePixel = 0
		previewBox.ZIndex = 51
		previewBox.Parent = card
		Instance.new("UICorner", previewBox).CornerRadius = UDim.new(0, 10)

		if isDiscovered then
			local iconLbl = Instance.new("TextLabel")
			iconLbl.Size = UDim2.new(1, 0, 1, 0)
			iconLbl.BackgroundTransparency = 1
			iconLbl.Text = "🐟"
			iconLbl.Font = Enum.Font.GothamBlack
			iconLbl.TextSize = 38
			iconLbl.ZIndex = 52
			iconLbl.Parent = previewBox
		else
			-- Red Mystery Question Mark
			local qMark = Instance.new("TextLabel")
			qMark.Size = UDim2.new(1, 0, 1, 0)
			qMark.BackgroundTransparency = 1
			qMark.Text = "?"
			qMark.TextColor3 = Color3.fromRGB(244, 63, 94) -- Vibrant Red/Coral #F43F5E
			qMark.Font = Enum.Font.GothamBlack
			qMark.TextSize = 36
			qMark.ZIndex = 52
			qMark.Parent = previewBox
		end

		-- Line 1: Species Name (or "??? [Misterius]")
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -16, 0, 18)
		nameLbl.Position = UDim2.new(0, 8, 0, 96)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = isDiscovered and fish.name or "??? [Misterius]"
		nameLbl.TextColor3 = isDiscovered and rColor or Color3.fromRGB(226, 232, 240)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 12
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.ZIndex = 51
		nameLbl.Parent = card

		-- Line 2: Rarity Badge + Stars
		local rStars = ""
		for _, rc in ipairs(RARITY_CONFIG) do
			if rc.id == r then
				rStars = rc.stars
				break
			end
		end

		local tagLbl = Instance.new("TextLabel")
		tagLbl.Size = UDim2.new(1, -16, 0, 16)
		tagLbl.Position = UDim2.new(0, 8, 0, 116)
		tagLbl.BackgroundTransparency = 1
		tagLbl.RichText = true

		local hexColor = string.format("#%02X%02X%02X", math.floor(rColor.R * 255), math.floor(rColor.G * 255), math.floor(rColor.B * 255))
		tagLbl.Text = string.format("<font color=\"%s\"><b>[%s]</b></font>  <font color=\"#F59E0B\">%s</font>", hexColor, tierData.displayName, rStars)
		tagLbl.Font = Enum.Font.GothamBold
		tagLbl.TextSize = 10
		tagLbl.TextXAlignment = Enum.TextXAlignment.Left
		tagLbl.ZIndex = 51
		tagLbl.Parent = card

		-- Line 3: Location Pin + Zone Name (or catch stats)
		local locLbl = Instance.new("TextLabel")
		locLbl.Size = UDim2.new(1, -16, 0, 16)
		locLbl.Position = UDim2.new(0, 8, 0, 136)
		locLbl.BackgroundTransparency = 1

		local zoneShort = (fish.favoriteZone == "SUMMIT_ABYSS" and "Summit") or (fish.favoriteZone == "TWIN_EYE_LAGOON" and "Twin Eye") or "Melody Bay"
		if isDiscovered then
			locLbl.Text = string.format("📍 %s  •  🎣 %dx", zoneShort, entry.count or 1)
		else
			locLbl.Text = string.format("📍 %s", zoneShort)
		end
		locLbl.TextColor3 = Color3.fromRGB(148, 163, 184)
		locLbl.Font = Enum.Font.GothamMedium
		locLbl.TextSize = 10
		locLbl.TextXAlignment = Enum.TextXAlignment.Left
		locLbl.ZIndex = 51
		locLbl.Parent = card

		-- Click Button & Hover Effect
		local clickBtn = Instance.new("TextButton")
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.ZIndex = 53
		clickBtn.Parent = card

		clickBtn.MouseEnter:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(24, 36, 56),
			}):Play()
		end)

		clickBtn.MouseLeave:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(18, 27, 43),
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

	-- 1. Fullscreen Dark Backdrop
	local overlay = Instance.new("Frame")
	overlay.Name = "FishDexOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(2, 6, 12)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 40
	overlay.Parent = targetGui
	activeOverlay = overlay

	-- 2. Main FishDex Card Container
	local card = Instance.new("Frame")
	card.Name = "FishDexCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.new(0, 840, 0, 620)
	card.Position = UDim2.new(0.5, 0, 0.54, 0)
	card.BackgroundColor3 = Color3.fromRGB(13, 21, 32) -- Background #0D1520
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

	-- Book Icon
	local bookIcon = Instance.new("TextLabel")
	bookIcon.Size = UDim2.new(0, 36, 0, 36)
	bookIcon.Position = UDim2.new(0, 24, 0, 10)
	bookIcon.BackgroundTransparency = 1
	bookIcon.Text = "📖"
	bookIcon.Font = Enum.Font.GothamBlack
	bookIcon.TextSize = 28
	bookIcon.ZIndex = 43
	bookIcon.Parent = header

	-- Header Title: "FISHDEX SAMUDRA"
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.65, 0, 0, 24)
	titleLabel.Position = UDim2.new(0, 66, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.RichText = true
	titleLabel.Text = "<font color=\"#FFFFFF\"><b>FISHDEX</b></font> <font color=\"#38BDF8\"><b>SAMUDRA</b></font>"
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 43
	titleLabel.Parent = header

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Size = UDim2.new(0.65, 0, 0, 16)
	subtitleLabel.Position = UDim2.new(0, 66, 0, 34)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Katalog seluruh spesies ikan, habitat, dan catatan rekor pribadi."
	subtitleLabel.TextColor3 = Color3.fromRGB(143, 160, 181)
	subtitleLabel.Font = Enum.Font.GothamMedium
	subtitleLabel.TextSize = 12
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.ZIndex = 43
	subtitleLabel.Parent = header

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

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(30, 45, 68)
	closeStroke.Thickness = 1
	closeStroke.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
		FishDexUI.Hide()
	end)

	-- Progress Bar Frame: "📖 Koleksi Samudra   0 / 35 Spesies (0%)"
	local progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressFrame"
	progressFrame.Size = UDim2.new(1, -48, 0, 40)
	progressFrame.Position = UDim2.new(0, 24, 0, 60)
	progressFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 38)
	progressFrame.BorderSizePixel = 0
	progressFrame.ZIndex = 42
	progressFrame.Parent = card
	Instance.new("UICorner", progressFrame).CornerRadius = UDim.new(0, 10)

	local progressStroke = Instance.new("UIStroke")
	progressStroke.Color = Color3.fromRGB(26, 40, 60)
	progressStroke.Thickness = 1
	progressStroke.Parent = progressFrame

	progressSummaryLabel = Instance.new("TextLabel")
	progressSummaryLabel.Size = UDim2.new(0.42, 0, 1, 0)
	progressSummaryLabel.Position = UDim2.new(0, 16, 0, 0)
	progressSummaryLabel.BackgroundTransparency = 1
	progressSummaryLabel.RichText = true
	progressSummaryLabel.Text = "📖 Koleksi Samudra    <font color=\"#38BDF8\"><b>0 / 35 Spesies (0%)</b></font>"
	progressSummaryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressSummaryLabel.Font = Enum.Font.GothamBold
	progressSummaryLabel.TextSize = 12
	progressSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	progressSummaryLabel.ZIndex = 43
	progressSummaryLabel.Parent = progressFrame

	local barTrack = Instance.new("Frame")
	barTrack.Name = "BarTrack"
	barTrack.Size = UDim2.new(0.52, 0, 0, 10)
	barTrack.Position = UDim2.new(0.44, 0, 0.5, -5)
	barTrack.BackgroundColor3 = Color3.fromRGB(10, 17, 29)
	barTrack.BorderSizePixel = 0
	barTrack.ZIndex = 43
	barTrack.Parent = progressFrame
	Instance.new("UICorner", barTrack).CornerRadius = UDim.new(1, 0)

	progressFillBar = Instance.new("Frame")
	progressFillBar.Name = "Fill"
	progressFillBar.Size = UDim2.new(0, 0, 1, 0)
	progressFillBar.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
	progressFillBar.BorderSizePixel = 0
	progressFillBar.ZIndex = 44
	progressFillBar.Parent = barTrack
	Instance.new("UICorner", progressFillBar).CornerRadius = UDim.new(1, 0)

	-- Filter Row 1: Rarity Tabs
	local rarityContainer = Instance.new("Frame")
	rarityContainer.Name = "RarityTabs"
	rarityContainer.Size = UDim2.new(1, -48, 0, 36)
	rarityContainer.Position = UDim2.new(0, 24, 0, 108)
	rarityContainer.BackgroundTransparency = 1
	rarityContainer.ZIndex = 42
	rarityContainer.Parent = card

	local rLayout = Instance.new("UIListLayout")
	rLayout.FillDirection = Enum.FillDirection.Horizontal
	rLayout.Padding = UDim.new(0, 8)
	rLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rLayout.Parent = rarityContainer

	rarityTabWidgets = {}
	for idx, tab in ipairs(RARITY_CONFIG) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "RarityTab_" .. tab.id
		tabBtn.Size = UDim2.new(0, (tab.id == "ALL" and 94) or (tab.id == "SUPER_RARE" and 124) or (tab.id == "LEGENDARY" and 124) or 100, 1, 0)
		tabBtn.LayoutOrder = idx
		tabBtn.BackgroundColor3 = Color3.fromRGB(19, 29, 46)
		tabBtn.BorderSizePixel = 0
		tabBtn.RichText = true

		if tab.id == "ALL" then
			tabBtn.Text = "<b>⊞  Semua</b>"
		elseif tab.id == "SPECIAL" then
			tabBtn.Text = "<font color=\"#E879F9\"><b>◆</b></font>  Special"
		else
			tabBtn.Text = string.format("<font color=\"#F59E0B\"><b>%s</b></font>  %s", tab.icon, tab.label)
		end

		tabBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.TextSize = 11
		tabBtn.ZIndex = 43
		tabBtn.Parent = rarityContainer
		Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

		local tStroke = Instance.new("UIStroke")
		tStroke.Color = Color3.fromRGB(30, 45, 68)
		tStroke.Thickness = 1
		tStroke.Parent = tabBtn

		rarityTabWidgets[tab.id] = { button = tabBtn, stroke = tStroke }

		tabBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			currentRarityFilter = tab.id
			updateFilterTabStyles()
			FishDexUI.RenderGrid()
		end)
	end

	-- Filter Row 2: Habitat Zones & Live Search
	local secondFilterRow = Instance.new("Frame")
	secondFilterRow.Name = "SecondFilterRow"
	secondFilterRow.Size = UDim2.new(1, -48, 0, 36)
	secondFilterRow.Position = UDim2.new(0, 24, 0, 150)
	secondFilterRow.BackgroundTransparency = 1
	secondFilterRow.ZIndex = 42
	secondFilterRow.Parent = card

	local zoneContainer = Instance.new("Frame")
	zoneContainer.Size = UDim2.new(0.68, 0, 1, 0)
	zoneContainer.BackgroundTransparency = 1
	zoneContainer.ZIndex = 42
	zoneContainer.Parent = secondFilterRow

	local zLayout = Instance.new("UIListLayout")
	zLayout.FillDirection = Enum.FillDirection.Horizontal
	zLayout.Padding = UDim.new(0, 8)
	zLayout.SortOrder = Enum.SortOrder.LayoutOrder
	zLayout.Parent = zoneContainer

	zoneTabWidgets = {}
	for idx, zone in ipairs(ZONE_CONFIG) do
		local zBtn = Instance.new("TextButton")
		zBtn.Name = "ZoneFilter_" .. zone.id
		zBtn.Size = UDim2.new(0, (zone.id == "ALL" and 124) or (zone.id == "TWIN_EYE_LAGOON" and 142) or 118, 1, 0)
		zBtn.LayoutOrder = idx
		zBtn.BackgroundColor3 = Color3.fromRGB(19, 29, 46)
		zBtn.BorderSizePixel = 0
		zBtn.Text = string.format("%s  %s", zone.icon, zone.label)
		zBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
		zBtn.Font = Enum.Font.GothamBold
		zBtn.TextSize = 11
		zBtn.ZIndex = 43
		zBtn.Parent = zoneContainer
		Instance.new("UICorner", zBtn).CornerRadius = UDim.new(0, 8)

		local zStroke = Instance.new("UIStroke")
		zStroke.Color = Color3.fromRGB(30, 45, 68)
		zStroke.Thickness = 1
		zStroke.Parent = zBtn

		zoneTabWidgets[zone.id] = { button = zBtn, stroke = zStroke }

		zBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			currentZoneFilter = zone.id
			updateFilterTabStyles()
			FishDexUI.RenderGrid()
		end)
	end

	-- Live Search Input on Right
	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchFrame"
	searchFrame.Size = UDim2.new(0.30, 0, 1, 0)
	searchFrame.Position = UDim2.new(0.70, 0, 0, 0)
	searchFrame.BackgroundColor3 = Color3.fromRGB(19, 29, 46)
	searchFrame.BorderSizePixel = 0
	searchFrame.ZIndex = 42
	searchFrame.Parent = secondFilterRow
	Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)

	local sStroke = Instance.new("UIStroke")
	sStroke.Color = Color3.fromRGB(30, 45, 68)
	sStroke.Thickness = 1
	sStroke.Parent = searchFrame

	local sIcon = Instance.new("TextLabel")
	sIcon.Size = UDim2.new(0, 28, 1, 0)
	sIcon.Position = UDim2.new(0, 6, 0, 0)
	sIcon.BackgroundTransparency = 1
	sIcon.Text = "🔍"
	sIcon.Font = Enum.Font.GothamBold
	sIcon.TextSize = 12
	sIcon.ZIndex = 43
	sIcon.Parent = searchFrame

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchBox"
	searchBox.Size = UDim2.new(1, -38, 1, 0)
	searchBox.Position = UDim2.new(0, 34, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.PlaceholderText = "Cari spesies..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
	searchBox.Text = searchKeyword
	searchBox.TextColor3 = Color3.fromRGB(241, 245, 249)
	searchBox.Font = Enum.Font.GothamMedium
	searchBox.TextSize = 11
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.ZIndex = 43
	searchBox.Parent = searchFrame

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchKeyword = searchBox.Text
		FishDexUI.RenderGrid()
	end)

	-- Scrollable 4-Column Species Grid
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "SpeciesGrid"
	scrollFrame.Size = UDim2.new(1, -48, 1, -204)
	scrollFrame.Position = UDim2.new(0, 24, 0, 194)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(2, 132, 199)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.ZIndex = 42
	scrollFrame.Parent = card
	gridContainer = scrollFrame

	local gLayout = Instance.new("UIGridLayout")
	gLayout.CellSize = UDim2.new(0, 187, 0, 160)
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
		Size = UDim2.new(0, 840, 0, 620),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0,
	})

	overlayIn:Play()
	cardIn:Play()

	return overlay
end

return FishDexUI
