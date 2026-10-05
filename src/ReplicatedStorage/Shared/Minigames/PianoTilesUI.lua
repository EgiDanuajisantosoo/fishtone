--[[
    PianoTilesUI
    FISH!TUNE — Guitar Fretboard Runway, Vibrating Strings & Instrument Sound Engine (FISH-027)

    Fitur Visual & Fretboard:
    1. Guitar Fretboard Runway & Neon Vibrating Strings:
       - 4 Senar neon vertikal dinamis (E-A-D-G / B-E-A-D / 1-2-3-4) dengan animasi getaran senar saat dipetik.
       - Fret wire markers horizontal & pearl inlay position dots.
    2. Dynamic Instrument Theming & Badges:
       - Mendukung tema visual Gitar Akustik, Gitar Elektrik, Abyssal Rock Metal, dan Piano Klasik.
       - Pill header badge instrumen interaktif dengan icon & warna rod yang digunakan.
    3. Target Hit Receptors dengan keybind & notasi senar gitar.
    4. Judgement Popups (PERFECT / GREAT / GOOD / MISS) & Ripple Shockwaves.
    5. Modern Glassmorphism Result Card dengan Grade Badge, Akurasi Live & Multiplier.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Config = require(
	Shared:WaitForChild("Config"):WaitForChild("PianoTilesConfig")
)
local PerformanceCalculator = require(
	Shared:WaitForChild("Systems"):WaitForChild("PerformanceCalculator")
)

local PianoTilesUI = {}

--==================================================
-- REFERENCES
--==================================================

local gui
local arenaContainer
local arenaFrame

local castBonusLabel
local songLabel
local instrumentBadgeLabel
local instrumentPill
local comboLabel
local centerJudgementLabel
local hitLine
local perfectZoneGuide

local resultOverlay
local resultLabel
local gradeBadgeLabel
local gradeTitleLabel
local statsDetailLabel
local multiplierDetailLabel

local progressContainer
local progressFill
local progressLabel
local progressGlow
local fish

local columns = {}
local columnFlashes = {}
local receptorPads = {}
local receptorLabels = {}
local receptorStringLabels = {}
local stringLines = {}
local fretWires = {}
local fretInlays = {}

--==================================================
-- PLAYER GUI
--==================================================

local function getPlayerGui()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end

	return player:FindFirstChild("PlayerGui")
		or player:WaitForChild("PlayerGui", 5)
end

--==================================================
-- DYNAMIC FALLBACK GUI BUILDER
--==================================================

local function buildDynamicGui(playerGui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PianoTilesGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Arena Container (Main Window)
	local container = Instance.new("Frame")
	container.Name = "ArenaContainer"
	container.Size = UDim2.new(0, 380, 0, 530)
	container.Position = UDim2.new(0.5, -190, 0.5, -265)
	container.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	container.BackgroundTransparency = 0.12
	container.BorderSizePixel = 0
	container.Parent = screenGui
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 18)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(0, 210, 255)
	cStroke.Thickness = 2.5
	cStroke.Transparency = 0.2
	cStroke.Parent = container

	-- Header Area
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundTransparency = 1
	header.Parent = container

	-- 1. Cast Bonus Pill Badge
	local castPill = Instance.new("Frame")
	castPill.Name = "CastPill"
	castPill.Size = UDim2.new(0.30, 0, 0, 26)
	castPill.Position = UDim2.new(0.03, 0, 0, 6)
	castPill.BackgroundColor3 = Color3.fromRGB(20, 36, 45)
	castPill.BackgroundTransparency = 0.2
	castPill.BorderSizePixel = 0
	castPill.Parent = header
	Instance.new("UICorner", castPill).CornerRadius = UDim.new(0, 13)

	local castStroke = Instance.new("UIStroke")
	castStroke.Color = Color3.fromRGB(50, 255, 140)
	castStroke.Thickness = 1.5
	castStroke.Transparency = 0.3
	castStroke.Parent = castPill

	local castBonus = Instance.new("TextLabel")
	castBonus.Name = "CastBonusLabel"
	castBonus.Size = UDim2.fromScale(1, 1)
	castBonus.BackgroundTransparency = 1
	castBonus.Text = "✨ PERFECT"
	castBonus.TextColor3 = Color3.fromRGB(60, 255, 150)
	castBonus.Font = Enum.Font.GothamBlack
	castBonus.TextSize = 11
	castBonus.Parent = castPill

	-- 2. Instrument Mode Pill Badge (FISH-027)
	local instPill = Instance.new("Frame")
	instPill.Name = "InstrumentPill"
	instPill.Size = UDim2.new(0.32, 0, 0, 26)
	instPill.Position = UDim2.new(0.34, 0, 0, 6)
	instPill.BackgroundColor3 = Color3.fromRGB(28, 20, 38)
	instPill.BackgroundTransparency = 0.2
	instPill.BorderSizePixel = 0
	instPill.Parent = header
	Instance.new("UICorner", instPill).CornerRadius = UDim.new(0, 13)

	local instStroke = Instance.new("UIStroke")
	instStroke.Color = Color3.fromRGB(245, 158, 11)
	instStroke.Thickness = 1.5
	instStroke.Transparency = 0.3
	instStroke.Parent = instPill

	local instBadge = Instance.new("TextLabel")
	instBadge.Name = "InstrumentBadgeLabel"
	instBadge.Size = UDim2.fromScale(1, 1)
	instBadge.BackgroundTransparency = 1
	instBadge.Text = "🎸 AKUSTIK"
	instBadge.TextColor3 = Color3.fromRGB(250, 204, 21)
	instBadge.Font = Enum.Font.GothamBlack
	instBadge.TextSize = 11
	instBadge.Parent = instPill

	-- 3. Song Info Pill Badge
	local songPill = Instance.new("Frame")
	songPill.Name = "SongPill"
	songPill.Size = UDim2.new(0.30, 0, 0, 26)
	songPill.Position = UDim2.new(0.67, 0, 0, 6)
	songPill.BackgroundColor3 = Color3.fromRGB(18, 28, 48)
	songPill.BackgroundTransparency = 0.2
	songPill.BorderSizePixel = 0
	songPill.Parent = header
	Instance.new("UICorner", songPill).CornerRadius = UDim.new(0, 13)

	local songStroke = Instance.new("UIStroke")
	songStroke.Color = Color3.fromRGB(0, 200, 255)
	songStroke.Thickness = 1.5
	songStroke.Transparency = 0.4
	songStroke.Parent = songPill

	local song = Instance.new("TextLabel")
	song.Name = "SongLabel"
	song.Size = UDim2.fromScale(1, 1)
	song.BackgroundTransparency = 1
	song.Text = "🎵 Melodi"
	song.TextColor3 = Color3.fromRGB(210, 240, 255)
	song.Font = Enum.Font.GothamBold
	song.TextSize = 11
	song.TextTruncate = Enum.TextTruncate.AtEnd
	song.Parent = songPill

	-- Combo Banner
	local combo = Instance.new("TextLabel")
	combo.Name = "ComboLabel"
	combo.Size = UDim2.new(1, 0, 0, 22)
	combo.Position = UDim2.new(0, 0, 0, 36)
	combo.BackgroundTransparency = 1
	combo.Text = "COMBO x0"
	combo.TextColor3 = Color3.fromRGB(255, 215, 0)
	combo.Font = Enum.Font.GothamBlack
	combo.TextSize = 16
	combo.Visible = false
	combo.Parent = header

	local comboStroke = Instance.new("UIStroke")
	comboStroke.Color = Color3.fromRGB(0, 0, 0)
	comboStroke.Thickness = 2
	comboStroke.Transparency = 0.2
	comboStroke.Parent = combo

	-- Top Hit Zone Legend (Keterangan Posisi Not: PERFECT, GREAT, GOOD)
	local legendBar = Instance.new("Frame")
	legendBar.Name = "HitZoneLegend"
	legendBar.Size = UDim2.new(0.92, 0, 0, 20)
	legendBar.Position = UDim2.new(0.04, 0, 0, 60)
	legendBar.BackgroundTransparency = 1
	legendBar.ZIndex = 25
	legendBar.Parent = container

	local legendLayout = Instance.new("UIListLayout")
	legendLayout.FillDirection = Enum.FillDirection.Horizontal
	legendLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	legendLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	legendLayout.Padding = UDim.new(0, 8)
	legendLayout.SortOrder = Enum.SortOrder.LayoutOrder
	legendLayout.Parent = legendBar

	local pTag = Instance.new("TextLabel")
	pTag.Name = "LegendPerfect"
	pTag.Size = UDim2.new(0, 105, 0, 18)
	pTag.BackgroundColor3 = Color3.fromRGB(42, 32, 12)
	pTag.BackgroundTransparency = 0.25
	pTag.Text = "⭐ PERFECT: Emas"
	pTag.TextColor3 = Color3.fromRGB(255, 215, 0)
	pTag.Font = Enum.Font.GothamBold
	pTag.TextSize = 9
	pTag.LayoutOrder = 1
	pTag.Parent = legendBar
	Instance.new("UICorner", pTag).CornerRadius = UDim.new(0, 9)
	local pTagStroke = Instance.new("UIStroke")
	pTagStroke.Color = Color3.fromRGB(250, 204, 21)
	pTagStroke.Thickness = 1
	pTagStroke.Transparency = 0.4
	pTagStroke.Parent = pTag

	local grTag = Instance.new("TextLabel")
	grTag.Name = "LegendGreat"
	grTag.Size = UDim2.new(0, 98, 0, 18)
	grTag.BackgroundColor3 = Color3.fromRGB(12, 32, 42)
	grTag.BackgroundTransparency = 0.25
	grTag.Text = "◆ GREAT: Cyan"
	grTag.TextColor3 = Color3.fromRGB(56, 189, 248)
	grTag.Font = Enum.Font.GothamBold
	grTag.TextSize = 9
	grTag.LayoutOrder = 2
	grTag.Parent = legendBar
	Instance.new("UICorner", grTag).CornerRadius = UDim.new(0, 9)
	local grTagStroke = Instance.new("UIStroke")
	grTagStroke.Color = Color3.fromRGB(56, 189, 248)
	grTagStroke.Thickness = 1
	grTagStroke.Transparency = 0.4
	grTagStroke.Parent = grTag

	local gdTag = Instance.new("TextLabel")
	gdTag.Name = "LegendGood"
	gdTag.Size = UDim2.new(0, 95, 0, 18)
	gdTag.BackgroundColor3 = Color3.fromRGB(12, 38, 24)
	gdTag.BackgroundTransparency = 0.25
	gdTag.Text = "● GOOD: Hijau"
	gdTag.TextColor3 = Color3.fromRGB(74, 222, 128)
	gdTag.Font = Enum.Font.GothamBold
	gdTag.TextSize = 9
	gdTag.LayoutOrder = 3
	gdTag.Parent = legendBar
	Instance.new("UICorner", gdTag).CornerRadius = UDim.new(0, 9)
	local gdTagStroke = Instance.new("UIStroke")
	gdTagStroke.Color = Color3.fromRGB(74, 222, 128)
	gdTagStroke.Thickness = 1
	gdTagStroke.Transparency = 0.4
	gdTagStroke.Parent = gdTag

	-- Arena Frame (Playing Field / Guitar Fretboard Runway)
	local arena = Instance.new("Frame")
	arena.Name = "ArenaFrame"
	arena.Size = UDim2.new(0.92, 0, 0.64, 0)
	arena.Position = UDim2.new(0.04, 0, 0, 84)
	arena.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	arena.BackgroundTransparency = 0.35
	arena.BorderSizePixel = 0
	arena.ClipsDescendants = true
	arena.Parent = container
	Instance.new("UICorner", arena).CornerRadius = UDim.new(0, 12)

	local arenaStroke = Instance.new("UIStroke")
	arenaStroke.Color = Color3.fromRGB(40, 80, 120)
	arenaStroke.Thickness = 1.5
	arenaStroke.Transparency = 0.5
	arenaStroke.Parent = arena

	-- Horizontal Fret Wires (FISH-027 Fretboard aesthetic)
	local fretYPositions = { 0.18, 0.36, 0.54, 0.72 }
	for idx, fY in ipairs(fretYPositions) do
		local fretWire = Instance.new("Frame")
		fretWire.Name = "FretWire" .. idx
		fretWire.Size = UDim2.new(1, 0, 0, 1)
		fretWire.Position = UDim2.new(0, 0, fY, 0)
		fretWire.BackgroundColor3 = Color3.fromRGB(180, 140, 90)
		fretWire.BackgroundTransparency = 0.60
		fretWire.BorderSizePixel = 0
		fretWire.ZIndex = 5
		fretWire.Parent = arena
	end

	-- Pearl Inlay Position Markers (Fret Inlays at Fret 2 and Fret 3)
	local inlayY = { 0.27, 0.45 }
	for idx, inY in ipairs(inlayY) do
		local dot = Instance.new("Frame")
		dot.Name = "FretInlay" .. idx
		dot.Size = UDim2.new(0, 8, 0, 8)
		dot.Position = UDim2.new(0.5, -4, inY, -4)
		dot.BackgroundColor3 = Color3.fromRGB(240, 240, 255)
		dot.BackgroundTransparency = 0.75
		dot.BorderSizePixel = 0
		dot.ZIndex = 5
		dot.Parent = arena
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	end

	-- 4 Columns, Vibrating String Lines & Dividers
	local keyLabels = Config.KEY_LABELS or { "A", "W", "S", "D" }
	local defaultStringColors = {
		Color3.fromRGB(245, 158, 11),
		Color3.fromRGB(56, 189, 248),
		Color3.fromRGB(74, 222, 128),
		Color3.fromRGB(244, 63, 94),
	}
	local defaultStringNames = { "E", "A", "D", "G" }

	for i = 1, Config.COLUMN_COUNT do
		local col = Instance.new("Frame")
		col.Name = "Column" .. i
		col.Size = UDim2.new(1 / Config.COLUMN_COUNT, 0, 1, 0)
		col.Position = UDim2.new((i - 1) / Config.COLUMN_COUNT, 0, 0, 0)
		col.BackgroundTransparency = (i % 2 == 0) and 0.94 or 0.98
		col.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		col.BorderSizePixel = 0
		col.Parent = arena

		-- Guitar String Line (FISH-027 Vibrating Neon String)
		local strLine = Instance.new("Frame")
		strLine.Name = "StringLine"
		strLine.Size = UDim2.new(0, 2, 1, 0)
		strLine.Position = UDim2.new(0.5, -1, 0, 0)
		strLine.BackgroundColor3 = defaultStringColors[i] or Color3.fromRGB(245, 158, 11)
		strLine.BackgroundTransparency = 0.40
		strLine.BorderSizePixel = 0
		strLine.ZIndex = 6
		strLine.Parent = col

		local strGlow = Instance.new("UIStroke")
		strGlow.Color = defaultStringColors[i] or Color3.fromRGB(253, 230, 138)
		strGlow.Thickness = 1.0
		strGlow.Transparency = 0.5
		strGlow.Parent = strLine

		-- Vertical Lane Divider
		if i < Config.COLUMN_COUNT then
			local divider = Instance.new("Frame")
			divider.Name = "Divider" .. i
			divider.Size = UDim2.new(0, 1, 1, 0)
			divider.Position = UDim2.new(i / Config.COLUMN_COUNT, -0.5, 0, 0)
			divider.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
			divider.BackgroundTransparency = 0.6
			divider.BorderSizePixel = 0
			divider.ZIndex = 8
			divider.Parent = arena
		end
	end

	-- ============ LAYERED HIT ZONE GUIDES (PERFECT, GREAT, GOOD) ============

	-- 1. GOOD HIT ZONE GUIDE (Y: 0.54 to 0.86, Hijau Emerald)
	local goodZone = Instance.new("Frame")
	goodZone.Name = "GoodZoneGuide"
	goodZone.Size = UDim2.new(1, 0, 0.32, 0)
	goodZone.Position = UDim2.new(0, 0, 0.54, 0)
	goodZone.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	goodZone.BackgroundTransparency = 0.94
	goodZone.BorderSizePixel = 0
	goodZone.ZIndex = 8
	goodZone.Parent = arena

	local goodTopLine = Instance.new("Frame")
	goodTopLine.Name = "GoodTopLine"
	goodTopLine.Size = UDim2.new(1, 0, 0, 1)
	goodTopLine.Position = UDim2.new(0, 0, 0, 0)
	goodTopLine.BackgroundColor3 = Color3.fromRGB(74, 222, 128)
	goodTopLine.BackgroundTransparency = 0.65
	goodTopLine.BorderSizePixel = 0
	goodTopLine.ZIndex = 9
	goodTopLine.Parent = goodZone

	local goodLabel = Instance.new("TextLabel")
	goodLabel.Name = "GoodZoneLabel"
	goodLabel.Size = UDim2.new(0, 70, 0, 14)
	goodLabel.Position = UDim2.new(0, 6, 0, 2)
	goodLabel.BackgroundTransparency = 1
	goodLabel.Text = "● GOOD"
	goodLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
	goodLabel.Font = Enum.Font.GothamBold
	goodLabel.TextSize = 9
	goodLabel.TextXAlignment = Enum.TextXAlignment.Left
	goodLabel.ZIndex = 10
	goodLabel.Parent = goodZone

	-- 2. GREAT HIT ZONE GUIDE (Y: 0.63 to 0.81, Electric Cyan)
	local greatZone = Instance.new("Frame")
	greatZone.Name = "GreatZoneGuide"
	greatZone.Size = UDim2.new(1, 0, 0.18, 0)
	greatZone.Position = UDim2.new(0, 0, 0.63, 0)
	greatZone.BackgroundColor3 = Color3.fromRGB(6, 182, 212)
	greatZone.BackgroundTransparency = 0.88
	greatZone.BorderSizePixel = 0
	greatZone.ZIndex = 9
	greatZone.Parent = arena

	local greatTopLine = Instance.new("Frame")
	greatTopLine.Name = "GreatTopLine"
	greatTopLine.Size = UDim2.new(1, 0, 0, 1)
	greatTopLine.Position = UDim2.new(0, 0, 0, 0)
	greatTopLine.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
	greatTopLine.BackgroundTransparency = 0.50
	greatTopLine.BorderSizePixel = 0
	greatTopLine.ZIndex = 10
	greatTopLine.Parent = greatZone

	local greatLabel = Instance.new("TextLabel")
	greatLabel.Name = "GreatZoneLabel"
	greatLabel.Size = UDim2.new(0, 70, 0, 14)
	greatLabel.Position = UDim2.new(0, 6, 0, 2)
	greatLabel.BackgroundTransparency = 1
	greatLabel.Text = "◆ GREAT"
	greatLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
	greatLabel.Font = Enum.Font.GothamBold
	greatLabel.TextSize = 9
	greatLabel.TextXAlignment = Enum.TextXAlignment.Left
	greatLabel.ZIndex = 11
	greatLabel.Parent = greatZone

	-- 3. PERFECT HIT ZONE GUIDE (Y: 0.67 to 0.77, Radiant Gold)
	local perfectZone = Instance.new("Frame")
	perfectZone.Name = "PerfectZoneGuide"
	perfectZone.Size = UDim2.new(1, 0, 0.10, 0)
	perfectZone.Position = UDim2.new(0, 0, 0.67, 0)
	perfectZone.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
	perfectZone.BackgroundTransparency = 0.76
	perfectZone.BorderSizePixel = 0
	perfectZone.ZIndex = 11
	perfectZone.Parent = arena

	local perfectStroke = Instance.new("UIStroke")
	perfectStroke.Color = Color3.fromRGB(250, 204, 21)
	perfectStroke.Thickness = 1.2
	perfectStroke.Transparency = 0.30
	perfectStroke.Parent = perfectZone

	local perfectLabelLeft = Instance.new("TextLabel")
	perfectLabelLeft.Name = "PerfectZoneLabelLeft"
	perfectLabelLeft.Size = UDim2.new(0, 80, 0, 14)
	perfectLabelLeft.Position = UDim2.new(0, 6, 0.5, -7)
	perfectLabelLeft.BackgroundTransparency = 1
	perfectLabelLeft.Text = "★ PERFECT"
	perfectLabelLeft.TextColor3 = Color3.fromRGB(255, 215, 0)
	perfectLabelLeft.Font = Enum.Font.GothamBlack
	perfectLabelLeft.TextSize = 9
	perfectLabelLeft.TextXAlignment = Enum.TextXAlignment.Left
	perfectLabelLeft.ZIndex = 13
	perfectLabelLeft.Parent = perfectZone

	local perfectLabelRight = Instance.new("TextLabel")
	perfectLabelRight.Name = "PerfectZoneLabelRight"
	perfectLabelRight.Size = UDim2.new(0, 80, 0, 14)
	perfectLabelRight.Position = UDim2.new(1, -86, 0.5, -7)
	perfectLabelRight.BackgroundTransparency = 1
	perfectLabelRight.Text = "PERFECT ★"
	perfectLabelRight.TextColor3 = Color3.fromRGB(255, 215, 0)
	perfectLabelRight.Font = Enum.Font.GothamBlack
	perfectLabelRight.TextSize = 9
	perfectLabelRight.TextXAlignment = Enum.TextXAlignment.Right
	perfectLabelRight.ZIndex = 13
	perfectLabelRight.Parent = perfectZone

	-- 4. CENTER TARGET LASER HIT LINE (Y = 0.72)
	local hLine = Instance.new("Frame")
	hLine.Name = "HitLine"
	hLine.Size = UDim2.new(1, 0, 0, 3)
	hLine.Position = UDim2.new(0, 0, Config.HIT_LINE, -1)
	hLine.BackgroundColor3 = Color3.fromRGB(255, 225, 80)
	hLine.BorderSizePixel = 0
	hLine.ZIndex = 14
	hLine.Parent = arena

	local hLineStroke = Instance.new("UIStroke")
	hLineStroke.Color = Color3.fromRGB(255, 245, 160)
	hLineStroke.Thickness = 1.8
	hLineStroke.Transparency = 0.2
	hLineStroke.Parent = hLine

	-- 5. MISS BOUNDARY LINE (Y = 0.86)
	local missLine = Instance.new("Frame")
	missLine.Name = "MissLine"
	missLine.Size = UDim2.new(1, 0, 0, 2)
	missLine.Position = UDim2.new(0, 0, Config.MISS_LINE, 0)
	missLine.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
	missLine.BackgroundTransparency = 0.45
	missLine.BorderSizePixel = 0
	missLine.ZIndex = 14
	missLine.Parent = arena

	local missLabel = Instance.new("TextLabel")
	missLabel.Name = "MissLineLabel"
	missLabel.Size = UDim2.new(0, 60, 0, 14)
	missLabel.Position = UDim2.new(0, 6, 0, 2)
	missLabel.BackgroundTransparency = 1
	missLabel.Text = "✕ MISS"
	missLabel.TextColor3 = Color3.fromRGB(248, 113, 113)
	missLabel.Font = Enum.Font.GothamBold
	missLabel.TextSize = 8
	missLabel.TextXAlignment = Enum.TextXAlignment.Left
	missLabel.ZIndex = 14
	missLabel.Parent = missLine

	-- Perfect Hit Target Receptors with Guitar Pick Styling (FISH-027)
	for i = 1, Config.COLUMN_COUNT do
		local col = arena:FindFirstChild("Column" .. i)
		if col then
			local receptor = Instance.new("Frame")
			receptor.Name = "ReceptorPad"
			receptor.Size = UDim2.new(0.88, 0, Config.TILE_HEIGHT, 0)
			receptor.Position = UDim2.new(0.06, 0, Config.HIT_LINE, 0)
			receptor.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
			receptor.BackgroundTransparency = 0.85
			receptor.BorderSizePixel = 0
			receptor.ZIndex = 11
			receptor.Parent = col
			Instance.new("UICorner", receptor).CornerRadius = UDim.new(0, 8)

			local rAspect = Instance.new("UIAspectRatioConstraint")
			rAspect.AspectRatio = 1
			rAspect.Parent = receptor

			local rStroke = Instance.new("UIStroke")
			rStroke.Color = defaultStringColors[i] or Color3.fromRGB(0, 220, 255)
			rStroke.Thickness = 2
			rStroke.Transparency = 0.3
			rStroke.Parent = receptor

			-- Key Label [A]
			local keyText = Instance.new("TextLabel")
			keyText.Name = "KeyLabel"
			keyText.Size = UDim2.new(1, 0, 0.65, 0)
			keyText.Position = UDim2.new(0, 0, 0, 0)
			keyText.BackgroundTransparency = 1
			keyText.Text = "[" .. (keyLabels[i] or tostring(i)) .. "]"
			keyText.TextColor3 = Color3.fromRGB(240, 250, 255)
			keyText.Font = Enum.Font.GothamBlack
			keyText.TextSize = 15
			keyText.ZIndex = 12
			keyText.Parent = receptor

			local ktStroke = Instance.new("UIStroke")
			ktStroke.Color = Color3.fromRGB(0, 0, 0)
			ktStroke.Thickness = 2
			ktStroke.Transparency = 0.2
			ktStroke.Parent = keyText

			-- String Notation Sub-label (E / Senar 1)
			local strLabel = Instance.new("TextLabel")
			strLabel.Name = "StringLabel"
			strLabel.Size = UDim2.new(1, 0, 0.35, 0)
			strLabel.Position = UDim2.new(0, 0, 0.65, 0)
			strLabel.BackgroundTransparency = 1
			strLabel.Text = defaultStringNames[i] or tostring(i)
			strLabel.TextColor3 = defaultStringColors[i] or Color3.fromRGB(250, 204, 21)
			strLabel.Font = Enum.Font.GothamBold
			strLabel.TextSize = 10
			strLabel.ZIndex = 12
			strLabel.Parent = receptor
		end
	end

	-- Center Judgement Feedback Label
	local centerJudge = Instance.new("TextLabel")
	centerJudge.Name = "CenterJudgementLabel"
	centerJudge.Size = UDim2.new(0.9, 0, 0, 38)
	centerJudge.Position = UDim2.new(0.5, 0, 0.44, 0)
	centerJudge.AnchorPoint = Vector2.new(0.5, 0.5)
	centerJudge.BackgroundTransparency = 1
	centerJudge.Font = Enum.Font.GothamBlack
	centerJudge.TextSize = 24
	centerJudge.TextColor3 = Color3.fromRGB(255, 215, 0)
	centerJudge.Text = ""
	centerJudge.ZIndex = 40
	centerJudge.Parent = arena

	local judgeStroke = Instance.new("UIStroke")
	judgeStroke.Thickness = 2.5
	judgeStroke.Color = Color3.fromRGB(0, 0, 0)
	judgeStroke.Transparency = 0.1
	judgeStroke.Parent = centerJudge

	-- Progress Bar Container (Catch Progress)
	local pBar = Instance.new("Frame")
	pBar.Name = "ProgressBar"
	pBar.Size = UDim2.new(0.92, 0, 0, 18)
	pBar.Position = UDim2.new(0.04, 0, 0.815, 0)
	pBar.BackgroundColor3 = Color3.fromRGB(16, 24, 38)
	pBar.BorderSizePixel = 0
	pBar.Parent = container
	Instance.new("UICorner", pBar).CornerRadius = UDim.new(0, 9)

	local pBarStroke = Instance.new("UIStroke")
	pBarStroke.Color = Color3.fromRGB(0, 180, 255)
	pBarStroke.Thickness = 1.5
	pBarStroke.Transparency = 0.4
	pBarStroke.Parent = pBar

	local pFill = Instance.new("Frame")
	pFill.Name = "Fill"
	pFill.Size = UDim2.new(0.1, 0, 1, 0)
	pFill.Position = UDim2.new(0, 0, 0, 0)
	pFill.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	pFill.BorderSizePixel = 0
	pFill.Parent = pBar
	Instance.new("UICorner", pFill).CornerRadius = UDim.new(0, 9)

	local fishIcon = Instance.new("TextLabel")
	fishIcon.Name = "Fish"
	fishIcon.Size = UDim2.new(0, 24, 0, 24)
	fishIcon.Position = UDim2.new(0.1, -12, 0.5, -12)
	fishIcon.BackgroundTransparency = 1
	fishIcon.Text = "🐟"
	fishIcon.TextSize = 16
	fishIcon.ZIndex = 5
	fishIcon.Parent = pBar

	-- Progress & Live Info Label
	local pLabel = Instance.new("TextLabel")
	pLabel.Name = "ProgressLabel"
	pLabel.Size = UDim2.new(0.92, 0, 0, 22)
	pLabel.Position = UDim2.new(0.04, 0, 0.88, 0)
	pLabel.BackgroundTransparency = 1
	pLabel.Text = "🎣 Progres: 0%  •  0 / 30 Not  •  🎯 Akurasi: 100%"
	pLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
	pLabel.Font = Enum.Font.GothamBold
	pLabel.TextSize = 12
	pLabel.Parent = container

	local plStroke = Instance.new("UIStroke")
	plStroke.Color = Color3.fromRGB(0, 0, 0)
	plStroke.Thickness = 1.5
	plStroke.Transparency = 0.3
	plStroke.Parent = pLabel

	-- Result Overlay Screen
	local result = Instance.new("Frame")
	result.Name = "ResultOverlay"
	result.Size = UDim2.fromScale(1, 1)
	result.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	result.BackgroundTransparency = 0.12
	result.BorderSizePixel = 0
	result.Visible = false
	result.ZIndex = 30
	result.Parent = container
	Instance.new("UICorner", result).CornerRadius = UDim.new(0, 18)

	local resLabel = Instance.new("TextLabel")
	resLabel.Name = "ResultLabel"
	resLabel.Size = UDim2.new(1, 0, 0, 36)
	resLabel.Position = UDim2.new(0, 0, 0.12, 0)
	resLabel.BackgroundTransparency = 1
	resLabel.Text = "BERHASIL DITANGKAP!"
	resLabel.TextColor3 = Color3.fromRGB(60, 240, 140)
	resLabel.Font = Enum.Font.GothamBlack
	resLabel.TextSize = 22
	resLabel.ZIndex = 32
	resLabel.Parent = result

	return screenGui
end

--==================================================
-- CREATE / INITIALIZE UI
--==================================================

function PianoTilesUI.Create()
	local playerGui = getPlayerGui()
	if not playerGui then
		warn("[PianoTilesUI] PlayerGui tidak ditemukan.")
		return false
	end

	-- Cari GUI yang sudah ada atau buat secara dinamis
	gui = playerGui:FindFirstChild("PianoTilesGui")
	if not gui then
		gui = buildDynamicGui(playerGui)
	end

	if not gui then
		warn("[PianoTilesUI] Gagal menginisialisasi PianoTilesGui.")
		return false
	end

	arenaContainer = gui:FindFirstChild("ArenaContainer") or gui:WaitForChild("ArenaContainer", 3)
	if not arenaContainer then
		warn("[PianoTilesUI] ArenaContainer tidak ditemukan.")
		return false
	end

	arenaFrame = arenaContainer:FindFirstChild("ArenaFrame") or arenaContainer:WaitForChild("ArenaFrame", 3)
	if not arenaFrame then
		warn("[PianoTilesUI] ArenaFrame tidak ditemukan.")
		return false
	end

	--==================================================
	-- HITLINE, PERFECT ZONE & JUDGEMENT LABELS
	--==================================================
	hitLine = arenaFrame:FindFirstChild("HitLine")
	perfectZoneGuide = arenaFrame:FindFirstChild("PerfectZoneGuide")

	centerJudgementLabel = arenaFrame:FindFirstChild("CenterJudgementLabel")
	if not centerJudgementLabel then
		centerJudgementLabel = Instance.new("TextLabel")
		centerJudgementLabel.Name = "CenterJudgementLabel"
		centerJudgementLabel.Size = UDim2.new(0.9, 0, 0, 38)
		centerJudgementLabel.Position = UDim2.new(0.5, 0, 0.44, 0)
		centerJudgementLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		centerJudgementLabel.BackgroundTransparency = 1
		centerJudgementLabel.Font = Enum.Font.GothamBlack
		centerJudgementLabel.TextSize = 24
		centerJudgementLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		centerJudgementLabel.Text = ""
		centerJudgementLabel.ZIndex = 40
		centerJudgementLabel.Parent = arenaFrame

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Transparency = 0.1
		stroke.Parent = centerJudgementLabel
	end

	--==================================================
	-- FRET WIRES & INLAYS
	--==================================================
	table.clear(fretWires)
	table.clear(fretInlays)
	for i = 1, 4 do
		local fw = arenaFrame:FindFirstChild("FretWire" .. i)
		if fw then
			table.insert(fretWires, fw)
		end
	end
	for i = 1, 2 do
		local inDot = arenaFrame:FindFirstChild("FretInlay" .. i)
		if inDot then
			table.insert(fretInlays, inDot)
		end
	end

	--==================================================
	-- COLUMNS, STRINGS, FLASHES & RECEPTOR PADS
	--==================================================
	table.clear(columns)
	table.clear(columnFlashes)
	table.clear(receptorPads)
	table.clear(receptorLabels)
	table.clear(receptorStringLabels)
	table.clear(stringLines)

	local keyLabels = Config.KEY_LABELS or { "A", "W", "S", "D" }

	for i = 1, Config.COLUMN_COUNT do
		local column = arenaFrame:WaitForChild("Column" .. i, 5)
		if not column then
			warn("[PianoTilesUI] Column" .. i .. " tidak ditemukan.")
			return false
		end

		columns[i] = column

		-- String Line (FISH-027 Guitar String)
		local strLine = column:FindFirstChild("StringLine")
		if not strLine then
			strLine = Instance.new("Frame")
			strLine.Name = "StringLine"
			strLine.Size = UDim2.new(0, 2, 1, 0)
			strLine.Position = UDim2.new(0.5, -1, 0, 0)
			strLine.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
			strLine.BackgroundTransparency = 0.40
			strLine.BorderSizePixel = 0
			strLine.ZIndex = 6
			strLine.Parent = column
		end
		stringLines[i] = strLine

		-- Flash Frame
		local flash = column:FindFirstChild("ColumnFlash") or column:FindFirstChild("MissFlash")
		if not flash then
			flash = Instance.new("Frame")
			flash.Name = "ColumnFlash"
			flash.Size = UDim2.fromScale(1, 1)
			flash.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			flash.BackgroundTransparency = 1
			flash.BorderSizePixel = 0
			flash.Visible = false
			flash.ZIndex = 20
			flash.Parent = column
		end
		columnFlashes[i] = flash

		-- Receptor Pad
		local receptor = column:FindFirstChild("ReceptorPad")
		if not receptor then
			receptor = Instance.new("Frame")
			receptor.Name = "ReceptorPad"
			receptor.Size = UDim2.new(0.88, 0, Config.TILE_HEIGHT, 0)
			receptor.Position = UDim2.new(0.06, 0, Config.HIT_LINE, 0)
			receptor.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
			receptor.BackgroundTransparency = 0.85
			receptor.BorderSizePixel = 0
			receptor.ZIndex = 11
			receptor.Parent = column
			Instance.new("UICorner", receptor).CornerRadius = UDim.new(0, 8)

			local rAspect = Instance.new("UIAspectRatioConstraint")
			rAspect.AspectRatio = 1
			rAspect.Parent = receptor

			local rStroke = Instance.new("UIStroke")
			rStroke.Color = Color3.fromRGB(0, 220, 255)
			rStroke.Thickness = 2
			rStroke.Transparency = 0.3
			rStroke.Parent = receptor

			local keyText = Instance.new("TextLabel")
			keyText.Name = "KeyLabel"
			keyText.Size = UDim2.new(1, 0, 0.65, 0)
			keyText.Position = UDim2.new(0, 0, 0, 0)
			keyText.BackgroundTransparency = 1
			keyText.Text = "[" .. (keyLabels[i] or tostring(i)) .. "]"
			keyText.TextColor3 = Color3.fromRGB(240, 250, 255)
			keyText.Font = Enum.Font.GothamBlack
			keyText.TextSize = 15
			keyText.ZIndex = 12
			keyText.Parent = receptor

			local ktStroke = Instance.new("UIStroke")
			ktStroke.Color = Color3.fromRGB(0, 0, 0)
			ktStroke.Thickness = 2
			ktStroke.Transparency = 0.2
			ktStroke.Parent = keyText

			local strLabel = Instance.new("TextLabel")
			strLabel.Name = "StringLabel"
			strLabel.Size = UDim2.new(1, 0, 0.35, 0)
			strLabel.Position = UDim2.new(0, 0, 0.65, 0)
			strLabel.BackgroundTransparency = 1
			strLabel.Text = tostring(i)
			strLabel.TextColor3 = Color3.fromRGB(250, 204, 21)
			strLabel.Font = Enum.Font.GothamBold
			strLabel.TextSize = 10
			strLabel.ZIndex = 12
			strLabel.Parent = receptor
		end

		receptorPads[i] = receptor
		receptorLabels[i] = receptor:FindFirstChild("KeyLabel")
		receptorStringLabels[i] = receptor:FindFirstChild("StringLabel")
	end

	--==================================================
	-- HEADER
	--==================================================
	local header = arenaContainer:WaitForChild("Header", 5)
	if header then
		castBonusLabel = header:FindFirstChild("CastBonusLabel", true)
		songLabel = header:FindFirstChild("SongLabel", true)
		comboLabel = header:FindFirstChild("ComboLabel", true)
		instrumentPill = header:FindFirstChild("InstrumentPill")
		instrumentBadgeLabel = header:FindFirstChild("InstrumentBadgeLabel", true)
	end

	--==================================================
	-- PROGRESS
	--==================================================
	progressContainer = arenaContainer:WaitForChild("ProgressBar", 5)
	if progressContainer then
		progressFill = progressContainer:WaitForChild("Fill", 5)
		fish = progressContainer:FindFirstChild("Fish")
		progressGlow = progressContainer:FindFirstChild("UIStroke")
	end

	progressLabel = arenaContainer:WaitForChild("ProgressLabel", 5)

	--==================================================
	-- RESULT
	--==================================================
	resultOverlay = arenaContainer:WaitForChild("ResultOverlay", 5)
	if resultOverlay then
		resultLabel = resultOverlay:WaitForChild("ResultLabel", 5)
	end

	--==================================================
	-- INITIAL STATE
	--==================================================
	gui.Enabled = false

	if centerJudgementLabel then
		centerJudgementLabel.Text = ""
	end

	if comboLabel then
		comboLabel.Visible = false
	end

	if resultOverlay then
		resultOverlay.Visible = false
	end

	return true
end

--==================================================
-- GETTERS
--==================================================

function PianoTilesUI.GetGui()
	return gui
end

function PianoTilesUI.GetArenaFrame()
	return arenaFrame
end

function PianoTilesUI.GetArenaContainer()
	return arenaContainer
end

function PianoTilesUI.GetColumns()
	return columns
end

function PianoTilesUI.GetStringLines()
	return stringLines
end

function PianoTilesUI.GetReceptorPads()
	return receptorPads
end

function PianoTilesUI.GetHeaderElements()
	return {
		castBonusLabel = castBonusLabel,
		songLabel = songLabel,
		comboLabel = comboLabel,
		instrumentBadgeLabel = instrumentBadgeLabel,
	}
end

function PianoTilesUI.GetProgressElements()
	return {
		container = progressContainer,
		fill = progressFill,
		label = progressLabel,
		glow = progressGlow,
	}
end

function PianoTilesUI.GetResultElements()
	return {
		overlay = resultOverlay,
		label = resultLabel,
	}
end

--==================================================
-- INSTRUMENT THEME ENGINE (FISH-027)
--==================================================

function PianoTilesUI.ApplyInstrumentTheme(instrument)
	if not instrument then return end

	-- 1. Update Header Instrument Badge
	if instrumentBadgeLabel then
		instrumentBadgeLabel.Text = tostring(instrument.badge or instrument.name or "GITAR")
		instrumentBadgeLabel.TextColor3 = instrument.headerColor or Color3.fromRGB(250, 204, 21)
	end

	if instrumentPill then
		local pillStroke = instrumentPill:FindFirstChildOfClass("UIStroke")
		if pillStroke then
			pillStroke.Color = instrument.headerColor or Color3.fromRGB(245, 158, 11)
		end
	end

	-- 2. Update Arena Background & Fret Wires
	if arenaFrame then
		if instrument.fretboardColor then
			arenaFrame.BackgroundColor3 = instrument.fretboardColor
		end
		for _, fw in ipairs(fretWires) do
			if fw and instrument.fretWireColor then
				fw.BackgroundColor3 = instrument.fretWireColor
			end
		end
	end

	-- 3. Update Strings, Receptors & Notations
	local strColors = instrument.stringColors or {}
	local strGlows = instrument.stringGlows or {}
	local strNames = instrument.stringNames or { "1", "2", "3", "4" }
	local keyLabels = instrument.keyLabels or Config.KEY_LABELS or { "A", "W", "S", "D" }

	for i = 1, Config.COLUMN_COUNT do
		local str = stringLines[i]
		if str then
			local sColor = strColors[i] or Color3.fromRGB(245, 158, 11)
			str.BackgroundColor3 = sColor
			local sGlow = str:FindFirstChildOfClass("UIStroke")
			if sGlow then
				sGlow.Color = strGlows[i] or sColor
			end
		end

		local receptor = receptorPads[i]
		if receptor then
			local rStroke = receptor:FindFirstChildOfClass("UIStroke")
			if rStroke then
				rStroke.Color = strColors[i] or Color3.fromRGB(0, 220, 255)
			end
		end

		local kLabel = receptorLabels[i]
		if kLabel then
			kLabel.Text = "[" .. (keyLabels[i] or tostring(i)) .. "]"
		end

		local sLabel = receptorStringLabels[i]
		if sLabel then
			sLabel.Text = strNames[i] or tostring(i)
			sLabel.TextColor3 = strColors[i] or Color3.fromRGB(250, 204, 21)
		end
	end
end

--==================================================
-- VIBRATING STRING PLUCK EFFECT (FISH-027)
--==================================================

function PianoTilesUI.PlayStringVibration(columnIndex, instrument)
	local str = stringLines[columnIndex]
	if not str or not str.Parent then return end

	local origSize = UDim2.new(0, 2, 1, 0)
	local origPos = UDim2.new(0.5, -1, 0, 0)
	local pluckSize = UDim2.new(0, 6, 1, 0)
	local pluckPos = UDim2.new(0.5, -3, 0, 0)

	str.Size = pluckSize
	str.Position = pluckPos
	str.BackgroundTransparency = 0.05

	local strGlow = str:FindFirstChildOfClass("UIStroke")
	if strGlow then
		strGlow.Thickness = 2.5
		strGlow.Transparency = 0.1
	end

	local tween = TweenService:Create(
		str,
		TweenInfo.new(0.24, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			Size = origSize,
			Position = origPos,
			BackgroundTransparency = 0.40,
		}
	)
	tween:Play()

	if strGlow then
		TweenService:Create(
			strGlow,
			TweenInfo.new(0.24, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				Thickness = 1.0,
				Transparency = 0.5,
			}
		):Play()
	end
end

--==================================================
-- ENABLE
--==================================================

function PianoTilesUI.SetEnabled(enabled)
	if gui then
		gui.Enabled = enabled
	end
end

--==================================================
-- TILE CREATION & MOVEMENT
--==================================================

function PianoTilesUI.CreateTile(column, y)
	local parent = columns[column]
	if not parent then
		return nil
	end

	local tile = Instance.new("ImageLabel")
	tile.Name = "Tile"
	tile.Size = UDim2.new(0.88, 0, Config.TILE_HEIGHT, 0)
	tile.Position = UDim2.new(0.06, 0, y, 0)
	tile.BackgroundTransparency = 1
	tile.Image = Config.TILE_IMAGES[column]
	tile.ScaleType = Enum.ScaleType.Fit
	tile.BorderSizePixel = 0
	tile.ZIndex = 15
	tile.Parent = parent

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.Name = "SquareConstraint"
	aspect.AspectRatio = 1
	aspect.Parent = tile

	return tile
end

function PianoTilesUI.MoveTile(tile, y)
	if tile and tile.Parent then
		tile.Position = UDim2.new(0.06, 0, y, 0)
	end
end

function PianoTilesUI.DestroyTile(tile)
	if tile and tile.Parent then
		tile:Destroy()
	end
end

--==================================================
-- RECEPTOR KEY PRESS TACTILE FEEDBACK
--==================================================

function PianoTilesUI.TriggerReceptorPress(column, ratingKey)
	local pad = receptorPads[column]
	if not pad then return end

	local ratingData = (Config.HIT_RATINGS and Config.HIT_RATINGS[ratingKey or "GOOD"]) or {
		flashColor = Color3.fromRGB(0, 220, 255),
		glowColor = Color3.fromRGB(150, 240, 255),
	}

	local pStroke = pad:FindFirstChildOfClass("UIStroke")

	pad.BackgroundColor3 = ratingData.flashColor
	pad.BackgroundTransparency = 0.35
	if pStroke then
		pStroke.Color = ratingData.glowColor
		pStroke.Thickness = 3
	end

	TweenService:Create(
		pad,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			BackgroundColor3 = Color3.fromRGB(0, 160, 255),
			BackgroundTransparency = 0.85,
		}
	):Play()

	if pStroke then
		TweenService:Create(
			pStroke,
			TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Color = Color3.fromRGB(0, 220, 255),
				Thickness = 2,
			}
		):Play()
	end
