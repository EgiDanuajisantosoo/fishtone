--[[
	FishingClient (Universal Water Fishing System with Server-Authoritative Sessions, Fish Inventory & Economy)
	Fitur:
	1. BAR MELEMPAR KAIL DINAMIS (RANDOMIZED CASTING TIMING BAR):
	   - Posisi zona PERFECT (Hijau Neon ⭐⭐⭐) dan GREAT (Cyan ⭐⭐) DIACAK SETIAP LEMPARAN.
	   - Lemparan PERFECT mempercepat waktu sambaran ikan & memberi bonus Luck ke server.
	2. Animasi Karakter Prosedural Lengkap (R15 & R6):
	   - Windup, Casting Swing, Idle Breathing Sway, Biting Tension, Reeling, Victory Lift.
	3. Tali Pancing Dinamis (Beam berkurva) dari ujung Joran ke Pelampung.
	4. Mini-game Piano Tiles Glassmorphism Anti-Spam & Blind Mystery.
	5. INTERAKTIF INVENTORY GUI & SISTEM JUAL IKAN:
	   - Tombol HUD & Hotkey [B] / [I] untuk membuka Inventory Ikan.
	   - Menampilkan seluruh ikan di Backpack dengan Rarity Badge, Bobot (Kg), dan Nilai Koin.
	   - Fitur "Jual Ikan" per item dan "Jual Semua Ikan" untuk menambah Koin pemain.
	6. Server-Authoritative Session & Catch Submission (Anti-Cheat).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local function getPlayerGui()
	return player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
end

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local remote = RemoteContract.GetRemote()
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local RhythmController = require(Shared:WaitForChild("Minigames"):WaitForChild("Rhythm"):WaitForChild("RhythmController"))
local PianoTilesGame = RhythmController
local FishingResultUI = require(Shared:WaitForChild("Minigames"):WaitForChild("FishingResultUI"))
local FishDexUI = require(Shared:WaitForChild("Minigames"):WaitForChild("FishDexUI"))
local ShopUI = require(Shared:WaitForChild("Minigames"):WaitForChild("ShopUI"))
local LevelUpUI = require(Shared:WaitForChild("Minigames"):WaitForChild("LevelUpUI"))
local ProgressionRoadmapUI = require(Shared:WaitForChild("Minigames"):WaitForChild("ProgressionRoadmapUI"))
local EconomyHUD = require(Shared:WaitForChild("Minigames"):WaitForChild("EconomyHUD"))
local TutorialUI = require(Shared:WaitForChild("Minigames"):WaitForChild("TutorialUI"))
local EconomyConfig = require(Shared:WaitForChild("Config"):WaitForChild("EconomyConfig"))
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local XPProgressionSystem = require(Shared:WaitForChild("Systems"):WaitForChild("XPProgressionSystem"))
local PitySystem = require(Shared:WaitForChild("Systems"):WaitForChild("PitySystem"))
local AudioEffectsSystem = require(Shared:WaitForChild("Systems"):WaitForChild("AudioEffectsSystem"))
local VisualEffectsSystem = require(Shared:WaitForChild("Systems"):WaitForChild("VisualEffectsSystem"))
local FishingStateMachine = require(Shared:WaitForChild("Systems"):WaitForChild("FishingStateMachine"))
local fsm = FishingStateMachine.new()
local fishTemplate = ReplicatedStorage:WaitForChild("AnimatedFish", 5)
local bobberTemplate = ReplicatedStorage:WaitForChild("BobberTemplate", 5)

local function getEquippedRodTool()
	local char = player.Character
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") and (item:GetAttribute("IsRod") == true or item.Name:lower():find("rod") or item.Name:lower():find("pancing") or item.Name:lower():find("joran")) then
				return item
			end
		end
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and (item:GetAttribute("IsRod") == true or item.Name:lower():find("rod") or item.Name:lower():find("pancing") or item.Name:lower():find("joran")) then
				return item
			end
		end
	end
	return nil
end

local clientPity = { LEGENDARY = 0, MYTHIC = 0, SPECIAL = 0 }
local lastPlayerData = {}
local activeSessionId = nil

local function mergePlayerData(newData)
	if not newData or typeof(newData) ~= "table" then return end
	for k, v in pairs(newData) do
		lastPlayerData[k] = v
	end
	if lastPlayerData.totalExp == nil and lastPlayerData.level ~= nil then
		lastPlayerData.totalExp = XPProgressionSystem.ReconcileToTotalExp(lastPlayerData.level or 1, lastPlayerData.exp or 0)
	end
end

local function hookLeaderstatsFolder(stats)
	if not stats then return end
	local function updateStats()
		local lvl = stats:FindFirstChild("Level")
		local exp = stats:FindFirstChild("Exp")
		local koin = stats:FindFirstChild("Koin") or stats:FindFirstChild("Coins")
		if lvl and tonumber(lvl.Value) ~= nil then
			lastPlayerData.level = tonumber(lvl.Value)
		end
		if exp and tonumber(exp.Value) ~= nil then
			lastPlayerData.exp = tonumber(exp.Value)
		end
		if koin and tonumber(koin.Value) ~= nil then
			lastPlayerData.coins = tonumber(koin.Value)
		end
		if lastPlayerData.level ~= nil then
			lastPlayerData.totalExp = XPProgressionSystem.ReconcileToTotalExp(lastPlayerData.level or 1, lastPlayerData.exp or 0)
		end
		if EconomyHUD and EconomyHUD.Update then
			EconomyHUD.Update(lastPlayerData)
		end
	end

	for _, v in ipairs(stats:GetChildren()) do
		if v:IsA("ValueBase") then
			v:GetPropertyChangedSignal("Value"):Connect(updateStats)
		end
	end
	stats.ChildAdded:Connect(function(v)
		if v:IsA("ValueBase") then
			v:GetPropertyChangedSignal("Value"):Connect(updateStats)
		end
		updateStats()
	end)
	updateStats()
end

local function syncFromLeaderstats()
	local stats = player and player:FindFirstChild("leaderstats")
	if stats then
		hookLeaderstatsFolder(stats)
	end
end

syncFromLeaderstats()
if player then
	player.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			task.defer(function() hookLeaderstatsFolder(child) end)
		end
	end)
end

-- ============ STATE & HELPER TUTORIAL (FISH-033) ============
local hasShownWelcomeTutorial = false

local function syncTutorialState(pData)
	if not pData then return end
	if pData.tutorialCompleted == true then
		TutorialUI.HideQuestPill()
		return
	end

	local step = tonumber(pData.tutorialStep) or 0
	if step == 0 and not hasShownWelcomeTutorial then
		hasShownWelcomeTutorial = true
		TutorialUI.ShowWelcomeModal(gui, function()
			TutorialUI.CreateOrUpdateQuestPill(gui, 1)
			RemoteContract.Client.CompleteTutorialStep(1)
		end, function()
			RemoteContract.Client.SkipTutorial()
		end)
	elseif step >= 1 and step <= 4 then
		TutorialUI.CreateOrUpdateQuestPill(gui, step)
	end
end

local function advanceTutorial(targetStep)
	if not lastPlayerData or lastPlayerData.tutorialCompleted == true then return end
	local current = tonumber(lastPlayerData.tutorialStep) or 0
	if current < targetStep then
		lastPlayerData.tutorialStep = targetStep
		TutorialUI.CreateOrUpdateQuestPill(gui, targetStep)
		RemoteContract.Client.CompleteTutorialStep(targetStep)
	end
end

-- ============ GUI ROOT ============
local pGui = getPlayerGui()
if pGui then
	local old = pGui:FindFirstChild("FishingGui")
	if old then old:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "FishingGui"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pGui or workspace

-- Inisialisasi Top Economy & Currency HUD
EconomyHUD.Create(gui)

-- ============ TOAST NOTIFICATION & REVEAL POPUP ============
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0, 500, 0, 64)
statusFrame.Position = UDim2.new(0.5, -250, 0.04, 0)
statusFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
statusFrame.BackgroundTransparency = 0.2
statusFrame.BorderSizePixel = 0
statusFrame.Visible = false
statusFrame.Parent = gui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 12)
statusCorner.Parent = statusFrame

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(0, 200, 255)
statusStroke.Thickness = 2
statusStroke.Transparency = 0.25
statusStroke.Parent = statusFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.fromScale(0.95, 1)
statusText.Position = UDim2.fromScale(0.025, 0)
statusText.BackgroundTransparency = 1
statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
statusText.Font = Enum.Font.GothamBold
statusText.TextSize = 14
statusText.TextWrapped = true
statusText.Text = ""
statusText.Parent = statusFrame

local hideToken = 0
local function showMessage(msg, color, duration)
	color = color or Color3.fromRGB(0, 200, 255)
	duration = duration or 3.5
	
	statusText.Text = msg
	statusStroke.Color = color
	statusFrame.Visible = true
	
	hideToken += 1
	local currentToken = hideToken
	task.delay(duration, function()
		if hideToken == currentToken then
			statusFrame.Visible = false
		end
	end)
end

-- ============ CASTING POWER & TIMING BAR GUI ============
local castMeterContainer = Instance.new("Frame")
castMeterContainer.Name = "CastMeterContainer"
castMeterContainer.Size = UDim2.new(0, 36, 0, 250)
castMeterContainer.Position = UDim2.new(0.72, 0, 0.5, -125)
castMeterContainer.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
castMeterContainer.BackgroundTransparency = 0.35
castMeterContainer.BorderSizePixel = 0
castMeterContainer.Visible = false
castMeterContainer.Parent = gui

local cmCorner = Instance.new("UICorner")
cmCorner.CornerRadius = UDim.new(0, 18)
cmCorner.Parent = castMeterContainer

local cmStroke = Instance.new("UIStroke")
cmStroke.Color = Color3.fromRGB(0, 200, 255)
cmStroke.Thickness = 2
cmStroke.Transparency = 0.3
cmStroke.Parent = castMeterContainer

local zoneGoodBase = Instance.new("Frame")
zoneGoodBase.Name = "ZoneGoodBase"
zoneGoodBase.Size = UDim2.fromScale(0.75, 0.92)
zoneGoodBase.Position = UDim2.fromScale(0.125, 0.04)
zoneGoodBase.BackgroundColor3 = Color3.fromRGB(25, 40, 60)
zoneGoodBase.BackgroundTransparency = 0.45
zoneGoodBase.BorderSizePixel = 0
zoneGoodBase.Parent = castMeterContainer
Instance.new("UICorner", zoneGoodBase).CornerRadius = UDim.new(0, 8)

local zoneGreat = Instance.new("Frame")
zoneGreat.Name = "ZoneGreat"
zoneGreat.Size = UDim2.fromScale(0.75, 0.28)
zoneGreat.Position = UDim2.fromScale(0.125, 0.15)
zoneGreat.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
zoneGreat.BackgroundTransparency = 0.35
zoneGreat.BorderSizePixel = 0
zoneGreat.Parent = castMeterContainer
Instance.new("UICorner", zoneGreat).CornerRadius = UDim.new(0, 8)

local zonePerfect = Instance.new("Frame")
zonePerfect.Name = "ZonePerfect"
zonePerfect.Size = UDim2.fromScale(0.75, 0.14)
zonePerfect.Position = UDim2.fromScale(0.125, 0.22)
zonePerfect.BackgroundColor3 = Color3.fromRGB(45, 245, 120)
zonePerfect.BackgroundTransparency = 0.15
zonePerfect.BorderSizePixel = 0
zonePerfect.Parent = castMeterContainer
Instance.new("UICorner", zonePerfect).CornerRadius = UDim.new(0, 8)

local pStroke = Instance.new("UIStroke")
pStroke.Color = Color3.fromRGB(180, 255, 200)
pStroke.Thickness = 1.5
pStroke.Parent = zonePerfect

local perfectBadge = Instance.new("TextLabel")
perfectBadge.Name = "PerfectBadge"
perfectBadge.Size = UDim2.new(0, 95, 0, 22)
perfectBadge.Position = UDim2.new(1.15, 0, 0.22, -2)
perfectBadge.BackgroundTransparency = 1
perfectBadge.Text = "PERFECT ⭐"
perfectBadge.TextColor3 = Color3.fromRGB(50, 255, 140)
perfectBadge.Font = Enum.Font.GothamBlack
perfectBadge.TextSize = 13
perfectBadge.TextXAlignment = Enum.TextXAlignment.Left
perfectBadge.Parent = castMeterContainer

