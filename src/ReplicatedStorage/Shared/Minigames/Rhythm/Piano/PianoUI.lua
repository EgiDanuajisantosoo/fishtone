--[[
    PianoUI (ModuleScript)
    FISH!TUNE — Authentic Tropical Fishing × Rhythm Minigame UI (100% Matching Stagging Image)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(Shared:WaitForChild("Config"):WaitForChild("PianoConfig"))
local PerformanceCalculator = require(Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator"))

local PianoUI = {}

local gui, arenaContainer, arenaFrame
local castBonusLabel, songLabel, comboLabel, centerJudgementLabel, hitLine, perfectZoneGuide
local resultOverlay, resultLabel, gradeBadgeLabel, gradeTitleLabel, statsDetailLabel, multiplierDetailLabel
local progressContainer, progressFill, progressLabel, progressGlow, fish
local columns, columnFlashes, receptorPads, receptorLabels = {}, {}, {}, {}

local function getPlayerGui()
	local player = Players.LocalPlayer
	return player and (player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5))
end

local function buildDynamicGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PianoTilesGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Main Layout Container
	local container = Instance.new("Frame")
	container.Name = "ArenaContainer"
	container.Size = UDim2.new(0, 520, 0, 500)
	container.Position = UDim2.new(0.5, -260, 0.5, -250)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = screenGui

	-- ==================================================
	-- 1. LEFT WOOD PANEL (Song & Cast Info)
	-- ==================================================
	local woodPanel = Instance.new("Frame")
	woodPanel.Name = "WoodPanel"
	woodPanel.Size = UDim2.new(0, 160, 0, 260)
	woodPanel.Position = UDim2.new(0, 0, 0, 20)
	woodPanel.BackgroundColor3 = Color3.fromRGB(112, 74, 46) -- Authentic Wood Plank Brown
	woodPanel.BorderSizePixel = 0
	woodPanel.Parent = container
	Instance.new("UICorner", woodPanel).CornerRadius = UDim.new(0, 18)

	local woodStroke = Instance.new("UIStroke")
	woodStroke.Color = Color3.fromRGB(68, 42, 24)
	woodStroke.Thickness = 3.5
	woodStroke.Parent = woodPanel

	-- Vertical Plank Dividers
	for p = 1, 3 do
		local stripe = Instance.new("Frame")
		stripe.Name = "PlankStripe" .. p
		stripe.Size = UDim2.new(0, 1, 1, 0)
		stripe.Position = UDim2.new(p * 0.25, 0, 0, 0)
		stripe.BackgroundColor3 = Color3.fromRGB(75, 48, 28)
		stripe.BackgroundTransparency = 0.5
		stripe.BorderSizePixel = 0
		stripe.Parent = woodPanel
	end

	local castBonus = Instance.new("TextLabel")
	castBonus.Name = "CastBonusLabel"
	castBonus.Size = UDim2.new(0.88, 0, 0, 28)
	castBonus.Position = UDim2.new(0.06, 0, 0, 14)
	castBonus.BackgroundTransparency = 1
	castBonus.Text = "✨ PERFECT CAST"
	castBonus.TextColor3 = Color3.fromRGB(255, 255, 255)
	castBonus.Font = Enum.Font.FredokaOne
	castBonus.TextSize = 16
	castBonus.TextXAlignment = Enum.TextXAlignment.Left
	castBonus.Parent = woodPanel

	local castStroke = Instance.new("UIStroke")
	castStroke.Color = Color3.fromRGB(45, 25, 12)
	castStroke.Thickness = 1.5
	castStroke.Parent = castBonus

	local song = Instance.new("TextLabel")
	song.Name = "SongLabel"
	song.Size = UDim2.new(0.88, 0, 0, 70)
	song.Position = UDim2.new(0.06, 0, 0, 48)
	song.BackgroundTransparency = 1
	song.Text = "🎵 RIVER FLOWS IN YOU"
	song.TextColor3 = Color3.fromRGB(255, 255, 255)
	song.Font = Enum.Font.FredokaOne
	song.TextSize = 15
	song.TextWrapped = true
	song.TextXAlignment = Enum.TextXAlignment.Left
	song.TextYAlignment = Enum.TextYAlignment.Top
	song.Parent = woodPanel

	local songStroke = Instance.new("UIStroke")
	songStroke.Color = Color3.fromRGB(45, 25, 12)
	songStroke.Thickness = 1.5
	songStroke.Parent = song

	local combo = Instance.new("TextLabel")
	combo.Name = "ComboLabel"
	combo.Size = UDim2.new(0.88, 0, 0, 28)
	combo.Position = UDim2.new(0.06, 0, 0, 215)
	combo.BackgroundTransparency = 1
	combo.Text = "COMBO x0"
	combo.TextColor3 = Color3.fromRGB(255, 215, 0)
	combo.Font = Enum.Font.FredokaOne
	combo.TextSize = 16
	combo.Visible = false
	combo.Parent = woodPanel

	local comboStroke = Instance.new("UIStroke")
	comboStroke.Color = Color3.fromRGB(0, 0, 0)
	comboStroke.Thickness = 2
	comboStroke.Parent = combo

	-- ==================================================
	-- 2. CENTER ARENA (4 Water Lanes)
	-- ==================================================
	local arena = Instance.new("Frame")
	arena.Name = "ArenaFrame"
	arena.Size = UDim2.new(0, 280, 0, 440)
	arena.Position = UDim2.new(0, 175, 0, 20)
	arena.BackgroundColor3 = Color3.fromRGB(56, 172, 224) -- Tropical Water Blue
	arena.BorderSizePixel = 0
	arena.ClipsDescendants = true
	arena.Parent = container
	Instance.new("UICorner", arena).CornerRadius = UDim.new(0, 16)

	local arenaStroke = Instance.new("UIStroke")
	arenaStroke.Color = Color3.fromRGB(255, 255, 255)
	arenaStroke.Thickness = 2.5
	arenaStroke.Parent = arena

	-- Water gradient
	local aGrad = Instance.new("UIGradient")
	aGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(64, 185, 235)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 148, 204)),
	})
	aGrad.Rotation = 90
	aGrad.Parent = arena

	for i = 1, Config.COLUMN_COUNT do
		local col = Instance.new("Frame")
		col.Name = "Column" .. i
		col.Size = UDim2.new(1 / Config.COLUMN_COUNT, 0, 1, 0)
		col.Position = UDim2.new((i - 1) / Config.COLUMN_COUNT, 0, 0, 0)
		col.BackgroundTransparency = (i % 2 == 0) and 0.96 or 1
		col.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		col.BorderSizePixel = 0
		col.Parent = arena

		if i < Config.COLUMN_COUNT then
			local divider = Instance.new("Frame")
			divider.Name = "Divider" .. i
			divider.Size = UDim2.new(0, 2, 1, 0)
			divider.Position = UDim2.new(i / Config.COLUMN_COUNT, -1, 0, 0)
			divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			divider.BackgroundTransparency = 0.15
			divider.BorderSizePixel = 0
			divider.ZIndex = 8
			divider.Parent = arena
		end
	end

	-- Bottom Wooden Dock
	local bottomDock = Instance.new("Frame")
	bottomDock.Name = "BottomDock"
	bottomDock.Size = UDim2.new(1, 0, 0, 68)
	bottomDock.Position = UDim2.new(0, 0, 1, -68)
	bottomDock.BackgroundColor3 = Color3.fromRGB(112, 74, 46) -- Dark Wood Dock
	bottomDock.BorderSizePixel = 0
	bottomDock.ZIndex = 9
	bottomDock.Parent = arena

	local dockTopBorder = Instance.new("Frame")
	dockTopBorder.Name = "DockTopBorder"
	dockTopBorder.Size = UDim2.new(1, 0, 0, 3)
	dockTopBorder.Position = UDim2.new(0, 0, 0, 0)
	dockTopBorder.BackgroundColor3 = Color3.fromRGB(68, 42, 24)
	dockTopBorder.BorderSizePixel = 0
	dockTopBorder.ZIndex = 10
	dockTopBorder.Parent = bottomDock

	-- PERFECT Laser Line & Badge
	local hLine = Instance.new("Frame")
	hLine.Name = "HitLine"
	hLine.Size = UDim2.new(1, 0, 0, 2)
	hLine.Position = UDim2.new(0, 0, 1, -68)
	hLine.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	hLine.BorderSizePixel = 0
	hLine.ZIndex = 14
	hLine.Parent = arena

	local hLineStroke = Instance.new("UIStroke")
	hLineStroke.Color = Color3.fromRGB(255, 245, 150)
	hLineStroke.Thickness = 1.5
	hLineStroke.Transparency = 0.2
	hLineStroke.Parent = hLine

	local perfectBadge = Instance.new("TextLabel")
	perfectBadge.Name = "PerfectBadge"
	perfectBadge.Size = UDim2.new(0, 70, 0, 14)
	perfectBadge.Position = UDim2.new(0, 6, 0, -15)
	perfectBadge.BackgroundTransparency = 1
	perfectBadge.Text = "★ PERFECT"
	perfectBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
	perfectBadge.Font = Enum.Font.FredokaOne
	perfectBadge.TextSize = 10
	perfectBadge.TextXAlignment = Enum.TextXAlignment.Left
	perfectBadge.ZIndex = 15
	perfectBadge.Parent = hLine

	local pbStroke = Instance.new("UIStroke")
	pbStroke.Color = Color3.fromRGB(0, 0, 0)
	pbStroke.Thickness = 1.5
	pbStroke.Parent = perfectBadge

	local keyLabels = Config.KEY_LABELS or { "A", "W", "S", "D" }
	for i = 1, Config.COLUMN_COUNT do
		local col = arena:FindFirstChild("Column" .. i)
		if col then
			-- Metallic Fishing Hook looping from dock into receptor
			local hookHolder = Instance.new("Frame")
			hookHolder.Name = "FishingHook" .. i
			hookHolder.Size = UDim2.new(0, 24, 0, 36)
			hookHolder.Position = UDim2.new(0.5, -12, 1, -82)
			hookHolder.BackgroundTransparency = 1
			hookHolder.ZIndex = 11
			hookHolder.Parent = col

			local eyelet = Instance.new("Frame")
			eyelet.Size = UDim2.new(0, 8, 0, 8)
			eyelet.Position = UDim2.new(0.5, -4, 0, 0)
			eyelet.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
			eyelet.BorderSizePixel = 0
			eyelet.ZIndex = 11
			eyelet.Parent = hookHolder
			Instance.new("UICorner", eyelet).CornerRadius = UDim.new(1, 0)

			local shank = Instance.new("Frame")
			shank.Size = UDim2.new(0, 3, 0, 20)
			shank.Position = UDim2.new(0.5, -1.5, 0, 6)
			shank.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
			shank.BorderSizePixel = 0
			shank.ZIndex = 11
			shank.Parent = hookHolder

			local bend = Instance.new("Frame")
			bend.Size = UDim2.new(0, 16, 0, 14)
			bend.Position = UDim2.new(0.5, -8, 0, 20)
			bend.BackgroundTransparency = 1
			bend.ZIndex = 11
			bend.Parent = hookHolder
			local bendStroke = Instance.new("UIStroke")
			bendStroke.Color = Color3.fromRGB(240, 245, 255)
			bendStroke.Thickness = 2.5
			bendStroke.Parent = bend
			Instance.new("UICorner", bend).CornerRadius = UDim.new(0, 7)

			-- Square Blue Key Button
			local receptor = Instance.new("Frame")
			receptor.Name = "ReceptorPad"
			receptor.Size = UDim2.new(0.72, 0, 0, 44)
			receptor.Position = UDim2.new(0.14, 0, 1, -54)
			receptor.BackgroundColor3 = Color3.fromRGB(0, 162, 232)
			receptor.BorderSizePixel = 0
			receptor.ZIndex = 12
			receptor.Parent = col
			Instance.new("UICorner", receptor).CornerRadius = UDim.new(0, 8)

			local rAspect = Instance.new("UIAspectRatioConstraint")
			rAspect.AspectRatio = 1
			rAspect.Parent = receptor

			local rStroke = Instance.new("UIStroke")
			rStroke.Color = Color3.fromRGB(255, 255, 255)
			rStroke.Thickness = 2.5
			rStroke.Parent = receptor

			local targetNotch = Instance.new("Frame")
			targetNotch.Name = "PerfectTargetNotch"
			targetNotch.Size = UDim2.new(0.6, 0, 0, 2)
			targetNotch.Position = UDim2.new(0.2, 0, 0.5, -1)
			targetNotch.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			targetNotch.BackgroundTransparency = 0.3
			targetNotch.BorderSizePixel = 0
			targetNotch.ZIndex = 14
			targetNotch.Parent = receptor

			local keyText = Instance.new("TextLabel")
			keyText.Name = "KeyLabel"
			keyText.Size = UDim2.fromScale(1, 1)
			keyText.BackgroundTransparency = 1
			keyText.Text = keyLabels[i] or tostring(i)
			keyText.TextColor3 = Color3.fromRGB(255, 255, 255)
			keyText.Font = Enum.Font.FredokaOne
			keyText.TextSize = 20
			keyText.ZIndex = 13
			keyText.Parent = receptor

			local ktStroke = Instance.new("UIStroke")
			ktStroke.Color = Color3.fromRGB(0, 100, 160)
			ktStroke.Thickness = 1.5
			ktStroke.Parent = keyText
		end
	end

	local centerJudge = Instance.new("TextLabel")
	centerJudge.Name = "CenterJudgementLabel"
	centerJudge.Size = UDim2.new(0.9, 0, 0, 38)
	centerJudge.Position = UDim2.new(0.5, 0, 0.44, 0)
	centerJudge.AnchorPoint = Vector2.new(0.5, 0.5)
	centerJudge.BackgroundTransparency = 1
	centerJudge.Font = Enum.Font.FredokaOne
	centerJudge.TextSize = 26
	centerJudge.TextColor3 = Color3.fromRGB(255, 215, 0)
	centerJudge.Text = ""
	centerJudge.ZIndex = 40
	centerJudge.Parent = arena

	local cjStroke = Instance.new("UIStroke")
	cjStroke.Color = Color3.fromRGB(0, 0, 0)
	cjStroke.Thickness = 2
	cjStroke.Parent = centerJudge

	-- ==================================================
	-- 3. RIGHT VERTICAL WATER PROGRESS BAR
	-- ==================================================
	local pBar = Instance.new("Frame")
	pBar.Name = "ProgressBar"
	pBar.Size = UDim2.new(0, 34, 0, 440)
	pBar.Position = UDim2.new(0, 468, 0, 20)
	pBar.BackgroundColor3 = Color3.fromRGB(56, 172, 224)
	pBar.BorderSizePixel = 0
	pBar.ClipsDescendants = true
	pBar.Parent = container
	Instance.new("UICorner", pBar).CornerRadius = UDim.new(0, 17)

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = Color3.fromRGB(255, 255, 255)
	pStroke.Thickness = 2.5
	pStroke.Parent = pBar

	local trackLine = Instance.new("Frame")
	trackLine.Name = "TrackLine"
	trackLine.Size = UDim2.new(0, 4, 0.94, 0)
	trackLine.Position = UDim2.new(0.5, -2, 0.03, 0)
	trackLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	trackLine.BorderSizePixel = 0
	trackLine.Parent = pBar
	Instance.new("UICorner", trackLine).CornerRadius = UDim.new(1, 0)

	local pFill = Instance.new("Frame")
	pFill.Name = "Fill"
	pFill.Size = UDim2.new(1, 0, 0, 0)
	pFill.Position = UDim2.new(0, 0, 1, 0)
	pFill.BackgroundColor3 = Color3.fromRGB(0, 210, 255)
	pFill.BackgroundTransparency = 0.4
	pFill.BorderSizePixel = 0
	pFill.Parent = pBar

	local fishIcon = Instance.new("ImageLabel")
	fishIcon.Name = "Fish"
	fishIcon.Size = UDim2.new(0, 26, 0, 26)
	fishIcon.Position = UDim2.new(0.5, -13, 0.92, -13)
	fishIcon.BackgroundTransparency = 1
	fishIcon.Image = "rbxassetid://81497165860027"
	fishIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
	fishIcon.ScaleType = Enum.ScaleType.Fit
	fishIcon.ZIndex = 5
	fishIcon.Parent = pBar

	-- ==================================================
	-- 4. BOTTOM PROGRESS TEXT
	-- ==================================================
	local pLabel = Instance.new("TextLabel")
	pLabel.Name = "ProgressLabel"
	pLabel.Size = UDim2.new(0, 320, 0, 26)
	pLabel.Position = UDim2.new(0, 185, 0, 468)
	pLabel.BackgroundTransparency = 1
	pLabel.Text = "🎣 PROGRES: 0% • 0/30 NOT"
	pLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	pLabel.Font = Enum.Font.FredokaOne
	pLabel.TextSize = 15
	pLabel.TextXAlignment = Enum.TextXAlignment.Right
	pLabel.Parent = container

	local plStroke = Instance.new("UIStroke")
	plStroke.Color = Color3.fromRGB(0, 100, 180)
	plStroke.Thickness = 2
	plStroke.Parent = pLabel

	-- ==================================================
	-- 5. RESULT OVERLAY
	-- ==================================================
	local result = Instance.new("Frame")
	result.Name = "ResultOverlay"
	result.Size = UDim2.fromScale(1, 1)
	result.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	result.BackgroundTransparency = 0.12
	result.BorderSizePixel = 0
	result.Visible = false
	result.ZIndex = 30
	result.Parent = arena
	Instance.new("UICorner", result).CornerRadius = UDim.new(0, 16)

	local resLabel = Instance.new("TextLabel")
	resLabel.Name = "ResultLabel"
	resLabel.Size = UDim2.new(1, 0, 0, 36)
	resLabel.Position = UDim2.new(0, 0, 0.12, 0)
	resLabel.BackgroundTransparency = 1
	resLabel.Text = "BERHASIL DITANGKAP!"
	resLabel.TextColor3 = Color3.fromRGB(60, 240, 140)
	resLabel.Font = Enum.Font.FredokaOne
	resLabel.TextSize = 22
	resLabel.ZIndex = 32
	resLabel.Parent = result

	return screenGui
