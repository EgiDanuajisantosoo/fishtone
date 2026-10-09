--[[
	FishingResultUI (ModuleScript)
	FISH!TUNE — Fishing Result & Catch Reveal Screen (FISH-022)

	Layar Modal Hasil Tangkapan (Victory & Catch Reveal UI) Premium Glassmorphism:
	1. Grade Showcase (S+, S, A, B, C, D) dengan warna tema, title, dan pill pencapaian (AP, FC, Mutasi, Pity).
	2. Item Showcase Card dengan badge kategori, bintang rarity, mutasi khusus, dan lore deskripsi.
	3. Grid Metrik Hadiah Lengkap (Koin dengan bonus grade, EXP, Akurasi ketukan rhythm, Berat tangkapan).
	4. Tombol Interaktif Responsif:
	   - [🎒 SIMPAN] -> Simpan ke backpack & tutup modal.
	   - [🔒 KUNCI & SIMPAN] -> Kunci item seketika (Anti-Jual) & simpan.
	   - [💰 JUAL LANGSUNG] -> Jual item seketika ke pedagang tanpa perlu membuka inventory.
	5. Animasi Halus & Sound Effects terintegrasi (TweenService Back/Quad).
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local XPProgressionSystem = require(Shared:WaitForChild("Systems"):WaitForChild("XPProgressionSystem"))
local AudioEffectsSystem = require(Shared:WaitForChild("Systems"):WaitForChild("AudioEffectsSystem"))

local player = Players.LocalPlayer

local FishingResultUI = {}
local activeModal = nil
local activeOverlay = nil
local isClosing = false

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

-- ============ HIDE / CLOSE MODAL ============
function FishingResultUI.Hide(callback)
	if isClosing or not activeModal or not activeOverlay then
		if callback then callback() end
		return
	end

	isClosing = true
	local card = activeModal
	local overlay = activeOverlay

	-- Animasi keluar yang halus
	local closeTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 480, 0, 440),
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

function FishingResultUI.IsOpen()
	return activeOverlay ~= nil and activeOverlay.Parent ~= nil
end

-- ============ SHOW MODAL ============
function FishingResultUI.Show(targetGui, data, onAction)
	if not targetGui then return end

	-- Tutup modal aktif jika ada
	if activeOverlay then
		activeOverlay:Destroy()
		activeOverlay = nil
		activeModal = nil
		isClosing = false
	end

	data = data or {}
	local fishData = data.fishData or {}
	local rewardInfo = data.rewardInfo or {}
	local pityState = data.pityState or {}
	local toolInstance = data.toolInstance

	local name = fishData.name or "Ikan Samudra"
	local dispName = fishData.displayName or fishData.rarity or "COMMON"
	local stars = fishData.stars or "⭐"
	local catBadge = fishData.categoryBadge or "🐟 IKAN"
	local weight = tonumber(fishData.weight) or 1.0
	local coins = tonumber(rewardInfo.coins) or tonumber(fishData.coins) or 15
	local exp = tonumber(rewardInfo.exp) or tonumber(fishData.exp) or 10
	local baseCoins = tonumber(fishData.coins) or 15
	local baseExp = tonumber(fishData.exp) or 10
	local desc = fishData.description or "Tangkapan segar dari samudra luas FishTune!"
	local rarityColor = fishData.color or Color3.fromRGB(0, 200, 255)

	local grade = rewardInfo.grade or "A"
	local gradeTitle = rewardInfo.gradeTitle or "GOOD CATCH"
	local gradeColor = rewardInfo.gradeColor or Color3.fromRGB(0, 230, 255)
	local xpMult = tonumber(rewardInfo.xpMultiplier) or 1.0
	local coinMult = tonumber(rewardInfo.coinMultiplier) or 1.0
	local luckBonus = tonumber(rewardInfo.performanceLuckBonus) or 0
	local acc = tonumber(rewardInfo.accuracy) or 100

	local isMutated = (fishData.isMutated == true) or (rewardInfo.isMutated == true)
	local mutationName = fishData.mutationName or rewardInfo.mutationName or ""
	local mutationPrefix = fishData.mutationPrefix or (mutationName ~= "" and ("[" .. mutationName:upper() .. "]") or "")

	local isAllPerfect = rewardInfo.isAllPerfect == true
	local isFullCombo = rewardInfo.isFullCombo == true
	local wasPity = rewardInfo.wasPity == true

	-- 1. Fullscreen Backdrop Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "FishingResultOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(5, 8, 15)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 45
	overlay.Parent = targetGui
	activeOverlay = overlay

	-- 2. Modal Card Container
	local card = Instance.new("Frame")
	card.Name = "ResultCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.new(0, 500, 0, 490)
	card.Position = UDim2.new(0.5, 0, 0.52, 0)
	card.BackgroundColor3 = Color3.fromRGB(12, 17, 28)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.ZIndex = 46
	card.Parent = overlay
	activeModal = card
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = rarityColor
	cardStroke.Thickness = 2.2
	cardStroke.Transparency = 0.2
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
	header.Size = UDim2.new(1, 0, 0, 48)
	header.BackgroundTransparency = 1
	header.ZIndex = 47
	header.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 20, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🎉 HASIL TANGKAPAN IKAN"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 17
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 47
	titleLabel.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -44, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextSize = 15
	closeBtn.ZIndex = 48
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
		FishingResultUI.Hide(function()
			if onAction then onAction("KEEP", toolInstance) end
		end)
	end)

	-- ============ 1. GRADE & PERFORMANCE ROW ============
	local gradeRow = Instance.new("Frame")
	gradeRow.Name = "GradeRow"
	gradeRow.Size = UDim2.new(1, -40, 0, 76)
	gradeRow.Position = UDim2.new(0, 20, 0, 48)
	gradeRow.BackgroundColor3 = Color3.fromRGB(18, 25, 40)
	gradeRow.BackgroundTransparency = 0.4
	gradeRow.BorderSizePixel = 0
	gradeRow.ZIndex = 47
	gradeRow.Parent = card
	Instance.new("UICorner", gradeRow).CornerRadius = UDim.new(0, 12)

	local gradeRowStroke = Instance.new("UIStroke")
	gradeRowStroke.Color = gradeColor
	gradeRowStroke.Thickness = 1.5
	gradeRowStroke.Transparency = 0.45
	gradeRowStroke.Parent = gradeRow

	-- Grade Letter Badge Box
	local gradeBox = Instance.new("Frame")
	gradeBox.Name = "GradeBox"
	gradeBox.Size = UDim2.new(0, 64, 0, 64)
	gradeBox.Position = UDim2.new(0, 6, 0.5, -32)
	gradeBox.BackgroundColor3 = Color3.fromRGB(25, 34, 54)
	gradeBox.BorderSizePixel = 0
	gradeBox.ZIndex = 48
	gradeBox.Parent = gradeRow
	Instance.new("UICorner", gradeBox).CornerRadius = UDim.new(0, 10)

	local gradeBoxStroke = Instance.new("UIStroke")
	gradeBoxStroke.Color = gradeColor
	gradeBoxStroke.Thickness = 2
	gradeBoxStroke.Parent = gradeBox

	local gradeLetter = Instance.new("TextLabel")
	gradeLetter.Size = UDim2.new(1, 0, 1, 0)
	gradeLetter.BackgroundTransparency = 1
	gradeLetter.Text = grade
	gradeLetter.TextColor3 = gradeColor
	gradeLetter.Font = Enum.Font.GothamBlack
	gradeLetter.TextSize = (grade == "S+") and 30 or 34
	gradeLetter.ZIndex = 49
	gradeLetter.Parent = gradeBox

	-- Grade Details
	local gradeTitleLabel = Instance.new("TextLabel")
	gradeTitleLabel.Size = UDim2.new(0.78, 0, 0, 22)
	gradeTitleLabel.Position = UDim2.new(0, 78, 0, 8)
	gradeTitleLabel.BackgroundTransparency = 1
	gradeTitleLabel.Text = string.format("RATING: %s", gradeTitle:upper())
	gradeTitleLabel.TextColor3 = gradeColor
	gradeTitleLabel.Font = Enum.Font.GothamBlack
	gradeTitleLabel.TextSize = 14
	gradeTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	gradeTitleLabel.ZIndex = 48
	gradeTitleLabel.Parent = gradeRow

	-- Pills Container (AP, FC, Pity, Mutation)
	local pillsContainer = Instance.new("Frame")
	pillsContainer.Size = UDim2.new(0.78, 0, 0, 20)
	pillsContainer.Position = UDim2.new(0, 78, 0, 30)
	pillsContainer.BackgroundTransparency = 1
	pillsContainer.ZIndex = 48
	pillsContainer.Parent = gradeRow

	local pillLayout = Instance.new("UIListLayout")
	pillLayout.FillDirection = Enum.FillDirection.Horizontal
	pillLayout.Padding = UDim.new(0, 6)
	pillLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pillLayout.Parent = pillsContainer

	local function addPill(text, bgColor, textColor, order)
		local pill = Instance.new("Frame")
		pill.Size = UDim2.new(0, 0, 1, 0)
		pill.AutomaticSize = Enum.AutomaticSize.X
		pill.BackgroundColor3 = bgColor
		pill.BorderSizePixel = 0
		pill.LayoutOrder = order or 1
		pill.ZIndex = 49
		pill.Parent = pillsContainer
		Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 6)

		local pPad = Instance.new("UIPadding")
		pPad.PaddingLeft = UDim.new(0, 8)
		pPad.PaddingRight = UDim.new(0, 8)
		pPad.Parent = pill

		local pTxt = Instance.new("TextLabel")
		pTxt.Size = UDim2.new(1, 0, 1, 0)
		pTxt.AutomaticSize = Enum.AutomaticSize.X
		pTxt.BackgroundTransparency = 1
		pTxt.Text = text
		pTxt.TextColor3 = textColor
		pTxt.Font = Enum.Font.GothamBold
		pTxt.TextSize = 10
		pTxt.ZIndex = 50
		pTxt.Parent = pill
	end

	if isAllPerfect then
		addPill("🌟 ALL PERFECT", Color3.fromRGB(70, 55, 10), Color3.fromRGB(255, 220, 60), 1)
	elseif isFullCombo then
		addPill("🔥 FULL COMBO", Color3.fromRGB(70, 35, 10), Color3.fromRGB(255, 160, 40), 2)
	end

	if wasPity then
		addPill("👑 GARANSI PITY", Color3.fromRGB(60, 20, 70), Color3.fromRGB(240, 150, 255), 3)
	end

	if isMutated and mutationName ~= "" then
		addPill("🌠 " .. mutationName:upper(), Color3.fromRGB(20, 50, 70), Color3.fromRGB(0, 230, 255), 4)
	end

	-- Subtitle Rhythm Performance
	local bonusSubLabel = Instance.new("TextLabel")
	bonusSubLabel.Size = UDim2.new(0.78, 0, 0, 18)
	bonusSubLabel.Position = UDim2.new(0, 78, 0, 52)
	bonusSubLabel.BackgroundTransparency = 1
	bonusSubLabel.Text = string.format("🎯 Akurasi: %.1f%%  •  Pengganda: EXP x%.2f | Koin x%.2f | +%.1f Luck", acc, xpMult, coinMult, luckBonus)
	bonusSubLabel.TextColor3 = Color3.fromRGB(190, 215, 240)
	bonusSubLabel.Font = Enum.Font.GothamMedium
	bonusSubLabel.TextSize = 11
	bonusSubLabel.TextXAlignment = Enum.TextXAlignment.Left
	bonusSubLabel.ZIndex = 48
	bonusSubLabel.Parent = gradeRow

	-- ============ 2. ITEM SHOWCASE CARD ============
	local itemCard = Instance.new("Frame")
	itemCard.Name = "ItemCard"
	itemCard.Size = UDim2.new(1, -40, 0, 112)
	itemCard.Position = UDim2.new(0, 20, 0, 132)
	itemCard.BackgroundColor3 = Color3.fromRGB(18, 25, 40)
	itemCard.BackgroundTransparency = 0.3
	itemCard.BorderSizePixel = 0
	itemCard.ZIndex = 47
	itemCard.Parent = card
	Instance.new("UICorner", itemCard).CornerRadius = UDim.new(0, 12)

	local itemCardStroke = Instance.new("UIStroke")
	itemCardStroke.Color = rarityColor
	itemCardStroke.Thickness = 1.8
	itemCardStroke.Transparency = 0.3
	itemCardStroke.Parent = itemCard

	-- Icon Box
	local iconBox = Instance.new("Frame")
	iconBox.Size = UDim2.new(0, 68, 0, 68)
	iconBox.Position = UDim2.new(0, 14, 0, 14)
	iconBox.BackgroundColor3 = Color3.fromRGB(24, 32, 50)
	iconBox.BorderSizePixel = 0
	iconBox.ZIndex = 48
	iconBox.Parent = itemCard
	Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 12)

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = rarityColor
	iconStroke.Thickness = 1.5
	iconStroke.Transparency = 0.4
	iconStroke.Parent = iconBox

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = (catBadge:find("PETI") and "📦") or (catBadge:find("RELIK") and "🔮") or (catBadge:find("SAMPAH") and "🗑️") or "🐟"
	iconLabel.Font = Enum.Font.GothamBlack
	iconLabel.TextSize = 32
	iconLabel.ZIndex = 49
	iconLabel.Parent = iconBox

	-- Item Name & Rarity Header
	local itemNameLabel = Instance.new("TextLabel")
	itemNameLabel.Size = UDim2.new(1, -100, 0, 22)
	itemNameLabel.Position = UDim2.new(0, 92, 0, 10)
	itemNameLabel.BackgroundTransparency = 1
	itemNameLabel.Text = string.format("%s [%s]%s %s %s", catBadge, dispName, mutationPrefix ~= "" and (" " .. mutationPrefix) or "", name, stars)
	itemNameLabel.TextColor3 = rarityColor
	itemNameLabel.Font = Enum.Font.GothamBlack
	itemNameLabel.TextSize = 14
	itemNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	itemNameLabel.ZIndex = 48
	itemNameLabel.Parent = itemCard

	-- Item Lore Description
	local itemDescLabel = Instance.new("TextLabel")
	itemDescLabel.Size = UDim2.new(1, -100, 0, 32)
	itemDescLabel.Position = UDim2.new(0, 92, 0, 32)
	itemDescLabel.BackgroundTransparency = 1
	itemDescLabel.Text = desc
	itemDescLabel.TextColor3 = Color3.fromRGB(165, 195, 225)
	itemDescLabel.Font = Enum.Font.GothamMedium
	itemDescLabel.TextSize = 11
	itemDescLabel.TextWrapped = true
	itemDescLabel.TextXAlignment = Enum.TextXAlignment.Left
	itemDescLabel.TextYAlignment = Enum.TextYAlignment.Top
	itemDescLabel.ZIndex = 48
	itemDescLabel.Parent = itemCard

	-- Item Spec Chips Bar
	local specChipsBar = Instance.new("Frame")
	specChipsBar.Size = UDim2.new(1, -100, 0, 22)
	specChipsBar.Position = UDim2.new(0, 92, 0, 78)
	specChipsBar.BackgroundTransparency = 1
	specChipsBar.ZIndex = 48
	specChipsBar.Parent = itemCard

	local specLayout = Instance.new("UIListLayout")
	specLayout.FillDirection = Enum.FillDirection.Horizontal
	specLayout.Padding = UDim.new(0, 8)
	specLayout.Parent = specChipsBar

	local function addSpecChip(txt, color)
		local chip = Instance.new("Frame")
		chip.Size = UDim2.new(0, 0, 1, 0)
		chip.AutomaticSize = Enum.AutomaticSize.X
		chip.BackgroundColor3 = Color3.fromRGB(24, 34, 52)
		chip.BorderSizePixel = 0
		chip.ZIndex = 49
		chip.Parent = specChipsBar
		Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 5)

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 6)
		pad.PaddingRight = UDim.new(0, 6)
		pad.Parent = chip

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.AutomaticSize = Enum.AutomaticSize.X
		lbl.BackgroundTransparency = 1
		lbl.Text = txt
		lbl.TextColor3 = color or Color3.fromRGB(220, 235, 255)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 10
		lbl.ZIndex = 50
		lbl.Parent = chip
	end

	addSpecChip(string.format("⚖️ %.1f Kg", weight), Color3.fromRGB(220, 235, 255))
	addSpecChip(string.format("⭐ %s Tier", dispName), rarityColor)
	if isMutated then
		addSpecChip("🌠 Mutasi Langka", Color3.fromRGB(255, 170, 255))
	end

	-- ============ 3. REWARDS & METRICS GRID (2x2) ============
	local gridFrame = Instance.new("Frame")
	gridFrame.Name = "MetricsGrid"
	gridFrame.Size = UDim2.new(1, -40, 0, 140)
	gridFrame.Position = UDim2.new(0, 20, 0, 252)
	gridFrame.BackgroundTransparency = 1
	gridFrame.ZIndex = 47
	gridFrame.Parent = card

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.485, 0, 0, 64)
	gridLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = gridFrame

	local function createMetricCard(title, mainVal, subVal, valColor, order)
		local mCard = Instance.new("Frame")
		mCard.BackgroundColor3 = Color3.fromRGB(18, 25, 40)
		mCard.BackgroundTransparency = 0.35
		mCard.BorderSizePixel = 0
		mCard.LayoutOrder = order
		mCard.ZIndex = 48
		mCard.Parent = gridFrame
		Instance.new("UICorner", mCard).CornerRadius = UDim.new(0, 10)

		local mStroke = Instance.new("UIStroke")
		mStroke.Color = Color3.fromRGB(40, 55, 80)
		mStroke.Thickness = 1
		mStroke.Transparency = 0.5
		mStroke.Parent = mCard

		local mTitle = Instance.new("TextLabel")
		mTitle.Size = UDim2.new(1, -16, 0, 16)
		mTitle.Position = UDim2.new(0, 10, 0, 6)
		mTitle.BackgroundTransparency = 1
		mTitle.Text = title
		mTitle.TextColor3 = Color3.fromRGB(140, 165, 195)
		mTitle.Font = Enum.Font.GothamMedium
		mTitle.TextSize = 11
		mTitle.TextXAlignment = Enum.TextXAlignment.Left
		mTitle.ZIndex = 49
		mTitle.Parent = mCard

		local mVal = Instance.new("TextLabel")
		mVal.Size = UDim2.new(1, -16, 0, 22)
		mVal.Position = UDim2.new(0, 10, 0, 22)
		mVal.BackgroundTransparency = 1
		mVal.Text = mainVal
		mVal.TextColor3 = valColor or Color3.fromRGB(255, 255, 255)
		mVal.Font = Enum.Font.GothamBlack
		mVal.TextSize = 15
		mVal.TextXAlignment = Enum.TextXAlignment.Left
		mVal.ZIndex = 49
		mVal.Parent = mCard

		local mSub = Instance.new("TextLabel")
		mSub.Size = UDim2.new(1, -16, 0, 14)
		mSub.Position = UDim2.new(0, 10, 0, 44)
		mSub.BackgroundTransparency = 1
		mSub.Text = subVal
		mSub.TextColor3 = Color3.fromRGB(160, 185, 210)
		mSub.Font = Enum.Font.GothamMedium
		mSub.TextSize = 10
		mSub.TextXAlignment = Enum.TextXAlignment.Left
		mSub.ZIndex = 49
		mSub.Parent = mCard
	end

	-- 1. Koin
	local coinSubText = (coinMult > 1.0) and string.format("Base: %d + Bonus Grade x%.2f", baseCoins, coinMult) or "Nilai jual standar"
	createMetricCard("💰 NILAI KOIN", string.format("+%d Koin", coins), coinSubText, Color3.fromRGB(255, 220, 50), 1)

	-- 2. EXP
	local expSubText = (xpMult > 1.0) and string.format("Base: %d + Bonus Grade x%.2f", baseExp, xpMult) or "Tambahan EXP pemain"
	createMetricCard("⭐ PENGALAMAN (EXP)", string.format("+%d EXP", exp), expSubText, Color3.fromRGB(0, 230, 255), 2)

	-- 3. Akurasi
	local accSubText = string.format("Rating %s • Combo Boost", grade)
	createMetricCard("🎯 AKURASI RHYTHM", string.format("%.1f%%", acc), accSubText, gradeColor, 3)

	-- 4. Berat
	local weightSubText = string.format("Skala Ukuran: %.2f", fishData.scale or 1.0)
	createMetricCard("⚖️ BERAT TANGKAPAN", string.format("%.1f Kg", weight), weightSubText, Color3.fromRGB(230, 240, 255), 4)

	-- ============ 3B. LIVE EXP PROGRESS BAR ============
	local pData = data.playerData or {}
	local totalExp = tonumber(pData.totalExp)
	if totalExp == nil then
		totalExp = XPProgressionSystem.ReconcileToTotalExp(pData.level or 1, pData.exp or 0)
	end
	local prog = XPProgressionSystem.DeriveProgression(totalExp)

	local expProgressRow = Instance.new("Frame")
	expProgressRow.Name = "ExpProgressRow"
	expProgressRow.Size = UDim2.new(1, -40, 0, 24)
	expProgressRow.Position = UDim2.new(0, 20, 0, 400)
	expProgressRow.BackgroundTransparency = 1
	expProgressRow.ZIndex = 47
	expProgressRow.Parent = card

	local lvBadgeMini = Instance.new("TextLabel")
	lvBadgeMini.Size = UDim2.new(0, 46, 0, 22)
	lvBadgeMini.Position = UDim2.new(0, 0, 0, 1)
	lvBadgeMini.BackgroundColor3 = Color3.fromRGB(15, 23, 38)
	lvBadgeMini.BorderSizePixel = 0
	lvBadgeMini.Text = string.format("Lv. %d", prog.level)
	lvBadgeMini.TextColor3 = Color3.fromRGB(56, 189, 248)
	lvBadgeMini.Font = Enum.Font.GothamBlack
	lvBadgeMini.TextSize = 10
	lvBadgeMini.ZIndex = 48
	lvBadgeMini.Parent = expProgressRow
	Instance.new("UICorner", lvBadgeMini).CornerRadius = UDim.new(0, 6)

	local expBarMiniBg = Instance.new("Frame")
	expBarMiniBg.Size = UDim2.new(1, -56, 0, 8)
	expBarMiniBg.Position = UDim2.new(0, 54, 0, 2)
	expBarMiniBg.BackgroundColor3 = Color3.fromRGB(10, 16, 26)
	expBarMiniBg.BorderSizePixel = 0
	expBarMiniBg.ZIndex = 48
	expBarMiniBg.Parent = expProgressRow
	Instance.new("UICorner", expBarMiniBg).CornerRadius = UDim.new(1, 0)

	local expBarMiniFill = Instance.new("Frame")
	expBarMiniFill.Size = UDim2.new(math.clamp(prog.progressPercent, 0, 1), 0, 1, 0)
	expBarMiniFill.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
	expBarMiniFill.BorderSizePixel = 0
	expBarMiniFill.ZIndex = 49
	expBarMiniFill.Parent = expBarMiniBg
	Instance.new("UICorner", expBarMiniFill).CornerRadius = UDim.new(1, 0)

	local expMiniSub = Instance.new("TextLabel")
	expMiniSub.Size = UDim2.new(1, -56, 0, 12)
	expMiniSub.Position = UDim2.new(0, 54, 0, 12)
	expMiniSub.BackgroundTransparency = 1
	expMiniSub.Text = string.format("%d / %d EXP (%d%%) • +%d EXP tangkapan", prog.currentLevelExp, prog.nextLevelExp, math.floor(prog.progressPercent * 100), exp)
	expMiniSub.TextColor3 = Color3.fromRGB(148, 163, 184)
	expMiniSub.Font = Enum.Font.GothamMedium
	expMiniSub.TextSize = 9
	expMiniSub.TextXAlignment = Enum.TextXAlignment.Left
	expMiniSub.ZIndex = 48
	expMiniSub.Parent = expProgressRow

	-- ============ 4. ACTION BUTTONS BAR ============
	local actionsBar = Instance.new("Frame")
	actionsBar.Name = "ActionsBar"
	actionsBar.Size = UDim2.new(1, -40, 0, 44)
	actionsBar.Position = UDim2.new(0, 20, 1, -54)
	actionsBar.BackgroundTransparency = 1
	actionsBar.ZIndex = 47
	actionsBar.Parent = card

	-- 1. Tombol Simpan ke Inventory
	local keepBtn = Instance.new("TextButton")
	keepBtn.Name = "KeepBtn"
	keepBtn.Size = UDim2.new(0.31, 0, 1, 0)
	keepBtn.Position = UDim2.new(0, 0, 0, 0)
	keepBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
	keepBtn.BorderSizePixel = 0
	keepBtn.Text = "🎒 SIMPAN"
	keepBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	keepBtn.Font = Enum.Font.GothamBlack
	keepBtn.TextSize = 12
	keepBtn.ZIndex = 48
	keepBtn.Parent = actionsBar
	Instance.new("UICorner", keepBtn).CornerRadius = UDim.new(0, 10)

	keepBtn.MouseButton1Click:Connect(function()
		AudioEffectsSystem.PlayButtonClick()
		FishingResultUI.Hide(function()
			if onAction then onAction("KEEP", toolInstance) end
		end)
	end)

	-- 2. Tombol Kunci & Simpan (Lock & Keep)
	local lockBtn = Instance.new("TextButton")
	lockBtn.Name = "LockBtn"
	lockBtn.Size = UDim2.new(0.33, 0, 1, 0)
	lockBtn.Position = UDim2.new(0.335, 0, 0, 0)
	lockBtn.BackgroundColor3 = Color3.fromRGB(235, 155, 25)
	lockBtn.BorderSizePixel = 0
	lockBtn.Text = "🔒 KUNCI & SIMPAN"
	lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	lockBtn.Font = Enum.Font.GothamBlack
	lockBtn.TextSize = 11
	lockBtn.ZIndex = 48
	lockBtn.Parent = actionsBar
	Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 10)

	lockBtn.MouseButton1Click:Connect(function()
		AudioEffectsSystem.PlayButtonClick()
		FishingResultUI.Hide(function()
			if onAction then onAction("LOCK", toolInstance) end
		end)
	end)

	-- 3. Tombol Jual Langsung (Quick Sell)
	local quickSellBtn = Instance.new("TextButton")
	quickSellBtn.Name = "QuickSellBtn"
	quickSellBtn.Size = UDim2.new(0.31, 0, 1, 0)
	quickSellBtn.Position = UDim2.new(0.69, 0, 0, 0)
	quickSellBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
	quickSellBtn.BorderSizePixel = 0
	quickSellBtn.Text = string.format("💰 JUAL (+%d)", coins)
	quickSellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	quickSellBtn.Font = Enum.Font.GothamBlack
	quickSellBtn.TextSize = 12
	quickSellBtn.ZIndex = 48
	quickSellBtn.Parent = actionsBar
	Instance.new("UICorner", quickSellBtn).CornerRadius = UDim.new(0, 10)

	quickSellBtn.MouseButton1Click:Connect(function()
		AudioEffectsSystem.PlayItemSell()
		FishingResultUI.Hide(function()
			if onAction then onAction("SELL", toolInstance) end
		end)
	end)

	-- ============ 5. ENTRANCE ANIMATIONS ============
	local overlayIn = TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.35,
	})
	local cardIn = TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 540, 0, 480),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0.1,
	})

	overlayIn:Play()
	cardIn:Play()

	-- Audio Fanfare disesuaikan dengan Rarity & Grade (FISH-036)
	AudioEffectsSystem.PlayCatchFanfare(fish.rarity or "COMMON", grade)

	return overlay
end

return FishingResultUI