end

--==================================================
-- TIMING JUDGEMENT FEEDBACK (PERFECT / GREAT / GOOD / MISS)
--==================================================

function PianoTilesUI.ShowHitRating(ratingKey, column, y)
	if not arenaFrame then return end

	ratingKey = ratingKey or "GOOD"
	local ratingData = (Config.HIT_RATINGS and Config.HIT_RATINGS[ratingKey]) or {
		text = ratingKey,
		symbol = ratingKey,
		color = Color3.fromRGB(80, 235, 120),
		glowColor = Color3.fromRGB(180, 255, 200),
		flashColor = Color3.fromRGB(70, 220, 110),
		score = 80,
		scale = 1.0,
	}

	-- 1. Update Center Judgement Banner
	if centerJudgementLabel then
		centerJudgementLabel.Text = ratingData.symbol
		centerJudgementLabel.TextColor3 = ratingData.color
		centerJudgementLabel.TextTransparency = 0

		local stroke = centerJudgementLabel:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = ratingData.glowColor
			stroke.Transparency = 0.1
		end

		centerJudgementLabel.TextSize = math.floor(20 * ratingData.scale)
		TweenService:Create(
			centerJudgementLabel,
			TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ TextSize = math.floor(27 * ratingData.scale) }
		):Play()

		task.delay(0.42, function()
			if centerJudgementLabel and centerJudgementLabel.Text == ratingData.symbol then
				TweenService:Create(
					centerJudgementLabel,
					TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 1 }
				):Play()
			end
		end)
	end

	-- 2. Floating Popup Badge above Column Hit Position
	local posX = column and ((column - 0.5) / Config.COLUMN_COUNT) or 0.5
	local posY = (y or Config.HIT_LINE) - 0.08

	local popup = Instance.new("TextLabel")
	popup.Name = "HitRatingPopup"
	popup.Size = UDim2.new(0, 130, 0, 34)
	popup.Position = UDim2.new(posX, 0, posY, 0)
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.GothamBlack
	popup.Text = ratingData.symbol
	popup.TextColor3 = ratingData.color
	popup.TextSize = math.floor(13 * ratingData.scale)
	popup.ZIndex = 50
	popup.Parent = arenaFrame

	local pStroke = Instance.new("UIStroke")
	pStroke.Thickness = 2
	pStroke.Color = ratingData.glowColor
	pStroke.Transparency = 0.15
	pStroke.Parent = popup

	-- Score badge indicator (+300, +180, +80)
	if ratingData.score and ratingData.score > 0 then
		local scoreLabel = Instance.new("TextLabel")
		scoreLabel.Name = "ScoreBadge"
		scoreLabel.Size = UDim2.new(1, 0, 0, 14)
		scoreLabel.Position = UDim2.new(0, 0, 1, -2)
		scoreLabel.BackgroundTransparency = 1
		scoreLabel.Font = Enum.Font.GothamBold
		scoreLabel.Text = string.format("+%d", ratingData.score)
		scoreLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
		scoreLabel.TextSize = 11
		scoreLabel.ZIndex = 51
		scoreLabel.Parent = popup

		local sbStroke = Instance.new("UIStroke")
		sbStroke.Color = Color3.fromRGB(0, 0, 0)
		sbStroke.Thickness = 1.5
		sbStroke.Transparency = 0.3
		sbStroke.Parent = scoreLabel
	end

	-- Scale Pop-in & Upward Float Animation
	local popTween = TweenService:Create(
		popup,
		TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			TextSize = math.floor(19 * ratingData.scale),
			Position = UDim2.new(posX, 0, posY - 0.03, 0),
		}
	)
	popTween:Play()

	popTween.Completed:Once(function()
		local floatTween = TweenService:Create(
			popup,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = UDim2.new(posX, 0, posY - 0.09, 0),
				TextTransparency = 1,
			}
		)
		if pStroke then
			TweenService:Create(
				pStroke,
				TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = 1 }
			):Play()
		end
		for _, child in ipairs(popup:GetChildren()) do
			if child:IsA("TextLabel") then
				TweenService:Create(
					child,
					TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 1 }
				):Play()
			end
		end

		floatTween:Play()
		floatTween.Completed:Once(function()
			if popup and popup.Parent then
				popup:Destroy()
			end
		end)
	end)

	-- 3. Hit Ripple / Expanding Shockwave Effect
	local ripple = Instance.new("Frame")
	ripple.Name = "HitRipple"
	ripple.Size = UDim2.new(0, 18, 0, 18)
	ripple.Position = UDim2.new(posX, 0, y or Config.HIT_LINE, 0)
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.BackgroundColor3 = ratingData.flashColor
	ripple.BackgroundTransparency = 0.40
	ripple.BorderSizePixel = 0
	ripple.ZIndex = 25
	ripple.Parent = arenaFrame
	Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = ratingData.glowColor
	rStroke.Thickness = 2.5
	rStroke.Transparency = 0.15
	rStroke.Parent = ripple

	TweenService:Create(
		ripple,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 72, 0, 72),
			BackgroundTransparency = 1,
		}
	):Play()
	TweenService:Create(
		rStroke,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 1, Thickness = 0.5 }
	):Play()

	task.delay(0.24, function()
		if ripple and ripple.Parent then
			ripple:Destroy()
		end
	end)

	-- 4. HitLine Glow Reaction
	if hitLine then
		hitLine.BackgroundColor3 = ratingData.flashColor
		TweenService:Create(
			hitLine,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundColor3 = Color3.fromRGB(0, 230, 255) }
		):Play()
	end
