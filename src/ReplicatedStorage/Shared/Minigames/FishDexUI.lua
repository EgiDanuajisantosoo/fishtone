-- FISH!TUNE - FishDex controller for manually-built ScreenGui
-- Place this ModuleScript where the old FishDexUI ModuleScript lives.
-- Expected GUI hierarchy: FishDexGui > Background > LeftPanel/CenterPanel/RightPanel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishDefinitions = require(Shared:WaitForChild("Config"):WaitForChild("FishDefinitions"))
local ZoneConfig = require(Shared:WaitForChild("Config"):WaitForChild("ZoneConfig"))
local RaritySystem = require(Shared:WaitForChild("Systems"):WaitForChild("FishingRaritySystem"))

local player = Players.LocalPlayer
local FishDexUI = {}

local gui, background, leftPanel, centerPanel, rightPanel
local locationGrid, locationTemplate, locationButton, locationButtonLabel
local speciesGrid, fishCardTemplate, centerViewport
local selectedFish
local cachedJournal = {}
local selectedZone = "ALL"
local undiscoveredOnly = false
local searchText = ""
local isOpen = false
local locationButtons = {}
local previewModel, previewCamera, previewWorld
local previewRotationConnection
local dragStartX, dragStartRotation = nil, 0
local RunService = game:GetService("RunService")

local RARITY_IMAGES = {
	COMMON = "rbxassetid://72414642890484",
	RARE = "rbxassetid://71899573158649",
	SUPER_RARE = "rbxassetid://91280591012511",
	LEGENDARY = "rbxassetid://74496426632920",
	SPECIAL = "rbxassetid://13780690345712",
	MYTHIC = "rbxassetid://109116929246833",
}

local function normalizeRarity(rarity)
	return string.upper(tostring(rarity or "COMMON"))
		:gsub("[%s%-]+", "_")
end

-- IMPORTANT: Models in ReplicatedStorage > Fish are named "1" through "8".
-- If you want a particular species to use a specific model, add its fish.id here.
-- Example: COMMON_GOLDFISH = 1,
local MODEL_INDEX_BY_FISH_ID = {
	-- COMMON_GOLDFISH = 1,
	-- COMMON_CATFISH = 2,
}

local MODEL_FOLDER = ReplicatedStorage:WaitForChild("Fish")
local COLORS = {
	background = Color3.fromRGB(5, 190, 232),
	panel = Color3.fromRGB(4, 67, 82),
	card = Color3.fromRGB(9, 48, 61),
	accent = Color3.fromRGB(0, 221, 255),
	white = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(190, 225, 235),
	locked = Color3.fromRGB(25, 35, 42),
}

local function findText(parent, name)
	local obj = parent and parent:FindFirstChild(name, true)
	if obj and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
		return obj
	end
	return nil
end

local function setText(parent, name, text)
	local obj = findText(parent, name)
	if obj then obj.Text = tostring(text or "") end
end

local function journalEntry(fish)
	return cachedJournal[fish.id] or cachedJournal[fish.name]
end

local function isDiscovered(fish)
	local entry = journalEntry(fish)
	return entry ~= nil and (tonumber(entry.count) or 0) > 0
end


local function getZoneName(zoneId)
	if not zoneId or zoneId == "" then return "Samudra Terbuka" end
	local ok, zone = pcall(function()
		return ZoneConfig.GetZoneById(zoneId)
	end)
	if ok and zone and zone.name then return zone.name end
	return tostring(zoneId):gsub("_", " "):lower():gsub("(%a)([%w]*)", function(a, b)
		return a:upper() .. b
	end)
end

local function getRarityInfo(fish)
	local rarity = fish.rarity or "COMMON"
	local ok, info = pcall(function()
		return RaritySystem.GetTierData(rarity)
	end)
	if ok and info then
		return info.displayName or rarity, info.color or fish.color or COLORS.accent, info.stars or ""
	end
	return rarity, fish.color or COLORS.accent, ""
end

local function clearViewport(viewport)
	for _, child in ipairs(viewport:GetChildren()) do
		if child:IsA("WorldModel") or child:IsA("Camera") then child:Destroy() end
	end