local indicator = Instance.new("Frame")
indicator.Name = "Indicator"
indicator.Size = UDim2.new(1.18, 0, 0, 8)
indicator.Position = UDim2.new(-0.09, 0, 0.9, -4)
indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
indicator.BorderSizePixel = 0
indicator.Parent = castMeterContainer
Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

local indStroke = Instance.new("UIStroke")
indStroke.Color = Color3.fromRGB(255, 255, 255)
indStroke.Thickness = 1.5
indStroke.Parent = indicator

local castHint = Instance.new("TextLabel")
castHint.Name = "CastHint"
castHint.Size = UDim2.new(0, 190, 0, 24)
castHint.Position = UDim2.new(0.5, -95, 1.05, 0)
castHint.BackgroundTransparency = 1
castHint.Text = "Tekan [E] / Klik untuk Kunci!"
castHint.TextColor3 = Color3.fromRGB(220, 240, 255)
castHint.Font = Enum.Font.GothamBold
castHint.TextSize = 13
castHint.Parent = castMeterContainer

local ratingPopup = Instance.new("Frame")
ratingPopup.Name = "RatingPopup"
ratingPopup.Size = UDim2.new(0, 230, 0, 48)
ratingPopup.Position = UDim2.new(0.5, -115, 0.36, 0)
ratingPopup.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
ratingPopup.BackgroundTransparency = 0.2
ratingPopup.BorderSizePixel = 0
ratingPopup.Visible = false
ratingPopup.Parent = gui
Instance.new("UICorner", ratingPopup).CornerRadius = UDim.new(0, 12)

local ratingStroke = Instance.new("UIStroke")
ratingStroke.Color = Color3.fromRGB(255, 215, 0)
ratingStroke.Thickness = 2
ratingStroke.Parent = ratingPopup

local ratingLabel = Instance.new("TextLabel")
ratingLabel.Size = UDim2.fromScale(1, 1)
ratingLabel.BackgroundTransparency = 1
ratingLabel.Text = "⭐ PERFECT CAST! ⭐"
ratingLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
ratingLabel.Font = Enum.Font.GothamBlack
ratingLabel.TextSize = 18
ratingLabel.Parent = ratingPopup

local function showRatingPopup(rating, color)
	ratingLabel.Text = rating
	ratingLabel.TextColor3 = color
	ratingStroke.Color = color
	ratingPopup.Size = UDim2.new(0, 80, 0, 20)
	ratingPopup.Position = UDim2.new(0.5, -40, 0.4, 0)
	ratingPopup.Visible = true

	local pop = TweenService:Create(ratingPopup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 230, 0, 48),
		Position = UDim2.new(0.5, -115, 0.36, 0)
	})
	pop:Play()

	task.delay(1.6, function()
		if ratingPopup and ratingPopup.Parent then
			ratingPopup.Visible = false
		end
	end)
end

-- ============ FLOATING COIN FX (FISH-025) ============
local function spawnFloatingCoinEffect(coinsGained, optSubtitle)
	local coinPopup = Instance.new("Frame")
	coinPopup.Name = "FloatingCoinFX"
	coinPopup.Size = UDim2.new(0, 220, 0, 50)
	coinPopup.Position = UDim2.new(0.5, -110, 0.45, 0)
	coinPopup.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	coinPopup.BackgroundTransparency = 0.15
	coinPopup.BorderSizePixel = 0
	coinPopup.ZIndex = 50
	coinPopup.Parent = gui
	Instance.new("UICorner", coinPopup).CornerRadius = UDim.new(0, 12)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(255, 215, 0)
	cStroke.Thickness = 2
	cStroke.Parent = coinPopup

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(1, 0, 0, 26)
	valLabel.Position = UDim2.new(0, 0, 0, 4)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = string.format("+💰 %d KOIN!", tonumber(coinsGained) or 0)
	valLabel.TextColor3 = Color3.fromRGB(255, 225, 60)
	valLabel.Font = Enum.Font.GothamBlack
	valLabel.TextSize = 16
	valLabel.ZIndex = 51
	valLabel.Parent = coinPopup

	local subLabel = Instance.new("TextLabel")
	subLabel.Size = UDim2.new(1, 0, 0, 16)
	subLabel.Position = UDim2.new(0, 0, 0, 28)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = optSubtitle or "Hasil Penjualan Tangkapan"
	subLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextSize = 11
	subLabel.ZIndex = 51
	subLabel.Parent = coinPopup

	-- Animasi melayang naik dan memudar
	local tweenUp = TweenService:Create(coinPopup, TweenInfo.new(1.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -110, 0.35, 0),
		Size = UDim2.new(0, 240, 0, 54)
	})
	tweenUp:Play()

	task.delay(0.9, function()
		if coinPopup and coinPopup.Parent then
			local fade = TweenService:Create(coinPopup, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, -110, 0.30, 0)
			})
			TweenService:Create(cStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
			TweenService:Create(valLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
			TweenService:Create(subLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
			fade:Play()
			fade.Completed:Connect(function()
				if coinPopup and coinPopup.Parent then
					coinPopup:Destroy()
				end
			end)
		end
	end)
end

-- ============ EFEK AUDIO & PARTIKEL ============
local function playSound(soundId, volume, pitch)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume or 0.6
	s.PlaybackSpeed = pitch or 1
	s.Parent = workspace
	s:Play()
	Debris:AddItem(s, 2.5)
end

local function createWaterSplash(pos, customColor, scale)
	VisualEffectsSystem.CreateWaterSplash(pos, customColor, scale or 1.0)
	AudioEffectsSystem.PlayWaterSplash(scale and scale > 1.2)
end

local function showStrikeAlert(pos)
	VisualEffectsSystem.CreateStrikeShockwave(pos)
	AudioEffectsSystem.PlayStrikeAlert()

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 72, 0, 72)
	billboard.AlwaysOnTop = true
	
	local anchor = Instance.new("Part")
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = pos + Vector3.new(0, 2.5, 0)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = workspace
	billboard.Adornee = anchor
	Debris:AddItem(anchor, 2)

	billboard.Parent = gui

	local badge = Instance.new("Frame")
	badge.Size = UDim2.fromScale(1, 1)
	badge.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
	badge.BorderSizePixel = 0
	badge.Parent = billboard
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)

	local bStroke = Instance.new("UIStroke")
	bStroke.Color = Color3.fromRGB(255, 255, 255)
	bStroke.Thickness = 2.5
	bStroke.Parent = badge

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "!"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 42
	label.Parent = badge

	badge.Size = UDim2.fromScale(0.2, 0.2)
	badge.Position = UDim2.fromScale(0.4, 0.4)
	local pop = TweenService:Create(badge, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0)
	})
	pop:Play()

	task.delay(1.5, function()
		if billboard and billboard.Parent then
			billboard:Destroy()
		end
	end)
end

local function createProceduralFishModel()
	local model = Instance.new("Model")
	model.Name = "AnimatedFish"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(0.9, 0.7, 2.2)
	body.Color = Color3.fromRGB(0, 210, 255)
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = false
	body.Anchored = true
	body.Parent = model

	local tail = Instance.new("WedgePart")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.3, 0.8, 0.9)
	tail.Color = Color3.fromRGB(0, 180, 240)
	tail.Material = Enum.Material.SmoothPlastic
	tail.CanCollide = false
	tail.Anchored = true
	tail.CFrame = body.CFrame * CFrame.new(0, 0, 1.1) * CFrame.Angles(0, math.pi, 0)
	tail.Parent = model

	local fin = Instance.new("WedgePart")
	fin.Name = "Fin"
	fin.Size = Vector3.new(0.2, 0.5, 0.7)
	fin.Color = Color3.fromRGB(255, 215, 0)
	fin.Material = Enum.Material.Neon
	fin.CanCollide = false
	fin.Anchored = true
	fin.CFrame = body.CFrame * CFrame.new(0, 0.5, -0.2) * CFrame.Angles(0, math.pi, 0)
	fin.Parent = model

	model.PrimaryPart = body
	return model
end

local function animateFishLeap(startPos, endPos, duration, height)
	duration = duration or 0.85
	height = height or 5.5
	
	local fish = (fishTemplate and fishTemplate:Clone()) or createProceduralFishModel()
	if not fish then return end
	
	fish.Parent = workspace
	local midPos = (startPos + endPos) / 2 + Vector3.new(0, height, 0)

	local startTime = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local t = math.clamp(elapsed / duration, 0, 1)
		
		local p0 = startPos
		local p1 = midPos
		local p2 = endPos
		local currentPos = (1 - t)^2 * p0 + 2 * (1 - t) * t * p1 + t^2 * p2
		
		local nextT = math.min(t + 0.05, 1)
		local nextPos = (1 - nextT)^2 * p0 + 2 * (1 - nextT) * nextT * p1 + nextT^2 * p2
		local dir = (nextPos - currentPos)
		if dir.Magnitude > 0.001 then
			fish:PivotTo(CFrame.lookAt(currentPos, currentPos + dir))
		end

		if t >= 1 then
			conn:Disconnect()
			createWaterSplash(endPos)
			fish:Destroy()
		end
	end)
end

-- ============ KEPEMILIKAN JORAN PANCING ============
local function isRodTool(tool)
	if not tool or not tool:IsA("Tool") then return false end
	if tool:GetAttribute("IsFish") == true then return false end
	local name = tool.Name:lower()
	return name:find("rod") ~= nil or name:find("pancing") ~= nil or name:find("joran") ~= nil or tool:GetAttribute("IsRod") == true or tool:GetAttribute("Luck") ~= nil
end

local function getEquippedRod()
	local character = player.Character
	if not character then return nil end
	for _, item in ipairs(character:GetChildren()) do
		if isRodTool(item) then return item end
	end
	return nil
end

local function isRodEquipped()
	return getEquippedRod() ~= nil
end

local function getFishingRod()
	local character = player.Character
	local equipped = getEquippedRod()
	if equipped then return equipped end

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if isRodTool(item) then return item end
		end
	end
	return nil
end

local function hasFishingRod()
	return getFishingRod() ~= nil
end

local function ensureEquipped()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChild("Backpack")
	if not character or not humanoid or not backpack then return end
	
	local equipped = getEquippedRod()
	if not equipped then
		local inBackpack = getFishingRod()
		if inBackpack and inBackpack.Parent == backpack then
			humanoid:EquipTool(inBackpack)
		end
	end
end

local function freezePlayer(freeze)
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not humanoid then return end

	if freeze then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
		if hrp then
			hrp.Anchored = true
		end
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
		if hrp then
			hrp.Anchored = false
		end
	end
end

-- ============ SISTEM ANIMASI KARAKTER ============
local AnimSystem = {
	savedC0 = {},
	activeConn = nil,
	currentPhase = "None",
	fishingLine = nil,
}

local function getMotor(char, name)
	for _, m in ipairs(char:GetDescendants()) do
		if m:IsA("Motor6D") and (m.Name == name or m.Name:lower() == name:lower()) then
			return m
		end
	end
	return nil
end

function AnimSystem.SaveJoints(char)
	AnimSystem.savedC0 = {}
	local rShoulder = getMotor(char, "Right Shoulder") or getMotor(char, "RightShoulder")
	local lShoulder = getMotor(char, "Left Shoulder") or getMotor(char, "LeftShoulder")
	local waist = getMotor(char, "Waist")
	
	if rShoulder then AnimSystem.savedC0.RightShoulder = { joint = rShoulder, orig = rShoulder.C0 } end
	if lShoulder then AnimSystem.savedC0.LeftShoulder = { joint = lShoulder, orig = lShoulder.C0 } end
	if waist then AnimSystem.savedC0.Waist = { joint = waist, orig = waist.C0 } end
end

function AnimSystem.ResetJoints()
	if AnimSystem.activeConn then
		AnimSystem.activeConn:Disconnect()
		AnimSystem.activeConn = nil
	end
	AnimSystem.currentPhase = "None"
	AnimSystem.RemoveFishingLine()

	for _, data in pairs(AnimSystem.savedC0) do
		if data.joint and data.joint.Parent then
			TweenService:Create(data.joint, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				C0 = data.orig
			}):Play()
		end
	end
	AnimSystem.savedC0 = {}
end