end

--==================================================
-- HIT EFFECT (TILE + RATING + FLASH + STRING VIBRATION)
--==================================================

function PianoTilesUI.PlayHitEffect(tile, y, ratingKey, column, instrument)
	ratingKey = ratingKey or "GOOD"
	column = column or (tile and tile.Parent and tonumber(string.match(tile.Parent.Name, "%d+")))

	-- Trigger Receptor Pad feedback, Rating Popup, Column Flash & String Pluck Vibration
	if column then
		PianoTilesUI.TriggerReceptorPress(column, ratingKey)
		PianoTilesUI.FlashColumn(column, ratingKey)
		PianoTilesUI.PlayStringVibration(column, instrument)
	end
	PianoTilesUI.ShowHitRating(ratingKey, column, y)

	if not tile or not tile.Parent then
		return
	end

	local tween = TweenService:Create(
		tile,
		TweenInfo.new(
			0.14,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			ImageTransparency = 1,
			Size = UDim2.new(
				0.98,
				0,
				Config.TILE_HEIGHT * 1.25,
				0
			),
			Position = UDim2.new(
				0.01,
				0,
				y - 0.02,
				0
			),
		}
	)

	tween:Play()
	tween.Completed:Once(function()
		if tile and tile.Parent then
			tile:Destroy()
		end
	end)