end

local function getModelIndex(fish, catalogIndex)
	local mapped = MODEL_INDEX_BY_FISH_ID[fish.id]
		or fish.modelIndex
		or fish.modelId
	if mapped and MODEL_FOLDER:FindFirstChild(tostring(mapped)) then
		return tostring(mapped)
	end
	-- Convenient default: catalog entries 1-8 use models 1-8.
	-- For any other species, set MODEL_INDEX_BY_FISH_ID above to choose a model.
	if catalogIndex and catalogIndex <= 8 then
		return tostring(catalogIndex)
	end
	return nil
end

local function putModelInViewport(viewport, fish, catalogIndex, rotateable)
	clearViewport(viewport)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(200, 220, 230)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)

	local camera = Instance.new("Camera")
	camera.Name = "FishCamera"
	camera.FieldOfView = 35
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local world = Instance.new("WorldModel")
	world.Name = "FishWorld"
	world.Parent = viewport

	local modelName = getModelIndex(fish, catalogIndex)
	local source = modelName and MODEL_FOLDER:FindFirstChild(modelName)
	if not source then
		return nil, camera, world
	end

	local clone = source:Clone()
	clone.Name = "PreviewFish"

	local discovered = isDiscovered(fish)

	if not discovered then
		local function applySilhouette(object)
			if object:IsA("BasePart") then
				object.Color = Color3.fromRGB(0, 0, 0)
				object.Material = Enum.Material.SmoothPlastic
				object.MaterialVariant = ""
				object.Transparency = 0
				object.Reflectance = 0

				if object:IsA("MeshPart") then
					object.TextureID = ""
				end

			elseif object:IsA("SpecialMesh") then
				object.TextureId = ""
				object.VertexColor = Vector3.new(0, 0, 0)

			elseif object:IsA("Decal")
				or object:IsA("Texture")
				or object:IsA("SurfaceAppearance") then
				object:Destroy()
			end
		end
		
		print(
			"[FishDex]",
			fish.name,
			"count =", journalEntry(fish) and journalEntry(fish).count,
			"discovered =", discovered
		)

		-- Terapkan pada model dan semua turunannya.
		applySilhouette(clone)

		for _, object in ipairs(clone:GetDescendants()) do
			applySilhouette(object)
		end
	end

	clone.Parent = world

	local model
	if clone:IsA("Model") then
		model = clone
	elseif clone:IsA("BasePart") then
		model = Instance.new("Model")
		model.Name = "PreviewFish"
		clone.Parent = model
		model.PrimaryPart = clone
		model.Parent = world
	else
		clone:Destroy()
		return nil, camera, world
	end

	-- Make sure the preview does not depend on live physics.
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end

	local boxCFrame, boxSize = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() - boxCFrame.Position)
	boxSize = Vector3.new(math.max(boxSize.X, 0.1), math.max(boxSize.Y, 0.1), math.max(boxSize.Z, 0.1))
	local maxDimension = math.max(boxSize.X, boxSize.Y, boxSize.Z)
	local distance = maxDimension * 2.1 + 1
	camera.CFrame = CFrame.lookAt(Vector3.new(0, boxSize.Y * 0.08, distance), Vector3.new(0, 0, 0))
	
	-- Rotasi otomatis hanya untuk preview CenterPanel.
	if rotateable then
		if previewRotationConnection then
			previewRotationConnection:Disconnect()
			previewRotationConnection = nil
		end

		local basePivot = model:GetPivot()
		local angle = 0

		previewRotationConnection = RunService.RenderStepped:Connect(function(dt)
			if not model.Parent or not FishDexUI.IsOpen() then
				previewRotationConnection:Disconnect()
				previewRotationConnection = nil
				return
			end

			angle += math.rad(30) * dt
			model:PivotTo(basePivot * CFrame.Angles(0, angle, 0))
		end)
	end

	return model, camera, world
end

