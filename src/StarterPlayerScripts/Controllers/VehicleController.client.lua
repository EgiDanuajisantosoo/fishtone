--[[
	VehicleController (ClientScript)
	FISH!TUNE — Client-Side Water Vehicle & Jet Ski Driving Physics
	
	Tanggung Jawab Klien:
	1. Mendeteksi saat pemain lokal duduk di VehicleSeat Jet Ski.
	2. Mengambil input kemudi native Roblox (WASD / Thumbstick HP / Controller).
	3. Active Water Gliding: Raycast mendeteksi ketinggian air Terrain secara real-time
	   sehingga Jet Ski mengapung dan meluncur mulus di permukaan air (ANTI-TENGGELAM).
	4. Menghitung akselerasi, pengereman, dan efek deselerasi hambatan air secara lokal (60+ FPS mulus).
	5. Mengatur kemudi halus (Yaw) dan efek miring dinamis (Banking Roll Tilt) saat bermanuver.
	6. Menangani posisi turun (Dismount Offset) agar karakter tidak tersangkut di bodi Jet Ski.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local VehicleConfig = require(Shared:WaitForChild("Config"):WaitForChild("VehicleConfig"))

local driveConnection = nil
local currentVehicle = nil

-- Memeriksa apakah seat adalah bagian dari Jet Ski
local function isJetSkiSeat(seat)
	if not seat or not seat:IsA("VehicleSeat") then return false end
	local model = seat:FindFirstAncestorOfClass("Model")
	if not model then return false end
	
	if model:GetAttribute("VehicleInitialized") then return true end
	
	for _, name in ipairs(VehicleConfig.MODEL_NAMES) do
		if model.Name:lower():find(name:lower()) ~= nil then
			return true
		end
	end
	
	return false
end

-- Mulai loop pengemudian lokal
local function startDriving(seat)
	local model = seat:FindFirstAncestorOfClass("Model")
	if not model then return end
	
	local hull = model.PrimaryPart or model:FindFirstChild("Hull")
	if not hull then return end
	
	local driveAttachment = seat:FindFirstChild("DriveAttachment") or hull:FindFirstChild("DriveAttachment")
	if not driveAttachment then return end
	
	local linearVel = driveAttachment:FindFirstChildOfClass("LinearVelocity")
	local alignOri = driveAttachment:FindFirstChildOfClass("AlignOrientation")
	if not linearVel or not alignOri then return end
	
	currentVehicle = model
	
	-- Setup Raycast Params untuk pendeteksian permukaan air Terrain
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local ignoreList = { model }
	if LocalPlayer.Character then
		table.insert(ignoreList, LocalPlayer.Character)
	end
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.IgnoreWater = false -- PENTING: Harus false agar mendeteksi air Terrain!
	
	-- Efek Suara Mesin Opsional
	local engineSound = hull:FindFirstChild("EngineSound") or seat:FindFirstChild("EngineSound")
	if engineSound and engineSound:IsA("Sound") then
		engineSound:Play()
	end
	
	-- Partikel Semburan Air Opsional
	local splashEmitter = driveAttachment:FindFirstChildOfClass("ParticleEmitter")
	
	-- Inisialisasi sudut hadap awal dari DriveAttachment (arah moncong mesin Jet Ski)
	local currentLook = driveAttachment.WorldCFrame.LookVector
	local currentYaw = math.atan2(-currentLook.X, -currentLook.Z)
	local currentSpeed = 0
	local currentRoll = 0
	local lastValidWaterY = hull.Position.Y - VehicleConfig.PHYSICS.FLOAT_OFFSET
	
	-- Loop fisika setiap frame
	driveConnection = RunService.Heartbeat:Connect(function(dt)
		if not seat or not seat.Parent or seat.Occupant == nil then
			if driveConnection then
				driveConnection:Disconnect()
				driveConnection = nil
			end
			return
		end
		
		local throttle = seat.ThrottleFloat or seat.Throttle
		local steer = seat.SteerFloat or seat.Steer
		
		-- 1. Perhitungan Kecepatan Maju / Mundur
		if throttle > 0.05 then
			currentSpeed = math.min(
				VehicleConfig.SPEED.MAX_FORWARD,
				currentSpeed + (VehicleConfig.SPEED.ACCELERATION * throttle * dt)
			)
		elseif throttle < -0.05 then
			if currentSpeed > 0 then
				-- Sedang melaju maju, ini berfungsi sebagai pengereman
				currentSpeed = math.max(
					0,
					currentSpeed - (VehicleConfig.SPEED.BRAKE_DECEL * math.abs(throttle) * dt)
				)
			else
				-- Mundur
				currentSpeed = math.max(
					-VehicleConfig.SPEED.MAX_REVERSE,
					currentSpeed - (VehicleConfig.SPEED.ACCELERATION * math.abs(throttle) * dt)
				)
			end
		else
			-- Dilepas (Coasting) -> Hambatan air memperlambat laju secara alami
			if currentSpeed > 0 then
				currentSpeed = math.max(0, currentSpeed - (VehicleConfig.SPEED.COAST_DECEL * dt))
			elseif currentSpeed < 0 then
				currentSpeed = math.min(0, currentSpeed + (VehicleConfig.SPEED.COAST_DECEL * dt))
			end
		end
		
		-- 2. Perhitungan Sudut Setir (Yaw)
		local speedMagnitude = math.abs(currentSpeed)
		local isMoving = speedMagnitude > 0.5 or math.abs(throttle) > 0.1
		
		if isMoving and math.abs(steer) > 0.05 then
			local steerDirection = (currentSpeed >= -1) and 1 or -1
			currentYaw = currentYaw - (steer * VehicleConfig.STEERING.TURN_SPEED * dt * steerDirection)
		end
		
		-- 3. Efek Miring Dinamis (Banking Roll Tilt)
		local speedRatio = math.clamp(currentSpeed / VehicleConfig.SPEED.MAX_FORWARD, 0, 1)
		local targetRoll = -steer * speedRatio * VehicleConfig.STEERING.BANK_MAX_ANGLE
		currentRoll = currentRoll + (targetRoll - currentRoll) * math.clamp(VehicleConfig.STEERING.BANK_SPEED * dt, 0, 1)
		
		-- 4. Deteksi Permukaan Air (Water Raycast Buoyancy)
		-- Menembakkan sinar ke bawah untuk mengetahui titik persis permukaan air laut
		local rayOrigin = hull.Position + Vector3.new(0, 15, 0)
		local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -35, 0), rayParams)
		
		local targetWaterY = lastValidWaterY
		if rayResult and rayResult.Instance then
			targetWaterY = rayResult.Position.Y
			lastValidWaterY = targetWaterY
		end
		
		-- Pegas Ketinggian Air (Spring Buoyancy)
		local desiredHullY = targetWaterY + VehicleConfig.PHYSICS.FLOAT_OFFSET
		local currentHullY = hull.Position.Y
		local verticalCorrection = math.clamp((desiredHullY - currentHullY) * 14, -15, 20)
		
		-- 5. Terapkan Orientasi (Tegak & Anti-Terbalik)
		local forwardVector = Vector3.new(-math.sin(currentYaw), 0, -math.cos(currentYaw))
		alignOri.CFrame = CFrame.lookAt(Vector3.zero, forwardVector, Vector3.yAxis) * CFrame.Angles(0, 0, currentRoll)
		
		-- 6. Terapkan Kecepatan Horizontal + Vertikal Penahan Air
		linearVel.VectorVelocity = Vector3.new(
			forwardVector.X * currentSpeed,
			verticalCorrection,
			forwardVector.Z * currentSpeed
		)
		
		-- Update Suara & Partikel jika ada
		if engineSound and engineSound:IsA("Sound") then
			engineSound.PlaybackSpeed = 0.8 + (speedRatio * 0.7)
		end
		if splashEmitter and splashEmitter:IsA("ParticleEmitter") then
			splashEmitter.Enabled = (speedMagnitude > 3)
		end
	end)