end

--==================================================
-- COLUMN FLASH WITH JUDGEMENT COLORS
--==================================================

function PianoTilesUI.FlashColumn(column, ratingKey)
	local flash = columnFlashes[column]
	if not flash then
		return
	end

	ratingKey = ratingKey or "MISS"
	local ratingData = (Config.HIT_RATINGS and Config.HIT_RATINGS[ratingKey]) or {
		flashColor = (ratingKey == "MISS" and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 215, 0))
	}

	flash.BackgroundColor3 = ratingData.flashColor
	flash.BackgroundTransparency = (ratingKey == "MISS" and 0.40 or 0.60)
	flash.Visible = true

	local tween = TweenService:Create(
		flash,
		TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)
	tween:Play()

	task.delay(0.20, function()
		if flash and flash.Parent then
			flash.Visible = false
		end
	end)
end

--==================================================
-- HUD UPDATE
--==================================================

function PianoTilesUI.UpdateHUD(
	progress,
	combo,
	currentNotes, 
	targetNotes,
	liveMetrics
)
	-- 1. COMBO BADGE WITH DYNAMIC COLORS & SCALE BOUNCE
	if comboLabel then
		if combo and combo >= 2 then
			local comboColor = Color3.fromRGB(80, 235, 120) -- Emerald Green
			local comboPrefix = "COMBO"

			if combo >= 10 then
				comboColor = Color3.fromRGB(255, 215, 0) -- Gold
				comboPrefix = "🔥 COMBO"
			elseif combo >= 5 then
				comboColor = Color3.fromRGB(0, 230, 255) -- Cyan
				comboPrefix = "✨ COMBO"
			end

			comboLabel.Text = string.format("%s x%d", comboPrefix, combo)
			comboLabel.TextColor3 = comboColor
			comboLabel.Visible = true

			-- Pop animation
			comboLabel.TextSize = 14
			TweenService:Create(
				comboLabel,
				TweenInfo.new(0.09, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ TextSize = 17 }
			):Play()
		else
			comboLabel.Visible = false
		end
	end

	-- 2. PROGRESS BAR & FISH
	if progressFill then
		local percent = math.clamp(progress or 0, 0, 1)
		
		progressFill.AnchorPoint = Vector2.new(0, 0)
		progressFill.Position = UDim2.fromScale(0, 0)

		TweenService:Create(
			progressFill,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(percent, 1) }
		):Play()

		local barColor = Color3.fromRGB(0, 220, 255)
		if percent >= 0.75 then
			barColor = Color3.fromRGB(60, 240, 140) -- Emerald
		elseif percent <= 0.25 then
			barColor = Color3.fromRGB(255, 180, 50) -- Amber warning
		end

		progressFill.BackgroundColor3 = barColor

		if progressGlow then
			progressGlow.Color = barColor
		end
		
		if fish and progressContainer then
			TweenService:Create(
				fish,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(percent, -12, 0.5, -12) }
			):Play()
		end
	end

	-- 3. PROGRESS & LIVE ACCURACY LABEL
	if progressLabel then
		local percent = math.clamp(progress or 0, 0, 1)
		local percentInt = math.floor(percent * 100)

		if liveMetrics and liveMetrics.accuracy then
			progressLabel.Text = string.format(
				"🎣 Progres: %d%%  •  %d/%d Not  •  🎯 Akurasi: %.1f%%",
				percentInt,
				currentNotes or 0,
				targetNotes or 0,
				liveMetrics.accuracy
			)
		else
			progressLabel.Text = string.format(
				"🎣 Progres: %d%%  •  %d / %d Not",
				percentInt,
				currentNotes or 0,
				targetNotes or 0
			)
		end
	end
