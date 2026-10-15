
-- FishingResultUI (ModuleScript)
-- Popup hasil tangkapan, EXP bar, viewport ikan berputar,
-- dan auto-hide.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FishingResultUI = {}

local displayToken = 0
local activePopup = nil
local activeViewportModel = nil
local rotationConnection = nil
local activeBarTween = nil
local activeFadeTweens = {}

local function cancelActiveFadeTweens()
	for _, tween in ipairs(activeFadeTweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	table.clear(activeFadeTweens)
end

-- Simpan transparansi asli agar elemen transparan tidak berubah jadi kotak solid.
local originalTransparency = setmetatable({}, { __mode = "k" })

local function getTransparencyProperties(object)
	local properties = {}

	if object:IsA("TextLabel") or object:IsA("TextButton") then
		properties.TextTransparency = object.TextTransparency
		properties.BackgroundTransparency = object.BackgroundTransparency
	elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
		properties.ImageTransparency = object.ImageTransparency
		properties.BackgroundTransparency = object.BackgroundTransparency
	elseif object:IsA("ViewportFrame") then
		properties.ImageTransparency = object.ImageTransparency
		properties.BackgroundTransparency = object.BackgroundTransparency
	elseif object:IsA("Frame") then
		properties.BackgroundTransparency = object.BackgroundTransparency
	elseif object:IsA("UIStroke") then
		properties.Transparency = object.Transparency
	end

	return properties
end

local function saveOriginalTransparency(popup)
	local objects = { popup }
	for _, object in ipairs(popup:GetDescendants()) do
		table.insert(objects, object)
	end

	for _, object in ipairs(objects) do
		if originalTransparency[object] == nil then
			originalTransparency[object] = getTransparencyProperties(object)
		end
	end
end

local function restoreOriginalTransparency(popup)
	local objects = { popup }
	for _, object in ipairs(popup:GetDescendants()) do
		table.insert(objects, object)
	end

	for _, object in ipairs(objects) do
		local properties = originalTransparency[object]
		if properties then
			for property, value in pairs(properties) do
				object[property] = value
			end
		end
	end
end

local function fadeOutPopup(popup, duration)
	cancelActiveFadeTweens()
	local tweens = {}
	local info = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local objects = { popup }

	for _, object in ipairs(popup:GetDescendants()) do
		table.insert(objects, object)
	end

	for _, object in ipairs(objects) do
		local original = originalTransparency[object]
		if original then
			local targets = {}
			for property, value in pairs(original) do
				if value < 1 then
					targets[property] = 1
				end
			end

			if next(targets) then
				table.insert(tweens, TweenService:Create(object, info, targets))
			end
		end
	end

	activeFadeTweens = tweens

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	task.wait(duration)

	-- Bersihkan hanya tween yang masih menjadi batch aktif.
	if activeFadeTweens == tweens then
		table.clear(activeFadeTweens)
	end
end

local ContentProvider = game:GetService("ContentProvider")

local gradeImages = {
	A = "rbxassetid://115729282597133",
	B = "rbxassetid://76174197369592",
	S = "rbxassetid://124735494073925",
	C = "rbxassetid://129970079564928",
}

-- Preload sekali saat ModuleScript pertama kali dijalankan
local gradeImageObjects = {}

for _, imageId in pairs(gradeImages) do
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Image = imageId
	table.insert(gradeImageObjects, imageLabel)
end

task.spawn(function()
	local success, err = pcall(function()
		ContentProvider:PreloadAsync(gradeImageObjects)
	end)

	if not success then
		warn("[FishingResultUI] Grade image preload gagal:", err)
	end

	for _, imageLabel in ipairs(gradeImageObjects) do
		imageLabel:Destroy()
	end

	table.clear(gradeImageObjects)
end)

local XPProgressionSystem = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Systems")
		:WaitForChild("XPProgressionSystem")
)

-- =========================================
-- HELPER: SET TEXT
-- =========================================

local function setText(root, name, value)
	local object = root:FindFirstChild(name, true)

	if object and (
		object:IsA("TextLabel")
			or object:IsA("TextButton")
		) then
		object.Text = tostring(value)
	end

	return object
end

-- =========================================
-- HELPER: STOP ROTATION
-- =========================================

local function stopFishRotation()
	if rotationConnection then
		rotationConnection:Disconnect()
		rotationConnection = nil
	end
end

-- =========================================
-- HELPER: START ROTATION
-- =========================================

