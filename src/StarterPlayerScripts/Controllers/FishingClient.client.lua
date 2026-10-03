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

local remote = ReplicatedStorage:WaitForChild("FishingRemote", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PianoTilesGame = require(Shared:WaitForChild("Minigames"):WaitForChild("PianoTilesGame"))
local FishingRaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))
local fishTemplate = ReplicatedStorage:WaitForChild("AnimatedFish", 5)
local bobberTemplate = ReplicatedStorage:WaitForChild("BobberTemplate", 5)

local clientPity = { LEGENDARY = 0, MYTHIC = 0, SPECIAL = 0 }
local activeSessionId = nil

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
gui.Parent = pGui or workspace

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

local function createWaterSplash(pos)
	local emitterPart = Instance.new("Part")
	emitterPart.Size = Vector3.new(1, 0.2, 1)
	emitterPart.Position = pos
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.Transparency = 1
	emitterPart.Parent = workspace
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255), Color3.fromRGB(255, 255, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1.8)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Speed = NumberRange.new(8, 14)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Acceleration = Vector3.new(0, -28, 0)
	emitter.Lifetime = NumberRange.new(0.4, 0.7)
	emitter.Rate = 0
	emitter.Parent = emitterPart
	
	emitter:Emit(25)
	playSound("rbxasset://sounds/splat.wav", 0.5, 1.2)
	Debris:AddItem(emitterPart, 1.5)
end

local function showStrikeAlert(pos)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 64, 0, 64)
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

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "!"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 38
	label.Parent = badge

	badge.Size = UDim2.fromScale(0.2, 0.2)
	badge.Position = UDim2.fromScale(0.4, 0.4)
	local pop = TweenService:Create(badge, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0, 0)
	})
	pop:Play()

	playSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.6)

	task.delay(1.5, function()
		if billboard and billboard.Parent then
			billboard:Destroy()
		end
	end)
end

local function animateFishLeap(startPos, endPos, duration, height)
	duration = duration or 0.8
	height = height or 6
	
	local fish = fishTemplate and fishTemplate:Clone()
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
local function getEquippedRod()
	local character = player.Character
	if not character then return nil end
	local rod = character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan")
	if rod and rod:IsA("Tool") then
		return rod
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
	local rod = (backpack and (backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan")))
	return rod
end

local function hasFishingRod()
	return getFishingRod() ~= nil
end

local function ensureEquipped()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChild("Backpack")
	if not character or not humanoid or not backpack then return end
	
	local equipped = character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan")
	if not equipped then
		local inBackpack = backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan")
		if inBackpack then
			humanoid:EquipTool(inBackpack)
		end
	end
end

local function freezePlayer(freeze)
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if freeze then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
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

	playSound("rbxasset://sounds/action_whoosh.mp3", 0.75, 1.1)
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
	if inst and inst:IsA("BasePart") then
		local name = inst.Name:lower()
		if inst.Material == Enum.Material.Water
			or name:find("ocean")
			or name:find("water")
			or name:find("lake")
			or name:find("danau")
			or name:find("river")
			or name:find("sungai")
			or name:find("laut")
			or name:find("sea")
			or name:find("pool")
			or name:find("kolam") then
			return true
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

	local mouse = player:GetMouse()
	if mouse and mouse.UnitRay then
		local mouseResult = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 150, rayParams)
		if mouseResult and isWaterInstance(mouseResult.Instance, mouseResult.Material) then
			local dist = (mouseResult.Position - hrp.Position).Magnitude
			if dist >= 6 and dist <= 48 then
				return mouseResult.Position
			end
		end
	end

	local lookCFrame = hrp.CFrame
	local angles = { 0, -15, 15, -30, 30, -45, 45 }
	local distances = { 12, 20, 30, 42 }

	for _, dist in ipairs(distances) do
		for _, angleDeg in ipairs(angles) do
			local checkDir = (lookCFrame * CFrame.Angles(0, math.rad(angleDeg), 0)).LookVector
			local startPos = hrp.Position + (checkDir * dist) + Vector3.new(0, 10, 0)
			local downRay = workspace:Raycast(startPos, Vector3.new(0, -35, 0), rayParams)
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

-- ============ ALUR MEMANCING LENGKAP ============
local busy = false
local executeCastAfterMeter = nil
local activeBobber = nil

local function startCastingMeter(waterPos)
	if busy or isCastingMeterActive or PianoTilesGame.IsPlaying() then return end

	if not hasFishingRod() then
		showMessage("⚠️ Kamu membutuhkan Joran Pancing di inventory untuk memancing!", Color3.fromRGB(255, 80, 80), 3.5)
		playSound("rbxasset://sounds/splat.wav", 0.5, 0.7)
		return
	end

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
		if not isCastingMeterActive then return end
		local elapsed = os.clock() - meterStartTime
		local pingPong = (math.sin(elapsed * meterSpeed - math.pi / 2) + 1) / 2
		currentCastPower = pingPong
		updateMeterVisual(currentCastPower)

		if elapsed > 4.5 then
			executeCastAfterMeter()
		end
	end)
