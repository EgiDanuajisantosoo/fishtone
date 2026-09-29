--[[
	FishingClient (Universal Water Fishing System with Dynamic Randomized Cast Timing Bar)
	Fitur:
	1. BAR MELEMPAR KAIL DINAMIS (RANDOMIZED CASTING TIMING BAR):
	   - Posisi zona PERFECT (Hijau Neon ⭐⭐⭐) dan GREAT (Cyan ⭐⭐) DIAÇAK SECARA OTOMATIS SETIAP KALI MELEMPAR!
	   - Kursor putih bergerak naik-turun halus; pemain mengklik atau menekan [E] untuk mengunci timing.
	   - Mencegah double-click / frame-skip sehingga bar PASTI selalu muncul stabil setiap lemparan.
	   - Lemparan PERFECT mempercepat waktu sambaran ikan & meningkatkan peluang ikan LANGKA / LEGENDARIS!
	2. Animasi Karakter Lengkap:
	   - Pose Siaga & Tarik Joran (Windup / Aiming).
	   - Swing Melempar Joran (Casting).
	   - Sikap Memegang Joran (Fishing Stance / Idle Breathing).
	   - Reaksi Sentakan Ikan Menyambar (Strike / Bite Tension).
	   - Gerakan Menggulung Senar (Reeling) saat Piano Tiles.
	   - Gerakan Menarik Ikan Naik (Catch Victory Lift).
	3. Tali Pancing Dinamis (Beam) dari ujung Joran ke Pelampung di air.
	4. Mini-game Piano Tiles Glassmorphism Anti-Spam & Maksimal 3 Nyawa.
	5. Ikan otomatis masuk ke Inventory (Backpack) sebagai item Tool 3D setelah berhasil!
	6. Mendukung Seluruh Map Lautan Luas (Ocean Map).
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
local PianoTilesGame = require(ReplicatedStorage:WaitForChild("PianoTilesGame"))
local FishingRaritySystem = require(ReplicatedStorage:WaitForChild("FishingRaritySystem"))
local fishTemplate = ReplicatedStorage:WaitForChild("AnimatedFish", 5)
local bobberTemplate = ReplicatedStorage:WaitForChild("BobberTemplate", 5)

local clientPity = { SSR = 0, UR = 0, EX = 0 }

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

-- ============ TOAST NOTIFICATION ============
local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0, 440, 0, 50)
statusFrame.Position = UDim2.new(0.5, -220, 0.04, 0)
statusFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
statusFrame.BackgroundTransparency = 0.25
statusFrame.BorderSizePixel = 0
statusFrame.Visible = false
statusFrame.Parent = gui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 12)
statusCorner.Parent = statusFrame

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(0, 200, 255)
statusStroke.Thickness = 1.5
statusStroke.Transparency = 0.3
statusStroke.Parent = statusFrame

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.fromScale(0.95, 1)
statusText.Position = UDim2.fromScale(0.025, 0)
statusText.BackgroundTransparency = 1
statusText.TextColor3 = Color3.fromRGB(255, 255, 255)
statusText.Font = Enum.Font.GothamBold
statusText.TextSize = 15
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

-- ============ CASTING POWER & TIMING BAR GUI (DENGAN ZONA ACAK) ============
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

-- Base Meter Fill (Good Zone / Latar Belakang)
local zoneGoodBase = Instance.new("Frame")
zoneGoodBase.Name = "ZoneGoodBase"
zoneGoodBase.Size = UDim2.fromScale(0.75, 0.92)
zoneGoodBase.Position = UDim2.fromScale(0.125, 0.04)
zoneGoodBase.BackgroundColor3 = Color3.fromRGB(25, 40, 60)
zoneGoodBase.BackgroundTransparency = 0.45
zoneGoodBase.BorderSizePixel = 0
zoneGoodBase.Parent = castMeterContainer
Instance.new("UICorner", zoneGoodBase).CornerRadius = UDim.new(0, 8)

-- Zona Great (Acak)
local zoneGreat = Instance.new("Frame")
zoneGreat.Name = "ZoneGreat"
zoneGreat.Size = UDim2.fromScale(0.75, 0.28)
zoneGreat.Position = UDim2.fromScale(0.125, 0.15)
zoneGreat.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
zoneGreat.BackgroundTransparency = 0.35
zoneGreat.BorderSizePixel = 0
zoneGreat.Parent = castMeterContainer
Instance.new("UICorner", zoneGreat).CornerRadius = UDim.new(0, 8)

