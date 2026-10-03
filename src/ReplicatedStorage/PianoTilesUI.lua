--[[
    PianoTilesUI

    UI Piano Tiles menggunakan GUI yang sudah dibuat
    secara manual di StarterGui.

    Struktur yang diharapkan:

    StarterGui
    └── PianoTilesGui
        └── ArenaContainer
            ├── Header
            │   ├── CastBonusLabel
            │   ├── SongLabel
            │   └── ComboLabel
            │
            ├── ArenaFrame
            │   ├── Background
            │   ├── Column1
            │   ├── Column2
            │   ├── Column3
            │   └── Column4
            │
            ├── KeybindBG
            ├── A
            ├── W
            ├── S
            ├── D
            ├── HitLine
            │
            ├── ProgressBar
            │   ├── Background
            │   └── Fill
            │
            └── ResultOverlay
                └── ResultLabel
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(
	ReplicatedStorage:WaitForChild("PianoTilesConfig")
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
local comboLabel

local resultOverlay
local resultLabel

local progressContainer
local progressFill
local progressLabel
local progressGlow
local fish

local columns = {}
local columnFlashes = {}

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
-- CREATE / LOAD UI
--==================================================

function PianoTilesUI.Create()

	local playerGui = getPlayerGui()

	if not playerGui then
		warn("[PianoTilesUI] PlayerGui tidak ditemukan.")
		return false
	end

	-- Ambil GUI dari StarterGui yang sudah di-clone
	gui = playerGui:WaitForChild("PianoTilesGui", 5)

	if not gui then
		warn("[PianoTilesUI] PianoTilesGui tidak ditemukan.")
		return false
	end

	arenaContainer = gui:WaitForChild(
		"ArenaContainer",
		5
	)

	if not arenaContainer then
		warn("[PianoTilesUI] ArenaContainer tidak ditemukan.")
		return false
	end

	arenaFrame = arenaContainer:WaitForChild(
		"ArenaFrame",
		5
	)

	if not arenaFrame then
		warn("[PianoTilesUI] ArenaFrame tidak ditemukan.")
		return false
	end

	--==================================================
	-- COLUMNS
	--==================================================

	table.clear(columns)
	table.clear(columnFlashes)

	for i = 1, Config.COLUMN_COUNT do

		local column = arenaFrame:WaitForChild(
			"Column" .. i,
			5
		)

		if not column then
			warn(
				"[PianoTilesUI] Column"
					.. i
					.. " tidak ditemukan."
			)

			return false
		end

		columns[i] = column

		-- Flash merah dibuat oleh script karena sifatnya effect
		local flash = column:FindFirstChild("MissFlash")

		if not flash then

			flash = Instance.new("Frame")

			flash.Name = "MissFlash"
			flash.Size = UDim2.fromScale(1, 1)

			flash.BackgroundColor3 =
				Color3.fromRGB(255, 40, 40)

			flash.BackgroundTransparency = 0.6
			flash.BorderSizePixel = 0

			flash.Visible = false
			flash.ZIndex = 20

			flash.Parent = column
		end

		columnFlashes[i] = flash
	end

	--==================================================
	-- HEADER
	--==================================================

	local header = arenaContainer:WaitForChild(
		"Header",
		5
	)

	if header then

		castBonusLabel = header:WaitForChild(
			"CastBonusLabel",
			5
		)

		songLabel = header:WaitForChild(
			"SongLabel",
			5
		)

		comboLabel = header:WaitForChild(
			"ComboLabel",
			5
		)

	else

		warn("[PianoTilesUI] Header tidak ditemukan.")

	end

	--==================================================
	-- PROGRESS
	--==================================================

	progressContainer = arenaContainer:WaitForChild(
		"ProgressBar",
		5
	)

	if progressContainer then

		progressFill =
			progressContainer:WaitForChild(
				"Fill",
				5
			)

	end

	-- ProgressLabel sekarang langsung anak ArenaContainer
	progressLabel =
		arenaContainer:WaitForChild(
			"ProgressLabel",
			5
		)
	
	progressGlow =
		progressContainer:FindFirstChild(
			"UIStroke"
		)

	fish = progressContainer:WaitForChild("Fish", 5)
	

	--==================================================
	-- RESULT
	--==================================================

	resultOverlay = arenaContainer:WaitForChild(
		"ResultOverlay",
		5
	)

	if resultOverlay then

		resultLabel =
			resultOverlay:WaitForChild(
				"ResultLabel",
				5
			)

	end

	--==================================================
	-- INITIAL STATE
	--==================================================

	gui.Enabled = false

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

function PianoTilesUI.GetHeaderElements()
	return {
		castBonusLabel = castBonusLabel,
		songLabel = songLabel,
		comboLabel = comboLabel,
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
-- ENABLE
--==================================================

function PianoTilesUI.SetEnabled(enabled)

	if gui then
		gui.Enabled = enabled
	end

end

--==================================================
-- TILE
--==================================================

function PianoTilesUI.CreateTile(column, y)

	local parent = columns[column]

	if not parent then
		return nil
	end

	local tile = Instance.new("ImageLabel")

	tile.Name = "Tile"

	tile.Size = UDim2.new(
		0.88,
		0,
		Config.TILE_HEIGHT,
		0
	)

	tile.Position = UDim2.new(
		0.06,
		0,
		y,
		0
	)

	tile.BackgroundTransparency = 1

	tile.Image =
		Config.TILE_IMAGES[column]

	tile.ScaleType =
		Enum.ScaleType.Fit

	tile.BorderSizePixel = 0
	tile.ZIndex = 5

	tile.Parent = parent

	-- Menjaga tile berbentuk square
	local aspect =
		Instance.new("UIAspectRatioConstraint")

	aspect.Name = "SquareConstraint"
	aspect.AspectRatio = 1

	aspect.Parent = tile

	return tile
end

--==================================================
-- MOVE TILE
--==================================================

function PianoTilesUI.MoveTile(tile, y)

	if tile and tile.Parent then

		tile.Position =
			UDim2.new(
				0.06,
				0,
				y,
				0
			)

	end

end

--==================================================
-- DESTROY TILE
--==================================================

function PianoTilesUI.DestroyTile(tile)

	if tile and tile.Parent then
		tile:Destroy()
	end

end

--==================================================
-- HIT EFFECT
--==================================================

function PianoTilesUI.PlayHitEffect(tile, y)

	if not tile or not tile.Parent then
		return
	end

	local tween =
		TweenService:Create(
			tile,

			TweenInfo.new(
				0.14,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				ImageTransparency = 1,

				Size = UDim2.new(
					0.96,
					0,
					Config.TILE_HEIGHT * 1.15,
					0
				),

				Position = UDim2.new(
					0.02,
					0,
					y - 0.01,
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
-- HUD
--==================================================

function PianoTilesUI.UpdateHUD(
	progress,
	combo,
	currentNotes, 
	targetNotes
)

	-- COMBO

	if comboLabel then

		if combo >= 2 then

			comboLabel.Text =
				"COMBO x"
				.. combo
				.. (
					combo >= 3
					and "\n "
					or ""
				)

			comboLabel.Visible = true

		else

			comboLabel.Visible = false

		end

	end

	-- PROGRESS

	if progressFill then

		local percent =
			math.clamp(progress, 0, 1)
		
		progressFill.AnchorPoint = Vector2.new(0, 0)
		progressFill.Position = UDim2.fromScale(0.475, 0)

		TweenService:Create(
			progressFill,

			TweenInfo.new(
				0.4,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),

			{
				Size =
					UDim2.fromScale(
						0.05,
						1 - percent
					)
			}

		):Play()

		local barColor =
			Color3.fromRGB(
				255,
				255,
				255
			)

		if percent >= 0.70 then

			barColor =
				Color3.fromRGB(
					255,
					255,
					255
				)

		elseif percent <= 0.25 then

			barColor =
				Color3.fromRGB(
					255,
					255,
					255
				)

		end

		progressFill.BackgroundColor3 =
			barColor

		if progressGlow then
			progressGlow.Color = barColor
		end
		
		if fish then

			TweenService:Create(
				fish,

				TweenInfo.new(
					0.4,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				),

				{
					Position = UDim2.fromScale(
						fish.Position.X.Scale,
						1 - percent
					)
				}

			):Play()

		end

	end
	
	

	if progressLabel then

		local percent =
			math.clamp(progress, 0, 1)

		local percentInt =
			math.floor(percent * 100)

		progressLabel.Text =
			string.format(
				"%d%% Completed , %d / %d Notes",
				percentInt,
				currentNotes or 0,
				targetNotes or 0
			)

	end

end

--==================================================
-- HEADER
--==================================================

function PianoTilesUI.UpdateHeader(
	castLabel,
	castColor,
	melodyName
)

	if castBonusLabel then

		castBonusLabel.Text =
			castLabel or ""

		castBonusLabel.TextColor3 =
			castColor
			or Color3.fromRGB(
				255,
				255,
				255
			)

	end

	if songLabel then

		songLabel.Text =
			"Melodi: \n"
			.. tostring(
				melodyName or ""
			)

	end

end

--==================================================
-- MISS FLASH
--==================================================

function PianoTilesUI.FlashColumn(column)

	local flash =
		columnFlashes[column]

	if not flash then
		return
	end

	flash.Visible = true

	task.delay(
		0.18,
		function()

			if flash
				and flash.Parent then

				flash.Visible = false

			end

		end
	)

end

--==================================================
-- SHAKE
--==================================================

function PianoTilesUI.ShakeArena()

	if not arenaContainer then
		return
	end

	local originalPosition =
		arenaContainer.Position

	local shakeTween =
		TweenService:Create(

			arenaContainer,

			TweenInfo.new(
				0.06,
				Enum.EasingStyle.Sine,
				Enum.EasingDirection.InOut,
				3,
				true
			),

			{
				Position =
				originalPosition
				+ UDim2.new(
					0,
					math.random(-6, 6),
					0,
					math.random(-3, 3)
				)
			}
		)

	shakeTween:Play()

	task.delay(
		0.2,
		function()

			if arenaContainer then
				arenaContainer.Position =
					originalPosition
			end

		end
	)

end

--==================================================
-- RESULT
--==================================================

function PianoTilesUI.ShowResult(
	win,
	message
)

	if not resultOverlay
		or not resultLabel then

		return

	end

	resultLabel.Text =
		message
		or (
			win
			and "BERHASIL DITANGKAP!"
			or "IKAN TERLEPAS!"
		)

	resultLabel.TextColor3 =
		win
		and Color3.fromRGB(
			60,
			240,
			140
		)
		or Color3.fromRGB(
			255,
			70,
			70
		)

	resultOverlay.Visible = true

end

function PianoTilesUI.HideResult()

	if resultOverlay then
		resultOverlay.Visible = false
	end

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
	comboLabel = nil

	resultOverlay = nil
	resultLabel = nil

	progressContainer = nil
	progressFill = nil
	progressLabel = nil
	progressGlow = nil

	table.clear(columns)
	table.clear(columnFlashes)

end

return PianoTilesUI