end

executeCastAfterMeter = function()
	if not isCastingMeterActive then return end
	isCastingMeterActive = false
	if meterConn then
		meterConn:Disconnect()
		meterConn = nil
	end
	castMeterContainer.Visible = false

	local finalPower = currentCastPower
	local waterPos = currentWaterTarget or findWaterTarget()
	if not waterPos then
		busy = false
		freezePlayer(false)
		AnimSystem.ResetJoints()
		return
	end

	busy = true

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

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if activeBobber then activeBobber:Destroy() end
	activeBobber = bobberTemplate and bobberTemplate:Clone() or Instance.new("Part")
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

	if char then
		AnimSystem.PlayCast(char, waterPos)
		AnimSystem.CreateFishingLine(char, activeBobber)
		AnimSystem.StartFishingStance(char)
	end

	createWaterSplash(waterPos)

	if remote then
		remote:FireServer("StartFishing", waterPos, castQuality, finalPower)
	end
end

local function onSessionStarted(sessionId, waitDuration, castQuality, rarity)
	activeSessionId = sessionId
	local waterPos = currentWaterTarget or findWaterTarget()
	if not waterPos then return end

	if castQuality == "PERFECT" then
		showMessage("⭐ PERFECT CAST! (+35 Luck) Sambaran Kilat!", Color3.fromRGB(255, 215, 0), 3)
	elseif castQuality == "GREAT" then
		showMessage("✨ GREAT CAST! (+15 Luck) Peluang Rarity Meningkat!", Color3.fromRGB(0, 220, 255), 3)
	else
		showMessage("🎣 Kail di air... Menunggu ikan menyambar...", Color3.fromRGB(150, 220, 255), 3.5)
	end

	task.wait(waitDuration)
	if not busy or activeSessionId ~= sessionId then
		if activeBobber then activeBobber:Destroy() end
		AnimSystem.ResetJoints()
		freezePlayer(false)
		return
	end

	AnimSystem.SetPhase("Biting")
	showStrikeAlert(waterPos)
	createWaterSplash(waterPos)

	local fishStart = waterPos + Vector3.new(math.random(-3, 3), -1, math.random(-3, 3))
	local fishEnd = waterPos + Vector3.new(math.random(-3, 3), -1, math.random(-3, 3))
	animateFishLeap(fishStart, fishEnd, 0.75, 4.5)

	local bobberPart = activeBobber:IsA("Model") and activeBobber.PrimaryPart or activeBobber
	if bobberPart then
		local down = TweenService:Create(bobberPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = waterPos - Vector3.new(0, 1.2, 0)
		})
		down:Play()
		down.Completed:Wait()
		TweenService:Create(bobberPart, TweenInfo.new(0.25, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
			Position = waterPos + Vector3.new(0, 0.4, 0)
		}):Play()
	end

	showMessage("🎣 IKAN MENYAMBAR! Mainkan Piano Tiles (D, F, J, K)!", Color3.fromRGB(255, 220, 50), 3.5)
	AnimSystem.SetPhase("Reeling")

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	PianoTilesGame.Start({
		castQuality = castQuality,
		tier = rarity,
	}, function(metrics)
		AnimSystem.PlayVictoryLift(char)
		local catchTarget = hrp and (hrp.Position + Vector3.new(0, 1.5, 0)) or (waterPos + Vector3.new(0, 5, 0))
		animateFishLeap(waterPos, catchTarget, 0.9, 7)
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.8)

		if remote and activeSessionId then
			remote:FireServer("SubmitCatch", activeSessionId, metrics)
		end

		task.delay(2.8, function()
			if activeBobber then activeBobber:Destroy() end
			AnimSystem.ResetJoints()
			busy = false
			freezePlayer(false)
		end)
	end, function(metrics)
		createWaterSplash(waterPos)
		showMessage("❌ Ikan terlepas! Irama musik belum tepat.", Color3.fromRGB(255, 75, 75), 3)

		if remote and activeSessionId then
			remote:FireServer("CancelFishing", activeSessionId)
		end

		task.delay(1.5, function()
			if activeBobber then activeBobber:Destroy() end
			AnimSystem.ResetJoints()
			busy = false
			freezePlayer(false)
		end)
	end)