end

function PianoUI.Create()
	local playerGui = getPlayerGui()
	if not playerGui then return false end

	local existing = playerGui:FindFirstChild("PianoTilesGui")
	if existing then
		existing:Destroy()
	end
	gui = buildDynamicGui(playerGui)
	if not gui then return false end

	arenaContainer = gui:FindFirstChild("ArenaContainer")
	if not arenaContainer then return false end

	arenaFrame = arenaContainer:FindFirstChild("ArenaFrame")
	if not arenaFrame then return false end

	hitLine = arenaFrame:FindFirstChild("HitLine")
	perfectZoneGuide = arenaFrame:FindFirstChild("PerfectZoneGuide")
	centerJudgementLabel = arenaFrame:FindFirstChild("CenterJudgementLabel")

	table.clear(columns)
	table.clear(columnFlashes)
	table.clear(receptorPads)
	table.clear(receptorLabels)

	for i = 1, Config.COLUMN_COUNT do
		local col = arenaFrame:WaitForChild("Column" .. i, 3)
		if col then
			columns[i] = col
			local flash = col:FindFirstChild("ColumnFlash")
			if not flash then
				flash = Instance.new("Frame")
				flash.Name = "ColumnFlash"
				flash.Size = UDim2.fromScale(1, 1)
				flash.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				flash.BackgroundTransparency = 1
				flash.BorderSizePixel = 0
				flash.Visible = false
				flash.ZIndex = 20
				flash.Parent = col
			end
			columnFlashes[i] = flash

			local receptor = col:FindFirstChild("ReceptorPad")
			if receptor then
				receptorPads[i] = receptor
				receptorLabels[i] = receptor:FindFirstChild("KeyLabel")
			end
		end
	end

	castBonusLabel = arenaContainer:FindFirstChild("CastBonusLabel", true)
	songLabel = arenaContainer:FindFirstChild("SongLabel", true)
	comboLabel = arenaContainer:FindFirstChild("ComboLabel", true)

	progressContainer = arenaContainer:FindFirstChild("ProgressBar")
	if progressContainer then
		progressFill = progressContainer:FindFirstChild("Fill")
		fish = progressContainer:FindFirstChild("Fish")
		progressGlow = progressContainer:FindFirstChild("UIStroke")
	end
	progressLabel = arenaContainer:FindFirstChild("ProgressLabel")

	resultOverlay = arenaFrame:FindFirstChild("ResultOverlay") or arenaContainer:FindFirstChild("ResultOverlay", true)
	if resultOverlay then
		resultLabel = resultOverlay:FindFirstChild("ResultLabel")
	end

	gui.Enabled = false
	return true