local function setPreview(fish)
	if not centerViewport or not fish then return end
	local index
	for i, item in ipairs(FishDefinitions.CATALOG) do
		if item == fish or item.id == fish.id then index = i break end
	end
	previewModel, previewCamera, previewWorld = putModelInViewport(centerViewport, fish, index, true)
	if not previewModel then
		-- No misleading fish model: show a readable fallback message.
		local hint = centerViewport:FindFirstChild("PreviewHint")
		if not hint then
			hint = Instance.new("TextLabel")
			hint.Name = "PreviewHint"
			hint.Size = UDim2.fromScale(1, 1)
			hint.BackgroundTransparency = 1
			hint.TextWrapped = true
			hint.Font = Enum.Font.GothamBold
			hint.TextSize = 16
			hint.TextColor3 = COLORS.white
			hint.Parent = centerViewport
		end
		hint.Text = "Model belum dipetakan\n" .. fish.name .. "\nTambahkan ID ikan ke MODEL_INDEX_BY_FISH_ID"
	else
		local hint = centerViewport:FindFirstChild("PreviewHint")
		if hint then hint:Destroy() end
	end
end

local function updateDetails(fish)
	if not fish then return end
	local entry = journalEntry(fish)
	local discovered = isDiscovered(fish)
	local rarityName, rarityColor, stars = getRarityInfo(fish)
	local zoneName = getZoneName(fish.favoriteZone)

	setText(rightPanel, "FishName", discovered and fish.name or "???")
	setText(rightPanel, "DesciptionLabel", discovered and (fish.description or "Spesies ikan FISH!TUNE.") or "Spesies ini belum ditemukan. Jelajahi habitatnya dan cobalah memancing!")
	setText(rightPanel, "DescriptionLabel", discovered and (fish.description or "Spesies ikan FISH!TUNE.") or "Spesies ini belum ditemukan. Jelajahi habitatnya dan cobalah memancing!")
	setText(rightPanel, "HabitatLabel", zoneName)
	setText(rightPanel, "CatchCountLabel", discovered and string.format("%d", tonumber(entry.count) or 0) or "0")
	setText(rightPanel, "WeightLabel", string.format("%.1f–%.1f kg", fish.minWeight or 0, fish.maxWeight or 0))
	setText(rightPanel, "RecordLabel", discovered and string.format("%.1f kg", tonumber(entry.maxWeight) or (fish.minWeight or 0)) or "Rekor: —")
	setText(rightPanel, "RewardLabel", string.format("%d koin  •  %d EXP", fish.baseCoins or 0, fish.baseExp or 0))
	local rarityImage = centerPanel:FindFirstChild(
		"RarityImage",
		true
	)

	if rarityImage and rarityImage:IsA("ImageLabel") then
		local rarityKey = normalizeRarity(fish.rarity)

		rarityImage.Image = RARITY_IMAGES[rarityKey]
			or RARITY_IMAGES.COMMON

		rarityImage.Visible = true
	end

	local rarityLabel = findText(rightPanel, "RarityLabel")
	if rarityLabel then rarityLabel.TextColor3 = rarityColor end
end

local function selectFish(fish)
	selectedFish = fish
	setPreview(fish)
	updateDetails(fish)
	for _, card in ipairs(speciesGrid:GetChildren()) do
		if card:IsA("GuiObject") and card:GetAttribute("FishId") then
			local stroke = card:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = card:GetAttribute("FishId") == fish.id and COLORS.accent or Color3.fromRGB(70, 110, 125)
				stroke.Thickness = card:GetAttribute("FishId") == fish.id and 2 or 1
			end
		end
	end
end

local function updateProgress()
	local discovered, total = 0, #FishDefinitions.CATALOG
	for _, fish in ipairs(FishDefinitions.CATALOG) do
		if isDiscovered(fish) then discovered += 1 end
	end
	setText(gui, "ProgressLabel", string.format("%d / %d SPESIES  •  %d%%", discovered, total, total > 0 and math.floor(discovered / total * 100) or 0))
end

