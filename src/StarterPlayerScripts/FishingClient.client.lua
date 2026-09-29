--[[
	FishingClient (Universal Water Fishing System)
	Fitur:
	1. Mendukung MEMANCING DI SEMUA AREA AIR (Terrain Water & Water Parts seperti Danau, Sungai, Laut).
	2. Deteksi otomatis air via Raycast (klik mouse / arah hadap karakter).
	3. Pelampung dinamis (Dynamic Bobber) yang terbang & mendarat di titik air yang ditargetkan.
	4. Animasi melempar (Casting), cipratan air (Splash), dan ikan 3D melompat saat menyambar.
	5. Mini-game Piano Tiles Glassmorphism Semi-Transparan yang seirama dengan nada.
	6. Penguncian gerakan karakter (WalkSpeed = 0 & Input Sink) agar tombol D tidak menggerakkan player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remote = ReplicatedStorage:WaitForChild("FishingRemote", 10)
local PianoTilesGame = require(ReplicatedStorage:WaitForChild("PianoTilesGame"))
local fishTemplate = ReplicatedStorage:WaitForChild("AnimatedFish", 5)
local bobberTemplate = ReplicatedStorage:WaitForChild("BobberTemplate", 5)

local spot = workspace:FindFirstChild("FishingSpot")

-- ============ GUI STATUS & BANNER ============
local oldGui = playerGui:FindFirstChild("FishingGui")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FishingGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0, 420, 0, 48)
statusFrame.Position = UDim2.new(0.5, -210, 0.04, 0)
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
statusText.TextSize = 16
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

-- ============ EFEK AUDIO & PARTIKEL ============
local function playSound(soundId, volume, pitch)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume or 0.6
	s.PlaybackSpeed = pitch or 1
	s.Parent = workspace
	s:Play()
	Debris:AddItem(s, 2)
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

local function showStrikeAlert(adorneeOrPos)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 64, 0, 64)
	billboard.AlwaysOnTop = true
	
	if typeof(adorneeOrPos) == "Vector3" then
		local anchor = Instance.new("Part")
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.Position = adorneeOrPos + Vector3.new(0, 2.5, 0)
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Transparency = 1
		anchor.Parent = workspace
		billboard.Adornee = anchor
		Debris:AddItem(anchor, 2)
	elseif typeof(adorneeOrPos) == "Instance" then
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.Adornee = adorneeOrPos
	end

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
	conn = game:GetService("RunService").Heartbeat:Connect(function()
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

-- ============ KEPEMILIKAN PANCINGAN ============
local function getFishingRod()
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local rod = (backpack and (backpack:FindFirstChild("FishingRod") or backpack:FindFirstChild("Pancingan")))
		or (character and (character:FindFirstChild("FishingRod") or character:FindFirstChild("Pancingan")))
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

-- ============ DETEKSI SEMUA AIR DI MAP ============
local function isWaterInstance(inst, mat)
	if mat == Enum.Material.Water then
		return true
	end
	if inst and inst:IsA("BasePart") then
		local name = inst.Name:lower()
		if inst.Material == Enum.Material.Water
			or name:find("water")
			or name:find("lake")
			or name:find("danau")
			or name:find("river")
			or name:find("sungai")
			or name:find("ocean")
			or name:find("laut")
			or name:find("sea")
			or name:find("pool")
			or name:find("kolam") then
			return true
		end
	end
	return false
end

local function findWaterTarget(clickPos)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { char }
	rayParams.IgnoreWater = false

	-- 1. Cek Raycast dari posisi kursor / kamera
	local mouse = player:GetMouse()
	if mouse and mouse.UnitRay then
		local mouseResult = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 180, rayParams)
		if mouseResult and isWaterInstance(mouseResult.Instance, mouseResult.Material) then
			local dist = (mouseResult.Position - hrp.Position).Magnitude
			if dist <= 65 then
				return mouseResult.Position
			end
		end
	end

	-- 2. Cek Raycast dari hadap depan karakter ke bawah air
	local lookDir = hrp.CFrame.LookVector
	local forwardOrigin = hrp.Position + Vector3.new(0, 2, 0)
	local forwardRay = workspace:Raycast(forwardOrigin, (lookDir * 25) + Vector3.new(0, -15, 0), rayParams)
	if forwardRay and isWaterInstance(forwardRay.Instance, forwardRay.Material) then
		return forwardRay.Position
	end

	-- 3. Cek area FishingSpot bawaan jika berada dekat
	if spot and spot.PrimaryPart and (hrp.Position - spot.PrimaryPart.Position).Magnitude <= 35 then
		local bob = spot:FindFirstChild("Bobber")
		return bob and bob.Position or (spot.PrimaryPart.Position + Vector3.new(4, -6, 0))
	end

	-- 4. Cek part danau di workspace jika ada
	local lakePart = workspace:FindFirstChild("Lake")
	if lakePart and lakePart:IsA("BasePart") then
		local dist = (hrp.Position - lakePart.Position).Magnitude
		if dist <= 60 then
			return Vector3.new(
				math.clamp(hrp.Position.X + lookDir.X * 15, lakePart.Position.X - lakePart.Size.X/2 + 2, lakePart.Position.X + lakePart.Size.X/2 - 2),
				lakePart.Position.Y + lakePart.Size.Y/2 + 0.1,
				math.clamp(hrp.Position.Z + lookDir.Z * 15, lakePart.Position.Z - lakePart.Size.Z/2 + 2, lakePart.Position.Z + lakePart.Size.Z/2 - 2)
			)
		end
	end

	return nil