function AnimSystem.CreateFishingLine(char, bobber)
	AnimSystem.RemoveFishingLine()
	if not char or not bobber then return end

	local rodTool = char:FindFirstChild("FishingRod") or char:FindFirstChild("Pancingan")
	local rodPart = rodTool and (rodTool:FindFirstChild("Rod") or rodTool:FindFirstChild("Handle") or rodTool:FindFirstChild("Line"))
	if not rodPart then return end

	local att0 = Instance.new("Attachment")
	att0.Name = "RodTipAttachment"
	att0.Position = Vector3.new(0, (rodPart.Size.Y / 2), 0)
	att0.Parent = rodPart

	local bobberPart = bobber:IsA("Model") and (bobber.PrimaryPart or bobber:FindFirstChildWhichIsA("BasePart")) or bobber
	if not bobberPart then return end

	local att1 = Instance.new("Attachment")
	att1.Name = "BobberAttachment"
	att1.Position = Vector3.new(0, 0.4, 0)
	att1.Parent = bobberPart

	local beam = Instance.new("Beam")
	beam.Name = "FishingLineBeam"
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = 0.05
	beam.Width1 = 0.05
	beam.Color = ColorSequence.new(Color3.fromRGB(240, 245, 255))
	beam.Transparency = NumberSequence.new(0.25)
	beam.FaceCamera = true
	beam.CurveSize0 = -1.2
	beam.CurveSize1 = 1.2
	beam.Segments = 16
	beam.Parent = rodPart

	AnimSystem.fishingLine = { beam = beam, att0 = att0, att1 = att1 }
end

function AnimSystem.RemoveFishingLine()
	if AnimSystem.fishingLine then
		if AnimSystem.fishingLine.beam then AnimSystem.fishingLine.beam:Destroy() end
		if AnimSystem.fishingLine.att0 then AnimSystem.fishingLine.att0:Destroy() end
		if AnimSystem.fishingLine.att1 then AnimSystem.fishingLine.att1:Destroy() end
		AnimSystem.fishingLine = nil
	end
end

function AnimSystem.PlayWindup(char, targetPos)
	AnimSystem.SaveJoints(char)
	AnimSystem.currentPhase = "Windup"

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
	end

	local rS = AnimSystem.savedC0.RightShoulder
	local lS = AnimSystem.savedC0.LeftShoulder
	local w = AnimSystem.savedC0.Waist

	if rS then
		TweenService:Create(rS.joint, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			C0 = rS.orig * CFrame.Angles(math.rad(120), math.rad(-15), math.rad(-20))
		}):Play()
	end
	if lS then
		TweenService:Create(lS.joint, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			C0 = lS.orig * CFrame.Angles(math.rad(45), 0, math.rad(-15))
		}):Play()
	end
	if w then
		TweenService:Create(w.joint, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			C0 = w.orig * CFrame.Angles(0, math.rad(-20), 0)
		}):Play()
	end
end

function AnimSystem.PlayCast(char, targetPos)
	AnimSystem.currentPhase = "Casting"

	local rS = AnimSystem.savedC0.RightShoulder
	local lS = AnimSystem.savedC0.LeftShoulder
	local w = AnimSystem.savedC0.Waist

	playSound("rbxasset://sounds/swordslash.wav", 0.5, 1.4)
	if rS then
		TweenService:Create(rS.joint, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = rS.orig * CFrame.Angles(math.rad(-45), 0, math.rad(10))
		}):Play()
	end
	if lS then
		TweenService:Create(lS.joint, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = lS.orig * CFrame.Angles(math.rad(-25), 0, math.rad(10))
		}):Play()
	end
	if w then
		TweenService:Create(w.joint, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			C0 = w.orig * CFrame.Angles(0, math.rad(10), 0)
		}):Play()
	end

	task.wait(0.25)
end

function AnimSystem.StartFishingStance(char)
	AnimSystem.currentPhase = "Waiting"
	if AnimSystem.activeConn then AnimSystem.activeConn:Disconnect() end

	local rS = AnimSystem.savedC0.RightShoulder
	local lS = AnimSystem.savedC0.LeftShoulder

	local baseRight = rS and (rS.orig * CFrame.Angles(math.rad(-30), math.rad(-10), math.rad(8)))
	local baseLeft = lS and (lS.orig * CFrame.Angles(math.rad(-20), math.rad(12), math.rad(-8)))

	AnimSystem.activeConn = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		if AnimSystem.currentPhase == "Waiting" then
			local sway = math.sin(t * 2.5) * 0.03
			if rS and rS.joint.Parent then
				rS.joint.C0 = baseRight * CFrame.Angles(sway, 0, sway * 0.5)
			end
			if lS and lS.joint.Parent then
				lS.joint.C0 = baseLeft * CFrame.Angles(sway * 0.8, 0, 0)
			end
		elseif AnimSystem.currentPhase == "Biting" then
			local tug = math.sin(t * 30) * 0.08
			if rS and rS.joint.Parent then
				rS.joint.C0 = baseRight * CFrame.Angles(math.rad(-15) + tug, 0, tug)
			end
			if lS and lS.joint.Parent then
				lS.joint.C0 = baseLeft * CFrame.Angles(math.rad(-10) + tug, 0, 0)
			end
		elseif AnimSystem.currentPhase == "Reeling" then
			local reelMotion = math.sin(t * 8) * 0.06
			if rS and rS.joint.Parent then
				rS.joint.C0 = baseRight * CFrame.Angles(math.rad(-10) + reelMotion, 0, 0)
			end
			if lS and lS.joint.Parent then
				lS.joint.C0 = baseLeft * CFrame.Angles(math.rad(15) * math.sin(t * 12), math.rad(10) * math.cos(t * 12), 0)
			end
		end
	end)
end

function AnimSystem.SetPhase(phase)
	AnimSystem.currentPhase = phase
end

function AnimSystem.PlayVictoryLift(char)
	AnimSystem.currentPhase = "Victory"
	if AnimSystem.activeConn then AnimSystem.activeConn:Disconnect() end

	local rS = AnimSystem.savedC0.RightShoulder
	local lS = AnimSystem.savedC0.LeftShoulder

	if rS and rS.joint.Parent then
		TweenService:Create(rS.joint, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = rS.orig * CFrame.Angles(math.rad(110), 0, math.rad(20))
		}):Play()
	end
	if lS then
		TweenService:Create(lS.joint, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = lS.orig * CFrame.Angles(math.rad(80), 0, math.rad(-20))
		}):Play()
	end
end

-- ============ DETEKSI AIR DI MAP ============
local function isWaterInstance(inst, mat)
	if mat == Enum.Material.Water then
		return true
	end
	if inst and (inst:IsA("BasePart") or inst:IsA("Model")) then
		local name = inst.Name:lower()
		if inst:IsA("BasePart") and inst.Material == Enum.Material.Water then
			return true
		end
		if name:find("water") or name:find("ocean") or name:find("lake") or name:find("danau")
			or name:find("river") or name:find("sungai") or name:find("laut") or name:find("sea")
			or name:find("pool") or name:find("kolam") or name:find("air") or name:find("wave")
			or name:find("aqua") or name:find("beach") then
			return true
		end
		if inst:GetAttribute("IsWater") == true or inst:GetAttribute("Water") == true or inst:HasTag("Water") then
			return true
		end
		if inst.Parent and inst.Parent ~= workspace and inst.Parent:IsA("Model") then
			local pName = inst.Parent.Name:lower()
			if pName:find("water") or pName:find("ocean") or pName:find("lake") or pName:find("danau")
				or pName:find("river") or pName:find("sungai") or pName:find("laut") or pName:find("sea") then
				return true
			end
		end
	end
	return false
end

local function findWaterTarget()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { char }
	rayParams.IgnoreWater = false

	-- 1. Deteksi Target Berdasarkan Arah Mouse Kursor
	local mouse = player:GetMouse()
	if mouse and mouse.UnitRay then
		local mouseResult = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 200, rayParams)
		if mouseResult and isWaterInstance(mouseResult.Instance, mouseResult.Material) then
			local dist = (mouseResult.Position - hrp.Position).Magnitude
			if dist >= 4 and dist <= 65 then
				return mouseResult.Position
			end
		end
	end

	-- 2. Deteksi Sapuan Multi-Arah di Depan Karakter
	local lookCFrame = hrp.CFrame
	local angles = { 0, -15, 15, -30, 30, -45, 45, -60, 60, -75, 75 }
	local distances = { 8, 16, 24, 34, 46, 58 }

	for _, dist in ipairs(distances) do
		for _, angleDeg in ipairs(angles) do
			local checkDir = (lookCFrame * CFrame.Angles(0, math.rad(angleDeg), 0)).LookVector
			local startPos = hrp.Position + (checkDir * dist) + Vector3.new(0, 12, 0)
			local downRay = workspace:Raycast(startPos, Vector3.new(0, -45, 0), rayParams)
			if downRay and isWaterInstance(downRay.Instance, downRay.Material) then
				return downRay.Position
			end
		end
	end

	return nil
end

-- ============ MEKANISME BAR MELEMPAR KAIL ============
local isCastingMeterActive = false
local meterStartTime = 0
local meterConn = nil
local currentWaterTarget = nil
local currentCastPower = 0.5
local meterSpeed = 3.2

local currentZones = {
	perfectMin = 0.78,
	perfectMax = 0.94,
	greatMin = 0.60,
	greatMax = 0.98,
}

local function randomizeZones()
	local perfectCenter = math.random(22, 80) / 100
	local perfectHalfWidth = 0.075
	local greatHalfWidth = 0.16

	local pMin = math.clamp(perfectCenter - perfectHalfWidth, 0.04, 0.88)
	local pMax = math.clamp(perfectCenter + perfectHalfWidth, 0.16, 0.96)

	local gMin = math.clamp(perfectCenter - greatHalfWidth, 0.02, pMin)
	local gMax = math.clamp(perfectCenter + greatHalfWidth, pMax, 0.98)

	currentZones.perfectMin = pMin
	currentZones.perfectMax = pMax
	currentZones.greatMin = gMin
	currentZones.greatMax = gMax

	local gTop = (1 - gMax) * 0.92 + 0.04
	local gHeight = (gMax - gMin) * 0.92
	zoneGreat.Position = UDim2.fromScale(0.125, gTop)
	zoneGreat.Size = UDim2.fromScale(0.75, gHeight)

	local pTop = (1 - pMax) * 0.92 + 0.04
	local pHeight = (pMax - pMin) * 0.92
	zonePerfect.Position = UDim2.fromScale(0.125, pTop)
	zonePerfect.Size = UDim2.fromScale(0.75, pHeight)

	perfectBadge.Position = UDim2.new(1.15, 0, pTop, -2)
end

local function updateMeterVisual(power)
	local yPercent = (1 - power) * 0.88 + 0.04
	indicator.Position = UDim2.new(-0.09, 0, yPercent, -4)

	if power >= currentZones.perfectMin and power <= currentZones.perfectMax then
		indicator.BackgroundColor3 = Color3.fromRGB(50, 255, 140)
		indStroke.Color = Color3.fromRGB(180, 255, 200)
	elseif power >= currentZones.greatMin and power <= currentZones.greatMax then
		indicator.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
		indStroke.Color = Color3.fromRGB(150, 240, 255)
	else
		indicator.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
		indStroke.Color = Color3.fromRGB(255, 255, 255)
	end
end

-- ============ ALUR MEMANCING DENGAN STATE MACHINE ============
local executeCastAfterMeter = nil
local activeBobber = nil
local sessionToken = 0
local serverSessionReceived = false

local function destroyBobberSafely()
	if activeBobber then
		pcall(function()
			activeBobber:Destroy()
		end)
		activeBobber = nil
	end
	AnimSystem.RemoveFishingLine()

	-- Bersihkan part bobber liar milik player di workspace
	for _, child in ipairs(workspace:GetChildren()) do
		if (child.Name == "BobberTemplate" or child.Name == "ActiveBobber" or child.Name == "FishingBobber")
			and child:GetAttribute("OwnerUserId") == player.UserId then
			pcall(function() child:Destroy() end)
		end
	end
end

-- FSM Lifecycle: Hook saat kembali ke status IDLE (Pembersihan Total)
fsm:OnEnter(FishingStateMachine.States.IDLE, function()
	isCastingMeterActive = false
	castMeterContainer.Visible = false
	if meterConn then
		meterConn:Disconnect()
		meterConn = nil
	end
	destroyBobberSafely()
	RhythmController.Cancel()
	AnimSystem.ResetJoints()
	freezePlayer(false)
end)