end

function PianoUI.SetEnabled(enabled)
	if gui then gui.Enabled = enabled end
end

function PianoUI.GetArenaFrame()
	return arenaFrame
end

function PianoUI.CreateTile(column, y)
	local parent = columns[column]
	if not parent then return nil end

	local tile = Instance.new("Frame")
	tile.Name = "Tile"
	tile.Size = UDim2.new(0.82, 0, Config.TILE_HEIGHT, 0)
	tile.Position = UDim2.new(0.09, 0, y, 0)
	tile.BackgroundColor3 = Color3.fromRGB(0, 162, 232)
	tile.BorderSizePixel = 0
	tile.ZIndex = 15
	tile.Parent = parent
	Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 8)

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = tile

	local fishImg = Instance.new("ImageLabel")
	fishImg.Name = "FishImage"
	fishImg.Size = UDim2.new(0.75, 0, 0.75, 0)
	fishImg.Position = UDim2.new(0.125, 0, 0.125, 0)
	fishImg.BackgroundTransparency = 1
	fishImg.Image = Config.TILE_IMAGES[column] or "rbxassetid://81497165860027"
	fishImg.ScaleType = Enum.ScaleType.Fit
	fishImg.BorderSizePixel = 0
	fishImg.ZIndex = 16
	fishImg.Parent = tile

	local glow = Instance.new("UIStroke")
	glow.Name = "TileGlow"
	glow.Color = Color3.fromRGB(255, 255, 255)
	glow.Thickness = 2.5
	glow.Transparency = 0
	glow.Parent = tile

	return tile