end

--==================================================
-- HEADER
--==================================================

function PianoTilesUI.UpdateHeader(
	castLabel,
	castColor,
	melodyName,
	instrument
)
	if castBonusLabel then
		castBonusLabel.Text = "✨ " .. tostring(castLabel or "PERFECT CAST")
		castBonusLabel.TextColor3 = castColor or Color3.fromRGB(60, 255, 150)
	end

	if songLabel then
		songLabel.Text = "🎵 " .. tostring(melodyName or "Melodi")
	end

	if instrument then
		PianoTilesUI.ApplyInstrumentTheme(instrument)
	end
end

--==================================================
-- SHAKE
--==================================================

function PianoTilesUI.ShakeArena()
	if not arenaContainer then
		return
	end

	local originalPosition = arenaContainer.Position

	local shakeTween = TweenService:Create(
		arenaContainer,
		TweenInfo.new(
			0.06,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			3,
			true
		),
		{
			Position = originalPosition + UDim2.new(
				0,
				math.random(-6, 6),
				0,
				math.random(-3, 3)
			)
		}
	)

	shakeTween:Play()

	task.delay(0.2, function()
		if arenaContainer then
			arenaContainer.Position = originalPosition
		end
	end)
end

--==================================================
-- RESULT OVERLAY
--==================================================