end

-- ============ SISTEM INVENTORY & PENJUALAN IKAN ============
local inventoryFrame, inventoryList, invTotalFishLabel, invTotalCoinsLabel, invSellAllBtn
local invToggleBtn, invBadge

local function getFishInBackpack()
	local fishList = {}
	local backpack = player:FindFirstChild("Backpack")
	local char = player.Character

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and (item:GetAttribute("IsFish") == true or (item.Name ~= "FishingRod" and item.Name ~= "Pancingan")) then
				table.insert(fishList, item)
			end
		end
	end
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") and (item:GetAttribute("IsFish") == true or (item.Name ~= "FishingRod" and item.Name ~= "Pancingan")) then
				table.insert(fishList, item)
			end
		end
	end

	return fishList
end

local function updateInventoryUI()
	if not inventoryFrame or not inventoryList then return end

	-- Bersihkan list sebelumnya
	for _, child in ipairs(inventoryList:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local allFish = getFishInBackpack()
	local totalCoins = 0

	if invBadge then
		invBadge.Text = tostring(#allFish)
		invBadge.Visible = #allFish > 0
	end

	if invTotalFishLabel then
		invTotalFishLabel.Text = "🎣 Total Ikan: " .. #allFish
	end

	if #allFish == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, -20, 0, 120)
		emptyLabel.Position = UDim2.new(0, 10, 0, 40)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "🎣 Belum ada ikan di inventory.\nAyo memancing di lautan luas!"
		emptyLabel.TextColor3 = Color3.fromRGB(160, 180, 200)
		emptyLabel.Font = Enum.Font.GothamMedium
		emptyLabel.TextSize = 15
		emptyLabel.Parent = inventoryList

		if invTotalCoinsLabel then
			invTotalCoinsLabel.Text = "💰 Estimasi Nilai: 0 Koin"
		end
		if invSellAllBtn then
			invSellAllBtn.Text = "💰 JUAL SEMUA IKAN (0 Koin)"
			invSellAllBtn.BackgroundColor3 = Color3.fromRGB(50, 60, 75)
		end
		return
	end

	for _, tool in ipairs(allFish) do
		local rName = tool:GetAttribute("Rarity") or "COMMON"
		local tierData = FishingRaritySystem.GetTierData(rName)
		local fishName = tool:GetAttribute("FishName") or tool.Name
		local dispName = tool:GetAttribute("DisplayName") or tierData.displayName
		local stars = tool:GetAttribute("Stars") or tierData.stars
		local weight = tonumber(tool:GetAttribute("Weight")) or 1.0
		local coins = tonumber(tool:GetAttribute("Coins")) or 15
		local color = tierData.color or Color3.fromRGB(0, 200, 255)

		totalCoins += coins

		local card = Instance.new("Frame")
		card.Name = "FishCard_" .. tool.Name
		card.Size = UDim2.new(1, -12, 0, 64)
		card.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
		card.BackgroundTransparency = 0.25
		card.BorderSizePixel = 0
		card.Parent = inventoryList
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = color
		cardStroke.Thickness = 1.5
		cardStroke.Transparency = 0.35
		cardStroke.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.62, 0, 0, 22)
		nameLabel.Position = UDim2.new(0, 14, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = string.format("[%s] %s %s", dispName, fishName, stars)
		nameLabel.TextColor3 = color
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(0.62, 0, 0, 18)
		statsLabel.Position = UDim2.new(0, 14, 0, 32)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Text = string.format("⚖️ %.1f Kg  |  💰 Nilai: %d Koin", weight, coins)
		statsLabel.TextColor3 = Color3.fromRGB(220, 235, 255)
		statsLabel.Font = Enum.Font.GothamMedium
		statsLabel.TextSize = 12
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = card

		local sellBtn = Instance.new("TextButton")
		sellBtn.Name = "SellBtn"
		sellBtn.Size = UDim2.new(0, 110, 0, 36)
		sellBtn.Position = UDim2.new(1, -124, 0.5, -18)
		sellBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
		sellBtn.BorderSizePixel = 0
		sellBtn.Text = string.format("Jual (💰 %d)", coins)
		sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		sellBtn.Font = Enum.Font.GothamBold
		sellBtn.TextSize = 12
		sellBtn.Parent = card
		Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 8)

		sellBtn.MouseButton1Click:Connect(function()
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.4)
			if remote and tool and tool.Parent then
				remote:FireServer("SellFish", tool)
			end
		end)
	end

	if invTotalCoinsLabel then
		invTotalCoinsLabel.Text = string.format("💰 Total Nilai: %d Koin", totalCoins)
	end
	if invSellAllBtn then
		invSellAllBtn.Text = string.format("💰 JUAL SEMUA IKAN (💰 %d Koin)", totalCoins)
		invSellAllBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 95)
	end