end

function PianoUI.MoveTile(tile, y)
	if tile and tile.Parent then
		tile.Position = UDim2.new(0.09, 0, y, 0)
		local glow = tile:FindFirstChild("TileGlow")
		if glow then
			local delta = math.abs(y - Config.HIT_LINE)
			if delta <= 0.05 then
				-- Zone PERFECT: Radiant Gold Glow
				glow.Color = Color3.fromRGB(255, 215, 0)
				glow.Thickness = 3.5
				glow.Transparency = 0
			elseif delta <= 0.09 then
				-- Zone GREAT: Vibrant Cyan Glow
				glow.Color = Color3.fromRGB(0, 240, 255)
				glow.Thickness = 2.5
				glow.Transparency = 0.15
			else
				-- Normal State: Crisp White Outline
				glow.Color = Color3.fromRGB(255, 255, 255)
				glow.Thickness = 2.5
				glow.Transparency = 0
			end
		end
	end
end

function PianoUI.DestroyTile(tile)
	if tile and tile.Parent then tile:Destroy() end
end

function PianoUI.TriggerReceptorPress(column, ratingKey)
	local pad = receptorPads[column]
	if not pad then return end

	local ratingData = Config.HIT_RATINGS[ratingKey or "GOOD"] or Config.HIT_RATINGS.GOOD
	pad.BackgroundColor3 = ratingData.flashColor
	pad.BackgroundTransparency = 0.2

	TweenService:Create(pad, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(0, 162, 232),
		BackgroundTransparency = 0,
	}):Play()