local function ensureResultDetails()
	if not resultOverlay then return end

	if not gradeBadgeLabel or gradeBadgeLabel.Parent ~= resultOverlay then
		gradeBadgeLabel = resultOverlay:FindFirstChild("GradeBadgeLabel")
		if not gradeBadgeLabel then
			gradeBadgeLabel = Instance.new("TextLabel")
			gradeBadgeLabel.Name = "GradeBadgeLabel"
			gradeBadgeLabel.Size = UDim2.new(1, 0, 0, 56)
			gradeBadgeLabel.Position = UDim2.new(0, 0, 0.28, 0)
			gradeBadgeLabel.BackgroundTransparency = 1
			gradeBadgeLabel.Font = Enum.Font.GothamBlack
			gradeBadgeLabel.TextSize = 48
			gradeBadgeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
			gradeBadgeLabel.Text = "S+"
			gradeBadgeLabel.ZIndex = 35
			gradeBadgeLabel.Parent = resultOverlay

			local gbStroke = Instance.new("UIStroke")
			gbStroke.Color = Color3.fromRGB(0, 0, 0)
			gbStroke.Thickness = 2.5
			gbStroke.Transparency = 0.2
			gbStroke.Parent = gradeBadgeLabel
		end
	end

	if not gradeTitleLabel or gradeTitleLabel.Parent ~= resultOverlay then
		gradeTitleLabel = resultOverlay:FindFirstChild("GradeTitleLabel")
		if not gradeTitleLabel then
			gradeTitleLabel = Instance.new("TextLabel")
			gradeTitleLabel.Name = "GradeTitleLabel"
			gradeTitleLabel.Size = UDim2.new(1, 0, 0, 24)
			gradeTitleLabel.Position = UDim2.new(0, 0, 0.48, 0)
			gradeTitleLabel.BackgroundTransparency = 1
			gradeTitleLabel.Font = Enum.Font.GothamBold
			gradeTitleLabel.TextSize = 16
			gradeTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			gradeTitleLabel.Text = "ALL PERFECT"
			gradeTitleLabel.ZIndex = 35
			gradeTitleLabel.Parent = resultOverlay

			local gtStroke = Instance.new("UIStroke")
			gtStroke.Color = Color3.fromRGB(0, 0, 0)
			gtStroke.Thickness = 2
			gtStroke.Transparency = 0.3
			gtStroke.Parent = gradeTitleLabel
		end
	end

	if not statsDetailLabel or statsDetailLabel.Parent ~= resultOverlay then
		statsDetailLabel = resultOverlay:FindFirstChild("StatsDetailLabel")
		if not statsDetailLabel then
			local statsCard = Instance.new("Frame")
			statsCard.Name = "StatsCard"
			statsCard.Size = UDim2.new(0.92, 0, 0, 52)
			statsCard.Position = UDim2.new(0.04, 0, 0.58, 0)
			statsCard.BackgroundColor3 = Color3.fromRGB(18, 26, 42)
			statsCard.BackgroundTransparency = 0.3
			statsCard.BorderSizePixel = 0
			statsCard.ZIndex = 34
			statsCard.Parent = resultOverlay
			Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 10)

			statsDetailLabel = Instance.new("TextLabel")
			statsDetailLabel.Name = "StatsDetailLabel"
			statsDetailLabel.Size = UDim2.fromScale(1, 1)
			statsDetailLabel.BackgroundTransparency = 1
			statsDetailLabel.Font = Enum.Font.GothamMedium
			statsDetailLabel.TextSize = 13
			statsDetailLabel.TextColor3 = Color3.fromRGB(220, 240, 255)
			statsDetailLabel.Text = ""
			statsDetailLabel.ZIndex = 35
			statsDetailLabel.Parent = statsCard
		end
	end

	if not multiplierDetailLabel or multiplierDetailLabel.Parent ~= resultOverlay then
		multiplierDetailLabel = resultOverlay:FindFirstChild("MultiplierDetailLabel")
		if not multiplierDetailLabel then
			local multCard = Instance.new("Frame")
			multCard.Name = "MultiplierCard"
			multCard.Size = UDim2.new(0.92, 0, 0, 36)
			multCard.Position = UDim2.new(0.04, 0, 0.76, 0)
			multCard.BackgroundColor3 = Color3.fromRGB(30, 38, 24)
			multCard.BackgroundTransparency = 0.3
			multCard.BorderSizePixel = 0
			multCard.ZIndex = 34
			multCard.Parent = resultOverlay
			Instance.new("UICorner", multCard).CornerRadius = UDim.new(0, 10)

			local mcStroke = Instance.new("UIStroke")
			mcStroke.Color = Color3.fromRGB(255, 215, 0)
			mcStroke.Thickness = 1.5
			mcStroke.Transparency = 0.4
			mcStroke.Parent = multCard

			multiplierDetailLabel = Instance.new("TextLabel")
			multiplierDetailLabel.Name = "MultiplierDetailLabel"
			multiplierDetailLabel.Size = UDim2.fromScale(1, 1)
			multiplierDetailLabel.BackgroundTransparency = 1
			multiplierDetailLabel.Font = Enum.Font.GothamBold
			multiplierDetailLabel.TextSize = 13
			multiplierDetailLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
			multiplierDetailLabel.Text = ""
			multiplierDetailLabel.ZIndex = 35
			multiplierDetailLabel.Parent = multCard
		end
	end