-- Global FSM listener to lock character during ANY fishing activity
fsm:OnStateChanged(function(newState, oldState)
	if newState == FishingStateMachine.States.IDLE then
		freezePlayer(false)
	else
		freezePlayer(true)
	end
end)

-- FSM Lifecycle: Hook saat mengisi bar meter lemparan (CHARGING_CAST)
fsm:OnEnter(FishingStateMachine.States.CHARGING_CAST, function(payload)
	local waterPos = payload and payload.waterPos or currentWaterTarget
	randomizeZones()

	isCastingMeterActive = true
	currentWaterTarget = waterPos
	ensureEquipped()
	freezePlayer(true)

	local char = player.Character
	if char then
		AnimSystem.PlayWindup(char, waterPos)
	end

	castMeterContainer.Visible = true
	meterStartTime = os.clock()

	if meterConn then meterConn:Disconnect() end
	meterConn = RunService.RenderStepped:Connect(function()
		if not fsm:Is(FishingStateMachine.States.CHARGING_CAST) then return end
		local elapsed = os.clock() - meterStartTime
		local pingPong = (math.sin(elapsed * meterSpeed - math.pi / 2) + 1) / 2
		currentCastPower = pingPong
		updateMeterVisual(currentCastPower)

		if elapsed > 4.5 then
			executeCastAfterMeter()
		end
	end)
end)

-- FSM Lifecycle: Hook saat melempar kail ke air (CASTING)
fsm:OnEnter(FishingStateMachine.States.CASTING, function(payload)
	local waterPos = payload.waterPos
	local castQuality = payload.castQuality
	local finalPower = payload.finalPower

	sessionToken += 1
	local currentToken = sessionToken
	activeSessionId = nil
	serverSessionReceived = false

	isCastingMeterActive = false
	castMeterContainer.Visible = false
	if meterConn then
		meterConn:Disconnect()
		meterConn = nil
	end
	freezePlayer(true)

	destroyBobberSafely()
	activeBobber = bobberTemplate and bobberTemplate:Clone() or Instance.new("Part")
	activeBobber.Name = "ActiveBobber"
	activeBobber:SetAttribute("OwnerUserId", player.UserId)
	if activeBobber:IsA("Model") then
		activeBobber:PivotTo(CFrame.new(waterPos + Vector3.new(0, 0.4, 0)))
	else
		activeBobber.Size = Vector3.new(0.9, 0.9, 0.9)
		activeBobber.Shape = Enum.PartType.Ball
		activeBobber.Color = (castQuality == "PERFECT" and Color3.fromRGB(255, 215, 0)) or Color3.fromRGB(240, 40, 40)
		activeBobber.Material = Enum.Material.SmoothPlastic
		activeBobber.Anchored = true
		activeBobber.CanCollide = false
		activeBobber.Position = waterPos + Vector3.new(0, 0.4, 0)
	end
	activeBobber.Parent = workspace

	local char = player.Character
	if char then
		AnimSystem.PlayCast(char, waterPos)
		AnimSystem.CreateFishingLine(char, activeBobber)
		AnimSystem.StartFishingStance(char)
	end

	AudioEffectsSystem.PlayCastSwing(finalPower)
	createWaterSplash(waterPos)
	task.delay(0.25, function()
		if fsm:Is(FishingStateMachine.States.CASTING) or fsm:Is(FishingStateMachine.States.WAITING_FOR_BITE) then
			AudioEffectsSystem.PlayBobberPlop()
		end
	end)

	if remote then
		RemoteContract.Client.StartFishing(waterPos, castQuality, finalPower)
	end

	-- Timeout pelindung jika server tidak merespon dalam 10 detik
	task.delay(10.0, function()
		if sessionToken == currentToken and fsm:Is(FishingStateMachine.States.CASTING) and not serverSessionReceived then
			showMessage("⚠️ Server tidak merespons lemparan kail. Silakan coba lempar kembali.", Color3.fromRGB(255, 140, 140), 3.0)
			fsm:ForceReset("CastTimeout")
		end
	end)
end)

local function startCastingMeter(waterPos)
	if not fsm:Is(FishingStateMachine.States.IDLE) or RhythmController.IsPlaying() then return end

	if not hasFishingRod() then
		showMessage("⚠️ Kamu membutuhkan Joran Pancing di inventory untuk memancing!", Color3.fromRGB(255, 80, 80), 3.5)
		playSound("rbxasset://sounds/splat.wav", 0.5, 0.7)
		return
	end

	fsm:Transition(FishingStateMachine.States.CHARGING_CAST, { waterPos = waterPos })
end

executeCastAfterMeter = function()
	if not fsm:Is(FishingStateMachine.States.CHARGING_CAST) then return end

	local finalPower = currentCastPower
	local waterPos = currentWaterTarget or findWaterTarget()
	if not waterPos then
		fsm:Transition(FishingStateMachine.States.IDLE, { reason = "NoWaterTarget" })
		return
	end

	local castQuality = "GOOD"
	if finalPower >= currentZones.perfectMin and finalPower <= currentZones.perfectMax then
		castQuality = "PERFECT"
		showRatingPopup("⭐ PERFECT CAST! ⭐", Color3.fromRGB(255, 215, 0))
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.8)
	elseif finalPower >= currentZones.greatMin and finalPower <= currentZones.greatMax then
		castQuality = "GREAT"
		showRatingPopup("✨ GREAT CAST! ✨", Color3.fromRGB(0, 220, 255))
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.5)
	else
		castQuality = "GOOD"
		showRatingPopup("GOOD CAST 👍", Color3.fromRGB(230, 235, 255))
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.2)
	end

	fsm:Transition(FishingStateMachine.States.CASTING, {
		waterPos = waterPos,
		castQuality = castQuality,
		finalPower = finalPower,
	})
end

onSessionStarted = function(sessionId, waitDuration, castQuality)
	serverSessionReceived = true

	-- Batalkan jika status bukan CASTING atau WAITING_FOR_BITE yang cocok
	if not fsm:Is(FishingStateMachine.States.CASTING) and not fsm:Is(FishingStateMachine.States.WAITING_FOR_BITE) then
		return
	end

	sessionToken += 1
	local currentToken = sessionToken
	activeSessionId = sessionId

	local waterPos = currentWaterTarget or findWaterTarget()
	if not waterPos then
		fsm:ForceReset("NoWaterTargetOnSession")
		return
	end

	fsm:Transition(FishingStateMachine.States.WAITING_FOR_BITE, {
		sessionId = sessionId,
		waitDuration = waitDuration,
		castQuality = castQuality,
	})

	advanceTutorial(2)

	if castQuality == "PERFECT" then
		showMessage("⭐ PERFECT CAST! Sambaran Kilat!", Color3.fromRGB(255, 215, 0), 2.5)
	elseif castQuality == "GREAT" then
		showMessage("✨ GREAT CAST! Sambaran Cepat!", Color3.fromRGB(0, 220, 255), 2.5)
	else
		showMessage("🎣 Kail di air... Menunggu ikan menyambar...", Color3.fromRGB(150, 220, 255), 2.5)
	end

	-- Ambient bobber buoyancy ripples loop (FISH-036)
	task.spawn(function()
		while sessionToken == currentToken and fsm:Is(FishingStateMachine.States.WAITING_FOR_BITE) do
			if activeBobber then
				local bobberPart = activeBobber:IsA("Model") and (activeBobber.PrimaryPart or activeBobber:FindFirstChildWhichIsA("BasePart")) or activeBobber
				if bobberPart and bobberPart.Parent then
					VisualEffectsSystem.SpawnBobberPulse(bobberPart)
				end
			end
			task.wait(1.0)
		end
	end)

	task.wait(waitDuration)

	-- Validasi kepemilikan token & status setelah durasi tunggu
	if sessionToken ~= currentToken or not fsm:Is(FishingStateMachine.States.WAITING_FOR_BITE) then
		return
	end

	-- Hentikan minigame lama jika ada
	RhythmController.Cancel()

	fsm:Transition(FishingStateMachine.States.BITING, { waterPos = waterPos })
	AnimSystem.SetPhase("Biting")
	showStrikeAlert(waterPos)
	createWaterSplash(waterPos)

	local fishStart = waterPos + Vector3.new(math.random(-3, 3), -1, math.random(-3, 3))
	local fishEnd = waterPos + Vector3.new(math.random(-3, 3), -1, math.random(-3, 3))
	animateFishLeap(fishStart, fishEnd, 0.8, 5.5)

	local bobberPart = activeBobber and (activeBobber:IsA("Model") and (activeBobber.PrimaryPart or activeBobber:FindFirstChildWhichIsA("BasePart")) or activeBobber)
	if bobberPart and bobberPart:IsA("BasePart") then
		pcall(function()
			local down = TweenService:Create(bobberPart, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = waterPos - Vector3.new(0, 1.2, 0)
			})
			down:Play()
			task.delay(0.2, function()
				if activeBobber and activeBobber.Parent and bobberPart and bobberPart.Parent then
					TweenService:Create(bobberPart, TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
						Position = waterPos + Vector3.new(0, 0.4, 0)
					}):Play()
				end
			end)
		end)
	end

	local rodTool = getEquippedRodTool()
	local currentRod = (rodTool and rodTool:GetAttribute("RodId")) or (lastPlayerData and lastPlayerData.equippedRod) or "StarterRod"
	local instType = (rodTool and rodTool:GetAttribute("InstrumentType"))
		or (lastPlayerData and lastPlayerData.equippedInstrument)
		or InstrumentDefinitions.GetInstrumentTypeForRod(currentRod)
	local instData = InstrumentDefinitions.GetInstrumentData(instType)
	local hint = InstrumentDefinitions.GetInstrumentHint(instType)

	advanceTutorial(3)

	showMessage(string.format("%s IKAN MENYAMBAR! %s", instData.icon or "🎵", hint), instData.color or Color3.fromRGB(255, 220, 50), 3.5)
	AnimSystem.SetPhase("Reeling")

	fsm:Transition(FishingStateMachine.States.MINIGAME, { sessionId = sessionId })

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	RhythmController.Start({
		castQuality = castQuality,
		tier = "MYSTERY",
		rodId = currentRod,
		instrumentType = instType,
	}, function(metrics)
		fsm:Transition(FishingStateMachine.States.REELING_SUCCESS, { metrics = metrics })
		destroyBobberSafely()
		AnimSystem.PlayVictoryLift(char)
		local catchTarget = hrp and (hrp.Position + Vector3.new(0, 1.5, 0)) or (waterPos + Vector3.new(0, 5, 0))
		animateFishLeap(waterPos, catchTarget, 0.9, 7)
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.8)

		if remote and activeSessionId and activeSessionId ~= "" then
			print(string.format("[FishingClient] 📤 Mengirim SubmitCatch ke Server! SessionId: %s | Skor: %d", tostring(activeSessionId), tonumber(metrics.score or 0) or 0))
			RemoteContract.Client.SubmitCatch(activeSessionId, metrics)
		else
			warn(string.format("[FishingClient] ⚠️ activeSessionId tidak ditemukan saat minigame selesai! SessionId: %s", tostring(activeSessionId)))
			showMessage("🎉 TANGKAPAN BERHASIL! Skor: " .. tostring(metrics.score or 0), Color3.fromRGB(50, 255, 130), 4.0)
		end

		task.delay(2.8, function()
			fsm:Transition(FishingStateMachine.States.IDLE, { reason = "CatchSuccessComplete" })
		end)
	end, function(metrics)
		fsm:Transition(FishingStateMachine.States.REELING_FAIL, { metrics = metrics })
		destroyBobberSafely()
		AudioEffectsSystem.PlayFishEscape()
		createWaterSplash(waterPos, Color3.fromRGB(160, 180, 200), 1.2)
		showMessage("❌ Ikan terlepas! Irama musik belum tepat.", Color3.fromRGB(255, 75, 75), 3)

		if remote and activeSessionId and activeSessionId ~= "" then
			RemoteContract.Client.CancelFishing(activeSessionId)
		end

		task.delay(1.5, function()
			fsm:Transition(FishingStateMachine.States.IDLE, { reason = "CatchFailComplete" })
		end)
	end)
end