local function makeCard(fish, catalogIndex, layoutOrder)
	local card = fishCardTemplate:Clone()
	card.Name = "FishCard_" .. tostring(fish.id)
	card.Visible = true
	card.LayoutOrder = layoutOrder
	card:SetAttribute("FishId", fish.id)
	card.Parent = speciesGrid

	local nameLabel = findText(card, "FishName")
	if nameLabel then
		nameLabel.Text = isDiscovered(fish) and fish.name or "???"
	end

	local cardViewport = card:FindFirstChild("ViewportFrame", true)
	if cardViewport and cardViewport:IsA("ViewportFrame") then
		local model = putModelInViewport(cardViewport, fish, catalogIndex, false)
		if not model then
			local hint = Instance.new("TextLabel")
			hint.Name = "ModelHint"
			hint.Size = UDim2.fromScale(1, 1)
			hint.BackgroundTransparency = 1
			hint.Text = "?"
			hint.TextColor3 = Color3.fromRGB(255, 255, 255)
			hint.Font = Enum.Font.GothamBlack
			hint.TextScaled = true
			hint.Parent = cardViewport
		end
	end

	local click = card:FindFirstChild("CardClick", true)
	if not click then
		click = Instance.new("TextButton")
		click.Name = "CardClick"
		click.BackgroundTransparency = 1
		click.Text = ""
		click.Size = UDim2.fromScale(1, 1)
		click.ZIndex = 50
		click.Parent = card
	end
	if click:IsA("GuiButton") then
		click.Activated:Connect(function() selectFish(fish) end)
	end
end

function FishDexUI.RenderGrid()
	if not speciesGrid or not fishCardTemplate then return end
	for _, child in ipairs(speciesGrid:GetChildren()) do
		if child ~= fishCardTemplate and not child:IsA("UIGridStyleLayout") then
			child:Destroy()
		end
	end

	local filtered = {}
	local needle = string.lower(searchText or "")
	for index, fish in ipairs(FishDefinitions.CATALOG) do
		local zoneMatches = selectedZone == "ALL" or fish.favoriteZone == selectedZone
		local discoveryMatches = not undiscoveredOnly or not isDiscovered(fish)
		local searchMatches = needle == "" or string.find(string.lower(fish.name or ""), needle, 1, true) ~= nil
		if zoneMatches and discoveryMatches and searchMatches then
			table.insert(filtered, { fish = fish, index = index })
		end
	end

	for order, item in ipairs(filtered) do
		makeCard(item.fish, item.index, order)
	end

	if #filtered > 0 then
		local stillExists = false
		for _, item in ipairs(filtered) do
			if selectedFish and item.fish.id == selectedFish.id then stillExists = true break end
		end
		if not stillExists then selectFish(filtered[1].fish) end
	else
		selectedFish = nil
		clearViewport(centerViewport)
		setText(rightPanel, "FishName", "Tidak ada ikan")
		setText(rightPanel, "DescriptionLabel", "Coba ubah filter lokasi atau pencarian.")
	end
end

local function buildLocationDropdown()
	if not locationGrid or not locationTemplate then return end
	locationTemplate.Visible = false
	for _, child in ipairs(locationGrid:GetChildren()) do
		if child ~= locationTemplate and not child:IsA("UIGridStyleLayout") then child:Destroy() end
	end
	locationButtons = {}

	local unique = {}
	for _, fish in ipairs(FishDefinitions.CATALOG) do
		if fish.favoriteZone and fish.favoriteZone ~= "" then unique[fish.favoriteZone] = true end
	end
	local ids = {}
	for id in pairs(unique) do table.insert(ids, id) end
	table.sort(ids)
	table.insert(ids, 1, "ALL")

	for order, id in ipairs(ids) do
		local button = locationTemplate:Clone()
		button.Name = "LocationOption_" .. id
		button.Visible = true
		button.LayoutOrder = order
		button.Parent = locationGrid
		local label = findText(button, "LocationName")
		local displayName = id == "ALL" and "Semua Lokasi" or getZoneName(id)
		if label then label.Text = displayName elseif button:IsA("TextButton") then button.Text = displayName end
		if button:IsA("GuiButton") then
			button.Activated:Connect(function()
				selectedZone = id
				if locationButtonLabel then locationButtonLabel.Text = displayName .. "  ▼" end
				locationGrid.Visible = false
				FishDexUI.RenderGrid()
			end)
		end
	end