end

local function toggleInventory(forcedState)
	if not inventoryFrame then return end
	local newState = (forcedState ~= nil) and forcedState or (not inventoryFrame.Visible)
	if newState then
		updateInventoryUI()
		inventoryFrame.Visible = true
		inventoryFrame.Size = UDim2.new(0, 480, 0, 420)
		inventoryFrame.Position = UDim2.new(0.5, -240, 0.5, -210)
		TweenService:Create(inventoryFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 520, 0, 460),
			Position = UDim2.new(0.5, -260, 0.5, -230)
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
	invToggleBtn.Size = UDim2.new(0, 140, 0, 44)
	invToggleBtn.Position = UDim2.new(0, 20, 0.24, 0)
	invToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	invToggleBtn.BackgroundTransparency = 0.25
	invToggleBtn.BorderSizePixel = 0
	invToggleBtn.Text = "🎒 INVENTORY"
	invToggleBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
	invToggleBtn.Font = Enum.Font.GothamBlack
	invToggleBtn.TextSize = 13
	invToggleBtn.Parent = gui
	Instance.new("UICorner", invToggleBtn).CornerRadius = UDim.new(0, 12)

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
	inventoryFrame.Size = UDim2.new(0, 520, 0, 460)
	inventoryFrame.Position = UDim2.new(0.5, -260, 0.5, -230)
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
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.Parent = inventoryFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0.7, 0, 0, 26)
	title.Position = UDim2.new(0, 18, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "🎒 INVENTORY IKAN"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(0.7, 0, 0, 16)
	subtitle.Position = UDim2.new(0, 18, 0, 32)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Jual hasil tangkapan untuk menambah Koin!"
	subtitle.TextColor3 = Color3.fromRGB(160, 200, 230)
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextSize = 12
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -44, 0, 11)
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

	-- Subheader Stats
	local statsBar = Instance.new("Frame")
	statsBar.Size = UDim2.new(1, -36, 0, 30)
	statsBar.Position = UDim2.new(0, 18, 0, 60)
	statsBar.BackgroundColor3 = Color3.fromRGB(20, 28, 44)
	statsBar.BackgroundTransparency = 0.5
	statsBar.BorderSizePixel = 0
	statsBar.Parent = inventoryFrame
	Instance.new("UICorner", statsBar).CornerRadius = UDim.new(0, 8)

	invTotalFishLabel = Instance.new("TextLabel")
	invTotalFishLabel.Size = UDim2.new(0.48, 0, 1, 0)
	invTotalFishLabel.Position = UDim2.new(0.03, 0, 0, 0)
	invTotalFishLabel.BackgroundTransparency = 1
	invTotalFishLabel.Text = "🎣 Total Ikan: 0"
	invTotalFishLabel.TextColor3 = Color3.fromRGB(0, 210, 255)
	invTotalFishLabel.Font = Enum.Font.GothamBold
	invTotalFishLabel.TextSize = 12
	invTotalFishLabel.TextXAlignment = Enum.TextXAlignment.Left
	invTotalFishLabel.Parent = statsBar

	invTotalCoinsLabel = Instance.new("TextLabel")
	invTotalCoinsLabel.Size = UDim2.new(0.48, 0, 1, 0)
	invTotalCoinsLabel.Position = UDim2.new(0.49, 0, 0, 0)
	invTotalCoinsLabel.BackgroundTransparency = 1
	invTotalCoinsLabel.Text = "💰 Total Nilai: 0 Koin"
	invTotalCoinsLabel.TextColor3 = Color3.fromRGB(255, 220, 60)
	invTotalCoinsLabel.Font = Enum.Font.GothamBold
	invTotalCoinsLabel.TextSize = 12
	invTotalCoinsLabel.TextXAlignment = Enum.TextXAlignment.Right
	invTotalCoinsLabel.Parent = statsBar

	-- Scrollable List Ikan
	inventoryList = Instance.new("ScrollingFrame")
	inventoryList.Name = "InventoryList"
	inventoryList.Size = UDim2.new(1, -36, 1, -165)
	inventoryList.Position = UDim2.new(0, 18, 0, 98)
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

	-- Bottom Bar (Sell All)
	invSellAllBtn = Instance.new("TextButton")
	invSellAllBtn.Name = "SellAllBtn"
	invSellAllBtn.Size = UDim2.new(1, -36, 0, 44)
	invSellAllBtn.Position = UDim2.new(0, 18, 1, -54)
	invSellAllBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 95)
	invSellAllBtn.BorderSizePixel = 0
	invSellAllBtn.Text = "💰 JUAL SEMUA IKAN (0 Koin)"
	invSellAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	invSellAllBtn.Font = Enum.Font.GothamBlack
	invSellAllBtn.TextSize = 14
	invSellAllBtn.Parent = inventoryFrame
	Instance.new("UICorner", invSellAllBtn).CornerRadius = UDim.new(0, 10)

	invSellAllBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.8, 1.4)
		if remote then
			remote:FireServer("SellAllFish")
		end
	end)

	updateInventoryUI()