end

-- Hentikan pengemudian lokal dan amankan posisi karakter
local function stopDriving(seat)
	if driveConnection then
		driveConnection:Disconnect()
		driveConnection = nil
	end
	
	if currentVehicle then
		local hull = currentVehicle.PrimaryPart or currentVehicle:FindFirstChild("Hull")
		local driveAttachment = (seat and seat:FindFirstChild("DriveAttachment")) or (hull and hull:FindFirstChild("DriveAttachment"))
		if hull then
			if driveAttachment then
				local linearVel = driveAttachment:FindFirstChildOfClass("LinearVelocity")
				if linearVel then
					linearVel.VectorVelocity = Vector3.zero
				end
				local splashEmitter = driveAttachment:FindFirstChildOfClass("ParticleEmitter")
				if splashEmitter then
					splashEmitter.Enabled = false
				end
			end
			local engineSound = hull:FindFirstChild("EngineSound") or (seat and seat:FindFirstChild("EngineSound"))
			if engineSound and engineSound:IsA("Sound") then
				engineSound:Stop()
			end
		end
		
		-- Posisikan karakter sedikit ke samping jet ski agar tidak tersangkut di bodi mesh
		local character = LocalPlayer.Character
		if character and seat then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				task.defer(function()
					local dismountOffset = VehicleConfig.DISMOUNT.SIDE_OFFSET
					local targetCFrame = seat.CFrame * CFrame.new(dismountOffset)
					rootPart.CFrame = CFrame.new(targetCFrame.Position, targetCFrame.Position + seat.CFrame.LookVector)
				end)
			end
		end
		
		currentVehicle = nil
	end
end

-- Menghubungkan event Seated pada Humanoid pemain lokal
local function bindCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	
	humanoid.Seated:Connect(function(active, currentSeat)
		if active and currentSeat and isJetSkiSeat(currentSeat) then
			startDriving(currentSeat)
		else
			stopDriving(currentSeat)
		end
	end)
end

if LocalPlayer.Character then
	bindCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
	bindCharacter(character)
end)