end

function PianoUI.ShowHitRating(ratingKey, column, y)
	if not arenaFrame then return end
	local ratingData = Config.HIT_RATINGS[ratingKey or "GOOD"] or Config.HIT_RATINGS.GOOD

	if centerJudgementLabel then
		centerJudgementLabel.Text = ratingData.symbol
		centerJudgementLabel.TextColor3 = ratingData.color
		centerJudgementLabel.TextTransparency = 0
		TweenService:Create(centerJudgementLabel, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = math.floor(27 * ratingData.scale)
		}):Play()

		task.delay(0.42, function()
			if centerJudgementLabel and centerJudgementLabel.Text == ratingData.symbol then
				TweenService:Create(centerJudgementLabel, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 1
				}):Play()
			end
		end)
	end

	local posX = column and ((column - 0.5) / Config.COLUMN_COUNT) or 0.5
	local posY = (y or Config.HIT_LINE) - 0.08

	local popup = Instance.new("TextLabel")
	popup.Name = "HitRatingPopup"
	popup.Size = UDim2.new(0, 130, 0, 34)
	popup.Position = UDim2.new(posX, 0, posY, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.FredokaOne
	popup.Text = ratingData.symbol
	popup.TextColor3 = ratingData.color
	popup.TextSize = math.floor(13 * ratingData.scale)
	popup.ZIndex = 50
	popup.Parent = arenaFrame

	local popTween = TweenService:Create(popup, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = math.floor(19 * ratingData.scale),
		Position = UDim2.new(posX, 0, posY - 0.03, 0),
	})
	popTween:Play()
	popTween.Completed:Once(function()
		local floatTween = TweenService:Create(popup, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(posX, 0, posY - 0.09, 0),
			TextTransparency = 1,
		})
		floatTween:Play()
		floatTween.Completed:Once(function()
			if popup and popup.Parent then popup:Destroy() end
		end)
	end)
