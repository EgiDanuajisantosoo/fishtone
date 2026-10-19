--[[
	VehicleService (ServerScript)
	FISH!TUNE — Central Server Water Vehicle Management System
	
	Tanggung Jawab Otoritatif Server:
	1. Auto-Settle to Water: Menurunkan Jet Ski pas di atas permukaan air tanpa merusak rotasi asli Studio.
	2. Seat-Centric Physics: Menggunakan VehicleSeat sebagai poros utama (LookVector seat = arah stang).
	   Mencegah jet ski terbalik miring ke kiri dan meluruskan arah W maju dan S mundur 100%.
	3. Setup Collision & Constraints (DriveAttachment di dalam VehicleSeat, LinearVelocity & AlignOrientation).
	4. Dual Mounting: Tombol interaksi [E] pada Hull & Auto-Sit saat melompat ke atas dek.
	5. Smart Anchor Parking: Dikunci saat kosong (anti-hanyut) dan unanchor saat dikendarai.
	6. Pengalihan Network Ownership ke Pengemudi saat aktif.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local VehicleConfig = require(Shared:WaitForChild("Config"):WaitForChild("VehicleConfig"))

local initializedVehicles = {}

-- Memeriksa apakah model adalah Jet Ski berdasarkan nama atau tag
local function isJetSkiModel(instance)
	if not instance or not instance:IsA("Model") then return false end
	
	for _, tag in ipairs(VehicleConfig.TAGS) do
		if CollectionService:HasTag(instance, tag) then
			return true
		end
	end
	
	for _, name in ipairs(VehicleConfig.MODEL_NAMES) do
		if instance.Name:lower():find(name:lower()) ~= nil then
			return true
		end
	end
	
	if instance:FindFirstChildOfClass("VehicleSeat") and (instance:FindFirstChild("Hull") or instance.PrimaryPart) then
		return true
	end
	
	return false
end

-- Inisialisasi fisika dan interaksi pada satu model Jet Ski
local function setupJetSki(model)
	if not model or not model:IsA("Model") then return end
	if initializedVehicles[model] or model:GetAttribute("VehicleInitialized") then return end
	
	initializedVehicles[model] = true
	model:SetAttribute("VehicleInitialized", true)
	
	-- 1. Cari atau tentukan Hull (PrimaryPart)
	local hull = model.PrimaryPart or model:FindFirstChild("Hull")
	if not hull then
		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("BasePart") and not child:IsA("VehicleSeat") then
				hull = child
				break
			end
		end
	end
	
	if not hull then
		warn("[VehicleService] Gagal setup " .. model.Name .. ": Hull/PrimaryPart tidak ditemukan.")
		return
	end
	
	if model.PrimaryPart ~= hull then
		model.PrimaryPart = hull
	end
	
	-- 2. Cari VehicleSeat
	local seat = model:FindFirstChildOfClass("VehicleSeat")
	if not seat then
		warn("[VehicleService] Gagal setup " .. model.Name .. ": VehicleSeat tidak ditemukan.")
		return
	end
	
	seat.Disabled = false
	seat.CanTouch = true
	
	-- 3. Enforce Solid Collision pada Hull (Agar pemain bisa berdiri kokoh di atasnya)
	hull.CanCollide = true
	hull.CanTouch = true
	hull.CanQuery = true
	
	-- Helper untuk Anchor/Unanchor seluruh part dalam model
	local function setModelAnchored(anchored)
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = anchored
			end
		end
	end
	
	-- 4. AUTO-SETTLE KE PERMUKAAN AIR (Mencegah Melayang & Mencegah Terbalik Miring)
	local function snapToWaterSurface()
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { model }
		rayParams.IgnoreWater = false -- Wajib false agar mendeteksi air Terrain
		
		local rayOrigin = seat.Position + Vector3.new(0, 20, 0)
		local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -150, 0), rayParams)
		
		if rayResult and rayResult.Position then
			local targetWaterY = rayResult.Position.Y + VehicleConfig.PHYSICS.FLOAT_OFFSET
			local currentPivot = model:GetPivot()
			
			-- Ambil arah hadap horizontal dari seat (tegak lurus terhadap air, tidak miring roll)
			local seatLook = seat.CFrame.LookVector
			local flatLook = Vector3.new(seatLook.X, 0, seatLook.Z)
			if flatLook.Magnitude < 0.01 then
				flatLook = Vector3.new(0, 0, -1)
			else
				flatLook = flatLook.Unit
			end
			
			-- Hanya geser ketinggian Y dan stabilkan kemiringan agar tegak sempurna di atas air
			local deltaY = targetWaterY - hull.Position.Y
			model:PivotTo(CFrame.new(currentPivot.Position.X, currentPivot.Position.Y + deltaY, currentPivot.Position.Z) * currentPivot.Rotation)
			print("[VehicleService] " .. model.Name .. " diturunkan pas ke permukaan air (Y = " .. math.floor(targetWaterY) .. ")")
		end
	end
	
	snapToWaterSurface()
	setModelAnchored(true)
	
	local spawnCFrame = hull.CFrame
	
	-- 5. Konfigurasi Buoyancy Terrain Water
	local buoyancyProps = PhysicalProperties.new(
		VehicleConfig.PHYSICS.BUOYANCY_DENSITY,
		VehicleConfig.PHYSICS.FRICTION,
		VehicleConfig.PHYSICS.ELASTICITY,
		1,
		1
	)
	
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function()
				part.CustomPhysicalProperties = buoyancyProps
			end)
		end
	end
	
	-- 6. Pastikan Pengelasan (WeldConstraint)
	local weld = model:FindFirstChildOfClass("WeldConstraint")
	if not weld then
		weld = Instance.new("WeldConstraint")
		weld.Name = "AutoWeld_Hull_Seat"
		weld.Part0 = hull
		weld.Part1 = seat
		weld.Parent = model
	end
	
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= hull then
			local hasWeld = false
			for _, w in ipairs(model:GetChildren()) do
				if w:IsA("WeldConstraint") and (w.Part1 == part or w.Part0 == part) then
					hasWeld = true
					break
				end
			end
			if not hasWeld then
				local extraWeld = Instance.new("WeldConstraint")
				extraWeld.Name = "AutoWeld_" .. part.Name
				extraWeld.Part0 = hull
				extraWeld.Part1 = part
				extraWeld.Parent = model
			end
		end
	end
	
	-- 7. Setup DriveAttachment di dalam VehicleSeat (KUNCI UTAMA: Agar arah gerak lurus 100% dengan hadap kursi)
	-- Bersihkan DriveAttachment lama dari hull jika ada
	local oldAttachment = hull:FindFirstChild("DriveAttachment")
	if oldAttachment then
		oldAttachment:Destroy()
	end
	
	local driveAttachment = seat:FindFirstChild("DriveAttachment")
	if not driveAttachment then
		driveAttachment = Instance.new("Attachment")
		driveAttachment.Name = "DriveAttachment"
		driveAttachment.Parent = seat
	end
	driveAttachment.CFrame = CFrame.identity -- Sudut 0, 0, 0 lurus sempurna dengan VehicleSeat
	
	-- LinearVelocity (Tenaga dorong)
	local linearVel = driveAttachment:FindFirstChildOfClass("LinearVelocity")
	if not linearVel then
		linearVel = Instance.new("LinearVelocity")
		linearVel.Name = "LinearVelocity"
		linearVel.Parent = driveAttachment
	end
	linearVel.Attachment0 = driveAttachment
	linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVel.MaxAxesForce = Vector3.new(
		VehicleConfig.PHYSICS.MAX_DRIVE_FORCE,
		VehicleConfig.PHYSICS.MAX_VERTICAL_FORCE,
		VehicleConfig.PHYSICS.MAX_DRIVE_FORCE
	)
	linearVel.VectorVelocity = Vector3.zero
	
	-- AlignOrientation (Penyeimbang & Kemudi)
	local alignOri = driveAttachment:FindFirstChildOfClass("AlignOrientation")
	if not alignOri then
		alignOri = Instance.new("AlignOrientation")
		alignOri.Name = "AlignOrientation"
		alignOri.Parent = driveAttachment
	end
	alignOri.Attachment0 = driveAttachment
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.MaxTorque = VehicleConfig.PHYSICS.ALIGN_MAX_TORQUE
	alignOri.Responsiveness = VehicleConfig.PHYSICS.ALIGN_RESPONSIVENESS
	
	-- Set orientasi awal tegak lurus mengikuti hadap VehicleSeat (TIDAK AKAN TERBALIK KE KIRI)
	local initialSeatLook = seat.CFrame.LookVector
	local flatSeatLook = Vector3.new(initialSeatLook.X, 0, initialSeatLook.Z)
	if flatSeatLook.Magnitude < 0.01 then
		flatSeatLook = Vector3.new(0, 0, -1)
	else
		flatSeatLook = flatSeatLook.Unit
	end
	alignOri.CFrame = CFrame.lookAt(Vector3.zero, flatSeatLook, Vector3.yAxis)
	
	-- 8. Setup ProximityPrompt pada HULL (Bodi Utama)
	local prompt = hull:FindFirstChildOfClass("ProximityPrompt") or seat:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
	end
	prompt.Name = "VehicleDrivePrompt"
	prompt.Parent = hull
	prompt.ActionText = VehicleConfig.PROXIMITY_PROMPT.ACTION_TEXT
	prompt.ObjectText = VehicleConfig.PROXIMITY_PROMPT.OBJECT_TEXT
	prompt.KeyboardKeyCode = VehicleConfig.PROXIMITY_PROMPT.KEYCODE
	prompt.MaxActivationDistance = VehicleConfig.PROXIMITY_PROMPT.MAX_DISTANCE
	prompt.HoldDuration = VehicleConfig.PROXIMITY_PROMPT.HOLD_DURATION
	prompt.RequiresLineOfSight = false
	prompt.Enabled = (seat.Occupant == nil)
	prompt:SetAttribute("IsVehiclePrompt", true)
	
	-- 9. FUNGSI MOUNTING (Mendudukkan Karakter Secara Bersih & Seketika)
	local isMounting = false
	local function mountCharacter(character)
		if seat.Occupant ~= nil or isMounting then return end
		if not character then return end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not rootPart then return end
		
		isMounting = true
		seat.Disabled = false
		
		setModelAnchored(false)
		
		rootPart.CFrame = seat.CFrame + Vector3.new(0, 0.8, 0)
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
		
		task.defer(function()
			if seat.Occupant == nil and humanoid.Health > 0 then
				seat:Sit(humanoid)
			end
			task.wait(0.3)
			isMounting = false
		end)
	end
	
	prompt.Triggered:Connect(function(player)
		if player and player.Character then
			mountCharacter(player.Character)
		end
	end)
	
	hull.Touched:Connect(function(hit)
		if seat.Occupant ~= nil or isMounting then return end
		local character = hit:FindFirstAncestorOfClass("Model")
		if character and character:FindFirstChildOfClass("Humanoid") then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y >= hull.Position.Y then
				mountCharacter(character)
			end
		end
	end)
	
	seat.Touched:Connect(function(hit)
		if seat.Occupant ~= nil or isMounting then return end
		local character = hit:FindFirstAncestorOfClass("Model")
		if character and character:FindFirstChildOfClass("Humanoid") then
			mountCharacter(character)
		end
	end)
	
	-- 10. Manajemen State Pengemudi (Naik vs Turun)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if occupant and occupant:IsA("Humanoid") then
			prompt.Enabled = false
			setModelAnchored(false)
			
			local player = Players:GetPlayerFromCharacter(occupant.Parent)
			if player then
				pcall(function()
					hull:SetNetworkOwner(player)
				end)
			end
		else
			pcall(function()
				hull:SetNetworkOwner(nil)
			end)
			
			linearVel.VectorVelocity = Vector3.zero
			
			local currentSeatLook = seat.CFrame.LookVector
			local flatLook = Vector3.new(currentSeatLook.X, 0, currentSeatLook.Z)
			if flatLook.Magnitude > 0.01 then
				alignOri.CFrame = CFrame.lookAt(Vector3.zero, flatLook.Unit, Vector3.yAxis)
			end
			
			task.wait(0.2)
			if seat.Occupant == nil then
				snapToWaterSurface()
				setModelAnchored(true)
				prompt.Enabled = true
			end
		end
	end)
	
	-- 11. SAFETY NET: Anti-Void Respawn Loop
	task.spawn(function()
		while model.Parent do
			task.wait(2)
			if hull and hull.Position.Y < VehicleConfig.PHYSICS.VOID_Y_THRESHOLD then
				warn("[VehicleService] " .. model.Name .. " jatuh di bawah batas air. Mengembalikan ke dermaga...")
				
				if seat.Occupant then
					seat.Occupant.Sit = false
				end
				
				snapToWaterSurface()
				setModelAnchored(true)
				linearVel.VectorVelocity = Vector3.zero
				alignOri.CFrame = spawnCFrame
				prompt.Enabled = true
			end
		end
	end)
	
	if not CollectionService:HasTag(model, "JetSki") then
		CollectionService:AddTag(model, "JetSki")
	end
	
	print("[VehicleService] Sukses inisialisasi Jet Ski (Seat-Centric Physics):", model.Name)
end

-- ============ SCANNING & LIFECYCLE ============

local function scanExistingVehicles()
	for _, child in ipairs(workspace:GetDescendants()) do
		if isJetSkiModel(child) then
			setupJetSki(child)
		end
	end
end

workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") and isJetSkiModel(descendant) then
		task.defer(setupJetSki, descendant)
	end
end)

CollectionService:GetInstanceAddedSignal("JetSki"):Connect(function(instance)
	if instance:IsA("Model") then
		task.defer(setupJetSki, instance)
	end
end)

task.defer(scanExistingVehicles)
