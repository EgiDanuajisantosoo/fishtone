--[[
	EconomyHUD (ModuleScript)
	FISH!TUNE — Central Top Economy & Progression HUD Widget (FISH-026)

	Widget HUD Terpusat untuk Status Ekonomi & Progresi Pemain:
	1. Coin Dashboard: Saldo koin real-time dengan animasi angka count-up & pulse glow.
	2. Level & EXP Progress Bar: Level badge, bar EXP bertransisi halus, dan persentase level up.
	3. Luck Indicator: Total Luck aktif (Joran + Umpan + Rhythm Streak Performance).
	4. Bag Capacity Pill: Kapasitas tas dinamis (Terisi / Maksimum Slot).
	5. Transaction Mini-Receipt Popup: Pop-up notifikasi transaksi instan saat jual/beli.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))

local EconomyHUD = {}

-- UI Components
local hudContainer = nil
local coinLabel = nil
local coinPill = nil
local levelBadge = nil
local expFillBar = nil
local expTextLabel = nil
local luckPillLabel = nil
local bagPillLabel = nil
local receiptContainer = nil

-- Cached State
local displayedCoins = 0
local targetCoins = 0
local isCountUpRunning = false
local currentLevel = 1
local currentExp = 0

-- ============ FORMAT NUMBERS ============
local function formatNumber(n)
	n = math.floor(tonumber(n) or 0)
	local str = tostring(n)
	return str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- ============ CREATE HUD ============