-- Zona Perfect (Acak)
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

-- Label Perfect & Stars yang Mengikuti Posisi Zona Perfect
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

-- Kursor / Indikator Putih yang Bergerak
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

-- Label Petunjuk Melempar
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

-- Banner Rating Popup (Muncul saat dikunci)
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

-- ============ KEPEMILIKAN & STATUS JORAN PANCING ============
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

-- ============ SISTEM ANIMASI KARAKTER (R15 & R6) ============
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

-- Visual Tali Pancing (Beam) dari Ujung Joran ke Bobber
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

-- Pose Menyiapkan Lemparan (Windup Stance saat Bar Berjalan)
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

-- 1. Animasi Melempar (Casting Swing)
function AnimSystem.PlayCast(char, targetPos)
	AnimSystem.currentPhase = "Casting"

	local rS = AnimSystem.savedC0.RightShoulder
	local lS = AnimSystem.savedC0.LeftShoulder
	local w = AnimSystem.savedC0.Waist

	-- Ayunkan Joran Maju dengan Bertenaga (Cast Forward)
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

-- 2. Sikap Memegang Joran (Fishing Stance Loop)
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

-- 3. Set Status Fase Animasi
function AnimSystem.SetPhase(phase)
	AnimSystem.currentPhase = phase
end

-- 4. Animasi Mengangkat Tangkapan (Victory Lift)
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
	if lS and lS.joint.Parent then
		TweenService:Create(lS.joint, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = lS.orig * CFrame.Angles(math.rad(80), 0, math.rad(-20))
		}):Play()
	end
end

-- ============ DETEKSI SEMUA AIR DI MAP ============
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

	-- 1. Cek Raycast dari posisi kursor mouse pemain ke air (Jangkauan Realistis: 8 - 45 stud)
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

	-- 2. Sweep ke arah pandang depan karakter (LookVector) dalam sudut wajar (-45 sampai +45 derajat)
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

-- ============ MEKANISME BAR MELEMPAR KAIL (RANDOMIZED ZONES) ============
local isCastingMeterActive = false
local meterStartTime = 0
local meterConn = nil
local currentWaterTarget = nil
local currentCastPower = 0.5
local meterSpeed = 3.2

-- State Zona Dinamis yang Diacak Setiap Lemparan
local currentZones = {
	perfectMin = 0.78,
	perfectMax = 0.94,
	greatMin = 0.60,
	greatMax = 0.98,
}

local function randomizeZones()
	-- Acak posisi tengah zona Perfect antara 20% sampai 82% tinggi bar
	local perfectCenter = math.random(22, 80) / 100
	local perfectHalfWidth = 0.075 -- Lebar zona Perfect = 15%
	local greatHalfWidth = 0.16    -- Lebar zona Great = 32%

	local pMin = math.clamp(perfectCenter - perfectHalfWidth, 0.04, 0.88)
	local pMax = math.clamp(perfectCenter + perfectHalfWidth, 0.16, 0.96)

	local gMin = math.clamp(perfectCenter - greatHalfWidth, 0.02, pMin)
	local gMax = math.clamp(perfectCenter + greatHalfWidth, pMax, 0.98)

	currentZones.perfectMin = pMin
	currentZones.perfectMax = pMax
	currentZones.greatMin = gMin
	currentZones.greatMax = gMax

	-- Update Posisi Visual Zona Great
	local gTop = (1 - gMax) * 0.92 + 0.04
	local gHeight = (gMax - gMin) * 0.92
	zoneGreat.Position = UDim2.fromScale(0.125, gTop)
	zoneGreat.Size = UDim2.fromScale(0.75, gHeight)

	-- Update Posisi Visual Zona Perfect
	local pTop = (1 - pMax) * 0.92 + 0.04
	local pHeight = (pMax - pMin) * 0.92
	zonePerfect.Position = UDim2.fromScale(0.125, pTop)
	zonePerfect.Size = UDim2.fromScale(0.75, pHeight)

	-- Update Posisi Badge PERFECT di sebelah zona hijau
	perfectBadge.Position = UDim2.new(1.15, 0, pTop, -2)
end