end

-- ============ ANIMASI MELEMPAR ============
local function playCastingAnimation(char, targetPos)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
	end

	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("RightUpperArm") or char:FindFirstChild("UpperTorso")
	local shoulder = char:FindFirstChild("Right Shoulder", true) or (torso and torso:FindFirstChild("RightShoulder"))
	
	if shoulder and shoulder:IsA("Motor6D") then
		local origC0 = shoulder.C0
		local backTween = TweenService:Create(shoulder, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			C0 = origC0 * CFrame.Angles(math.rad(110), 0, math.rad(-20))
		})
		backTween:Play()
		backTween.Completed:Wait()

		playSound("rbxasset://sounds/action_whoosh.mp3", 0.7, 1.1)
		local throwTween = TweenService:Create(shoulder, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			C0 = origC0 * CFrame.Angles(math.rad(-45), 0, math.rad(15))
		})
		throwTween:Play()
		throwTween.Completed:Wait()

		task.delay(0.2, function()
			TweenService:Create(shoulder, TweenInfo.new(0.4), {
				C0 = origC0 * CFrame.Angles(math.rad(-15), 0, 0)
			}):Play()
		end)
	end
end

-- ============ ALUR MEMANCING UNIVERSAL ============
local busy = false

local function startFishingAtWater(waterPos)
	if busy or PianoTilesGame.IsPlaying() then return end

	-- 1. Periksa Pancingan di Inventory
	if not hasFishingRod() then
		showMessage("⚠️ Kamu membutuhkan Joran Pancing di inventory untuk memancing!", Color3.fromRGB(255, 80, 80), 3.5)
		playSound("rbxasset://sounds/splat.wav", 0.5, 0.7)
		return
	end

	busy = true
	if prompt then prompt.Enabled = false end
	ensureEquipped()
	freezePlayer(true)

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	-- Buat Pelampung Dinamis di Air
	local activeBobber = bobberTemplate and bobberTemplate:Clone() or Instance.new("Part")
	if activeBobber:IsA("Model") then
		activeBobber:PivotTo(CFrame.new(waterPos + Vector3.new(0, 0.4, 0)))
	else
		activeBobber.Size = Vector3.new(0.9, 0.9, 0.9)
		activeBobber.Shape = Enum.PartType.Ball
		activeBobber.Color = Color3.fromRGB(240, 40, 40)
		activeBobber.Material = Enum.Material.SmoothPlastic
		activeBobber.Anchored = true
		activeBobber.CanCollide = false
		activeBobber.Position = waterPos + Vector3.new(0, 0.4, 0)
	end
	activeBobber.Parent = workspace

	if char then
		showMessage("🎣 Melemparkan kail ke air...", Color3.fromRGB(0, 200, 255), 2)
		playCastingAnimation(char, waterPos)
	end

	createWaterSplash(waterPos)
	showMessage("🎣 Kail telah di air... Menunggu ikan menyambar...", Color3.fromRGB(150, 220, 255), 4)

	task.wait(math.random(18, 38) / 10)
	if not busy then
		activeBobber:Destroy()
		freezePlayer(false)
		return
	end

	-- 2. Ikan Menyambar di Posisi Air Ini!
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

	showMessage("🎵 IKAN MENYAMBAR! Mainkan Piano Tiles (D, F, J, K)!", Color3.fromRGB(255, 220, 50), 3.5)

	local roll = math.random(100)
	local tiles, speed
	if roll > 90 then
		tiles, speed = 16, 0.52 -- Legendaris
	elseif roll > 70 then
		tiles, speed = 12, 0.44 -- Langka
	elseif roll > 40 then
		tiles, speed = 9, 0.38 -- Sedang
	else
		tiles, speed = 7, 0.32 -- Biasa
	end

	-- 3. Jalankan Mini-game Piano Tiles
	PianoTilesGame.Start({
		tiles = tiles,
		speed = speed,
	}, function()
		-- Menang
		local catchTarget = hrp and (hrp.Position + Vector3.new(0, 1, 0)) or (waterPos + Vector3.new(0, 5, 0))
		animateFishLeap(waterPos, catchTarget, 0.9, 7)
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.9, 1.8)

		if remote then
			remote:FireServer("Catch", tiles)
		end

		task.delay(3, function()
			activeBobber:Destroy()
			busy = false
			freezePlayer(false)
			if prompt then prompt.Enabled = true end
		end)
	end, function()
		-- Gagal
		createWaterSplash(waterPos)
		showMessage("❌ Ikan terlepas! Irama musik belum tepat.", Color3.fromRGB(255, 75, 75), 3)

		task.delay(2, function()
			activeBobber:Destroy()
			busy = false
			freezePlayer(false)
			if prompt then prompt.Enabled = true end
		end)
	end)