function EconomyHUD.Create(targetGui)
	if hudContainer and hudContainer.Parent then
		return hudContainer
	end

	-- 1. Main Top-Right Container
	hudContainer = Instance.new("Frame")
	hudContainer.Name = "EconomyHUD"
	hudContainer.AnchorPoint = Vector2.new(1, 0)
	hudContainer.Size = UDim2.new(0, 480, 0, 42)
	hudContainer.Position = UDim2.new(1, -20, 0, 16)
	hudContainer.BackgroundTransparency = 1
	hudContainer.ZIndex = 25
	hudContainer.Parent = targetGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = hudContainer

	-- ============ PILL 1: LUCK INDICATOR ============
	local luckPill = Instance.new("Frame")
	luckPill.Name = "LuckPill"
	luckPill.Size = UDim2.new(0, 0, 0, 36)
	luckPill.AutomaticSize = Enum.AutomaticSize.X
	luckPill.BackgroundColor3 = Color3.fromRGB(15, 24, 38)
	luckPill.BackgroundTransparency = 0.25
	luckPill.BorderSizePixel = 0
	luckPill.LayoutOrder = 1
	luckPill.ZIndex = 26
	luckPill.Parent = hudContainer
	Instance.new("UICorner", luckPill).CornerRadius = UDim.new(0, 10)

	local lStroke = Instance.new("UIStroke")
	lStroke.Color = Color3.fromRGB(74, 222, 128)
	lStroke.Thickness = 1.4
	lStroke.Transparency = 0.4
	lStroke.Parent = luckPill

	local lPad = Instance.new("UIPadding")
	lPad.PaddingLeft = UDim.new(0, 10)
	lPad.PaddingRight = UDim.new(0, 10)
	lPad.Parent = luckPill

	luckPillLabel = Instance.new("TextLabel")
	luckPillLabel.Name = "Label"
	luckPillLabel.Size = UDim2.new(0, 0, 1, 0)
	luckPillLabel.AutomaticSize = Enum.AutomaticSize.X
	luckPillLabel.BackgroundTransparency = 1
	luckPillLabel.RichText = true
	luckPillLabel.Text = "🍀 <b>+5 Luck</b>"
	luckPillLabel.TextColor3 = Color3.fromRGB(134, 239, 172)
	luckPillLabel.Font = Enum.Font.GothamBold
	luckPillLabel.TextSize = 12
	luckPillLabel.ZIndex = 27
	luckPillLabel.Parent = luckPill

	-- ============ PILL 2: BAG CAPACITY ============
	local bagPill = Instance.new("Frame")
	bagPill.Name = "BagPill"
	bagPill.Size = UDim2.new(0, 0, 0, 36)
	bagPill.AutomaticSize = Enum.AutomaticSize.X
	bagPill.BackgroundColor3 = Color3.fromRGB(15, 24, 38)
	bagPill.BackgroundTransparency = 0.25
	bagPill.BorderSizePixel = 0
	bagPill.LayoutOrder = 2
	bagPill.ZIndex = 26
	bagPill.Parent = hudContainer
	Instance.new("UICorner", bagPill).CornerRadius = UDim.new(0, 10)

	local bStroke = Instance.new("UIStroke")
	bStroke.Color = Color3.fromRGB(56, 189, 248)
	bStroke.Thickness = 1.4
	bStroke.Transparency = 0.4
	bStroke.Parent = bagPill

	local bPad = Instance.new("UIPadding")
	bPad.PaddingLeft = UDim.new(0, 10)
	bPad.PaddingRight = UDim.new(0, 10)
	bPad.Parent = bagPill

	bagPillLabel = Instance.new("TextLabel")
	bagPillLabel.Name = "Label"
	bagPillLabel.Size = UDim2.new(0, 0, 1, 0)
	bagPillLabel.AutomaticSize = Enum.AutomaticSize.X
	bagPillLabel.BackgroundTransparency = 1
	bagPillLabel.RichText = true
	bagPillLabel.Text = "🎒 <b>0/35</b>"
	bagPillLabel.TextColor3 = Color3.fromRGB(186, 230, 253)
	bagPillLabel.Font = Enum.Font.GothamBold
	bagPillLabel.TextSize = 12
	bagPillLabel.ZIndex = 27
	bagPillLabel.Parent = bagPill

	-- ============ PILL 3: LEVEL & EXP PROGRESS ============
	local levelPill = Instance.new("Frame")
	levelPill.Name = "LevelPill"
	levelPill.Size = UDim2.new(0, 160, 0, 36)
	levelPill.BackgroundColor3 = Color3.fromRGB(15, 24, 38)
	levelPill.BackgroundTransparency = 0.25
	levelPill.BorderSizePixel = 0
	levelPill.LayoutOrder = 3
	levelPill.ZIndex = 26
	levelPill.Parent = hudContainer
	Instance.new("UICorner", levelPill).CornerRadius = UDim.new(0, 10)

	local lvStroke = Instance.new("UIStroke")
	lvStroke.Color = Color3.fromRGB(14, 165, 233)
	lvStroke.Thickness = 1.4
	lvStroke.Transparency = 0.4
	lvStroke.Parent = levelPill

	levelBadge = Instance.new("TextLabel")
	levelBadge.Name = "LevelBadge"
	levelBadge.Size = UDim2.new(0, 48, 1, 0)
	levelBadge.Position = UDim2.new(0, 6, 0, 0)
	levelBadge.BackgroundTransparency = 1
	levelBadge.Text = "Lv. 1"
	levelBadge.TextColor3 = Color3.fromRGB(56, 189, 248)
	levelBadge.Font = Enum.Font.GothamBlack
	levelBadge.TextSize = 12
	levelBadge.ZIndex = 27
	levelBadge.Parent = levelPill

	local expBarBg = Instance.new("Frame")
	expBarBg.Name = "ExpBarBg"
	expBarBg.Size = UDim2.new(1, -62, 0, 8)
	expBarBg.Position = UDim2.new(0, 54, 0, 8)
	expBarBg.BackgroundColor3 = Color3.fromRGB(10, 16, 26)
	expBarBg.BorderSizePixel = 0
	expBarBg.ZIndex = 27
	expBarBg.Parent = levelPill
	Instance.new("UICorner", expBarBg).CornerRadius = UDim.new(1, 0)

	expFillBar = Instance.new("Frame")
	expFillBar.Name = "ExpFill"
	expFillBar.Size = UDim2.new(0, 0, 1, 0)
	expFillBar.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
	expFillBar.BorderSizePixel = 0
	expFillBar.ZIndex = 28
	expFillBar.Parent = expBarBg
	Instance.new("UICorner", expFillBar).CornerRadius = UDim.new(1, 0)

	expTextLabel = Instance.new("TextLabel")
	expTextLabel.Name = "ExpText"
	expTextLabel.Size = UDim2.new(1, -62, 0, 14)
	expTextLabel.Position = UDim2.new(0, 54, 0, 18)
	expTextLabel.BackgroundTransparency = 1
	expTextLabel.Text = "0 / 100 EXP (0%)"
	expTextLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	expTextLabel.Font = Enum.Font.GothamMedium
	expTextLabel.TextSize = 9
	expTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	expTextLabel.ZIndex = 27
	expTextLabel.Parent = levelPill

	-- ============ PILL 4: COINS DASHBOARD ============
	coinPill = Instance.new("Frame")
	coinPill.Name = "CoinPill"
	coinPill.Size = UDim2.new(0, 0, 0, 36)
	coinPill.AutomaticSize = Enum.AutomaticSize.X
	coinPill.BackgroundColor3 = Color3.fromRGB(15, 24, 38)
	coinPill.BackgroundTransparency = 0.2
	coinPill.BorderSizePixel = 0
	coinPill.LayoutOrder = 4
	coinPill.ZIndex = 26
	coinPill.Parent = hudContainer
	Instance.new("UICorner", coinPill).CornerRadius = UDim.new(0, 10)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(234, 179, 8)
	cStroke.Thickness = 1.6
	cStroke.Transparency = 0.3
	cStroke.Parent = coinPill

	local cPad = Instance.new("UIPadding")
	cPad.PaddingLeft = UDim.new(0, 12)
	cPad.PaddingRight = UDim.new(0, 12)
	cPad.Parent = coinPill

	coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.Size = UDim2.new(0, 0, 1, 0)
	coinLabel.AutomaticSize = Enum.AutomaticSize.X
	coinLabel.BackgroundTransparency = 1
	coinLabel.RichText = true
	coinLabel.Text = "💰 <b>0</b>"
	coinLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
	coinLabel.Font = Enum.Font.GothamBlack
	coinLabel.TextSize = 14
	coinLabel.ZIndex = 27
	coinLabel.Parent = coinPill

	-- ============ RECEIPT NOTIFICATION CONTAINER ============
	receiptContainer = Instance.new("Frame")
	receiptContainer.Name = "ReceiptContainer"
	receiptContainer.AnchorPoint = Vector2.new(1, 0)
	receiptContainer.Size = UDim2.new(0, 260, 0, 200)
	receiptContainer.Position = UDim2.new(1, -20, 0, 64)
	receiptContainer.BackgroundTransparency = 1
	receiptContainer.ZIndex = 35
	receiptContainer.Parent = targetGui

	local rLayout = Instance.new("UIListLayout")
	rLayout.FillDirection = Enum.FillDirection.Vertical
	rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	rLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	rLayout.Padding = UDim.new(0, 6)
	rLayout.Parent = receiptContainer

	return hudContainer