-- ============ SISTEM INVENTORY & PENJUALAN IKAN ============
-- ============ SISTEM INVENTORY & PENJUALAN IKAN (FISH-021) ============
local inventoryFrame, inventoryList, invTotalFishLabel, invTotalCoinsLabel, invSellAllBtn
local invToggleBtn, invBadge
local currentCategoryFilter = "ALL"
local categoryTabButtons = {}

local CATEGORY_CONFIG = {
	{ id = "ALL", label = "✨ SEMUA" },
	{ id = "FISH", label = "🐟 IKAN" },
	{ id = "TREASURE", label = "📦 PETI" },
	{ id = "ARTIFACT", label = "🔮 RELIK" },
	{ id = "JUNK", label = "🗑️ SAMPAH" },
}

local function getFishInBackpack()
	local fishList = {}
	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character

	local function checkAndAdd(item)
		if not item:IsA("Tool") then return end
		if isRodTool(item) then return end
		if item:GetAttribute("IsFish") == true or item:GetAttribute("IsLoot") == true or item:GetAttribute("Coins") ~= nil or item:GetAttribute("Weight") ~= nil or item:GetAttribute("ItemId") ~= nil then
			table.insert(fishList, item)
		end
	end

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			checkAndAdd(item)
		end
	end
	if char then
		for _, item in ipairs(char:GetChildren()) do
			checkAndAdd(item)
		end
	end

	return fishList
end

local function updateCategoryTabStyles()
	for catId, btnData in pairs(categoryTabButtons) do
		local isSelected = (catId == currentCategoryFilter)
		if isSelected then
			btnData.button.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
			btnData.button.TextColor3 = Color3.fromRGB(255, 255, 255)
			btnData.stroke.Color = Color3.fromRGB(0, 230, 255)
			btnData.stroke.Transparency = 0.1
		else
			btnData.button.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
			btnData.button.TextColor3 = Color3.fromRGB(150, 175, 205)
			btnData.stroke.Color = Color3.fromRGB(50, 70, 100)
			btnData.stroke.Transparency = 0.6
		end
	end
end

local function updateInventoryUI()
	if not inventoryFrame or not inventoryList then return end

	updateCategoryTabStyles()

	-- Bersihkan list sebelumnya
	for _, child in ipairs(inventoryList:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local allItems = getFishInBackpack()
	local totalLockedOverall = 0
	local filteredItems = {}
	local unlockedFilteredCoins = 0
	local totalFilteredCoins = 0

	for _, tool in ipairs(allItems) do
		local isLocked = tool:GetAttribute("IsLocked") == true
		if isLocked then
			totalLockedOverall += 1
		end

		local itemType = tool:GetAttribute("ItemType") or "FISH"
		if currentCategoryFilter == "ALL" or itemType == currentCategoryFilter then
			table.insert(filteredItems, tool)
			local c = tonumber(tool:GetAttribute("Coins")) or 15
			totalFilteredCoins += c
			if not isLocked then
				unlockedFilteredCoins += c
			end
		end
	end

	if invBadge then
		invBadge.Text = tostring(#allItems)
		invBadge.Visible = #allItems > 0
	end

	if invTotalFishLabel then
		if totalLockedOverall > 0 then
			invTotalFishLabel.Text = string.format("🎣 Total: %d  (🔒 %d Terkunci)", #allItems, totalLockedOverall)
		else
			invTotalFishLabel.Text = string.format("🎣 Total Tangkapan: %d", #allItems)
		end
	end

	if invTotalCoinsLabel then
		invTotalCoinsLabel.Text = string.format("💰 Siap Jual: %d Koin", unlockedFilteredCoins)
	end

	if #filteredItems == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 120)
		emptyLabel.Position = UDim2.new(0, 10, 0, 40)
		emptyLabel.BackgroundTransparency = 1
		if #allItems == 0 then
			emptyLabel.Text = "🎣 Belum ada tangkapan di inventory.\nAyo lemparkan kailmu ke samudra luas!"
		else
			emptyLabel.Text = "🔍 Tidak ada item pada kategori ini.\nPilih tab lain atau mulai memancing!"
		end
		emptyLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
		emptyLabel.Font = Enum.Font.GothamMedium
		emptyLabel.TextSize = 15
		emptyLabel.Parent = inventoryList

		if invSellAllBtn then
			invSellAllBtn.Text = "💰 TIDAK ADA ITEM UNTUK DIJUAL (0 Koin)"
			invSellAllBtn.BackgroundColor3 = Color3.fromRGB(50, 60, 75)
		end
		return
	end

	for _, tool in ipairs(filteredItems) do
		local rName = tool:GetAttribute("Rarity") or "COMMON"
		local tierData = FishingRaritySystem.GetTierData(rName)
		local catBadge = tool:GetAttribute("CategoryBadge") or "🐟 IKAN"
		local fishName = tool:GetAttribute("FishName") or tool.Name
		local dispName = tool:GetAttribute("DisplayName") or tierData.displayName
		local stars = tool:GetAttribute("Stars") or tierData.stars
		local weight = tonumber(tool:GetAttribute("Weight")) or 1.0
		local coins = tonumber(tool:GetAttribute("Coins")) or 15
		local isLocked = tool:GetAttribute("IsLocked") == true
		local color = tierData.color or Color3.fromRGB(0, 200, 255)

		local card = Instance.new("Frame")
		card.Name = "LootCard_" .. tool.Name
		card.Size = UDim2.new(1, -12, 0, 66)
		card.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
		card.BackgroundTransparency = 0.25
		card.BorderSizePixel = 0
		card.Parent = inventoryList
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = isLocked and Color3.fromRGB(255, 195, 60) or color
		cardStroke.Thickness = isLocked and 2 or 1.5
		cardStroke.Transparency = isLocked and 0.15 or 0.35
		cardStroke.Parent = card

		local isMutated = tool:GetAttribute("IsMutated") == true
		local mutPrefix = tool:GetAttribute("MutationPrefix") or ""
		local mutTag = isMutated and string.format(" %s", mutPrefix) or ""

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.56, 0, 0, 22)
		nameLabel.Position = UDim2.new(0, 14, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = string.format("%s [%s]%s %s %s", catBadge, dispName, mutTag, fishName, stars)
		nameLabel.TextColor3 = color
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local grade = tool:GetAttribute("Grade")
		local gradeTag = grade and string.format(" • [Grade %s]", grade) or ""
		local lockTag = isLocked and " • 🔒 [TERKUNCI]" or ""

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(0.56, 0, 0, 18)
		statsLabel.Position = UDim2.new(0, 14, 0, 33)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Text = string.format("⚖️ %.1f Kg  |  💰 %d Koin%s%s", weight, coins, gradeTag, lockTag)
		statsLabel.TextColor3 = isLocked and Color3.fromRGB(255, 215, 120) or Color3.fromRGB(220, 235, 255)
		statsLabel.Font = Enum.Font.GothamMedium
		statsLabel.TextSize = 12
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = card

		-- Lock / Favorite Button
		local lockBtn = Instance.new("TextButton")
		lockBtn.Name = "LockBtn"
		lockBtn.Size = UDim2.new(0, 36, 0, 36)
		lockBtn.Position = UDim2.new(1, -156, 0.5, -18)
		lockBtn.BackgroundColor3 = isLocked and Color3.fromRGB(50, 40, 20) or Color3.fromRGB(26, 34, 48)
		lockBtn.BorderSizePixel = 0
		lockBtn.Text = isLocked and "🔒" or "🔓"
		lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		lockBtn.Font = Enum.Font.GothamBold
		lockBtn.TextSize = 16
		lockBtn.Parent = card
		Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 8)

		local lockStroke = Instance.new("UIStroke")
		lockStroke.Color = isLocked and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(75, 95, 125)
		lockStroke.Thickness = 1.2
		lockStroke.Parent = lockBtn

		lockBtn.MouseButton1Click:Connect(function()
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.6)
			if remote and tool and tool.Parent then
				RemoteContract.Client.ToggleLockItem(tool)
			end
		end)

		-- Sell Single Button
		local sellBtn = Instance.new("TextButton")
		sellBtn.Name = "SellBtn"
		sellBtn.Size = UDim2.new(0, 106, 0, 36)
		sellBtn.Position = UDim2.new(1, -114, 0.5, -18)
		sellBtn.BorderSizePixel = 0
		sellBtn.Font = Enum.Font.GothamBold
		sellBtn.TextSize = 12
		sellBtn.Parent = card
		Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 8)

		if isLocked then
			sellBtn.BackgroundColor3 = Color3.fromRGB(48, 54, 66)
			sellBtn.Text = "🔒 Terkunci"
			sellBtn.TextColor3 = Color3.fromRGB(160, 175, 195)
			sellBtn.MouseButton1Click:Connect(function()
				showMessage("🔒 Item ini terkunci! Buka kunci (🔓) terlebih dahulu untuk menjual.", Color3.fromRGB(255, 200, 80), 2.5)
			end)
		else
			sellBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
			sellBtn.Text = string.format("Jual (💰 %d)", coins)
			sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			sellBtn.MouseButton1Click:Connect(function()
				playSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.4)
				if remote and tool and tool.Parent then
					RemoteContract.Client.SellFish(tool)
				end
			end)
		end
	end

	if invSellAllBtn then
		if unlockedFilteredCoins > 0 then
			local activeTabName = "ITEM"
			for _, tab in ipairs(CATEGORY_CONFIG) do
				if tab.id == currentCategoryFilter then
					activeTabName = tab.id == "ALL" and "SEMUA" or tab.label
					break
				end
			end
			invSellAllBtn.Text = string.format("💰 JUAL %s TERBUKA (💰 %d Koin)", activeTabName, unlockedFilteredCoins)
			invSellAllBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 95)
			invSellAllBtn.AutoButtonColor = true
		else
			invSellAllBtn.Text = (#filteredItems > 0 and totalLockedOverall > 0) and "🔒 SEMUA ITEM TERKUNCI (0 Koin)" or "💰 TIDAK ADA ITEM UNTUK DIJUAL (0 Koin)"
			invSellAllBtn.BackgroundColor3 = Color3.fromRGB(50, 60, 75)
			invSellAllBtn.AutoButtonColor = false
		end
	end

	EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
end

local function toggleInventory(forcedState)
	if not inventoryFrame then return end
	local newState = (forcedState ~= nil) and forcedState or (not inventoryFrame.Visible)
	if newState then
		updateInventoryUI()
		inventoryFrame.Visible = true
		inventoryFrame.Size = UDim2.new(0, 500, 0, 440)
		inventoryFrame.Position = UDim2.new(0.5, -250, 0.5, -220)
		TweenService:Create(inventoryFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 540, 0, 480),
			Position = UDim2.new(0.5, -270, 0.5, -240)
		}):Play()
	else
		inventoryFrame.Visible = false
	end
end