local function startFishRotation(model)
	stopFishRotation()

	if not model or not model.Parent then
		return
	end

	local baseCFrame = model:GetPivot()
	local rotationAngle = 0

	rotationConnection = RunService.RenderStepped:Connect(function(dt)
		if not model.Parent then
			stopFishRotation()
			return
		end

		rotationAngle += math.rad(35) * dt

		model:PivotTo(
			baseCFrame * CFrame.Angles(0, rotationAngle, 0)
		)
	end)
end

-- =========================================
-- HELPER: CLEAR VIEWPORT
-- =========================================

local function clearViewport(viewport)
	stopFishRotation()

	if not viewport then
		activeViewportModel = nil
		return
	end

	for _, child in ipairs(viewport:GetChildren()) do
		if child:IsA("WorldModel") or child:IsA("Camera") then
			child:Destroy()
		end
	end

	viewport.CurrentCamera = nil
	activeViewportModel = nil
end

-- =========================================
-- HELPER: SHOW FISH MODEL
-- =========================================

local function showFishModel(viewport, fishData)
	if not viewport or not viewport:IsA("ViewportFrame") then
		return
	end

	clearViewport(viewport)

	-- Cari model berdasarkan nama ikan.
	-- Jika tidak tersedia, gunakan AnimatedFish.
	local templateName = tostring(
		fishData.modelName or fishData.name or ""
	)

	local template = ReplicatedStorage:FindFirstChild(templateName)

	if not template then
		template = ReplicatedStorage:FindFirstChild("AnimatedFish")
	end

	if not template or not (
		template:IsA("Model") or template:IsA("BasePart")
		) then
		warn(
			"[FishingResultUI] Model ikan tidak ditemukan:",
			templateName
		)
		return
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local clone = template:Clone()
	local model

	if clone:IsA("BasePart") then
		model = Instance.new("Model")
		model.Name = clone.Name .. "ViewportModel"

		clone.Parent = model
		model.PrimaryPart = clone
	else
		model = clone
	end

	model.Parent = worldModel
	activeViewportModel = model

	-- Model tidak perlu fisika di dalam viewport.
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end


	-- Hitung bounding box model
	local ok, boxCFrame, boxSize = pcall(function()
		return model:GetBoundingBox()
	end)

	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	if ok then
		-- Simpan pivot awal model
		local originalPivot = model:GetPivot()

		-- Geser model agar pusat bounding box berada di titik nol
		local offset = originalPivot:ToObjectSpace(boxCFrame)
		model:PivotTo(CFrame.new() * offset:Inverse())

		-- Hitung ulang ukuran setelah dipusatkan
		local _, centeredSize = model:GetBoundingBox()

		local largest = math.max(
			centeredSize.X,
			centeredSize.Y,
			centeredSize.Z,
			0.1
		)

		local distance = largest * 2.5

		camera.CFrame = CFrame.lookAt(
			Vector3.new(0, 0, distance),
			Vector3.zero
		)
	else
		camera.CFrame = CFrame.lookAt(
			Vector3.new(0, 0, 5),
			Vector3.zero
		)
	end

	-- Mulai rotasi setelah model dipusatkan
	startFishRotation(model)

end

-- =========================================
-- HIDE POPUP
-- =========================================

function FishingResultUI.Hide()
	displayToken += 1

	local popup = activePopup
	activePopup = nil

	stopFishRotation()

	if activeBarTween then
		activeBarTween:Cancel()
		activeBarTween = nil
	end

	if popup and popup.Parent then
		local viewport = popup:FindFirstChild("FishViewport", true)

		clearViewport(viewport)
		popup.Visible = false
	end
end

-- =========================================
-- CHECK POPUP STATUS
-- =========================================

function FishingResultUI.IsOpen()
	return activePopup ~= nil
		and activePopup.Parent ~= nil
		and activePopup.Visible
end

-- =========================================
-- SHOW RESULT POPUP
-- =========================================
-- targetGui = FishingResultGui (ScreenGui)
-- data = data hasil tangkapan
-- duration = durasi popup (default 2.5 detik)