local function updateMeterVisual(power)
	-- Posisi indicator Y: 0.04 (Atas = power 1.0) sampai 0.92 (Bawah = power 0.0)
	local yPercent = (1 - power) * 0.88 + 0.04
	indicator.Position = UDim2.new(-0.09, 0, yPercent, -4)

	-- Indikator berubah warna dinamis sesuai zona acak saat ini
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

local function startCastingMeter(waterPos)
	if busy or isCastingMeterActive or PianoTilesGame.IsPlaying() then return end

	-- 1. Periksa Kepemilikan Joran Pancing
	if not hasFishingRod() then
		showMessage("⚠️ Kamu membutuhkan Joran Pancing di inventory untuk memancing!", Color3.fromRGB(255, 80, 80), 3.5)
		playSound("rbxasset://sounds/splat.wav", 0.5, 0.7)
		return
	end

	-- Acak posisi zona Perfect & Great untuk lemparan ini!
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
		-- Osilasi sinusoidal naik-turun halus (0 sampai 1)
		local pingPong = (math.sin(elapsed * meterSpeed - math.pi / 2) + 1) / 2
		currentCastPower = pingPong
		updateMeterVisual(currentCastPower)

		-- Auto-cast jika pemain tidak mengklik selama 4.5 detik
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

	-- Evaluasi Kualitas Lemparan Berdasarkan Zona Acak Saat Ini
	local castQuality = "GOOD"
	local castLuck = 0
	local waitDuration = math.random(28, 42) / 10

	if finalPower >= currentZones.perfectMin and finalPower <= currentZones.perfectMax then
		castQuality = "PERFECT"
		castLuck = 35 -- +35 Bonus Luck!
		showRatingPopup("⭐ PERFECT CAST! ⭐", Color3.fromRGB(255, 215, 0))
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.8)
		waitDuration = math.random(12, 20) / 10 -- Sambaran kilat (1.2s - 2.0s)
	elseif finalPower >= currentZones.greatMin and finalPower <= currentZones.greatMax then
		castQuality = "GREAT"
		castLuck = 15 -- +15 Bonus Luck!
		showRatingPopup("✨ GREAT CAST! ✨", Color3.fromRGB(0, 220, 255))
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.5)
		waitDuration = math.random(18, 28) / 10 -- Sambaran lebih cepat (1.8s - 2.8s)
	else
		castQuality = "GOOD"
		castLuck = 0
		showRatingPopup("GOOD CAST 👍", Color3.fromRGB(230, 235, 255))
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.2)
	end

	-- Hitung Total Luck Berdasarkan Rod + Bonus Lemparan
	local rodTool = getFishingRod()
	local rodLuck = (rodTool and rodTool:GetAttribute("Luck")) or 5
	local totalLuck = math.clamp(rodLuck + castLuck, FishingRaritySystem.MIN_LUCK, FishingRaritySystem.MAX_LUCK)

	-- Roll Rarity Berdasarkan Distribusi Total Luck & Cek Hierarchical Pity System
	local rolledRarity, wasPity = FishingRaritySystem.EvaluateWithPity(totalLuck, clientPity)
	local tierData = FishingRaritySystem.TIERS[rolledRarity] or FishingRaritySystem.TIERS.Common
	local fishName = FishingRaritySystem.GetRandomFishName(rolledRarity)

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	-- Buat Pelampung Dinamis di Air
	local activeBobber = bobberTemplate and bobberTemplate:Clone() or Instance.new("Part")
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

	-- Jalankan Animasi Ayunan Melempar
	if char then
		AnimSystem.PlayCast(char, waterPos)
		AnimSystem.CreateFishingLine(char, activeBobber)
		AnimSystem.StartFishingStance(char)
	end

	createWaterSplash(waterPos)
	if wasPity then
		showMessage("✨ PITY SYSTEM AKTIF! Menjamin Ikan " .. tierData.displayName .. "!", Color3.fromRGB(255, 215, 0), 3.5)
	elseif castQuality == "PERFECT" then
		showMessage("⭐ PERFECT CAST! (+35 Luck | Total Luck: " .. totalLuck .. ") Sambaran Kilat!", Color3.fromRGB(255, 215, 0), 3)
	elseif castQuality == "GREAT" then
		showMessage("✨ GREAT CAST! (+15 Luck | Total Luck: " .. totalLuck .. ") Peluang Rarity Meningkat!", Color3.fromRGB(0, 220, 255), 3)
	else
		showMessage("🎣 Kail di air... (Total Luck: " .. totalLuck .. ") Menunggu ikan menyambar...", Color3.fromRGB(150, 220, 255), 3.5)
	end

	task.wait(waitDuration)
	if not busy then
		activeBobber:Destroy()
		AnimSystem.ResetJoints()
		freezePlayer(false)
		return
	end

	-- 2. Ikan Menyambar di Lokasi Air Ini!
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

	-- 3. Jalankan Mini-game Piano Tiles dengan Tier Rarity 6 Tingkat
	PianoTilesGame.Start({
		tier = rolledRarity,
		castQuality = castQuality,
		speed = tierData.speed,
	}, function()
		-- Player Menang
		AnimSystem.PlayVictoryLift(char)
		local catchTarget = hrp and (hrp.Position + Vector3.new(0, 1.5, 0)) or (waterPos + Vector3.new(0, 5, 0))
		animateFishLeap(waterPos, catchTarget, 0.9, 7)
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.8)

		if remote then
			remote:FireServer("Catch", rolledRarity, castQuality, fishName)
		end
		clientPity = FishingRaritySystem.UpdatePityOnCatch(clientPity, rolledRarity)

		task.delay(2.8, function()
			activeBobber:Destroy()
			AnimSystem.ResetJoints()
			busy = false
			freezePlayer(false)
		end)
	end, function()
		-- Player Gagal
		createWaterSplash(waterPos)
		showMessage("❌ Ikan terlepas! Irama musik belum tepat.", Color3.fromRGB(255, 75, 75), 3)

		task.delay(1.5, function()
			activeBobber:Destroy()
			AnimSystem.ResetJoints()
			busy = false
			freezePlayer(false)
		end)
	end)