-- ============ MEMBANGUN INVENTORY MODAL GUI ============
local function buildInventoryUI()
	-- 1. Tombol Toggle Inventory di Layar (HUD)
	invToggleBtn = Instance.new("TextButton")
	invToggleBtn.Name = "InvToggleBtn"
	invToggleBtn.Size = UDim2.new(0, 145, 0, 36)
	invToggleBtn.Position = UDim2.new(0, 20, 0.20, 0)
	invToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	invToggleBtn.BackgroundTransparency = 0.25
	invToggleBtn.BorderSizePixel = 0
	invToggleBtn.Text = "🎒 INVENTORY [B]"
	invToggleBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
	invToggleBtn.Font = Enum.Font.GothamBlack
	invToggleBtn.TextSize = 12
	invToggleBtn.Parent = gui
	Instance.new("UICorner", invToggleBtn).CornerRadius = UDim.new(0, 10)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(0, 200, 255)
	btnStroke.Thickness = 1.5
	btnStroke.Transparency = 0.3
	btnStroke.Parent = invToggleBtn

	invBadge = Instance.new("TextLabel")
	invBadge.Name = "Badge"
	invBadge.Size = UDim2.new(0, 22, 0, 22)
	invBadge.Position = UDim2.new(1, -12, 0, -8)
	invBadge.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	invBadge.BorderSizePixel = 0
	invBadge.Text = "0"
	invBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
	invBadge.Font = Enum.Font.GothamBold
	invBadge.TextSize = 11
	invBadge.Visible = false
	invBadge.Parent = invToggleBtn
	Instance.new("UICorner", invBadge).CornerRadius = UDim.new(1, 0)

	invToggleBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.2)
		toggleInventory()
	end)

	-- 2. Modal Frame Inventory
	inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Size = UDim2.new(0, 540, 0, 480)
	inventoryFrame.Position = UDim2.new(0.5, -270, 0.5, -240)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	inventoryFrame.BackgroundTransparency = 0.15
	inventoryFrame.BorderSizePixel = 0
	inventoryFrame.Visible = false
	inventoryFrame.Parent = gui
	Instance.new("UICorner", inventoryFrame).CornerRadius = UDim.new(0, 16)

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(0, 200, 255)
	frameStroke.Thickness = 2
	frameStroke.Transparency = 0.3
	frameStroke.Parent = inventoryFrame

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.Parent = inventoryFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.7, 0, 0, 24)
	title.Position = UDim2.new(0, 18, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "🎒 INVENTORY & TANGKAPAN"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 17
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.7, 0, 0, 16)
	subtitle.Position = UDim2.new(0, 18, 0, 30)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Kunci item berharga (🔒) agar aman dari penjualan massal!"
	subtitle.TextColor3 = Color3.fromRGB(160, 200, 230)
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 11
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -44, 0, 9)
	closeBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 65)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextSize = 16
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		toggleInventory(false)
	end)

	-- Category Tabs Bar
	local tabsContainer = Instance.new("Frame")
	tabsContainer.Name = "CategoryTabs"
	tabsContainer.Size = UDim2.new(1, -36, 0, 30)
	tabsContainer.Position = UDim2.new(0, 18, 0, 54)
	tabsContainer.BackgroundTransparency = 1
	tabsContainer.Parent = inventoryFrame

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabsContainer

	categoryTabButtons = {}
	for idx, tabData in ipairs(CATEGORY_CONFIG) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Tab_" .. tabData.id
		tabBtn.Size = UDim2.new(0, 94, 1, 0)
		tabBtn.LayoutOrder = idx
		tabBtn.BackgroundColor3 = Color3.fromRGB(20, 28, 42)
		tabBtn.BorderSizePixel = 0
		tabBtn.Text = tabData.label
		tabBtn.TextColor3 = Color3.fromRGB(150, 175, 205)
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.TextSize = 11
		tabBtn.Parent = tabsContainer
		Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

		local tStroke = Instance.new("UIStroke")
		tStroke.Color = Color3.fromRGB(50, 70, 100)
		tStroke.Thickness = 1
		tStroke.Transparency = 0.5
		tStroke.Parent = tabBtn

		categoryTabButtons[tabData.id] = { button = tabBtn, stroke = tStroke }

		tabBtn.MouseButton1Click:Connect(function()
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
			currentCategoryFilter = tabData.id
			updateInventoryUI()
		end)
	end

	-- Subheader Stats Bar
	local statsBar = Instance.new("Frame")
	statsBar.Size = UDim2.new(1, -36, 0, 28)
	statsBar.Position = UDim2.new(0, 18, 0, 90)
	statsBar.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
	statsBar.BackgroundTransparency = 0.5
	statsBar.BorderSizePixel = 0
	statsBar.Parent = inventoryFrame
	Instance.new("UICorner", statsBar).CornerRadius = UDim.new(0, 6)

	invTotalFishLabel = Instance.new("TextLabel")
	invTotalFishLabel.Size = UDim2.new(0.55, 0, 1, 0)
	invTotalFishLabel.Position = UDim2.new(0.02, 0, 0, 0)
	invTotalFishLabel.BackgroundTransparency = 1
	invTotalFishLabel.Text = "🎣 Total: 0"
	invTotalFishLabel.TextColor3 = Color3.fromRGB(0, 210, 255)
	invTotalFishLabel.Font = Enum.Font.GothamBold
	invTotalFishLabel.TextSize = 12
	invTotalFishLabel.TextXAlignment = Enum.TextXAlignment.Left
	invTotalFishLabel.Parent = statsBar

	invTotalCoinsLabel = Instance.new("TextLabel")
	invTotalCoinsLabel.Size = UDim2.new(0.41, 0, 1, 0)
	invTotalCoinsLabel.Position = UDim2.new(0.57, 0, 0, 0)
	invTotalCoinsLabel.BackgroundTransparency = 1
	invTotalCoinsLabel.Text = "💰 Siap Jual: 0 Koin"
	invTotalCoinsLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
	invTotalCoinsLabel.Font = Enum.Font.GothamBold
	invTotalCoinsLabel.TextSize = 12
	invTotalCoinsLabel.TextXAlignment = Enum.TextXAlignment.Right
	invTotalCoinsLabel.Parent = statsBar

	-- Scrollable List
	inventoryList = Instance.new("ScrollingFrame")
	inventoryList.Name = "InventoryList"
	inventoryList.Size = UDim2.new(1, -36, 1, -188)
	inventoryList.Position = UDim2.new(0, 18, 0, 124)
	inventoryList.BackgroundTransparency = 1
	inventoryList.BorderSizePixel = 0
	inventoryList.ScrollBarThickness = 5
	inventoryList.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
	inventoryList.CanvasSize = UDim2.new(0, 0, 0, 0)
	inventoryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	inventoryList.Parent = inventoryFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = inventoryList

	-- Bottom Bar (Sell All / Sell Category)
	invSellAllBtn = Instance.new("TextButton")
	invSellAllBtn.Name = "SellAllBtn"
	invSellAllBtn.Size = UDim2.new(1, -36, 0, 44)
	invSellAllBtn.Position = UDim2.new(0, 18, 1, -52)
	invSellAllBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 95)
	invSellAllBtn.BorderSizePixel = 0
	invSellAllBtn.Text = "💰 JUAL SEMUA ITEM TERBUKA (0 Koin)"
	invSellAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	invSellAllBtn.Font = Enum.Font.GothamBlack
	invSellAllBtn.TextSize = 13
	invSellAllBtn.Parent = inventoryFrame
	Instance.new("UICorner", invSellAllBtn).CornerRadius = UDim.new(0, 10)

	invSellAllBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.8, 1.4)
		if remote then
			if currentCategoryFilter == "ALL" then
				RemoteContract.Client.SellAllFish()
			else
				RemoteContract.Client.SellCategory(currentCategoryFilter)
			end
		end
	end)

	updateInventoryUI()
end

buildInventoryUI()

-- ============ SISTEM PITY TRACKER HUD (FISH-020) ============
local pityTrackerBtn, pityFrame
local pityBars = {} -- [tierKey] = { fillBar = ..., countLabel = ..., tagLabel = ... }

local function updatePityUI()
	if not pityFrame then return end
	local allProg = PitySystem.GetAllProgress(clientPity)

	for tierKey, prog in pairs(allProg) do
		local widgets = pityBars[tierKey]
		if widgets then
			local countStr = string.format("%d / %d", prog.current, prog.hardPity)
			widgets.countLabel.Text = countStr

			local targetScale = math.clamp(prog.current / prog.hardPity, 0, 1)
			TweenService:Create(widgets.fillBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(targetScale, 0, 1, 0)
			}):Play()

			if prog.isHardPityGuaranteed then
				widgets.tagLabel.Text = "👑 100% GARANSI!"
				widgets.tagLabel.TextColor3 = Color3.fromRGB(255, 230, 80)
				widgets.tagLabel.Visible = true
			elseif prog.isSoftPityActive then
				widgets.tagLabel.Text = string.format("🔥 SOFT PITY (x%.1f)", prog.multiplier)
				widgets.tagLabel.TextColor3 = Color3.fromRGB(255, 160, 50)
				widgets.tagLabel.Visible = true
			else
				widgets.tagLabel.Text = string.format("(%s)", prog.displayName)
				widgets.tagLabel.TextColor3 = Color3.fromRGB(150, 170, 195)
				widgets.tagLabel.Visible = false
			end
		end
	end
end

local function togglePityFrame(forcedState)
	if not pityFrame then return end
	local newState = (forcedState ~= nil) and forcedState or (not pityFrame.Visible)
	if newState then
		updatePityUI()
		pityFrame.Visible = true
		pityFrame.Size = UDim2.new(0, 240, 0, 180)
		TweenService:Create(pityFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 260, 0, 200)
		}):Play()
	else
		pityFrame.Visible = false
	end
end

local function buildPityTrackerUI()
	-- 1. Tombol Toggle Pity di HUD
	pityTrackerBtn = Instance.new("TextButton")
	pityTrackerBtn.Name = "PityTrackerBtn"
	pityTrackerBtn.Size = UDim2.new(0, 145, 0, 36)
	pityTrackerBtn.Position = UDim2.new(0, 20, 0.26, 0)
	pityTrackerBtn.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	pityTrackerBtn.BackgroundTransparency = 0.25
	pityTrackerBtn.BorderSizePixel = 0
	pityTrackerBtn.Text = "🌟 PITY TRACKER"
	pityTrackerBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	pityTrackerBtn.Font = Enum.Font.GothamBlack
	pityTrackerBtn.TextSize = 12
	pityTrackerBtn.Parent = gui
	Instance.new("UICorner", pityTrackerBtn).CornerRadius = UDim.new(0, 10)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(255, 200, 50)
	btnStroke.Thickness = 1.5
	btnStroke.Transparency = 0.4
	btnStroke.Parent = pityTrackerBtn

	pityTrackerBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
		togglePityFrame()
	end)

	-- 2. Frame Detail Pity Tracker
	pityFrame = Instance.new("Frame")
	pityFrame.Name = "PityFrame"
	pityFrame.Size = UDim2.new(0, 260, 0, 200)
	pityFrame.Position = UDim2.new(0, 20, 0.45, 0)
	pityFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	pityFrame.BackgroundTransparency = 0.15
	pityFrame.BorderSizePixel = 0
	pityFrame.Visible = false
	pityFrame.Parent = gui
	Instance.new("UICorner", pityFrame).CornerRadius = UDim.new(0, 14)

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(255, 200, 50)
	frameStroke.Thickness = 1.5
	frameStroke.Transparency = 0.3
	frameStroke.Parent = pityFrame

	-- Header
	local headerLabel = Instance.new("TextLabel")
	headerLabel.Size = UDim2.new(1, -20, 0, 24)
	headerLabel.Position = UDim2.new(0, 12, 0, 8)
	headerLabel.BackgroundTransparency = 1
	headerLabel.Text = "🌟 JAMINAN PITY GACHA"
	headerLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
	headerLabel.Font = Enum.Font.GothamBlack
	headerLabel.TextSize = 13
	headerLabel.TextXAlignment = Enum.TextXAlignment.Left
	headerLabel.Parent = pityFrame

	local subHeader = Instance.new("TextLabel")
	subHeader.Size = UDim2.new(1, -20, 0, 14)
	subHeader.Position = UDim2.new(0, 12, 0, 30)
	subHeader.BackgroundTransparency = 1
	subHeader.Text = "Garansi bertambah tiap tarikan tanpa reset"
	subHeader.TextColor3 = Color3.fromRGB(160, 180, 200)
	subHeader.Font = Enum.Font.GothamMedium
	subHeader.TextSize = 10
	subHeader.TextXAlignment = Enum.TextXAlignment.Left
	subHeader.Parent = pityFrame

	local tiersToDisplay = {
		{ key = "SPECIAL", name = "👑 SPECIAL", color = Color3.fromRGB(255, 60, 200), yOffset = 50 },
		{ key = "MYTHIC", name = "🔥 MYTHIC", color = Color3.fromRGB(235, 45, 45), yOffset = 98 },
		{ key = "LEGENDARY", name = "🌟 LEGENDARY", color = Color3.fromRGB(240, 185, 20), yOffset = 146 },
	}

	for _, t in ipairs(tiersToDisplay) do
		local row = Instance.new("Frame")
		row.Name = "PityRow_" .. t.key
		row.Size = UDim2.new(1, -24, 0, 42)
		row.Position = UDim2.new(0, 12, 0, t.yOffset)
		row.BackgroundTransparency = 1
		row.Parent = pityFrame

		local rowTitle = Instance.new("TextLabel")
		rowTitle.Size = UDim2.new(0.5, 0, 0, 16)
		rowTitle.Position = UDim2.new(0, 0, 0, 0)
		rowTitle.BackgroundTransparency = 1
		rowTitle.Text = t.name
		rowTitle.TextColor3 = t.color
		rowTitle.Font = Enum.Font.GothamBold
		rowTitle.TextSize = 11
		rowTitle.TextXAlignment = Enum.TextXAlignment.Left
		rowTitle.Parent = row

		local countLabel = Instance.new("TextLabel")
		countLabel.Name = "CountLabel"
		countLabel.Size = UDim2.new(0.48, 0, 0, 16)
		countLabel.Position = UDim2.new(0.52, 0, 0, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = "0 / 100"
		countLabel.TextColor3 = Color3.fromRGB(220, 230, 245)
		countLabel.Font = Enum.Font.GothamBold
		countLabel.TextSize = 11
		countLabel.TextXAlignment = Enum.TextXAlignment.Right
		countLabel.Parent = row

		local barBg = Instance.new("Frame")
		barBg.Name = "BarBg"
		barBg.Size = UDim2.new(1, 0, 0, 10)
		barBg.Position = UDim2.new(0, 0, 0, 18)
		barBg.BackgroundColor3 = Color3.fromRGB(24, 30, 45)
		barBg.BorderSizePixel = 0
		barBg.Parent = row
		Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

		local fillBar = Instance.new("Frame")
		fillBar.Name = "Fill"
		fillBar.Size = UDim2.new(0, 0, 1, 0)
		fillBar.BackgroundColor3 = t.color
		fillBar.BorderSizePixel = 0
		fillBar.Parent = barBg
		Instance.new("UICorner", fillBar).CornerRadius = UDim.new(1, 0)

		local tagLabel = Instance.new("TextLabel")
		tagLabel.Name = "Tag"
		tagLabel.Size = UDim2.new(1, 0, 0, 12)
		tagLabel.Position = UDim2.new(0, 0, 0, 30)
		tagLabel.BackgroundTransparency = 1
		tagLabel.Text = "🔥 SOFT PITY"
		tagLabel.TextColor3 = Color3.fromRGB(255, 160, 50)
		tagLabel.Font = Enum.Font.GothamBold
		tagLabel.TextSize = 9
		tagLabel.TextXAlignment = Enum.TextXAlignment.Right
		tagLabel.Visible = false
		tagLabel.Parent = row

		pityBars[t.key] = {
			fillBar = fillBar,
			countLabel = countLabel,
			tagLabel = tagLabel,
		}
	end

	updatePityUI()
end

buildPityTrackerUI()

-- ============ SISTEM FISHDEX HUD (FISH-023) ============
local fishDexBtn
local function buildFishDexHUD()
	fishDexBtn = Instance.new("TextButton")
	fishDexBtn.Name = "FishDexBtn"
	fishDexBtn.Size = UDim2.new(0, 145, 0, 36)
	fishDexBtn.Position = UDim2.new(0, 20, 0.32, 0)
	fishDexBtn.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	fishDexBtn.BackgroundTransparency = 0.25
	fishDexBtn.BorderSizePixel = 0
	fishDexBtn.Text = "📖 FISHDEX [J]"
	fishDexBtn.TextColor3 = Color3.fromRGB(0, 230, 255)
	fishDexBtn.Font = Enum.Font.GothamBlack
	fishDexBtn.TextSize = 12
	fishDexBtn.Parent = gui
	Instance.new("UICorner", fishDexBtn).CornerRadius = UDim.new(0, 10)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(0, 200, 255)
	btnStroke.Thickness = 1.5
	btnStroke.Transparency = 0.4
	btnStroke.Parent = fishDexBtn

	fishDexBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
		if FishDexUI.IsOpen() then
			FishDexUI.Hide()
		else
			FishDexUI.Show(gui, lastPlayerData)
		end
	end)
