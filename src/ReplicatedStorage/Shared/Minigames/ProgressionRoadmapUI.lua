--[[
	ProgressionRoadmapUI (ModuleScript)
	FISH!TUNE — Level Progression Roadmap & Instruments Mastery Dashboard (FISH-032)

	Dashboard Komprehensif Progresi & Jalur Milestone Pemain:
	1. Active Level Card: Status level real-time, Bar EXP dinamis, Total Akumulasi EXP, & Sisa EXP ke level berikutnya.
	2. Instruments Mastery Grid: Status 3 instrumen ritme kanonikal (Piano, Gitar, Drum) dengan level req & tipe minigame.
	3. Milestone Timeline: Rangkaian milestone level 1–30+ lengkap dengan status [✅ SELESAI], [⚡ AKTIF/SEGERA], [🔒 TERKUNCI].
	4. Navigasi & Shortcut Responsif: Klik Level Pill di HUD atau Hotkey [P]/[L] untuk membuka/menutup.
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local XPProgressionSystem = require(Shared:WaitForChild("Systems"):WaitForChild("XPProgressionSystem"))
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local MobileResponsiveHelper = require(Shared:WaitForChild("Systems"):WaitForChild("MobileResponsiveHelper"))

local ProgressionRoadmapUI = {}
local activeModal = nil
local activeOverlay = nil
local isClosing = false

-- ============ MILESTONES DATA ============
local MILESTONES = {
	{
		level = 1,
		title = "Nelayan Pemula Teluk Melodi",
		category = "STARTER",
		desc = "Mulai petualangan dengan Joran Bambu Pemula (Minigame Piano Tiles 4-Jalur) dan kapasitas tas 35 slot.",
		icon = "🎹",
		color = Color3.fromRGB(0, 210, 255),
	},
	{
		level = 2,
		title = "🎸 Pembukaan Minigame Gitar Akustik",
		category = "INSTRUMENT",
		desc = "Buka akses instrumen Gitar! Joran Gitar Akustik Mahoni (Bamboo Rod) kini dapat dibeli di toko.",
		icon = "🎸",
		color = Color3.fromRGB(245, 158, 11),
	},
	{
		level = 3,
		title = "🎒 Upgrade Tas Tier 1 (40 Slot)",
		category = "BAG",
		desc = "Buka akses pembelian Tas Nelayan Kanvas (+5 Slot) seharga 350 Koin di Toko Samudra.",
		icon = "🎒",
		color = Color3.fromRGB(168, 85, 247),
	},
	{
		level = 4,
		title = "🥁 Pembukaan Minigame Drum Perkusi",
		category = "INSTRUMENT",
		desc = "Buka akses instrumen Drum! Joran Perkusi Ritme Rimba (Tribal Rod) kini dapat dibeli di toko.",
		icon = "🥁",
		color = Color3.fromRGB(239, 68, 68),
	},
	{
		level = 6,
		title = "🎹 Joran Grand Piano Harmoni",
		category = "ROD",
		desc = "Joran Grand Piano Harmoni (+38 Luck, Pengganda Lemparan 1.22x) siap dibeli di toko seharga 1,400 Koin.",
		icon = "🎹",
		color = Color3.fromRGB(56, 189, 248),
	},
	{
		level = 7,
		title = "🎒 Upgrade Tas Tier 2 (45 Slot)",
		category = "BAG",
		desc = "Buka akses pembelian Ransel Kulit Kedap Air (+5 Slot) seharga 950 Koin di Toko Samudra.",
		icon = "🎒",
		color = Color3.fromRGB(168, 85, 247),
	},
	{
		level = 10,
		title = "🎸 Joran Gitar Elektrik Overdrive",
		category = "ROD",
		desc = "Joran Gitar Elektrik Overdrive (+62 Luck, Serat Karbon Sintetis) siap dibeli seharga 2,800 Koin.",
		icon = "🎸",
		color = Color3.fromRGB(239, 68, 68),
	},
	{
		level = 12,
		title = "🎒 Upgrade Tas Tier 3 (55 Slot)",
		category = "BAG",
		desc = "Buka akses Kotak Pancing Karbon Ringan (+10 Slot) seharga 2,500 Koin di Toko Samudra.",
		icon = "🎒",
		color = Color3.fromRGB(168, 85, 247),
	},
	{
		level = 14,
		title = "🥁 Joran Drum Pad Neon Synthwave",
		category = "ROD",
		desc = "Joran Drum Pad Neon Synthwave (+90 Luck, 16-Pad RGB) siap dibeli seharga 5,200 Koin.",
		icon = "🥁",
		color = Color3.fromRGB(236, 72, 153),
	},
	{
		level = 18,
		title = "🎹 Joran Sonata Kristal Resonansi",
		category = "ROD",
		desc = "Joran Sonata Kristal Resonansi (+115 Luck, Kristal Laut Dalam) siap dibeli seharga 8,500 Koin.",
		icon = "🎹",
		color = Color3.fromRGB(147, 197, 253),
	},
	{
		level = 20,
		title = "🎒 Upgrade Tas Tier 4 (65 Slot)",
		category = "BAG",
		desc = "Buka akses Koper Samudra Berpendingin Titanium (+10 Slot) seharga 6,500 Koin di Toko Samudra.",
		icon = "🎒",
		color = Color3.fromRGB(168, 85, 247),
	},
	{
		level = 22,
		title = "🎸 Joran Trisula Heavy Metal Palung",
		category = "ROD",
		desc = "Joran Trisula Heavy Metal Palung (+140 Luck, Obsidian Palung) siap dibeli seharga 11,500 Koin.",
		icon = "🎸",
		color = Color3.fromRGB(168, 85, 247),
	},
	{
		level = 30,
		title = "👑 Joran Melodi Bintang Kosmik",
		category = "MYTHIC",
		desc = "Joran Melodi Bintang Kosmik (+200 Luck, Meteorit Emas Para Dewa) siap dibeli seharga 25,000 Koin.",
		icon = "👑",
		color = Color3.fromRGB(251, 191, 36),
	},
}

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

-- ============ FORMAT NUMBERS ============
local function formatNumber(n)
	n = math.floor(tonumber(n) or 0)
	local str = tostring(n)
	return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- ============ HIDE / CLOSE MODAL ============
function ProgressionRoadmapUI.Hide(callback)
	if isClosing or not activeModal or not activeOverlay then
		if callback then callback() end
		return
	end

	isClosing = true
	local card = activeModal
	local overlay = activeOverlay

	local closeTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 680, 0, 520),
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

function ProgressionRoadmapUI.IsOpen()
	return activeOverlay ~= nil and activeOverlay.Parent ~= nil
end

function ProgressionRoadmapUI.Toggle(targetGui, playerData)
	if ProgressionRoadmapUI.IsOpen() then
		ProgressionRoadmapUI.Hide()
	else
		ProgressionRoadmapUI.Show(targetGui, playerData)
	end
end

-- ============ SHOW MODAL ============
function ProgressionRoadmapUI.Show(targetGui, playerData)
	if not targetGui then return end

	if activeOverlay then
		activeOverlay:Destroy()
		activeOverlay = nil
		activeModal = nil
		isClosing = false
	end

	playerData = playerData or {}
	local totalExp = tonumber(playerData.totalExp)
	local level = tonumber(playerData.level)
	local exp = tonumber(playerData.exp)

	if totalExp == nil and (level == nil or level <= 1) and (exp == nil or exp == 0) then
		local lp = Players.LocalPlayer
		local stats = lp and lp:FindFirstChild("leaderstats")
		if stats then
			local lLevel = stats:FindFirstChild("Level")
			local lExp = stats:FindFirstChild("Exp")
			if lLevel and tonumber(lLevel.Value) ~= nil and tonumber(lLevel.Value) > 0 then
				level = tonumber(lLevel.Value)
			end
			if lExp and tonumber(lExp.Value) ~= nil and tonumber(lExp.Value) > 0 then
				exp = tonumber(lExp.Value)
			end
		end
	end

	if totalExp == nil then
		totalExp = XPProgressionSystem.ReconcileToTotalExp(level or 1, exp or 0)
	end

	local prog = XPProgressionSystem.DeriveProgression(totalExp)
	local pLevel = prog.level
	local unlockedInsts = playerData.unlockedInstruments or { "PIANO" }

	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.3)

	-- 1. Backdrop Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "RoadmapOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(6, 10, 20)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 48
	overlay.Parent = targetGui
	activeOverlay = overlay

	-- 2. Modal Card
	local card = Instance.new("Frame")
	card.Name = "RoadmapCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.new(0, 720, 0, 560)
	card.Position = UDim2.new(0.5, 0, 0.52, 0)
	card.BackgroundColor3 = Color3.fromRGB(15, 23, 38)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.ZIndex = 49
	card.Parent = overlay
	activeModal = card
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

	-- Responsive Auto-Fit untuk Layar HP / Tablet (FISH-037)
	MobileResponsiveHelper.AttachResponsiveScale(card, 720, 560)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(14, 165, 233)
	cardStroke.Thickness = 1.6
	cardStroke.Transparency = 0.3
	cardStroke.Parent = card

	-- Header Bar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.ZIndex = 50
	header.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.65, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 24, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.RichText = true
	titleLabel.Text = "📈 <b>JALUR PROGRESI & MILESTONE</b>"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 51
	titleLabel.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -54, 0.5, -18)
	closeBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(203, 213, 225)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.ZIndex = 51
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.4)
		ProgressionRoadmapUI.Hide()
	end)

	-- ============ 1. ACTIVE LEVEL STATUS CARD ============
	local statusCard = Instance.new("Frame")
	statusCard.Name = "StatusCard"
	statusCard.Size = UDim2.new(1, -48, 0, 92)
	statusCard.Position = UDim2.new(0, 24, 0, 60)
	statusCard.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
	statusCard.BorderSizePixel = 0
	statusCard.ZIndex = 50
	statusCard.Parent = card
	Instance.new("UICorner", statusCard).CornerRadius = UDim.new(0, 14)

	local scStroke = Instance.new("UIStroke")
	scStroke.Color = Color3.fromRGB(56, 189, 248)
	scStroke.Thickness = 1.2
	scStroke.Transparency = 0.4
	scStroke.Parent = statusCard

	-- Level Big Badge
	local bigBadge = Instance.new("Frame")
	bigBadge.Size = UDim2.new(0, 72, 0, 72)
	bigBadge.Position = UDim2.new(0, 10, 0.5, -36)
	bigBadge.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
	bigBadge.BorderSizePixel = 0
	bigBadge.ZIndex = 51
	bigBadge.Parent = statusCard
	Instance.new("UICorner", bigBadge).CornerRadius = UDim.new(0, 12)

	local bbStroke = Instance.new("UIStroke")
	bbStroke.Color = Color3.fromRGB(56, 189, 248)
	bbStroke.Thickness = 1.4
	bbStroke.Parent = bigBadge

	local bbLabel = Instance.new("TextLabel")
	bbLabel.Size = UDim2.new(1, 0, 0, 32)
	bbLabel.Position = UDim2.new(0, 0, 0, 10)
	bbLabel.BackgroundTransparency = 1
	bbLabel.Text = tostring(pLevel)
	bbLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
	bbLabel.Font = Enum.Font.GothamBlack
	bbLabel.TextSize = 28
	bbLabel.ZIndex = 52
	bbLabel.Parent = bigBadge

	local bbSub = Instance.new("TextLabel")
	bbSub.Size = UDim2.new(1, 0, 0, 16)
	bbSub.Position = UDim2.new(0, 0, 0, 42)
	bbSub.BackgroundTransparency = 1
	bbSub.Text = "LEVEL"
	bbSub.TextColor3 = Color3.fromRGB(148, 163, 184)
	bbSub.Font = Enum.Font.GothamBold
	bbSub.TextSize = 10
	bbSub.ZIndex = 52
	bbSub.Parent = bigBadge

	-- EXP Progress Details
	local expHeader = Instance.new("TextLabel")
	expHeader.Size = UDim2.new(1, -220, 0, 20)
	expHeader.Position = UDim2.new(0, 94, 0, 12)
	expHeader.BackgroundTransparency = 1
	expHeader.RichText = true
	expHeader.Text = string.format("⭐ Progres Menuju <b>Level %d</b>", pLevel + 1)
	expHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
	expHeader.Font = Enum.Font.GothamBold
	expHeader.TextSize = 14
	expHeader.TextXAlignment = Enum.TextXAlignment.Left
	expHeader.ZIndex = 51
	expHeader.Parent = statusCard

	local totalExpLabel = Instance.new("TextLabel")
	totalExpLabel.Size = UDim2.new(0, 120, 0, 20)
	totalExpLabel.Position = UDim2.new(1, -130, 0, 12)
	totalExpLabel.BackgroundTransparency = 1
	totalExpLabel.Text = string.format("Total XP: %s", formatNumber(totalExp))
	totalExpLabel.TextColor3 = Color3.fromRGB(234, 179, 8)
	totalExpLabel.Font = Enum.Font.GothamBold
	totalExpLabel.TextSize = 11
	totalExpLabel.TextXAlignment = Enum.TextXAlignment.Right
	totalExpLabel.ZIndex = 51
	totalExpLabel.Parent = statusCard

	-- Progress Bar
	local pBarBg = Instance.new("Frame")
	pBarBg.Size = UDim2.new(1, -104, 0, 12)
	pBarBg.Position = UDim2.new(0, 94, 0, 38)
	pBarBg.BackgroundColor3 = Color3.fromRGB(10, 16, 26)
	pBarBg.BorderSizePixel = 0
	pBarBg.ZIndex = 51
	pBarBg.Parent = statusCard
	Instance.new("UICorner", pBarBg).CornerRadius = UDim.new(1, 0)

	local pBarFill = Instance.new("Frame")
	pBarFill.Size = UDim2.new(prog.progressPercent, 0, 1, 0)
	pBarFill.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
	pBarFill.BorderSizePixel = 0
	pBarFill.ZIndex = 52
	pBarFill.Parent = pBarBg
	Instance.new("UICorner", pBarFill).CornerRadius = UDim.new(1, 0)

	local expSubText = Instance.new("TextLabel")
	expSubText.Size = UDim2.new(1, -104, 0, 18)
	expSubText.Position = UDim2.new(0, 94, 0, 56)
	expSubText.BackgroundTransparency = 1
	expSubText.Text = string.format("%s / %s EXP (%d%%) • Sisa %s EXP lagi untuk naik level",
		formatNumber(prog.currentLevelExp),
		formatNumber(prog.nextLevelExp),
		math.floor(prog.progressPercent * 100),
		formatNumber(prog.nextLevelExp - prog.currentLevelExp)
	)
	expSubText.TextColor3 = Color3.fromRGB(148, 163, 184)
	expSubText.Font = Enum.Font.GothamMedium
	expSubText.TextSize = 10
	expSubText.TextXAlignment = Enum.TextXAlignment.Left
	expSubText.ZIndex = 51
	expSubText.Parent = statusCard

	-- ============ 2. INSTRUMENTS MASTERY SECTION ============
	local instSectionTitle = Instance.new("TextLabel")
	instSectionTitle.Size = UDim2.new(1, -48, 0, 20)
	instSectionTitle.Position = UDim2.new(0, 24, 0, 160)
	instSectionTitle.BackgroundTransparency = 1
	instSectionTitle.Text = "🎵 PENGUASAAN INSTRUMEN RITME:"
	instSectionTitle.TextColor3 = Color3.fromRGB(203, 213, 225)
	instSectionTitle.Font = Enum.Font.GothamBold
	instSectionTitle.TextSize = 12
	instSectionTitle.TextXAlignment = Enum.TextXAlignment.Left
	instSectionTitle.ZIndex = 50
	instSectionTitle.Parent = card

	local instGrid = Instance.new("Frame")
	instGrid.Name = "InstrumentsGrid"
	instGrid.Size = UDim2.new(1, -48, 0, 72)
	instGrid.Position = UDim2.new(0, 24, 0, 184)
	instGrid.BackgroundTransparency = 1
	instGrid.ZIndex = 50
	instGrid.Parent = card

	local igLayout = Instance.new("UIGridLayout")
	igLayout.CellSize = UDim2.new(0.318, 0, 1, 0)
	igLayout.CellPadding = UDim2.new(0.023, 0, 0, 0)
	igLayout.Parent = instGrid

	local instrumentsList = {
		{ id = "PIANO", name = "Piano Tiles", icon = "🎹", levelReq = 1, mechanic = "Multi-Lane Precision", keybinds = "A, W, S, D", color = Color3.fromRGB(0, 210, 255) },
		{ id = "GUITAR", name = "Guitar Fretboard", icon = "🎸", levelReq = 2, mechanic = "Fretboard Pattern", keybinds = "A, S, D", color = Color3.fromRGB(245, 158, 11) },
		{ id = "DRUM", name = "Drum Beat Pulse", icon = "🥁", levelReq = 4, mechanic = "Concentric Beat", keybinds = "SPACE / D / K", color = Color3.fromRGB(239, 68, 68) },
	}

	for _, inst in ipairs(instrumentsList) do
		local isUnlocked = table.find(unlockedInsts, inst.id) ~= nil or (pLevel >= inst.levelReq)

		local iCard = Instance.new("Frame")
		iCard.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
		iCard.BorderSizePixel = 0
		iCard.ZIndex = 51
		iCard.Parent = instGrid
		Instance.new("UICorner", iCard).CornerRadius = UDim.new(0, 10)

		local iStroke = Instance.new("UIStroke")
		iStroke.Color = isUnlocked and inst.color or Color3.fromRGB(40, 55, 80)
		iStroke.Thickness = isUnlocked and 1.2 or 0.8
		iStroke.Transparency = isUnlocked and 0.2 or 0.6
		iStroke.Parent = iCard

		local iIcon = Instance.new("TextLabel")
		iIcon.Size = UDim2.new(0, 32, 0, 32)
		iIcon.Position = UDim2.new(0, 8, 0, 8)
		iIcon.BackgroundTransparency = 1
		iIcon.Text = inst.icon
		iIcon.Font = Enum.Font.GothamBlack
		iIcon.TextSize = 22
		iIcon.ZIndex = 52
		iIcon.Parent = iCard

		local iTitle = Instance.new("TextLabel")
		iTitle.Size = UDim2.new(1, -48, 0, 16)
		iTitle.Position = UDim2.new(0, 44, 0, 8)
		iTitle.BackgroundTransparency = 1
		iTitle.Text = inst.name
		iTitle.TextColor3 = isUnlocked and inst.color or Color3.fromRGB(148, 163, 184)
		iTitle.Font = Enum.Font.GothamBlack
		iTitle.TextSize = 11
		iTitle.TextXAlignment = Enum.TextXAlignment.Left
		iTitle.ZIndex = 52
		iTitle.Parent = iCard

		local iStatus = Instance.new("TextLabel")
		iStatus.Size = UDim2.new(1, -48, 0, 14)
		iStatus.Position = UDim2.new(0, 44, 0, 24)
		iStatus.BackgroundTransparency = 1
		iStatus.Text = isUnlocked and "✅ Terbuka & Aktif" or string.format("🔒 Terbuka di Lv. %d", inst.levelReq)
		iStatus.TextColor3 = isUnlocked and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(248, 113, 113)
		iStatus.Font = Enum.Font.GothamBold
		iStatus.TextSize = 9
		iStatus.TextXAlignment = Enum.TextXAlignment.Left
		iStatus.ZIndex = 52
		iStatus.Parent = iCard

		local iMech = Instance.new("TextLabel")
		iMech.Size = UDim2.new(1, -16, 0, 16)
		iMech.Position = UDim2.new(0, 8, 0, 48)
		iMech.BackgroundTransparency = 1
		iMech.Text = string.format("🎮 %s • [%s]", inst.mechanic, inst.keybinds)
		iMech.TextColor3 = Color3.fromRGB(148, 163, 184)
		iMech.Font = Enum.Font.GothamMedium
		iMech.TextSize = 9
		iMech.TextXAlignment = Enum.TextXAlignment.Left
		iMech.ZIndex = 52
		iMech.Parent = iCard
	end

	-- ============ 3. MILESTONES TIMELINE SCROLL ============
	local mlTitle = Instance.new("TextLabel")
	mlTitle.Size = UDim2.new(1, -48, 0, 20)
	mlTitle.Position = UDim2.new(0, 24, 0, 266)
	mlTitle.BackgroundTransparency = 1
	mlTitle.Text = "🗺️ JALUR MILESTONE & HADIAH TINGKAT:"
	mlTitle.TextColor3 = Color3.fromRGB(203, 213, 225)
	mlTitle.Font = Enum.Font.GothamBold
	mlTitle.TextSize = 12
	mlTitle.TextXAlignment = Enum.TextXAlignment.Left
	mlTitle.ZIndex = 50
	mlTitle.Parent = card

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "MilestonesScroll"
	scroll.Size = UDim2.new(1, -48, 0, 250)
	scroll.Position = UDim2.new(0, 24, 0, 290)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.ScrollBarImageColor3 = Color3.fromRGB(14, 165, 233)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = 50
	scroll.Parent = card

	local sLayout = Instance.new("UIListLayout")
	sLayout.Padding = UDim.new(0, 8)
	sLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sLayout.Parent = scroll

	for idx, m in ipairs(MILESTONES) do
		local isCompleted = (pLevel >= m.level)
		local isNext = (pLevel == m.level - 1)

		local mCard = Instance.new("Frame")
		mCard.Name = "Milestone_" .. m.level
		mCard.Size = UDim2.new(1, -10, 0, 64)
		mCard.BackgroundColor3 = isCompleted and Color3.fromRGB(18, 28, 44) or (isNext and Color3.fromRGB(28, 36, 52) or Color3.fromRGB(14, 20, 32))
		mCard.BorderSizePixel = 0
		mCard.LayoutOrder = idx
		mCard.ZIndex = 51
		mCard.Parent = scroll
		Instance.new("UICorner", mCard).CornerRadius = UDim.new(0, 10)

		local mStroke = Instance.new("UIStroke")
		mStroke.Color = isCompleted and Color3.fromRGB(34, 197, 94) or (isNext and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(40, 55, 80))
		mStroke.Thickness = (isNext or isCompleted) and 1.2 or 0.8
		mStroke.Transparency = isCompleted and 0.4 or (isNext and 0.1 or 0.7)
		mStroke.Parent = mCard

		-- Level Pill Badge on Left
		local lBadge = Instance.new("Frame")
		lBadge.Size = UDim2.new(0, 48, 0, 48)
		lBadge.Position = UDim2.new(0, 8, 0.5, -24)
		lBadge.BackgroundColor3 = isCompleted and Color3.fromRGB(15, 60, 45) or (isNext and Color3.fromRGB(55, 45, 15) or Color3.fromRGB(20, 26, 38))
		lBadge.BorderSizePixel = 0
		lBadge.ZIndex = 52
		lBadge.Parent = mCard
		Instance.new("UICorner", lBadge).CornerRadius = UDim.new(0, 8)

		local lText = Instance.new("TextLabel")
		lText.Size = UDim2.new(1, 0, 1, 0)
		lText.BackgroundTransparency = 1
		lText.Text = string.format("Lv.%d", m.level)
		lText.TextColor3 = isCompleted and Color3.fromRGB(74, 222, 128) or (isNext and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(148, 163, 184))
		lText.Font = Enum.Font.GothamBlack
		lText.TextSize = 11
		lText.ZIndex = 53
		lText.Parent = lBadge

		-- Milestone Info
		local mTitleLabel = Instance.new("TextLabel")
		mTitleLabel.Size = UDim2.new(0.68, 0, 0, 18)
		mTitleLabel.Position = UDim2.new(0, 66, 0, 10)
		mTitleLabel.BackgroundTransparency = 1
		mTitleLabel.Text = m.title
		mTitleLabel.TextColor3 = isCompleted and Color3.fromRGB(255, 255, 255) or (isNext and Color3.fromRGB(253, 224, 71) or Color3.fromRGB(180, 195, 215))
		mTitleLabel.Font = Enum.Font.GothamBold
		mTitleLabel.TextSize = 12
		mTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		mTitleLabel.ZIndex = 52
		mTitleLabel.Parent = mCard

		local mDescLabel = Instance.new("TextLabel")
		mDescLabel.Size = UDim2.new(0.68, 0, 0, 28)
		mDescLabel.Position = UDim2.new(0, 66, 0, 28)
		mDescLabel.BackgroundTransparency = 1
		mDescLabel.Text = m.desc
		mDescLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
		mDescLabel.Font = Enum.Font.GothamMedium
		mDescLabel.TextSize = 10
		mDescLabel.TextWrapped = true
		mDescLabel.TextXAlignment = Enum.TextXAlignment.Left
		mDescLabel.TextYAlignment = Enum.TextYAlignment.Top
		mDescLabel.ZIndex = 52
		mDescLabel.Parent = mCard

		-- Status Pill on Right
		local sBadge = Instance.new("Frame")
		sBadge.Size = UDim2.new(0, 110, 0, 26)
		sBadge.Position = UDim2.new(1, -120, 0.5, -13)
		sBadge.BackgroundColor3 = isCompleted and Color3.fromRGB(20, 45, 35) or (isNext and Color3.fromRGB(45, 38, 15) or Color3.fromRGB(25, 25, 35))
		sBadge.BorderSizePixel = 0
		sBadge.ZIndex = 52
		sBadge.Parent = mCard
		Instance.new("UICorner", sBadge).CornerRadius = UDim.new(0, 6)

		local sText = Instance.new("TextLabel")
		sText.Size = UDim2.new(1, 0, 1, 0)
		sText.BackgroundTransparency = 1
		sText.Text = isCompleted and "✅ TERCAPAI" or (isNext and "⚡ BERIKUTNYA" or "🔒 TERKUNCI")
		sText.TextColor3 = isCompleted and Color3.fromRGB(74, 222, 128) or (isNext and Color3.fromRGB(251, 191, 36) or Color3.fromRGB(148, 163, 184))
		sText.Font = Enum.Font.GothamBold
		sText.TextSize = 10
		sText.ZIndex = 53
		sText.Parent = sBadge
	end

	-- Entrance Animation
	card.Size = UDim2.new(0, 660, 0, 510)
	card.Position = UDim2.new(0.5, 0, 0.54, 0)
	card.BackgroundTransparency = 1

	TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.5,
	}):Play()

	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 720, 0, 560),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0.1,
	}):Play()
end

return ProgressionRoadmapUI