end

local function tryStartFishing()
	local waterPos = findWaterTarget()
	if waterPos then
		startFishingAtWater(waterPos)
	else
		showMessage("Arahkan kursor atau dekati area air untuk mulai memancing!", Color3.fromRGB(220, 220, 240), 2.5)
	end
end

-- ============ INTERAKSI ============

if prompt then
	prompt.ActionText = "Mancing"
	prompt.ObjectText = "Danau Pancing"
	prompt.Triggered:Connect(function()
		tryStartFishing()
	end)
end

local function hookTool(tool)
	if tool.Name == "FishingRod" or tool.Name == "Pancingan" then
		tool.Activated:Connect(function()
			tryStartFishing()
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

if remote then
	remote.OnClientEvent:Connect(function(action, arg1, arg2)
		if action == "CatchSuccess" then
			local fishName = arg1 or "Ikan"
			local category = arg2 or "BIASA"
			local color = (category == "LEGENDARIS" and Color3.fromRGB(255, 215, 0))
				or (category == "LANGKA" and Color3.fromRGB(200, 80, 255))
				or (category == "SEDANG" and Color3.fromRGB(60, 230, 130))
				or Color3.fromRGB(0, 200, 255)

			showMessage("🎉 BERHASIL! Menangkap: " .. fishName .. " [" .. category .. "]! (+1 Ikan)", color, 4)
		elseif action == "Notification" then
			showMessage(arg1, Color3.fromRGB(255, 200, 80), 3.5)
		end
	end)
end