end

buildFishDexHUD()

-- ============ SISTEM TOKO HUD (FISH-024) ============
local shopBtn
local function buildShopHUD()
	shopBtn = Instance.new("TextButton")
	shopBtn.Name = "ShopBtn"
	shopBtn.Size = UDim2.new(0, 145, 0, 36)
	shopBtn.Position = UDim2.new(0, 20, 0.38, 0)
	shopBtn.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	shopBtn.BackgroundTransparency = 0.25
	shopBtn.BorderSizePixel = 0
	shopBtn.Text = "🛒 TOKO [K]"
	shopBtn.TextColor3 = Color3.fromRGB(251, 191, 36)
	shopBtn.Font = Enum.Font.GothamBlack
	shopBtn.TextSize = 12
	shopBtn.Parent = gui
	Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 10)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(234, 179, 8)
	btnStroke.Thickness = 1.5
	btnStroke.Transparency = 0.4
	btnStroke.Parent = shopBtn

	shopBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
		if ShopUI.IsOpen() then
			ShopUI.Hide()
		else
			ShopUI.Show(gui)
		end
	end)
end

buildShopHUD()

-- ============ SISTEM PANDUAN HUD (FISH-033) ============
local panduanBtn
local function buildPanduanHUD()
	panduanBtn = Instance.new("TextButton")
	panduanBtn.Name = "PanduanBtn"
	panduanBtn.Size = UDim2.new(0, 145, 0, 36)
	panduanBtn.Position = UDim2.new(0, 20, 0.44, 0)
	panduanBtn.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	panduanBtn.BackgroundTransparency = 0.25
	panduanBtn.BorderSizePixel = 0
	panduanBtn.Text = "❓ PANDUAN [H]"
	panduanBtn.TextColor3 = Color3.fromRGB(56, 189, 248)
	panduanBtn.Font = Enum.Font.GothamBlack
	panduanBtn.TextSize = 12
	panduanBtn.Parent = gui
	Instance.new("UICorner", panduanBtn).CornerRadius = UDim.new(0, 10)

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(56, 189, 248)
	btnStroke.Thickness = 1.5
	btnStroke.Transparency = 0.4
	btnStroke.Parent = panduanBtn

	panduanBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.3)
		TutorialUI.ToggleHelpGuide(gui)
	end)
end

buildPanduanHUD()

-- ============ LISTENER INPUT AKTIVASI ============
local lastTriggerTime = 0
local function handleInteractionTrigger()
	local now = os.clock()
	if now - lastTriggerTime < 0.25 then return end
	lastTriggerTime = now

	-- 1. Jika meter lemparan sedang aktif, kunci dan lempar kail
	if fsm:Is(FishingStateMachine.States.CHARGING_CAST) then
		if now - meterStartTime < 0.20 then return end
		executeCastAfterMeter()
		return
	end

	-- 2. Jika sedang memancing atau minigame aktif, abaikan input klik untuk melempar kail
	if fsm:IsBusy() or RhythmController.IsPlaying() then
		return
	end

	-- 3. Hanya mulai mengisi bar lemparan jika status benar-benar IDLE
	if fsm:Is(FishingStateMachine.States.IDLE) then
		local waterPos = findWaterTarget()
		if waterPos then
			startCastingMeter(waterPos)
		else
			showMessage("Arahkan atau dekati area lautan/air untuk mulai memancing!", Color3.fromRGB(220, 220, 240), 2.5)
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Hotkey B atau I untuk Toggle Inventory
	if not gameProcessed and (input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.I) then
		toggleInventory()
		return
	end

	-- Hotkey J untuk Toggle FishDex
	if not gameProcessed and (input.KeyCode == Enum.KeyCode.J) then
		if FishDexUI.IsOpen() then
			FishDexUI.Hide()
		else
			FishDexUI.Show(gui, lastPlayerData)
		end
		return
	end

	-- Hotkey K untuk Toggle Toko Samudra
	if not gameProcessed and (input.KeyCode == Enum.KeyCode.K) then
		if ShopUI.IsOpen() then
			ShopUI.Hide()
		else
			ShopUI.Show(gui)
		end
		return
	end

	-- Hotkey P atau L untuk Toggle Jalur Progresi & Roadmap
	if not gameProcessed and (input.KeyCode == Enum.KeyCode.P or input.KeyCode == Enum.KeyCode.L) then
		ProgressionRoadmapUI.Toggle(gui, lastPlayerData)
		return
	end

	-- Hotkey H untuk Toggle Buku Panduan Nelayan (FISH-033)
	if not gameProcessed and (input.KeyCode == Enum.KeyCode.H) then
		TutorialUI.ToggleHelpGuide(gui)
		return
	end
	if gameProcessed then return end

	-- Jangan tangani interaksi pancing jika minigame sedang berjalan (karena [A,W,S,D] dipakai oleh minigame)
	if RhythmController.IsPlaying() then return end

	if isCastingMeterActive then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.E then
			handleInteractionTrigger()
		end
		return
	end

	if isRodEquipped() then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.E then
			handleInteractionTrigger()
		end
	end
end)

local function hookTool(tool)
	if not tool or not tool:IsA("Tool") then return end
	if tool.Name == "FishingRod" or tool.Name == "Pancingan" or tool:GetAttribute("IsRod") == true then
		tool.Unequipped:Connect(function()
			if not fsm:Is(FishingStateMachine.States.IDLE) then
				destroyBobberSafely()
				RhythmController.Cancel()
				fsm:ForceReset("ToolUnequipped")
			end
		end)
	else
		tool:GetAttributeChangedSignal("IsLocked"):Connect(function()
			updateInventoryUI()
		end)
	end
end

local function watchInventory()
	local backpack = player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then hookTool(child) end
		updateInventoryUI()
	end)
	backpack.ChildRemoved:Connect(function()
		updateInventoryUI()
	end)

	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") then hookTool(child) end
	end

	player.CharacterAdded:Connect(function(char)
		fsm:ForceReset("CharacterSpawn")
		AnimSystem.ResetJoints()
		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then hookTool(child) end
			updateInventoryUI()
		end)
		char.ChildRemoved:Connect(function()
			updateInventoryUI()
		end)
	end)
	if player.Character then
		for _, child in ipairs(player.Character:GetChildren()) do
			if child:IsA("Tool") then hookTool(child) end
		end
		player.Character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then hookTool(child) end
			updateInventoryUI()
		end)
		player.Character.ChildRemoved:Connect(function()
			updateInventoryUI()
		end)
	end
end

watchInventory()