end

function PianoUI.PlayHitEffect(tile, y, ratingKey, column)
	if column then
		PianoUI.TriggerReceptorPress(column, ratingKey)
		PianoUI.FlashColumn(column, ratingKey)
	end
	PianoUI.ShowHitRating(ratingKey, column, y)

	if tile and tile.Parent then
		local tween = TweenService:Create(tile, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.98, 0, Config.TILE_HEIGHT * 1.25, 0),
			Position = UDim2.new(0.01, 0, y - 0.02, 0),
		})
		tween:Play()
		tween.Completed:Once(function()
			if tile and tile.Parent then tile:Destroy() end
		end)
	end
end

function PianoUI.FlashColumn(column, ratingKey)
	local flash = columnFlashes[column]
	if not flash then return end
	local ratingData = Config.HIT_RATINGS[ratingKey or "MISS"] or Config.HIT_RATINGS.MISS

	flash.BackgroundColor3 = ratingData.flashColor
	flash.BackgroundTransparency = (ratingKey == "MISS" and 0.40 or 0.60)
	flash.Visible = true

	local tween = TweenService:Create(flash, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	})
	tween:Play()
	task.delay(0.20, function()
		if flash and flash.Parent then flash.Visible = false end
	end)
end

function PianoUI.UpdateHUD(progress, combo, currentNotes, targetNotes, liveMetrics)
	if comboLabel then
		if combo and combo >= 2 then
			comboLabel.Text = string.format("🔥 COMBO x%d", combo)
			comboLabel.Visible = true
		else
			comboLabel.Visible = false
		end
	end

	local percent = math.clamp(progress or 0, 0, 1)

	if progressFill then
		TweenService:Create(progressFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, percent, 0),
			Position = UDim2.new(0, 0, 1 - percent, 0),
		}):Play()
	end

	if fish and progressContainer then
		local targetY = (1 - percent) * 0.88 + 0.04
		TweenService:Create(fish, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -13, targetY, -13)
		}):Play()
	end

	if progressLabel then
		local pText = math.floor(percent * 100)
		if liveMetrics and liveMetrics.accuracy then
			progressLabel.Text = string.format("🎣 PROGRES: %d%% • %d/%d NOT • 🎯 %.1f%%", pText, currentNotes or 0, targetNotes or 0, liveMetrics.accuracy)
		else
			progressLabel.Text = string.format("🎣 PROGRES: %d%% • %d/%d NOT", pText, currentNotes or 0, targetNotes or 0)
		end
	end
