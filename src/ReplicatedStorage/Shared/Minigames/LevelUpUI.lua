--[[
	LevelUpUI (ModuleScript)
	FISH!TUNE — Level-Up Celebration & Milestone Unlocks Modal (FISH-032)

	Layar Perayaan Naik Level (Level Up Celebration Screen) Glassmorphism Premium:
	1. Visual Fanfare & Aura Bercahaya Emas (Golden Glow Rings & Particle Burst).
	2. Transisi Level Dinamis: [Lv. X] ➔ [Lv. Y] dengan efek scale tween.
	3. Showcase Fitur & Hadiah Baru yang Terbuka (Unlocked Instruments, Rods, Bag Tiers).
	4. Tombol Aksi Cepat:
	   - [✨ LANJUTKAN MEMANCING] -> Tutup modal dan lanjutkan memancing.
	   - [🛍️ LIHAT DI TOKO] -> Tutup modal & buka Toko Samudra langsung ke item baru.
	5. Sound effects fanfare terintegrasi dan safe dismiss (klik di luar atau hotkey).
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local MobileResponsiveHelper = require(Shared:WaitForChild("Systems"):WaitForChild("MobileResponsiveHelper"))

local LevelUpUI = {}
local activeModal = nil
local activeOverlay = nil
local isClosing = false

-- ============ SOUND HELPER ============
local function playLocalSound(soundId, volume, speed)
	task.spawn(function()
		local snd = Instance.new("Sound")
		snd.SoundId = soundId
		snd.Volume = volume or 0.85
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

-- ============ GET UNLOCKS FOR LEVEL ============
local function getUnlocksForLevel(newLevel)
	local unlocks = {}

	-- 1. Cek Pembukaan Instrumen Utama
	if newLevel == 2 then
		table.insert(unlocks, {
			type = "INSTRUMENT",
			icon = "🎸",
			badge = "🎸 GUITAR UNLOCKED",
			title = "Minigame Gitar Akustik Terbuka!",
			desc = "Mainkan alunan ritem fretboard & petikan senar dengan joran bertipe gitar.",
			color = Color3.fromRGB(245, 158, 11),
		})
	elseif newLevel == 4 then
		table.insert(unlocks, {
			type = "INSTRUMENT",
			icon = "🥁",
			badge = "🥁 DRUM UNLOCKED",
			title = "Minigame Drum Perkusi Terbuka!",
			desc = "Uji kecepatan respon pada gelombang ketukan perkusi rimba.",
			color = Color3.fromRGB(239, 68, 68),
		})
	end

	-- 2. Cek Joran Baru yang Siap Dibeli
	for _, rod in ipairs(EconomyConfig.RODS) do
		if rod.levelReq == newLevel and rod.price > 0 then
			local instData = InstrumentDefinitions.GetInstrumentData(rod.instrumentType)
			table.insert(unlocks, {
				type = "ROD",
				icon = (instData and instData.icon) or "🎣",
				badge = rod.badge or "JORAN BARU",
				title = rod.name,
				desc = string.format("Tersedia di Toko • +%d Luck • Harga: %d Koin", rod.luckBonus or 5, rod.price or 0),
				color = (instData and instData.color) or Color3.fromRGB(56, 189, 248),
				rodId = rod.id,
			})
		end
	end

	-- 3. Cek Upgrade Tas Baru
	for _, bag in ipairs(EconomyConfig.BAG_UPGRADES) do
		if bag.levelReq == newLevel then
			table.insert(unlocks, {
				type = "BAG",
				icon = "🎒",
				badge = bag.badge or "UPGRADE TAS",
				title = bag.name,
				desc = string.format("Kapasitas Tas +%d Slot (Total: %d Slot) • %d Koin", bag.extraSlots or 5, bag.totalSlots or 40, bag.price or 0),
				color = Color3.fromRGB(168, 85, 247),
			})
		end
	end

	-- 4. Fallback jika tidak ada item spesifik
	if #unlocks == 0 then
		table.insert(unlocks, {
			type = "PERK",
			icon = "⭐",
			badge = "PROGRESI",
			title = string.format("Keahlian Memancing Level %d", newLevel),
			desc = "Peluang menangkap ikan berbobot lebih besar & ketahanan strike meningkat!",
			color = Color3.fromRGB(251, 191, 36),
		})
	end

	return unlocks
end

-- ============ HIDE / CLOSE MODAL ============
function LevelUpUI.Hide(callback)
	if isClosing or not activeModal or not activeOverlay then
		if callback then callback() end
		return
	end

	isClosing = true
	local card = activeModal
	local overlay = activeOverlay

	local closeTween = TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 480, 0, 420),
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

function LevelUpUI.IsOpen()
	return activeOverlay ~= nil and activeOverlay.Parent ~= nil
end

-- ============ SHOW MODAL ============
function LevelUpUI.Show(targetGui, newLevel, oldLevel, playerData, onAction)
	if not targetGui then return end

	newLevel = math.max(1, math.floor(tonumber(newLevel) or 2))
	oldLevel = math.max(1, math.floor(tonumber(oldLevel) or (newLevel - 1)))

	if activeOverlay then
		activeOverlay:Destroy()
		activeOverlay = nil
		activeModal = nil
		isClosing = false
	end

	-- Suara perayaan Level Up Fanfare
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 1.8)
	task.delay(0.12, function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 2.2)
	end)

	local unlocks = getUnlocksForLevel(newLevel)

	-- 1. Backdrop Overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "LevelUpOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(6, 10, 20)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 50
	overlay.Parent = targetGui
	activeOverlay = overlay

	-- 2. Card Modal
	local card = Instance.new("Frame")
	card.Name = "LevelUpCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Size = UDim2.new(0, 520, 0, 480)
	card.Position = UDim2.new(0.5, 0, 0.54, 0)
	card.BackgroundColor3 = Color3.fromRGB(15, 23, 38)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel = 0
	card.ZIndex = 51
	card.Parent = overlay
	activeModal = card
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)

	-- Responsive Auto-Fit untuk Layar HP / Tablet (FISH-037)
	MobileResponsiveHelper.AttachResponsiveScale(card, 520, 480)

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(234, 179, 8)
	cardStroke.Thickness = 2.2
	cardStroke.Transparency = 0.2
	cardStroke.Parent = card

	-- Top Header Glow Ray
	local topGlow = Instance.new("Frame")
	topGlow.Name = "TopGlow"
	topGlow.Size = UDim2.new(1, 0, 0, 110)
	topGlow.Position = UDim2.new(0, 0, 0, 0)
	topGlow.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
	topGlow.BackgroundTransparency = 0.92
	topGlow.BorderSizePixel = 0
	topGlow.ZIndex = 52
	topGlow.Parent = card
	Instance.new("UICorner", topGlow).CornerRadius = UDim.new(0, 18)

	-- Star Header Icon
	local starHeader = Instance.new("TextLabel")
	starHeader.Size = UDim2.new(1, 0, 0, 32)
	starHeader.Position = UDim2.new(0, 0, 0, 16)
	starHeader.BackgroundTransparency = 1
	starHeader.Text = "⭐ ⭐ ⭐"
	starHeader.TextColor3 = Color3.fromRGB(253, 224, 71)
	starHeader.Font = Enum.Font.GothamBlack
	starHeader.TextSize = 22
	starHeader.ZIndex = 53
	starHeader.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Position = UDim2.new(0, 0, 0, 44)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "LEVEL UP!"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 26
	titleLabel.ZIndex = 53
	titleLabel.Parent = card

	-- Transition Badge: [Lv. X] ➔ [Lv. Y]
	local transBadge = Instance.new("Frame")
	transBadge.Size = UDim2.new(0, 240, 0, 38)
	transBadge.Position = UDim2.new(0.5, -120, 0, 80)
	transBadge.BackgroundColor3 = Color3.fromRGB(24, 34, 52)
	transBadge.BorderSizePixel = 0
	transBadge.ZIndex = 53
	transBadge.Parent = card
	Instance.new("UICorner", transBadge).CornerRadius = UDim.new(0, 10)

	local tbStroke = Instance.new("UIStroke")
	tbStroke.Color = Color3.fromRGB(234, 179, 8)
	tbStroke.Thickness = 1.4
	tbStroke.Parent = transBadge

	local transLabel = Instance.new("TextLabel")
	transLabel.Size = UDim2.new(1, 0, 1, 0)
	transLabel.BackgroundTransparency = 1
	transLabel.RichText = true
	transLabel.Text = string.format("<font color=\"#94A3B8\">Lv. %d</font>  ➔  <font color=\"#FACC15\"><b>Lv. %d</b></font>", oldLevel, newLevel)
	transLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	transLabel.Font = Enum.Font.GothamBlack
	transLabel.TextSize = 16
	transLabel.ZIndex = 54
	transLabel.Parent = transBadge

	-- Subtitle Unlocks
	local subTitle = Instance.new("TextLabel")
	subTitle.Size = UDim2.new(1, -40, 0, 20)
	subTitle.Position = UDim2.new(0, 20, 0, 130)
	subTitle.BackgroundTransparency = 1
	subTitle.Text = "🎁 FITUR & HADIAH TERBUKA:"
	subTitle.TextColor3 = Color3.fromRGB(203, 213, 225)
	subTitle.Font = Enum.Font.GothamBold
	subTitle.TextSize = 12
	subTitle.TextXAlignment = Enum.TextXAlignment.Left
	subTitle.ZIndex = 53
	subTitle.Parent = card

	-- Unlocks Scroll/Container
	local unlocksScroll = Instance.new("ScrollingFrame")
	unlocksScroll.Name = "UnlocksList"
	unlocksScroll.Size = UDim2.new(1, -40, 0, 250)
	unlocksScroll.Position = UDim2.new(0, 20, 0, 156)
	unlocksScroll.BackgroundTransparency = 1
	unlocksScroll.BorderSizePixel = 0
	unlocksScroll.ScrollBarThickness = 4
	unlocksScroll.ScrollBarImageColor3 = Color3.fromRGB(234, 179, 8)
	unlocksScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	unlocksScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	unlocksScroll.ZIndex = 53
	unlocksScroll.Parent = card

	local uLayout = Instance.new("UIListLayout")
	uLayout.Padding = UDim.new(0, 10)
	uLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uLayout.Parent = unlocksScroll

	for idx, item in ipairs(unlocks) do
		local uCard = Instance.new("Frame")
		uCard.Name = "UnlockCard_" .. idx
		uCard.Size = UDim2.new(1, -6, 0, 72)
		uCard.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
		uCard.BorderSizePixel = 0
		uCard.LayoutOrder = idx
		uCard.ZIndex = 54
		uCard.Parent = unlocksScroll
		Instance.new("UICorner", uCard).CornerRadius = UDim.new(0, 12)

		local uStroke = Instance.new("UIStroke")
		uStroke.Color = item.color or Color3.fromRGB(56, 189, 248)
		uStroke.Thickness = 1.2
		uStroke.Transparency = 0.3
		uStroke.Parent = uCard

		-- Left Icon
		local iBox = Instance.new("Frame")
		iBox.Size = UDim2.new(0, 52, 0, 52)
		iBox.Position = UDim2.new(0, 10, 0.5, -26)
		iBox.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
		iBox.BorderSizePixel = 0
		iBox.ZIndex = 55
		iBox.Parent = uCard
		Instance.new("UICorner", iBox).CornerRadius = UDim.new(0, 8)

		local iLbl = Instance.new("TextLabel")
		iLbl.Size = UDim2.new(1, 0, 1, 0)
		iLbl.BackgroundTransparency = 1
		iLbl.Text = item.icon or "✨"
		iLbl.Font = Enum.Font.GothamBlack
		iLbl.TextSize = 24
		iLbl.ZIndex = 56
		iLbl.Parent = iBox

		-- Title & Badge
		local tLbl = Instance.new("TextLabel")
		tLbl.Size = UDim2.new(1, -74, 0, 18)
		tLbl.Position = UDim2.new(0, 70, 0, 10)
		tLbl.BackgroundTransparency = 1
		tLbl.Text = item.title or ""
		tLbl.TextColor3 = item.color or Color3.fromRGB(255, 255, 255)
		tLbl.Font = Enum.Font.GothamBlack
		tLbl.TextSize = 13
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.ZIndex = 55
		tLbl.Parent = uCard

		local dLbl = Instance.new("TextLabel")
		dLbl.Size = UDim2.new(1, -74, 0, 32)
		dLbl.Position = UDim2.new(0, 70, 0, 30)
		dLbl.BackgroundTransparency = 1
		dLbl.Text = item.desc or ""
		dLbl.TextColor3 = Color3.fromRGB(203, 213, 225)
		dLbl.Font = Enum.Font.GothamMedium
		dLbl.TextSize = 11
		dLbl.TextWrapped = true
		dLbl.TextXAlignment = Enum.TextXAlignment.Left
		dLbl.TextYAlignment = Enum.TextYAlignment.Top
		dLbl.ZIndex = 55
		dLbl.Parent = uCard
	end

	-- Bottom Actions Bar
	local bottomBar = Instance.new("Frame")
	bottomBar.Size = UDim2.new(1, -40, 0, 44)
	bottomBar.Position = UDim2.new(0, 20, 1, -56)
	bottomBar.BackgroundTransparency = 1
	bottomBar.ZIndex = 53
	bottomBar.Parent = card

	local hasShopItem = false
	for _, u in ipairs(unlocks) do
		if u.type == "ROD" or u.type == "BAG" or u.type == "INSTRUMENT" then
			hasShopItem = true
			break
		end
	end

	local contBtn = Instance.new("TextButton")
	contBtn.Name = "ContinueBtn"
	contBtn.Size = UDim2.new(hasShopItem and 0.48 or 1, 0, 1, 0)
	contBtn.Position = UDim2.new(0, 0, 0, 0)
	contBtn.BackgroundColor3 = Color3.fromRGB(2, 132, 199)
	contBtn.BorderSizePixel = 0
	contBtn.Text = "✨ LANJUTKAN MEMANCING"
	contBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	contBtn.Font = Enum.Font.GothamBlack
	contBtn.TextSize = 12
	contBtn.ZIndex = 54
	contBtn.Parent = bottomBar
	Instance.new("UICorner", contBtn).CornerRadius = UDim.new(0, 10)

	contBtn.MouseButton1Click:Connect(function()
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
		LevelUpUI.Hide(function()
			if onAction then onAction("CONTINUE") end
		end)
	end)

	if hasShopItem then
		local shopBtn = Instance.new("TextButton")
		shopBtn.Name = "ShopBtn"
		shopBtn.Size = UDim2.new(0.48, 0, 1, 0)
		shopBtn.Position = UDim2.new(0.52, 0, 0, 0)
		shopBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
		shopBtn.BorderSizePixel = 0
		shopBtn.Text = "🛍️ BUKA TOKO"
		shopBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
		shopBtn.Font = Enum.Font.GothamBlack
		shopBtn.TextSize = 12
		shopBtn.ZIndex = 54
		shopBtn.Parent = bottomBar
		Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 10)

		shopBtn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
			LevelUpUI.Hide(function()
				if onAction then onAction("OPEN_SHOP") end
			end)
		end)
	end

	-- Entrance Animation
	card.Size = UDim2.new(0, 460, 0, 420)
	card.Position = UDim2.new(0.5, 0, 0.56, 0)
	card.BackgroundTransparency = 1

	TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.45,
	}):Play()

	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 520, 0, 480),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0.1,
	}):Play()
end

return LevelUpUI