end

local lastTriggerTime = 0

local function handleInteractionTrigger()
	local now = os.clock()
	if now - lastTriggerTime < 0.12 then return end
	lastTriggerTime = now

	if isCastingMeterActive then
		-- Debounce 0.2s dari pembukaan bar agar klik pertama tidak langsung mengunci bar secara instan!
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

-- ============ LISTENER INPUT AKTIVASI (KLIK MOUSE, SENTUH, ATAU TEKAN E) ============

-- 1. Klik Mouse / Touch / Tombol E saat memegang Joran Pancing
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Jangan trigger jika pemain sedang mengklik UI (Inventory Backpack, Chat, Menu, dsb)
	if gameProcessed then return end

	if isCastingMeterActive then
		-- Saat bar lemparan sedang berjalan, klik atau [E] akan mengunci lemparan
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.E then
			handleInteractionTrigger()
		end
		return
	end

	-- Hanya bisa memancing jika JORAN PANCING SEDANG DIPEGANG di tangan karakter!
	if isRodEquipped() and not PianoTilesGame.IsPlaying() then
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.E then
			handleInteractionTrigger()
		end
	end
end)

-- 2. Hook Tool Activated Event khusus untuk Joran Pancing
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
	end)
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") then hookTool(child) end
	end

	player.CharacterAdded:Connect(function(char)
		AnimSystem.ResetJoints()
		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then hookTool(child) end
		end)
	end)
	if player.Character then
		for _, child in ipairs(player.Character:GetChildren()) do
			if child:IsA("Tool") then hookTool(child) end
		end
		player.Character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then hookTool(child) end
		end)
	end
end

watchInventory()

-- 3. Respon dari Server
if remote then
	remote.OnClientEvent:Connect(function(action, arg1, arg2, arg3)
		if action == "CatchSuccess" then
			local fishName = arg1 or "Ikan"
			local rarity = arg2 or "COMMON"
			local pityState = arg3
			if pityState then
				clientPity = pityState
			end

			local tierData = FishingRaritySystem.GetTierData(rarity)
			local toastMsg = "🎉 BERHASIL! Menangkap: " .. fishName .. " [" .. tierData.displayName .. " " .. tierData.stars .. " | " .. (tierData.targetNotes or 30) .. " NADA]"
			showMessage(toastMsg, tierData.color, 4.5)
		elseif action == "PityStateUpdate" then
			if arg1 then
				clientPity = arg1
			end
		elseif action == "Notification" then
			showMessage(arg1, Color3.fromRGB(255, 200, 80), 3.5)
		end
	end)
end
