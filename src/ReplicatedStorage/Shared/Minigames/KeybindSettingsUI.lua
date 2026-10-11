--[[
	KeybindSettingsUI (ModuleScript)
	FISH!TUNE — Oceanic Rhythm Keybind Customization Modal (FISH-045)

	Modal Kustomisasi Tombol Kontrol Minigame:
	1. Glassmorphism Theme: Navy Gelap transparan, aksen Cyan & Gold neon.
	2. Quick Presets: [WASD], [DFJK 4K], [ASKL], [QWER], [Panah].
	3. 4-Lane Interactive Rebind:
	   - Klik tombol kolom -> status "TEKAN..." (Amber Gold Glow).
	   - Tekan tombol keyboard apapun -> tombol diperbarui seketika.
	   - Swap otomatis jika tombol bentrok dengan kolom lain.
	4. Aksi Simpan & Reset:
	   - [💾 SIMPAN]: Terapkan ke KeybindSystem & kirim remote ke server.
	   - [🔄 RESET DEFAULT]: Kembalikan ke WASD.
	5. Responsif Desktop & Mobile (Auto-scale, Touch-friendly chips).
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KeybindSystem = require(Shared:WaitForChild("Systems"):WaitForChild("KeybindSystem"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local MobileResponsiveHelper = require(Shared:WaitForChild("Systems"):WaitForChild("MobileResponsiveHelper"))

local KeybindSettingsUI = {}

local activeOverlay = nil
local activeModal = nil
local isClosing = false
local listeningColumn = nil -- 1..4 jika sedang menunggu input keyboard
local inputConnection = nil

-- Temp working keys sebelum user menekan "Simpan"
local draftKeys = {
	Enum.KeyCode.A,
	Enum.KeyCode.W,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
}

local columnButtons = {}
local columnLabels = {}
local presetButtons = {}

-- ============ SOUND HELPER ============
local function playLocalSound(soundId, volume, speed)
	task.spawn(function()
		local snd = Instance.new("Sound")
		snd.SoundId = soundId
		snd.Volume = volume or 0.8
		snd.PlaybackSpeed = speed or 1.0
		snd.Parent = SoundService
		snd:Play()
		snd.Ended:Connect(function()
			snd:Destroy()
		end)
		task.delay(3, function()
			if snd and snd.Parent then snd:Destroy() end
		end)
	end)
end

-- ============ REFRESH SLOTS DISPLAY ============
local function refreshSlotsDisplay()
	for i = 1, 4 do
		local btn = columnButtons[i]
		local lbl = columnLabels[i]
		if btn and lbl then
			local kc = draftKeys[i]
			if listeningColumn == i then
				lbl.Text = "TEKAN..."
				lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
				btn.BackgroundColor3 = Color3.fromRGB(60, 45, 10)
				local stroke = btn:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = Color3.fromRGB(255, 215, 0)
					stroke.Thickness = 2.5
				end
			else
				lbl.Text = KeybindSystem.KeyCodeToLabel(kc)
				lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
				btn.BackgroundColor3 = Color3.fromRGB(24, 34, 52)
				local stroke = btn:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = Color3.fromRGB(0, 210, 255)
					stroke.Thickness = 1.6
				end
			end
		end
	end

	-- Highlight active preset if matches exactly
	local activeLabels = {
		KeybindSystem.KeyCodeToLabel(draftKeys[1]),
		KeybindSystem.KeyCodeToLabel(draftKeys[2]),
		KeybindSystem.KeyCodeToLabel(draftKeys[3]),
		KeybindSystem.KeyCodeToLabel(draftKeys[4]),
	}

	for presetId, chip in pairs(presetButtons) do
		local preset = KeybindSystem.PRESETS[presetId]
		local matches = false
		if preset then
			matches = (preset.labels[1] == activeLabels[1] and
			           preset.labels[2] == activeLabels[2] and
			           preset.labels[3] == activeLabels[3] and
			           preset.labels[4] == activeLabels[4])
		end

		local stroke = chip:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = matches and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(56, 189, 248)
			stroke.Thickness = matches and 2.0 or 1.2
		end
		chip.BackgroundColor3 = matches and Color3.fromRGB(20, 50, 35) or Color3.fromRGB(20, 30, 48)
	end
end

-- ============ STOP LISTENING ============
local function stopListening()
	listeningColumn = nil
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	refreshSlotsDisplay()
end

-- ============ START LISTENING FOR COLUMN ============
local function startListening(colIndex)
	if listeningColumn == colIndex then
		stopListening()
		return
	end

	stopListening()
	listeningColumn = colIndex
	playLocalSound("rbxasset://sounds/action_swim.mp3", 0.7, 1.2)
	refreshSlotsDisplay()

	inputConnection = UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local kc = input.KeyCode
			if kc == Enum.KeyCode.Escape then
				stopListening()
				return
			end

			local ok, err = KeybindSystem.IsValidKey(kc)
			if not ok then
				playLocalSound("rbxasset://sounds/splat.wav", 0.6, 1.0)
				return
			end

			-- Auto-swap jika tombol ini sudah dipakai kolom lain di draft
			for otherCol = 1, 4 do
				if otherCol ~= colIndex and draftKeys[otherCol] == kc then
					draftKeys[otherCol] = draftKeys[colIndex]
					break
				end
			end

			draftKeys[colIndex] = kc

			-- Auto-apply ke KeybindSystem & simpan ke server seketika
			KeybindSystem.SetActiveKeys(draftKeys)
			pcall(function()
				local remote = RemoteContract.GetRemote()
				if remote then
					remote:FireServer(RemoteContract.C2S.SET_KEYBINDS, {
						keybinds = KeybindSystem.ExportSettings(),
					})
				end
			end)

			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.8, 1.3)
			stopListening()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			-- Jangan cancel jika klik pada tombol itu sendiri (ditangani event button)
		end
	end)
end

-- ============ SHOW MODAL ============
function KeybindSettingsUI.Show(targetGui)
	if activeModal or isClosing then return end

	-- Tutup modal lain yang mungkin sedang terbuka agar tidak bertumpuk
	pcall(function()
		local fishDex = Shared:FindFirstChild("Minigames") and Shared.Minigames:FindFirstChild("FishDexUI")
		if fishDex then
			local fMod = require(fishDex)
			if fMod and fMod.IsOpen and fMod.IsOpen() then fMod.Hide() end
		end
		local shop = Shared:FindFirstChild("Minigames") and Shared.Minigames:FindFirstChild("ShopUI")
		if shop then
			local sMod = require(shop)
			if sMod and sMod.IsOpen and sMod.IsOpen() then sMod.Hide() end
		end
	end)

	-- Ambil keybinds aktif saat ini ke draft
	local current = KeybindSystem.GetActiveKeys()
	draftKeys = { current[1], current[2], current[3], current[4] }

	-- 1. Fullscreen Dark Dim Overlay
	activeOverlay = Instance.new("TextButton")
	activeOverlay.Name = "KeybindOverlay"
	activeOverlay.Size = UDim2.fromScale(1, 1)
	activeOverlay.BackgroundColor3 = Color3.fromRGB(5, 8, 14)
	activeOverlay.BackgroundTransparency = 1
	activeOverlay.Text = ""
	activeOverlay.AutoButtonColor = false
	activeOverlay.ZIndex = 80
	activeOverlay.Parent = targetGui

	-- 2. Glassmorphic Modal Frame
	activeModal = Instance.new("Frame")
	activeModal.Name = "KeybindSettingsModal"
	activeModal.AnchorPoint = Vector2.new(0.5, 0.5)
	activeModal.Size = UDim2.new(0, 560, 0, 480)
	activeModal.Position = UDim2.new(0.5, 0, 0.5, 20)
	activeModal.BackgroundColor3 = Color3.fromRGB(15, 22, 36)
	activeModal.BackgroundTransparency = 0.08
	activeModal.BorderSizePixel = 0
	activeModal.ZIndex = 82
	activeModal.ClipsDescendants = true
	activeModal.Parent = activeOverlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = activeModal

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 210, 255)
	stroke.Thickness = 2.0
	stroke.Transparency = 0.35
	stroke.Parent = activeModal

	-- Attach responsive scaling
	MobileResponsiveHelper.AttachResponsiveScale(activeModal, 560, 480, 1.0, 16)

	-- ============ HEADER ============
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 72)
	header.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
	header.BorderSizePixel = 0
	header.ZIndex = 83
	header.Parent = activeModal

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft = UDim.new(0, 20)
	headerPad.PaddingRight = UDim.new(0, 20)
	headerPad.Parent = header

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -50, 0, 28)
	titleLabel.Position = UDim2.new(0, 0, 0, 14)
	titleLabel.BackgroundTransparency = 1
	titleLabel.RichText = true
	titleLabel.Text = "⌨️ <b>PENGATURAN KONTROL RHYTHM</b>"
	titleLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 84
	titleLabel.Parent = header

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(1, -50, 0, 20)
	subtitleLabel.Position = UDim2.new(0, 0, 0, 42)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Sesuaikan tombol Piano, Gitar, & Drum sesuai kenyamanan jarimu"
	subtitleLabel.TextColor3 = Color3.fromRGB(180, 210, 235)
	subtitleLabel.Font = Enum.Font.GothamMedium
	subtitleLabel.TextSize = 12
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.ZIndex = 84
	subtitleLabel.Parent = header

	-- Close Button (X)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 56)
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(220, 230, 245)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.ZIndex = 85
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

	closeBtn.MouseButton1Click:Connect(function()
		KeybindSettingsUI.Hide()
	end)

	-- ============ CONTENT CONTAINER ============
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 1, -72)
	content.Position = UDim2.new(0, 0, 0, 72)
	content.BackgroundTransparency = 1
	content.ZIndex = 83
	content.Parent = activeModal

	local cPad = Instance.new("UIPadding")
	cPad.PaddingTop = UDim.new(0, 14)
	cPad.PaddingBottom = UDim.new(0, 16)
	cPad.PaddingLeft = UDim.new(0, 20)
	cPad.PaddingRight = UDim.new(0, 20)
	cPad.Parent = content

	local cLayout = Instance.new("UIListLayout")
	cLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cLayout.Padding = UDim.new(0, 14)
	cLayout.Parent = content

	-- ============ SECTION 1: QUICK PRESETS ============
	local presetSection = Instance.new("Frame")
	presetSection.Name = "PresetSection"
	presetSection.Size = UDim2.new(1, 0, 0, 68)
	presetSection.BackgroundTransparency = 1
	presetSection.LayoutOrder = 1
	presetSection.ZIndex = 84
	presetSection.Parent = content

	local pSecTitle = Instance.new("TextLabel")
	pSecTitle.Name = "SecTitle"
	pSecTitle.Size = UDim2.new(1, 0, 0, 18)
	pSecTitle.BackgroundTransparency = 1
	pSecTitle.Text = "⚡ PILIH PRESET CEPAT:"
	pSecTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	pSecTitle.Font = Enum.Font.GothamBold
	pSecTitle.TextSize = 12
	pSecTitle.TextXAlignment = Enum.TextXAlignment.Left
	pSecTitle.ZIndex = 84
	pSecTitle.Parent = presetSection

	local chipsRow = Instance.new("Frame")
	chipsRow.Name = "ChipsRow"
	chipsRow.Size = UDim2.new(1, 0, 0, 42)
	chipsRow.Position = UDim2.new(0, 0, 0, 24)
	chipsRow.BackgroundTransparency = 1
	chipsRow.ZIndex = 84
	chipsRow.Parent = presetSection

	local chipsLayout = Instance.new("UIListLayout")
	chipsLayout.FillDirection = Enum.FillDirection.Horizontal
	chipsLayout.Padding = UDim.new(0, 8)
	chipsLayout.Parent = chipsRow

	table.clear(presetButtons)
	local presetList = { "WASD", "DFJK", "ASKL", "QWER", "ARROWS" }
	for _, pId in ipairs(presetList) do
		local pData = KeybindSystem.PRESETS[pId]
		if pData then
			local chip = Instance.new("TextButton")
			chip.Name = "Preset_" .. pId
			chip.Size = UDim2.new(0, 96, 0, 36)
			chip.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
			chip.BorderSizePixel = 0
			chip.Text = pData.name:split(" ")[1] or pId
			chip.TextColor3 = Color3.fromRGB(220, 240, 255)
			chip.Font = Enum.Font.GothamBold
			chip.TextSize = 12
			chip.ZIndex = 85
			chip.Parent = chipsRow

			Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 8)
			local chipStroke = Instance.new("UIStroke")
			chipStroke.Color = Color3.fromRGB(56, 189, 248)
			chipStroke.Thickness = 1.2
			chipStroke.Transparency = 0.5
			chipStroke.Parent = chip

			presetButtons[pId] = chip

			chip.MouseButton1Click:Connect(function()
				stopListening()
				draftKeys = { pData.keys[1], pData.keys[2], pData.keys[3], pData.keys[4] }
				KeybindSystem.SetActiveKeys(draftKeys)
				pcall(function()
					local remote = RemoteContract.GetRemote()
					if remote then
						remote:FireServer(RemoteContract.C2S.SET_KEYBINDS, {
							keybinds = KeybindSystem.ExportSettings(),
						})
					end
				end)
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.8, 1.2)
				refreshSlotsDisplay()
			end)
		end
	end

	-- ============ SECTION 2: 4-LANE SLOTS ============
	local lanesSection = Instance.new("Frame")
	lanesSection.Name = "LanesSection"
	lanesSection.Size = UDim2.new(1, 0, 0, 160)
	lanesSection.BackgroundTransparency = 1
	lanesSection.LayoutOrder = 2
	lanesSection.ZIndex = 84
	lanesSection.Parent = content

	local lSecTitle = Instance.new("TextLabel")
	lSecTitle.Name = "SecTitle"
	lSecTitle.Size = UDim2.new(1, 0, 0, 18)
	lSecTitle.BackgroundTransparency = 1
	lSecTitle.Text = "🎯 KLIK JALUR UNTUK MENGUBAH TOMBOL:"
	lSecTitle.TextColor3 = Color3.fromRGB(0, 210, 255)
	lSecTitle.Font = Enum.Font.GothamBold
	lSecTitle.TextSize = 12
	lSecTitle.TextXAlignment = Enum.TextXAlignment.Left
	lSecTitle.ZIndex = 84
	lSecTitle.Parent = lanesSection

	local slotsGrid = Instance.new("Frame")
	slotsGrid.Name = "SlotsGrid"
	slotsGrid.Size = UDim2.new(1, 0, 0, 134)
	slotsGrid.Position = UDim2.new(0, 0, 0, 24)
	slotsGrid.BackgroundTransparency = 1
	slotsGrid.ZIndex = 84
	slotsGrid.Parent = lanesSection

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.23, 0, 1, 0)
	gridLayout.CellPadding = UDim2.new(0.026, 0, 0, 0)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	gridLayout.Parent = slotsGrid

	table.clear(columnButtons)
	table.clear(columnLabels)

	local laneDescriptions = {
		{ name = "JALUR 1", pos = "Kiri Luar" },
		{ name = "JALUR 2", pos = "Kiri Tengah" },
		{ name = "JALUR 3", pos = "Kanan Tengah" },
		{ name = "JALUR 4", pos = "Kanan Luar" },
	}

	for i = 1, 4 do
		local laneCard = Instance.new("Frame")
		laneCard.Name = "LaneCard_" .. i
		laneCard.BackgroundColor3 = Color3.fromRGB(18, 25, 40)
		laneCard.BorderSizePixel = 0
		laneCard.ZIndex = 85
		laneCard.Parent = slotsGrid

		Instance.new("UICorner", laneCard).CornerRadius = UDim.new(0, 12)
		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Color3.fromRGB(45, 60, 85)
		cStroke.Thickness = 1.2
		cStroke.Parent = laneCard

		local cardPad = Instance.new("UIPadding")
		cardPad.PaddingTop = UDim.new(0, 8)
		cardPad.PaddingBottom = UDim.new(0, 8)
		cardPad.PaddingLeft = UDim.new(0, 8)
		cardPad.PaddingRight = UDim.new(0, 8)
		cardPad.Parent = laneCard

		local colName = Instance.new("TextLabel")
		colName.Name = "ColName"
		colName.Size = UDim2.new(1, 0, 0, 16)
		colName.BackgroundTransparency = 1
		colName.Text = laneDescriptions[i].name
		colName.TextColor3 = Color3.fromRGB(245, 210, 0)
		colName.Font = Enum.Font.FredokaOne
		colName.TextSize = 13
		colName.ZIndex = 86
		colName.Parent = laneCard

		local colPos = Instance.new("TextLabel")
		colPos.Name = "ColPos"
		colPos.Size = UDim2.new(1, 0, 0, 14)
		colPos.Position = UDim2.new(0, 0, 0, 18)
		colPos.BackgroundTransparency = 1
		colPos.Text = laneDescriptions[i].pos
		colPos.TextColor3 = Color3.fromRGB(150, 175, 200)
		colPos.Font = Enum.Font.Gotham
		colPos.TextSize = 10
		colPos.ZIndex = 86
		colPos.Parent = laneCard

		-- Rebind Slot Button
		local slotBtn = Instance.new("TextButton")
		slotBtn.Name = "SlotButton"
		slotBtn.Size = UDim2.new(1, 0, 0, 68)
		slotBtn.Position = UDim2.new(0, 0, 1, -68)
		slotBtn.BackgroundColor3 = Color3.fromRGB(24, 34, 52)
		slotBtn.BorderSizePixel = 0
		slotBtn.Text = ""
		slotBtn.AutoButtonColor = false
		slotBtn.ZIndex = 87
		slotBtn.Parent = laneCard

		Instance.new("UICorner", slotBtn).CornerRadius = UDim.new(0, 10)
		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(0, 210, 255)
		btnStroke.Thickness = 1.6
		btnStroke.Parent = slotBtn

		local slotLabel = Instance.new("TextLabel")
		slotLabel.Name = "KeyLabel"
		slotLabel.Size = UDim2.fromScale(1, 1)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Text = KeybindSystem.KeyCodeToLabel(draftKeys[i])
		slotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		slotLabel.Font = Enum.Font.FredokaOne
		slotLabel.TextSize = 26
		slotLabel.ZIndex = 88
		slotLabel.Parent = slotBtn

		columnButtons[i] = slotBtn
		columnLabels[i] = slotLabel

		slotBtn.MouseButton1Click:Connect(function()
			startListening(i)
		end)
	end

	-- ============ SECTION 3: ACTION BUTTONS ============
	local actionsRow = Instance.new("Frame")
	actionsRow.Name = "ActionsRow"
	actionsRow.Size = UDim2.new(1, 0, 0, 50)
	actionsRow.BackgroundTransparency = 1
	actionsRow.LayoutOrder = 3
	actionsRow.ZIndex = 84
	actionsRow.Parent = content

	local aLayout = Instance.new("UIListLayout")
	aLayout.FillDirection = Enum.FillDirection.Horizontal
	aLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	aLayout.Padding = UDim.new(0, 14)
	aLayout.Parent = actionsRow

	-- Tombol Reset WASD
	local resetBtn = Instance.new("TextButton")
	resetBtn.Name = "ResetBtn"
	resetBtn.Size = UDim2.new(0, 160, 0, 44)
	resetBtn.BackgroundColor3 = Color3.fromRGB(36, 42, 56)
	resetBtn.BorderSizePixel = 0
	resetBtn.Text = "🔄 Reset Bawaan"
	resetBtn.TextColor3 = Color3.fromRGB(200, 215, 235)
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.TextSize = 13
	resetBtn.ZIndex = 85
	resetBtn.Parent = actionsRow
	Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 10)

	resetBtn.MouseButton1Click:Connect(function()
		stopListening()
		local wasd = KeybindSystem.PRESETS.WASD
		draftKeys = { wasd.keys[1], wasd.keys[2], wasd.keys[3], wasd.keys[4] }
		KeybindSystem.SetActiveKeys(draftKeys)
		pcall(function()
			local remote = RemoteContract.GetRemote()
			if remote then
				remote:FireServer(RemoteContract.C2S.SET_KEYBINDS, {
					keybinds = KeybindSystem.ExportSettings(),
				})
			end
		end)
		playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 0.9)
		refreshSlotsDisplay()
	end)

	-- Tombol Simpan Pengaturan
	local saveBtn = Instance.new("TextButton")
	saveBtn.Name = "SaveBtn"
	saveBtn.Size = UDim2.new(0, 220, 0, 44)
	saveBtn.BackgroundColor3 = Color3.fromRGB(16, 145, 90)
	saveBtn.BorderSizePixel = 0
	saveBtn.Text = "💾 Simpan Pengaturan"
	saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	saveBtn.Font = Enum.Font.FredokaOne
	saveBtn.TextSize = 15
	saveBtn.ZIndex = 85
	saveBtn.Parent = actionsRow
	Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)

	local sGlow = Instance.new("UIStroke")
	sGlow.Color = Color3.fromRGB(74, 222, 128)
	sGlow.Thickness = 1.8
	sGlow.Parent = saveBtn

	saveBtn.MouseButton1Click:Connect(function()
		stopListening()

		-- Validasi & Terapkan ke KeybindSystem
		local ok, err = KeybindSystem.SetActiveKeys(draftKeys)
		if not ok then
			playLocalSound("rbxasset://sounds/splat.wav", 0.8, 1.0)
			return
		end

		-- Sinkronisasi ke Server via RemoteContract
		local remote = RemoteContract.GetRemote()
		if remote then
			pcall(function()
				remote:FireServer(RemoteContract.C2S.SET_KEYBINDS, {
					keybinds = KeybindSystem.ExportSettings(),
				})
			end)
		end

		playLocalSound("rbxasset://sounds/button.wav", 0.9, 1.3)
		KeybindSettingsUI.Hide()
	end)

	refreshSlotsDisplay()

	-- ============ OPEN ANIMATION ============
	activeOverlay.BackgroundTransparency = 1
	activeModal.Position = UDim2.new(0.5, 0, 0.5, 30)
	activeModal.BackgroundTransparency = 1

	TweenService:Create(activeOverlay, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
	TweenService:Create(activeModal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0.08,
	}):Play()

	playLocalSound("rbxasset://sounds/button.wav", 0.8, 1.1)
end

-- ============ HIDE MODAL ============
function KeybindSettingsUI.Hide()
	if not activeModal or isClosing then return end
	isClosing = true
	stopListening()

	TweenService:Create(activeOverlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	local closeTween = TweenService:Create(activeModal, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.5, 30),
		BackgroundTransparency = 1,
	})
	closeTween:Play()
	closeTween.Completed:Connect(function()
		if activeOverlay then
			activeOverlay:Destroy()
			activeOverlay = nil
			activeModal = nil
		end
		isClosing = false
	end)
end

function KeybindSettingsUI.Toggle(targetGui)
	if activeModal then
		KeybindSettingsUI.Hide()
	else
		KeybindSettingsUI.Show(targetGui)
	end
end

function KeybindSettingsUI.IsOpen()
	return activeModal ~= nil and not isClosing
end

return KeybindSettingsUI