function FishingResultUI.Show(targetGui, data, duration)
	if not targetGui then
		return
	end

	data = data or {}

	local fishData = data.fishData or {}
	local rewardInfo = data.rewardInfo or {}
	local playerData = data.playerData or {}

	local screenGui = targetGui

	if not screenGui:IsA("ScreenGui") then
		screenGui = targetGui:FindFirstAncestorOfClass("ScreenGui")
	end

	if not screenGui then
		warn("[FishingResultUI] ScreenGui tidak ditemukan")
		return
	end

	local popup = screenGui:FindFirstChild("ResultPopup")

	if not popup or not popup:IsA("Frame") then
		warn("[FishingResultUI] Frame ResultPopup tidak ditemukan")
		return
	end

	displayToken += 1
	local thisToken = displayToken

	activePopup = popup

	screenGui.Enabled = true
	-- Simpan transparansi awal dan pulihkan tampilan sebelum popup ditampilkan.
	saveOriginalTransparency(popup)
	restoreOriginalTransparency(popup)
	popup.Visible = true

	-- =========================================
	-- LEVEL & EXP PROGRESSION
	-- =========================================

	local totalExp = tonumber(
		playerData.totalExp or playerData.totalXP
	)

	local level = tonumber(playerData.level)
	local exp = tonumber(playerData.exp)

	if totalExp == nil then
		totalExp = XPProgressionSystem.ReconcileToTotalExp(
			level or 1,
			exp or 0
		)
	end

	local progression =
		XPProgressionSystem.DeriveProgression(totalExp)

	level = progression.level or level or 1

	-- Mendukung progressPercent format 0-1 atau 0-100.
	local rawProgress =
		tonumber(progression.progressPercent) or 0

	if rawProgress > 1 then
		rawProgress /= 100
	end

	local progress = math.clamp(rawProgress, 0, 1)

	-- =========================================
	-- FISH INFORMATION
	-- =========================================

	local fishName = fishData.name or "Ikan Samudra"
	local rarity = fishData.rarity or "COMMON"
	local weight = tonumber(fishData.weight) or 1

	local grade = rewardInfo.grade
		or fishData.grade
		or fishData.stars
		or "A"

	local accuracy = tonumber(
		rewardInfo.accuracy or fishData.accuracy
	) or 100

	local rarityColor =
		typeof(fishData.color) == "Color3"
		and fishData.color
		or Color3.fromRGB(180, 80, 100)

	setText(
		popup,
		"FishNameLabel",
		string.upper(tostring(fishName))
	)

	setText(
		popup,
		"WeightLabel",
		string.format("%.1f KG", weight)
	)

	setText(
		popup,
		"RarityLabel",
		string.upper(tostring(fishData.displayName or rarity))
	)

	setText(
		popup,
		"AccuracyLabel",
		string.format("ACCURACY: %g%%", accuracy)
	)


	local gradeLabel = popup:FindFirstChild("GradeLabel", true)

	if gradeLabel and gradeLabel:IsA("ImageLabel") then
		local gradeKey = string.upper(tostring(grade)):match("[ABCS]")

		gradeLabel.Visible = true
		gradeLabel.Image = gradeImages[gradeKey] or gradeImages.A
		gradeLabel.ImageTransparency = 0
	end

	setText(popup, "LevelLabel", "LVL " .. tostring(level))

	local rarityLabel = popup:FindFirstChild("RarityLabel", true)

	if rarityLabel and rarityLabel:IsA("TextLabel") then
		rarityLabel.BackgroundColor3 = rarityColor
		rarityLabel.TextColor3 = Color3.new(1, 1, 1)
	end

	-- =========================================
	-- LEVEL BAR ANIMATION
	-- =========================================

	local levelBar = popup:FindFirstChild("LevelBar", true)

	-- Mendukung kedua variasi nama objek.
	local barFill = levelBar and (
		levelBar:FindFirstChild("BarFill", true)
			or levelBar:FindFirstChild("BarFIll", true)
	)

	if levelBar and barFill and barFill:IsA("Frame") then
		if activeBarTween then
			activeBarTween:Cancel()
			activeBarTween = nil
		end

		barFill.Size = UDim2.new(0, 0, 1, 0)

		activeBarTween = TweenService:Create(
			barFill,
			TweenInfo.new(
				0.5,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				Size = UDim2.new(progress, 0, 1, 0)
			}
		)

		activeBarTween:Play()
	else
		warn(
			"[FishingResultUI] LevelBar atau BarFill tidak ditemukan!"
		)
	end

	-- =========================================
	-- FISH VIEWPORT
	-- =========================================

	local viewport = popup:FindFirstChild("FishViewport", true)
	showFishModel(viewport, fishData)



	-- =========================================
	-- AUTO-HIDE POPUP
	-- =========================================

	local popupDuration = math.max(0, tonumber(duration) or 2.5)

	task.delay(popupDuration, function()
		if displayToken ~= thisToken or not popup.Parent then
			return
		end

		-- Semua elemen fade-out bersamaan.
		fadeOutPopup(popup, 0.25)

		if displayToken ~= thisToken or not popup.Parent then
			return
		end

		popup.Visible = false
		restoreOriginalTransparency(popup)
		clearViewport(viewport)

		activePopup = nil
		activeBarTween = nil
	end)
end

return FishingResultUI