end

-- ============ COUNT-UP COINS ANIMATION ============
local function animateCoinsTo(target)
	target = math.max(0, math.floor(tonumber(target) or 0))
	targetCoins = target

	if isCountUpRunning then return end
	isCountUpRunning = true

	task.spawn(function()
		while math.abs(targetCoins - displayedCoins) > 0 do
			local diff = targetCoins - displayedCoins
			local step = math.ceil(math.abs(diff) / 6)
			if diff > 0 then
				displayedCoins = math.min(targetCoins, displayedCoins + step)
			else
				displayedCoins = math.max(targetCoins, displayedCoins - step)
			end

			if coinLabel then
				coinLabel.Text = string.format("💰 <b>%s</b>", formatNumber(displayedCoins))
			end
			task.wait(0.03)
		end

		displayedCoins = targetCoins
		if coinLabel then
			coinLabel.Text = string.format("💰 <b>%s</b>", formatNumber(displayedCoins))
		end
		isCountUpRunning = false
	end)
end

-- ============ PULSE COIN PILL ============
local function pulseCoinPill(isPositive)
	if not coinPill then return end
	local color = isPositive and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(248, 113, 113)

	local stroke = coinPill:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
		stroke.Thickness = 2.4
		TweenService:Create(stroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Color = Color3.fromRGB(234, 179, 8),
			Thickness = 1.6
		}):Play()
	end
end