-- ============ RESPON REMOTE SERVER ============
if remote then
	remote.OnClientEvent:Connect(function(action, arg1, arg2, arg3, arg4)
		if action == RemoteContract.S2C.SESSION_STARTED then
			local sessionId = arg1
			local waitDuration = arg2 or 3.0
			local castQuality = arg3 or "GOOD"

			task.spawn(function()
				onSessionStarted(
					sessionId,
					waitDuration,
					castQuality
				)
			end)
		elseif action == RemoteContract.S2C.CATCH_SUCCESS then
			local fishData = arg1 or {}
			local rewardInfo = arg2 or {}
			local pData = arg3 or {}
			local pityState = arg4 or {}

			print(string.format("[FishingClient] 🎉 CatchSuccess diterima dari Server! Ikan: %s (%s) | Bobot: %.1f Kg | Koin: +%d", tostring(fishData.name or "Ikan"), tostring(fishData.rarity or "COMMON"), tonumber(fishData.weight or 1) or 1, tonumber(rewardInfo.coins or 0) or 0))
			showMessage(string.format("🎉 TANGKAPAN BERHASIL: %s (%s) • +%d Koin • +%d EXP", tostring(fishData.name or "Ikan"), tostring(fishData.rarity or "COMMON"), tonumber(rewardInfo.coins or 15) or 15, tonumber(rewardInfo.exp or 10) or 10), Color3.fromRGB(50, 255, 130), 4.0)

			-- Trigger catch victory fanfare & 3D particle celebration (FISH-036)
			AudioEffectsSystem.PlayCatchFanfare(fishData.rarity, fishData.grade or "A")
			local char = player.Character
			if char then
				VisualEffectsSystem.CreateCatchCelebration(char, fishData.rarity)
				VisualEffectsSystem.SpawnFloatingReward(char, string.format("+%d 💰  +%d XP", tonumber(rewardInfo.coins or 15) or 15, tonumber(rewardInfo.exp or 10) or 10), Color3.fromRGB(255, 225, 60))
			end

			clientPity = pityState

			-- Temukan instance tool tangkapan di backpack/karakter pemain
			local foundTool = nil
			local allBackpackFish = getFishInBackpack()
			for _, t in ipairs(allBackpackFish) do
				if (fishData.itemId and t:GetAttribute("ItemId") == fishData.itemId) or t:GetAttribute("FishName") == fishData.name or t.Name:find(fishData.name or "") then
					foundTool = t
					break
				end
			end
			if not foundTool and #allBackpackFish > 0 then
				foundTool = allBackpackFish[#allBackpackFish]
			end

			-- Tampilkan Layar Modal Hasil Tangkapan (FishingResultUI)
			FishingResultUI.Show(gui, {
				fishData = fishData,
				rewardInfo = rewardInfo,
				pityState = pityState,
				toolInstance = foundTool,
				playerData = pData or lastPlayerData,
			}, function(actionType, targetTool)
				if actionType == "LOCK" then
					if targetTool and targetTool.Parent then
						RemoteContract.Client.ToggleLockItem(targetTool)
					end
				elseif actionType == "SELL" then
					if targetTool and targetTool.Parent then
						RemoteContract.Client.SellFish(targetTool)
					end
				end
				updateInventoryUI()
				updatePityUI()
			end)

			if pData and typeof(pData) == "table" then
				mergePlayerData(pData)
				if pData.journal then
					FishDexUI.UpdateJournalData(pData.journal)
				end
			end

			advanceTutorial(4)

			updateInventoryUI()
			updatePityUI()
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
		elseif action == RemoteContract.S2C.FISH_SOLD then
			local fishName = arg1 or "Ikan"
			local coinsGained = tonumber(arg2) or 0
			local currentCoins = tonumber(arg3) or 0

			if currentCoins > 0 then
				lastPlayerData.coins = currentCoins
			else
				lastPlayerData.coins = (lastPlayerData.coins or 0) + coinsGained
			end

			-- Jika pemain sedang berada di langkah tutorial 4, selesaikan tutorial
			if lastPlayerData and lastPlayerData.tutorialCompleted == false and (lastPlayerData.tutorialStep or 0) >= 4 then
				RemoteContract.Client.FinishTutorial()
			end

			showMessage(string.format("💰 Berhasil menjual %s seharga +%d Koin!", fishName, coinsGained), Color3.fromRGB(50, 255, 130), 3.5)
			spawnFloatingCoinEffect(coinsGained, "Terjual: " .. fishName)
			EconomyHUD.ShowTransactionNotification("💰 IKAN TERJUAL", string.format("+%d Koin • %s", coinsGained, fishName), true)
			AudioEffectsSystem.PlayItemSell()
			updateInventoryUI()
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
		elseif action == RemoteContract.S2C.ALL_FISH_SOLD then
			local count = tonumber(arg1) or 0
			local totalCoins = tonumber(arg2) or 0
			local currentCoins = tonumber(arg3) or 0

			if currentCoins > 0 then
				lastPlayerData.coins = currentCoins
			else
				lastPlayerData.coins = (lastPlayerData.coins or 0) + totalCoins
			end

			-- Jika pemain sedang berada di langkah tutorial 4, selesaikan tutorial
			if lastPlayerData and lastPlayerData.tutorialCompleted == false and (lastPlayerData.tutorialStep or 0) >= 4 then
				RemoteContract.Client.FinishTutorial()
			end

			showMessage(string.format("💰 Berhasil menjual %d Ikan seharga total +%d Koin!", count, totalCoins), Color3.fromRGB(50, 255, 130), 4.0)
			spawnFloatingCoinEffect(totalCoins, string.format("Jual Massal %d Tangkapan", count))
			EconomyHUD.ShowTransactionNotification("💰 JUAL MASSAL", string.format("+%d Koin (%d Tangkapan)", totalCoins, count), true)
			AudioEffectsSystem.PlayItemSell()
			AudioEffectsSystem.PlayCoinGain()
			updateInventoryUI()
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
		elseif action == RemoteContract.S2C.LEVEL_UP then
			local newLevel = arg1 or 2
			local oldLevel = lastPlayerData.level or (newLevel - 1)
			lastPlayerData.level = newLevel
			showMessage("⭐ LEVEL UP! Selamat, kamu sekarang Level " .. newLevel .. "! ⭐", Color3.fromRGB(255, 215, 0), 4.5)
			AudioEffectsSystem.PlayLevelUp()
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())

			-- Tampilkan Modal Perayaan Naik Level & Unlocks (FISH-032)
			LevelUpUI.Show(gui, newLevel, oldLevel, lastPlayerData, function(actionType)
				if actionType == "OPEN_SHOP" then
					ShopUI.Show(gui, nil, "RODS")
				end
			end)
		elseif action == RemoteContract.S2C.TUTORIAL_COMPLETED then
			local rewardData = arg1 or {}
			lastPlayerData.tutorialCompleted = true
			lastPlayerData.tutorialStep = 5
			if rewardData.coins then
				lastPlayerData.coins = (lastPlayerData.coins or 0) + rewardData.coins
			end
			TutorialUI.ShowCelebrationModal(gui, rewardData, function()
				-- Pemain mengonfirmasi klaim hadiah
			end)
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
		elseif action == RemoteContract.S2C.PLAYER_DATA_UPDATE then
			local pData = arg1 or {}
			local pityState = arg2 or pData.pity or {}
			mergePlayerData(pData)
			clientPity = pityState
			if pData.journal then
				FishDexUI.UpdateJournalData(pData.journal)
			end
			syncTutorialState(lastPlayerData)
			updatePityUI()
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
		elseif action == RemoteContract.S2C.SHOP_CATALOG_DATA then
			local catalog = arg1
			ShopUI.UpdateCatalogData(catalog)
			if catalog and typeof(catalog) == "table" then
				if catalog.coins ~= nil then
					lastPlayerData.coins = catalog.coins
				end
				if catalog.totalExp ~= nil then
					lastPlayerData.totalExp = catalog.totalExp
					lastPlayerData.exp = catalog.exp or lastPlayerData.exp
					lastPlayerData.level = catalog.level or lastPlayerData.level
				end
				EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
			end
			if catalog and catalog.openModal and not ShopUI.IsOpen() then
				ShopUI.Show(gui, catalog, catalog.initialTab)
			end
		elseif action == RemoteContract.S2C.SHOP_TRANSACTION_SUCCESS then
			local itemType = arg1
			local itemId = arg2
			local details = arg3
			local newCoins = arg4
			if newCoins then
				lastPlayerData.coins = newCoins
			end
			showMessage(string.format("🎉 Transaksi Berhasil: %s!", tostring(details or itemId)), Color3.fromRGB(50, 255, 130), 3.5)
			EconomyHUD.ShowTransactionNotification("🛍️ TRANSAKSI BERHASIL", tostring(details or itemId), false)
			AudioEffectsSystem.PlayCoinGain()
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
			RemoteContract.Client.GetShopCatalog()
		elseif action == RemoteContract.S2C.SHOP_TRANSACTION_FAILED then
			showMessage("❌ " .. tostring(arg1 or "Transaksi gagal"), Color3.fromRGB(255, 100, 100), 3.5)
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.8, 0.7)
		elseif action == RemoteContract.S2C.ROD_EQUIPPED then
			local rodId = arg1
			local rodData = arg2
			local rodName = (rodData and rodData.name) or rodId or "Joran"
			local luckVal = (rodData and rodData.luckBonus) or 5
			local instType = (rodData and rodData.instrumentType) or InstrumentDefinitions.GetInstrumentTypeForRod(rodId)
			lastPlayerData.equippedRod = rodId
			lastPlayerData.equippedInstrument = instType
			local instData = InstrumentDefinitions.GetInstrumentData(instType)
			showMessage(string.format("🎣 Berhasil memasang %s (%s | +%d Luck)!", rodName, instData.badge or "JORAN", luckVal), instData.color or Color3.fromRGB(0, 230, 255), 3.5)
			playSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 1.5)
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
			RemoteContract.Client.GetShopCatalog()
		elseif action == RemoteContract.S2C.BAIT_UPDATED then
			local eqBait = arg1
			local baits = arg2
			lastPlayerData.equippedBait = eqBait
			lastPlayerData.baits = baits
			if eqBait and eqBait ~= "" and eqBait ~= "NONE" then
				local bData = EconomyConfig.GetBait(eqBait)
				showMessage(string.format("🪱 Umpan terpasang: %s (+%d Luck)", bData and bData.name or eqBait, bData and bData.luckBonus or 0), Color3.fromRGB(74, 222, 128), 2.5)
			end
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
			RemoteContract.Client.GetShopCatalog()
		elseif action == RemoteContract.S2C.BAG_UPGRADED then
			local newTier = arg1
			local totalSlots = arg2
			local newCoins = arg3
			if newCoins then lastPlayerData.coins = newCoins end
			lastPlayerData.bagUpgradeTier = newTier
			lastPlayerData.maxInventorySlots = totalSlots
			showMessage(string.format("🎒 Kapasitas tas berhasil diperluas menjadi %d Slot (Tier %d)!", totalSlots, newTier), Color3.fromRGB(255, 215, 0), 4.0)
			playSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 2.0)
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
			RemoteContract.Client.GetShopCatalog()
		elseif action == RemoteContract.S2C.INSTRUMENT_UNLOCKED then
			local instType = arg1
			local instData = arg2 or InstrumentDefinitions.GetInstrumentData(instType)
			lastPlayerData.unlockedInstruments = lastPlayerData.unlockedInstruments or {}
			if not table.find(lastPlayerData.unlockedInstruments, instType) then
				table.insert(lastPlayerData.unlockedInstruments, instType)
			end
			local badge = instData and instData.badge or ("🎵 " .. tostring(instType))
			local name = instData and instData.name or tostring(instType)
			local desc = instData and instData.desc or "Minigame ritme baru telah terbuka!"
			local color = instData and instData.color or Color3.fromRGB(255, 215, 0)
			showMessage(string.format("🎉 INSTRUMEN TERBUKA: %s (%s)!", name, badge), color, 5.0)
			EconomyHUD.ShowTransactionNotification("🌟 INSTRUMEN BARU", string.format("%s • %s", name, desc), false)
			playSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 2.0)
			EconomyHUD.Update(lastPlayerData, #getFishInBackpack())
			RemoteContract.Client.GetShopCatalog()
		elseif action == RemoteContract.S2C.NOTIFICATION then
			showMessage(arg1, Color3.fromRGB(255, 200, 80), 3.5)
			if tostring(arg1):find("❌") or tostring(arg1):find("tidak valid") or tostring(arg1):find("Gagal") then
				fsm:ForceReset("ServerRejectedAction")
			end
		end
	end)

	-- Request Data Pemain Awal & Katalog Toko
	task.defer(function()
		RemoteContract.Client.GetPlayerData()
		RemoteContract.Client.GetShopCatalog()
	end)

	-- Client ProximityPrompt Handler untuk respon instan
	local ProximityPromptService = game:GetService("ProximityPromptService")
	
	local function sanitizeClientPrompt(prompt)
		if not prompt:IsA("ProximityPrompt") then return end
		if prompt.Parent and prompt.Parent:IsA("Model") then
			local model = prompt.Parent
			local targetPart = model.PrimaryPart 
				or model:FindFirstChild("HumanoidRootPart") 
				or model:FindFirstChild("Torso") 
				or model:FindFirstChild("UpperTorso") 
				or model:FindFirstChild("Head") 
				or model:FindFirstChildWhichIsA("BasePart")
			if targetPart then
				prompt.Parent = targetPart
			end
		end
		if prompt.MaxActivationDistance < 12 then
			prompt.MaxActivationDistance = 14
		end
		prompt.RequiresLineOfSight = false
	end

	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			sanitizeClientPrompt(desc)
		end
	end

	workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") then
			task.defer(function()
				sanitizeClientPrompt(desc)
			end)
		end
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local pName = prompt.Name:lower()
		local pAction = prompt.ActionText:lower()
		local pObject = prompt.ObjectText:lower()
		local parentName = (prompt.Parent and prompt.Parent.Name:lower()) or ""
		local modelName = (prompt.Parent and prompt.Parent:IsA("Model") and prompt.Parent.Name:lower())
			or (prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent:IsA("Model") and prompt.Parent.Parent.Name:lower())
			or ""
		local allText = string.format("%s %s %s %s %s", pName, pAction, pObject, parentName, modelName)

		RemoteContract.Client.GetShopCatalog()
		if not ShopUI.IsOpen() then
			if allText:find("sell") or allText:find("jual") or allText:find("merchant") or allText:find("pedagang")
				or allText:find("ikan") or allText:find("lapak") or allText:find("pasar") then
				ShopUI.Show(gui, nil, "SELL")
			else
				ShopUI.Show(gui, nil, "RODS")
			end
		end
	end)
end