end

buildInventoryUI()

-- ============ LISTENER INPUT AKTIVASI ============
local lastTriggerTime = 0
local function handleInteractionTrigger()
	local now = os.clock()
	if now - lastTriggerTime < 0.12 then return end
	lastTriggerTime = now

	if isCastingMeterActive then
		if now - meterStartTime < 0.20 then return end
		executeCastAfterMeter()
		return
	end

	if busy or PianoTilesGame.IsPlaying() then return end

	local waterPos = findWaterTarget()
	if waterPos then
		startCastingMeter(waterPos)
	else
		showMessage("Arahkan atau dekati area lautan/air untuk mulai memancing!", Color3.fromRGB(220, 220, 240), 2.5)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Hotkey B atau I untuk Toggle Inventory
	if not gameProcessed and (input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.I) then
		toggleInventory()
		return
	end

	if gameProcessed then return end

	if isCastingMeterActive then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.E then
			handleInteractionTrigger()
		end
		return
	end

	if isRodEquipped() and not PianoTilesGame.IsPlaying() then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.E then
			handleInteractionTrigger()
		end
	end
end)

local function hookTool(tool)
	if tool.Name == "FishingRod" or tool.Name == "Pancingan" then
		tool.Activated:Connect(function()
			if isCastingMeterActive or (isRodEquipped() and not PianoTilesGame.IsPlaying()) then
				handleInteractionTrigger()
			end
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
		if action == "SessionStarted" then
			local sessionId = arg1
			local waitDuration = arg2 or 3.0
			local castQuality = arg3 or "GOOD"
			local rarity = arg4 or "COMMON"

			print("[FishingClient] Rarity:", rarity)

			task.spawn(function()
				onSessionStarted(
					sessionId,
					waitDuration,
					castQuality,
					rarity
				)
			end)
		elseif action == "CatchSuccess" then
			local fishData = arg1 or {}
			local rewardInfo = arg2 or {}
			local pData = arg3 or {}
			local pityState = arg4 or {}

			clientPity = pityState

			local name = fishData.name or "Ikan"
			local disp = fishData.displayName or "COMMON"
			local stars = fishData.stars or "⭐"
			local weight = fishData.weight or 1.0
			local coins = rewardInfo.coins or (fishData.coins or 0)
			local exp = rewardInfo.exp or (fishData.exp or 0)
			local color = fishData.color or Color3.fromRGB(0, 200, 255)

			local revealMsg = string.format("🎉 TANGKAPAN BERHASIL!\n[%s] %s %s\n⚖️ %.1f Kg | 💰 Nilai: %d Koin (Bisa Dijual) | ⭐ +%d EXP", disp, name, stars, weight, coins, exp)
			showMessage(revealMsg, color, 5.0)

			playSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 1.8)
			updateInventoryUI()
		elseif action == "FishSold" then
			local fishName = arg1 or "Ikan"
			local coinsGained = arg2 or 0
			local currentCoins = arg3 or 0

			showMessage(string.format("💰 Berhasil menjual %s seharga +%d Koin!", fishName, coinsGained), Color3.fromRGB(50, 255, 130), 3.5)
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.6)
			updateInventoryUI()
		elseif action == "AllFishSold" then
			local count = arg1 or 0
			local totalCoins = arg2 or 0
			local currentCoins = arg3 or 0

			showMessage(string.format("💰 Berhasil menjual %d Ikan seharga total +%d Koin!", count, totalCoins), Color3.fromRGB(50, 255, 130), 4.0)
			playSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 1.6)
			updateInventoryUI()
		elseif action == "LevelUp" then
			local newLevel = arg1 or 2
			showMessage("⭐ LEVEL UP! Selamat, kamu sekarang Level " .. newLevel .. "! ⭐", Color3.fromRGB(255, 215, 0), 4.5)
			playSound("rbxasset://sounds/electronicpingshort.wav", 1.0, 2.0)
		elseif action == "Notification" then
			showMessage(arg1, Color3.fromRGB(255, 200, 80), 3.5)
		end
	end)
end