end

function PianoTilesUI.ShowResult(
	win,
	message,
	performance
)
	if not resultOverlay or not resultLabel then
		return
	end

	resultLabel.Text = message or (win and "BERHASIL DITANGKAP!" or "IKAN TERLEPAS!")
	resultLabel.TextColor3 = win and Color3.fromRGB(60, 240, 140) or Color3.fromRGB(255, 70, 70)

	ensureResultDetails()

	if performance and gradeBadgeLabel and gradeTitleLabel then
		local gradeColor = performance.gradeColor or PerformanceCalculator.GetGradeColor(performance.grade)
		gradeBadgeLabel.Text = tostring(performance.grade or (win and "A" or "D"))
		gradeBadgeLabel.TextColor3 = gradeColor
		gradeBadgeLabel.Visible = true

		local title = performance.gradeTitle or (performance.isAllPerfect and "ALL PERFECT" or (performance.isFullCombo and "FULL COMBO" or (win and "CLEARED" or "FAILED")))
		gradeTitleLabel.Text = title
		gradeTitleLabel.TextColor3 = performance.glowColor or Color3.fromRGB(255, 255, 255)
		gradeTitleLabel.Visible = true

		if statsDetailLabel then
			local acc = performance.accuracy or 0
			local maxCombo = (performance.breakdown and performance.breakdown.maxCombo) or performance.maxCombo or 0
			local pCount = (performance.breakdown and performance.breakdown.perfect) or performance.perfectHits or 0
			local gCount = (performance.breakdown and performance.breakdown.great) or performance.greatHits or 0
			local okCount = (performance.breakdown and performance.breakdown.good) or performance.goodHits or 0
			local mCount = (performance.breakdown and performance.breakdown.miss) or performance.mistakes or 0

			statsDetailLabel.Text = string.format("🎯 Akurasi: %.1f%%  •  🔥 Max Combo: %d\n[ P: %d  |  G: %d  |  OK: %d  |  M: %d ]", acc, maxCombo, pCount, gCount, okCount, mCount)
			statsDetailLabel.Visible = true
		end

		local multCard = resultOverlay:FindFirstChild("MultiplierCard")
		if multiplierDetailLabel then
			if win then
				local xpMult = performance.xpMultiplier or 1.0
				local coinMult = performance.coinMultiplier or 1.0
				local luckBonus = performance.performanceLuckBonus or 0
				multiplierDetailLabel.Text = string.format("⭐ EXP x%.2f  •  💰 Koin x%.2f  •  🍀 +%.1f Luck", xpMult, coinMult, luckBonus)
				multiplierDetailLabel.Visible = true
				if multCard then multCard.Visible = true end
			else
				multiplierDetailLabel.Visible = false
				if multCard then multCard.Visible = false end
			end
		end

		-- Animasi TextSize Bounce pada gradeBadge
		gradeBadgeLabel.TextSize = 24
		TweenService:Create(
			gradeBadgeLabel,
			TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ TextSize = 48 }
		):Play()
	else
		if gradeBadgeLabel then gradeBadgeLabel.Visible = false end
		if gradeTitleLabel then gradeTitleLabel.Visible = false end
		if statsDetailLabel then statsDetailLabel.Visible = false end
		if multiplierDetailLabel then multiplierDetailLabel.Visible = false end
	end

	resultOverlay.Visible = true