end

function FishDexUI.UpdateJournalData(journal)
	cachedJournal = journal or {}
	updateProgress()
	FishDexUI.RenderGrid()
end

function FishDexUI.SetZoneFilter(zoneId)
	selectedZone = zoneId or "ALL"
	FishDexUI.RenderGrid()
end

function FishDexUI.SetUndiscoveredOnly(enabled)
	undiscoveredOnly = enabled == true
	FishDexUI.RenderGrid()
end

function FishDexUI.Show(targetGui, pData)
	local playerGui = player:WaitForChild("PlayerGui")

	gui = playerGui:WaitForChild("FishDexGui")
	background = gui:WaitForChild("Background")
	leftPanel = gui:WaitForChild("LeftPanel")
	centerPanel = gui:WaitForChild("CenterPanel")
	rightPanel = gui:WaitForChild("RightPanel")

	locationGrid = leftPanel:WaitForChild("LocationGrid")
	locationTemplate = locationGrid:WaitForChild("LocationTemplate")
	locationButton = leftPanel:WaitForChild("LocationButton")
	locationButtonLabel = findText(locationButton, "LocationName")
	speciesGrid = leftPanel:WaitForChild("SpeciesGrid")
	fishCardTemplate = speciesGrid:WaitForChild("FishCardTemplate")
	centerViewport = centerPanel:WaitForChild("FishViewport")

	cachedJournal = (pData and pData.journal) or cachedJournal or {}
	isOpen = true
	gui.Enabled = true
	background.Visible = true
	locationGrid.Visible = false
	fishCardTemplate.Visible = false

	buildLocationDropdown()
	if locationButton:IsA("GuiButton") and not locationButton:GetAttribute("FishDexBound") then
		locationButton:SetAttribute("FishDexBound", true)
		locationButton.Activated:Connect(function()
			locationGrid.Visible = not locationGrid.Visible
		end)
	end

	-- The TextButton directly under LeftPanel is treated as the undiscovered-only toggle.
	local undiscoveredButton = leftPanel:FindFirstChild("TextButton")
	if undiscoveredButton and undiscoveredButton:IsA("GuiButton") then
		local label = findText(undiscoveredButton, "TextLabel")
		local function refreshToggleText()
			if undiscoveredButton:IsA("TextButton") then
				undiscoveredButton.Text = undiscoveredOnly and "☑" or "☐"
			end
		end
		refreshToggleText()
		if not undiscoveredButton:GetAttribute("FishDexBound") then
			undiscoveredButton:SetAttribute("FishDexBound", true)
			undiscoveredButton.Activated:Connect(function()
				undiscoveredOnly = not undiscoveredOnly
				refreshToggleText()
				FishDexUI.RenderGrid()
			end)
		end
	end

	local searchBox = leftPanel:FindFirstChild("SearchBox", true)
	if searchBox and searchBox:IsA("TextBox") then
		searchText = searchBox.Text
		if not searchBox:GetAttribute("FishDexBound") then
			searchBox:SetAttribute("FishDexBound", true)
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				searchText = searchBox.Text
				FishDexUI.RenderGrid()
			end)
		end
	end

	local closeButton = gui:FindFirstChild("CloseButton", true)
	if closeButton and closeButton:IsA("GuiButton") and not closeButton:GetAttribute("FishDexBound") then
		closeButton:SetAttribute("FishDexBound", true)
		closeButton.Activated:Connect(function() FishDexUI.Hide() end)
	end

	updateProgress()
	FishDexUI.RenderGrid()
	return gui
end

function FishDexUI.Hide(callback)
	isOpen = false

	if previewRotationConnection then
		previewRotationConnection:Disconnect()
		previewRotationConnection = nil
	end

	if gui then
		gui.Enabled = false
	end

	if callback then
		callback()
	end
end

function FishDexUI.IsOpen()
	return isOpen and gui ~= nil and gui.Enabled
end

function FishDexUI.SelectFish(fish)
	if fish then selectFish(fish) end
end

return FishDexUI