-- ============ UPDATE ALL HUD STATE ============
function EconomyHUD.Update(playerData, optLootCount)
	if not hudContainer then return end
	playerData = playerData or {}

	-- 1. Update Coins
	local coins = math.max(0, tonumber(playerData.coins) or 0)
	if coins ~= targetCoins then
		pulseCoinPill(coins > targetCoins)
		animateCoinsTo(coins)
	else
		displayedCoins = coins
		if coinLabel then
			coinLabel.Text = string.format("💰 <b>%s</b>", formatNumber(coins))
		end
	end

	-- 2. Update Level & EXP
	local totalExp = math.max(0, tonumber(playerData.exp) or 0)
	local level, curExp, nextExp, percent = FishingRaritySystem.GetLevelFromTotalExp(totalExp)
	currentLevel = level
	currentExp = curExp

	if levelBadge then
		levelBadge.Text = string.format("Lv. %d", level)
	end
	if expFillBar then
		TweenService:Create(expFillBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(percent, 0, 1, 0)
		}):Play()
	end
	if expTextLabel then
		expTextLabel.Text = string.format("%d / %d EXP (%d%%)", curExp, nextExp, math.floor(percent * 100))
	end

	-- 3. Update Active Luck
	local equippedRodId = playerData.equippedRod or "StarterRod"
	local rodData = EconomyConfig.GetRod(equippedRodId)
	local rodLuck = rodData and rodData.luckBonus or 5

	local equippedBaitId = playerData.equippedBait
	local baitData = equippedBaitId and EconomyConfig.GetBait(equippedBaitId)
	local baitLuck = baitData and baitData.luckBonus or 0

	local streakLuck = math.floor((tonumber(playerData.prevPerformanceLuckBonus) or 0) * 10) / 10
	local totalLuck = rodLuck + baitLuck + streakLuck

	if luckPillLabel then
		luckPillLabel.Text = string.format("🍀 <b>+%d Luck</b>", totalLuck)
	end

	-- 4. Update Bag Capacity Pill
	local maxSlots = tonumber(playerData.maxInventorySlots) or 35
	local count = tonumber(optLootCount) or 0
	if bagPillLabel then
		bagPillLabel.Text = string.format("🎒 <b>%d/%d</b>", count, maxSlots)
	end
end

-- ============ SHOW MINI TRANSACTION RECEIPT ============
function EconomyHUD.ShowTransactionNotification(title, subtitle, isPositive)
	if not receiptContainer then return end

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 44)
	card.BackgroundColor3 = Color3.fromRGB(15, 23, 38)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.ZIndex = 36
	card.Parent = receiptContainer
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = isPositive and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(234, 179, 8)
	cStroke.Thickness = 1.4
	cStroke.Parent = card

	local tLabel = Instance.new("TextLabel")
	tLabel.Size = UDim2.new(1, -16, 0, 20)
	tLabel.Position = UDim2.new(0, 10, 0, 4)
	tLabel.BackgroundTransparency = 1
	tLabel.Text = title
	tLabel.TextColor3 = isPositive and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(251, 191, 36)
	tLabel.Font = Enum.Font.GothamBlack
	tLabel.TextSize = 12
	tLabel.TextXAlignment = Enum.TextXAlignment.Left
	tLabel.ZIndex = 37
	tLabel.Parent = card

	local sLabel = Instance.new("TextLabel")
	sLabel.Size = UDim2.new(1, -16, 0, 16)
	sLabel.Position = UDim2.new(0, 10, 0, 22)
	sLabel.BackgroundTransparency = 1
	sLabel.Text = subtitle or ""
	sLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
	sLabel.Font = Enum.Font.GothamMedium
	sLabel.TextSize = 10
	sLabel.TextXAlignment = Enum.TextXAlignment.Left
	sLabel.ZIndex = 37
	sLabel.Parent = card

	-- Slide In
	card.Position = UDim2.new(1, 20, 0, 0)
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()

	-- Auto Fade Out & Destroy
	task.delay(2.8, function()
		if card and card.Parent then
			local fade = TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, -20)
			})
			TweenService:Create(cStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
			TweenService:Create(tLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
			TweenService:Create(sLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
			fade:Play()
			fade.Completed:Connect(function()
				if card and card.Parent then card:Destroy() end
			end)
		end
	end)
end

return EconomyHUD