end

function PianoTilesUI.HideResult()
	if resultOverlay then
		resultOverlay.Visible = false
	end

	if gradeBadgeLabel then gradeBadgeLabel.Visible = false end
	if gradeTitleLabel then gradeTitleLabel.Visible = false end
	if statsDetailLabel then statsDetailLabel.Visible = false end
	if multiplierDetailLabel then multiplierDetailLabel.Visible = false end
end

--==================================================
-- DESTROY
--==================================================

function PianoTilesUI.Destroy()
	if gui then
		gui.Enabled = false
	end

	gui = nil
	arenaContainer = nil
	arenaFrame = nil

	castBonusLabel = nil
	songLabel = nil
	instrumentBadgeLabel = nil
	instrumentPill = nil
	comboLabel = nil
	centerJudgementLabel = nil
	hitLine = nil
	perfectZoneGuide = nil

	resultOverlay = nil
	resultLabel = nil
	gradeBadgeLabel = nil
	gradeTitleLabel = nil
	statsDetailLabel = nil
	multiplierDetailLabel = nil

	progressContainer = nil
	progressFill = nil
	progressLabel = nil
	progressGlow = nil
	fish = nil

	table.clear(columns)
	table.clear(columnFlashes)
	table.clear(receptorPads)
	table.clear(receptorLabels)
	table.clear(receptorStringLabels)
	table.clear(stringLines)
	table.clear(fretWires)
	table.clear(fretInlays)
end

return PianoTilesUI