end

function PianoUI.UpdateHeader(castLabel, castColor, melodyName)
	if castBonusLabel then
		castBonusLabel.Text = "✨ " .. tostring(castLabel or "PERFECT CAST")
		castBonusLabel.TextColor3 = castColor or Color3.fromRGB(255, 255, 255)
	end
	if songLabel then
		songLabel.Text = "🎵 " .. tostring(melodyName or "RIVER FLOWS IN YOU"):upper()
	end
end

function PianoUI.ShakeArena()
	if not arenaContainer then return end
	local orig = arenaContainer.Position
	local tween = TweenService:Create(arenaContainer, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 3, true), {
		Position = orig + UDim2.new(0, math.random(-6, 6), 0, math.random(-3, 3))
	})
	tween:Play()
	task.delay(0.2, function()
		if arenaContainer then arenaContainer.Position = orig end
	end)
end

function PianoUI.ShowResult(win, message, performance)
	if not resultOverlay or not resultLabel then return end
	resultLabel.Text = message or (win and "BERHASIL DITANGKAP!" or "IKAN TERLEPAS!")
	resultLabel.TextColor3 = win and Color3.fromRGB(60, 240, 140) or Color3.fromRGB(255, 70, 70)
	resultOverlay.Visible = true
end

function PianoUI.HideResult()
	if resultOverlay then resultOverlay.Visible = false end
end

return PianoUI
