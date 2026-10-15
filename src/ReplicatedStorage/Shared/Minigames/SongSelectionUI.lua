--[[
	SongSelectionUI (ModuleScript)
	FISH!TUNE — Player Song Selection & Jukebox Modal UI (FISH-046)

	Antarmuka Glassmorphism Pemilihan Lagu:
	1. Katalog Terpadu: Menampilkan seluruh lagu dari SongChartCatalog.
	2. Tab Filter Multi-Instrumen: [SEMUA], [🎹 PIANO], [🎸 GUITAR], [🥁 DRUM].
	3. Pencarian Cepat: Live search berdasarkan judul, artis/komponis, dan genre.
	4. Showcase Detail Lagu: Menampilkan BPM, bintang kesulitan, genre, dan afinitas zona.
	5. Live Audio Melody Preview: Mendengarkan sampel melodi lagu langsung di UI.
	6. Aksi Otoritatif:
	   - [🎶 PILIH LAGU INI]: Mengirim remote ke server & memperbarui preferredSongId.
	   - [🎲 OTOMATIS]: Mengembalikan seleksi acak dinamis sesuai zona & kelangkaan ikan.
	7. Responsif Desktop, Laptop, dan Mobile (Auto-scale via UIScale).
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SongChartCatalog = require(Shared:WaitForChild("Definitions"):WaitForChild("SongChartCatalog"))
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local MobileResponsiveHelper = require(Shared:WaitForChild("Systems"):WaitForChild("MobileResponsiveHelper"))

local SongSelectionUI = {}

-- UI State
local activeOverlay = nil
local activeModal = nil
local isClosing = false
local currentFilter = "ALL" -- "ALL", "PIANO", "GUITAR", "DRUM"
local searchQuery = ""
local selectedSongId = "AUTO" -- "AUTO" atau song.id
local inspectingSongId = nil -- Lagu yang sedang dilihat di panel kanan

-- Audio Preview State
local isPreviewPlaying = false
local previewTask = nil
local vinylDiscImage = nil

-- UI References
local cardsContainer = nil
local detailContainer = nil
local activeTagLabel = nil
local filterButtons = {}
local songCardsMap = {}

-- ============ SOUND HELPER ============
local function playLocalSound(soundId, volume, speed)
	task.spawn(function()
		local snd = Instance.new("Sound")
		snd.SoundId = soundId or "rbxasset://sounds/electronicpingshort.wav"
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

-- ============ PREVIEW PLAYER ============
local function stopMelodyPreview()
	isPreviewPlaying = false
	if previewTask then
		task.cancel(previewTask)
		previewTask = nil
	end
end

local function playMelodyPreview(songData)
	stopMelodyPreview()
	if not songData then return end

	local chart = songData.charts and (songData.charts["PIANO"] or songData.charts["GUITAR"] or songData.charts["DRUM"])
	local notes = (chart and chart.notes) or (songData.charts and songData.charts["PIANO"] and songData.charts["PIANO"].notes)
	if not notes or #notes == 0 then return end

	isPreviewPlaying = true
	local bpm = (chart and chart.bpm) or songData.bpm or 120
	local beatDuration = 60 / bpm
	local noteDelay = math.clamp(beatDuration * 0.65, 0.22, 0.45)

	previewTask = task.spawn(function()
		local maxNotes = math.min(12, #notes)
		for i = 1, maxNotes do
			if not isPreviewPlaying then break end
			local semitone = notes[i] or 0
			local sound = Instance.new("Sound")
			sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			sound.Volume = 0.75
			sound.PlaybackSpeed = 0.85 * (2 ^ (semitone / 12))
			sound.Parent = SoundService
			sound:Play()

			task.delay(1.0, function()
				if sound then sound:Destroy() end
			end)

			task.wait(noteDelay)
		end
		isPreviewPlaying = false
	end)
end

-- ============ UI BUILDER ============
function SongSelectionUI.Create(targetGui, playerData)
	if activeOverlay and activeOverlay.Parent then
		return activeOverlay
	end

	if playerData and playerData.preferredSongId then
		selectedSongId = playerData.preferredSongId
	end

	-- 1. Fullscreen Dark Dim Overlay
	activeOverlay = Instance.new("Frame")
	activeOverlay.Name = "SongSelectionOverlay"
	activeOverlay.Size = UDim2.new(1, 0, 1, 0)
	activeOverlay.Position = UDim2.new(0, 0, 0, 0)
	activeOverlay.BackgroundColor3 = Color3.fromRGB(6, 10, 18)
	activeOverlay.BackgroundTransparency = 1
	activeOverlay.ZIndex = 50
	activeOverlay.Parent = targetGui

	-- Tangkap klik overlay untuk menutup modal
	local overlayBtn = Instance.new("TextButton")
	overlayBtn.Name = "DismissBackdrop"
	overlayBtn.Size = UDim2.new(1, 0, 1, 0)
	overlayBtn.BackgroundTransparency = 1
	overlayBtn.Text = ""
	overlayBtn.Parent = activeOverlay
	overlayBtn.MouseButton1Click:Connect(function()
		SongSelectionUI.Hide()
	end)

	-- 2. Central Glassmorphism Modal Window
	activeModal = Instance.new("Frame")
	activeModal.Name = "SongSelectionModal"
	activeModal.AnchorPoint = Vector2.new(0.5, 0.5)
	activeModal.Size = UDim2.new(0, 860, 0, 560)
	activeModal.Position = UDim2.new(0.5, 0, 0.5, 0)
	activeModal.BackgroundColor3 = Color3.fromRGB(13, 20, 32)
	activeModal.BackgroundTransparency = 0.12
	activeModal.BorderSizePixel = 0
	activeModal.ZIndex = 51
	activeModal.Parent = activeOverlay

	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 16)
	modalCorner.Parent = activeModal

	local modalStroke = Instance.new("UIStroke")
	modalStroke.Color = Color3.fromRGB(56, 189, 248)
	modalStroke.Thickness = 1.8
	modalStroke.Transparency = 0.35
	modalStroke.Parent = activeModal

	-- Register modal to MobileResponsiveHelper
	MobileResponsiveHelper.RegisterModal(activeModal, { baseWidth = 860, baseHeight = 560 })

	-- ============ HEADER ============
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 68)
	header.BackgroundTransparency = 1
	header.Parent = activeModal

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0, 400, 0, 30)
	titleLabel.Position = UDim2.new(0, 24, 0, 14)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = "🎵 KATALOG & PEMILIHAN LAGU"
	titleLabel.TextColor3 = Color3.fromRGB(240, 249, 255)
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Subtitle"
	subLabel.Size = UDim2.new(0, 500, 0, 18)
	subLabel.Position = UDim2.new(0, 24, 0, 42)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = Enum.Font.Gotham
	subLabel.Text = "Pilih lagu melodi untuk minigame memancing atau gunakan acak otomatis"
	subLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	subLabel.TextSize = 12
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.Parent = header

	-- Active Song Badge
	local activeBadge = Instance.new("Frame")
	activeBadge.Name = "ActiveBadge"
	activeBadge.AnchorPoint = Vector2.new(1, 0.5)
	activeBadge.Size = UDim2.new(0, 260, 0, 34)
	activeBadge.Position = UDim2.new(1, -68, 0, 34)
	activeBadge.BackgroundColor3 = Color3.fromRGB(22, 32, 50)
	activeBadge.BackgroundTransparency = 0.3
	activeBadge.Parent = header

	Instance.new("UICorner", activeBadge).CornerRadius = UDim.new(0, 8)
	local abStroke = Instance.new("UIStroke")
	abStroke.Color = Color3.fromRGB(234, 179, 8)
	abStroke.Thickness = 1.2
	abStroke.Transparency = 0.4
	abStroke.Parent = activeBadge

	activeTagLabel = Instance.new("TextLabel")
	activeTagLabel.Name = "Label"
	activeTagLabel.Size = UDim2.new(1, -16, 1, 0)
	activeTagLabel.Position = UDim2.new(0, 8, 0, 0)
	activeTagLabel.BackgroundTransparency = 1
	activeTagLabel.Font = Enum.Font.GothamBold
	activeTagLabel.Text = "🎵 Aktif: 🎲 Otomatis"
	activeTagLabel.TextColor3 = Color3.fromRGB(253, 224, 71)
	activeTagLabel.TextSize = 11
	activeTagLabel.TextXAlignment = Enum.TextXAlignment.Center
	activeTagLabel.TextTruncate = Enum.TextTruncate.AtEnd
	activeTagLabel.Parent = activeBadge

	-- Close Button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Size = UDim2.new(0, 34, 0, 34)
	closeBtn.Position = UDim2.new(1, -20, 0, 34)
	closeBtn.BackgroundColor3 = Color3.fromRGB(244, 63, 94)
	closeBtn.BackgroundTransparency = 0.25
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		SongSelectionUI.Hide()
	end)

	-- Divider Line
	local div1 = Instance.new("Frame")
	div1.Size = UDim2.new(1, -40, 0, 1)
	div1.Position = UDim2.new(0, 20, 0, 68)
	div1.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
	div1.BackgroundTransparency = 0.8
	div1.BorderSizePixel = 0
	div1.Parent = activeModal

	-- ============ FILTER & SEARCH BAR ============
	local filterBar = Instance.new("Frame")
	filterBar.Name = "FilterBar"
	filterBar.Size = UDim2.new(1, -40, 0, 42)
	filterBar.Position = UDim2.new(0, 20, 0, 78)
	filterBar.BackgroundTransparency = 1
	filterBar.Parent = activeModal

	-- Instrument Tabs
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(0, 480, 1, 0)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = filterBar

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabContainer

	local tabs = {
		{ id = "ALL", label = "🌐 SEMUA" },
		{ id = "PIANO", label = "🎹 PIANO" },
		{ id = "GUITAR", label = "🎸 GITAR" },
		{ id = "DRUM", label = "🥁 DRUM" },
	}

	for i, t in ipairs(tabs) do
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. t.id
		btn.Size = UDim2.new(0, 105, 0, 34)
		btn.LayoutOrder = i
		btn.BackgroundColor3 = (currentFilter == t.id) and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(15, 23, 42)
		btn.BackgroundTransparency = 0.2
		btn.Font = Enum.Font.GothamBold
		btn.Text = t.label
		btn.TextColor3 = (currentFilter == t.id) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
		btn.TextSize = 12
		btn.Parent = tabContainer
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		local tStroke = Instance.new("UIStroke")
		tStroke.Color = (currentFilter == t.id) and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(51, 65, 85)
		tStroke.Thickness = 1.2
		tStroke.Parent = btn

		filterButtons[t.id] = { button = btn, stroke = tStroke }

		btn.MouseButton1Click:Connect(function()
			playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.4)
			SongSelectionUI.SetFilter(t.id)
		end)
	end

	-- Search Box
	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchFrame"
	searchFrame.AnchorPoint = Vector2.new(1, 0)
	searchFrame.Size = UDim2.new(0, 310, 0, 34)
	searchFrame.Position = UDim2.new(1, 0, 0, 0)
	searchFrame.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	searchFrame.BackgroundTransparency = 0.2
	searchFrame.Parent = filterBar
	Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)

	local sStroke = Instance.new("UIStroke")
	sStroke.Color = Color3.fromRGB(51, 65, 85)
	sStroke.Thickness = 1.2
	sStroke.Parent = searchFrame

	local searchBox = Instance.new("TextBox")
	searchBox.Name = "SearchInput"
	searchBox.Size = UDim2.new(1, -20, 1, 0)
	searchBox.Position = UDim2.new(0, 10, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.Font = Enum.Font.Gotham
	searchBox.PlaceholderText = "🔍 Cari lagu atau komposer..."
	searchBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
	searchBox.Text = searchQuery
	searchBox.TextColor3 = Color3.fromRGB(240, 249, 255)
	searchBox.TextSize = 12
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchFrame

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchQuery = searchBox.Text:lower()
		SongSelectionUI.RefreshSongList()
	end)

	-- ============ MAIN BODY: TWO-PANEL SPLIT ============
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Size = UDim2.new(1, -40, 1, -135)
	body.Position = UDim2.new(0, 20, 0, 125)
	body.BackgroundTransparency = 1
	body.Parent = activeModal

	-- Left Panel: Scrollable List of Songs
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel"
	leftPanel.Size = UDim2.new(0, 480, 1, 0)
	leftPanel.BackgroundTransparency = 1
	leftPanel.Parent = body

	cardsContainer = Instance.new("ScrollingFrame")
	cardsContainer.Name = "CardsContainer"
	cardsContainer.Size = UDim2.new(1, 0, 1, 0)
	cardsContainer.BackgroundTransparency = 1
	cardsContainer.ScrollBarThickness = 5
	cardsContainer.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
	cardsContainer.BorderSizePixel = 0
	cardsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	cardsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	cardsContainer.Parent = leftPanel

	local cardLayout = Instance.new("UIListLayout")
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 8)
	cardLayout.Parent = cardsContainer

	-- Right Panel: Song Detail Showcase & Audio Player
	detailContainer = Instance.new("Frame")
	detailContainer.Name = "DetailContainer"
	detailContainer.AnchorPoint = Vector2.new(1, 0)
	detailContainer.Size = UDim2.new(0, 320, 1, 0)
	detailContainer.Position = UDim2.new(1, 0, 0, 0)
	detailContainer.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	detailContainer.BackgroundTransparency = 0.25
	detailContainer.Parent = body
	Instance.new("UICorner", detailContainer).CornerRadius = UDim.new(0, 12)

	local dStroke = Instance.new("UIStroke")
	dStroke.Color = Color3.fromRGB(56, 189, 248)
	dStroke.Thickness = 1.4
	dStroke.Transparency = 0.4
	dStroke.Parent = detailContainer

	-- Populate initial song list and detail view
	SongSelectionUI.RefreshSongList()

	-- Set default inspecting song
	local all = SongChartCatalog.GetAllSongs()
	if #all > 0 then
		SongSelectionUI.InspectSong(all[1].id)
	end

	return activeOverlay
end

-- ============ SET FILTER ============
function SongSelectionUI.SetFilter(filterId)
	currentFilter = filterId or "ALL"
	for id, refs in pairs(filterButtons) do
		local active = (id == currentFilter)
		refs.button.BackgroundColor3 = active and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(15, 23, 42)
		refs.button.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(148, 163, 184)
		refs.stroke.Color = active and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(51, 65, 85)
	end
	SongSelectionUI.RefreshSongList()
end

-- ============ REFRESH SONG LIST ============
function SongSelectionUI.RefreshSongList()
	if not cardsContainer then return end

	-- Bersihkan kartu-kartu sebelumnya
	for _, child in ipairs(cardsContainer:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end
	table.clear(songCardsMap)

	-- 1. Kartu Khusus: "🎲 Otomatis (Sesuai Zona & Rarity)"
	local autoCard = Instance.new("Frame")
	autoCard.Name = "Card_AUTO"
	autoCard.Size = UDim2.new(1, -8, 0, 68)
	autoCard.BackgroundColor3 = (selectedSongId == "AUTO") and Color3.fromRGB(24, 38, 62) or Color3.fromRGB(15, 23, 42)
	autoCard.BackgroundTransparency = 0.2
	autoCard.LayoutOrder = 0
	autoCard.Parent = cardsContainer
	Instance.new("UICorner", autoCard).CornerRadius = UDim.new(0, 10)

	local autoStroke = Instance.new("UIStroke")
	autoStroke.Color = (selectedSongId == "AUTO") and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(51, 65, 85)
	autoStroke.Thickness = (selectedSongId == "AUTO") and 1.8 or 1.0
	autoStroke.Parent = autoCard

	local autoIcon = Instance.new("TextLabel")
	autoIcon.Size = UDim2.new(0, 44, 0, 44)
	autoIcon.Position = UDim2.new(0, 12, 0.5, -22)
	autoIcon.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	autoIcon.Font = Enum.Font.GothamBlack
	autoIcon.Text = "🎲"
	autoIcon.TextSize = 22
	autoIcon.TextColor3 = Color3.fromRGB(253, 224, 71)
	autoIcon.Parent = autoCard
	Instance.new("UICorner", autoIcon).CornerRadius = UDim.new(0, 8)

	local autoTitle = Instance.new("TextLabel")
	autoTitle.Size = UDim2.new(1, -150, 0, 20)
	autoTitle.Position = UDim2.new(0, 66, 0, 14)
	autoTitle.BackgroundTransparency = 1
	autoTitle.Font = Enum.Font.GothamBold
	autoTitle.Text = "Otomatis (Sesuai Zona & Rarity)"
	autoTitle.TextColor3 = Color3.fromRGB(253, 224, 71)
	autoTitle.TextSize = 13
	autoTitle.TextXAlignment = Enum.TextXAlignment.Left
	autoTitle.Parent = autoCard

	local autoDesc = Instance.new("TextLabel")
	autoDesc.Size = UDim2.new(1, -150, 0, 16)
	autoDesc.Position = UDim2.new(0, 66, 0, 36)
	autoDesc.BackgroundTransparency = 1
	autoDesc.Font = Enum.Font.Gotham
	autoDesc.Text = "Rekomendasi default: Lagu dipilih secara acak cerdas"
	autoDesc.TextColor3 = Color3.fromRGB(148, 163, 184)
	autoDesc.TextSize = 10
	autoDesc.TextXAlignment = Enum.TextXAlignment.Left
	autoDesc.Parent = autoCard

	local autoSelectBtn = Instance.new("TextButton")
	autoSelectBtn.Size = UDim2.new(0, 72, 0, 30)
	autoSelectBtn.Position = UDim2.new(1, -84, 0.5, -15)
	autoSelectBtn.BackgroundColor3 = (selectedSongId == "AUTO") and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(30, 41, 59)
	autoSelectBtn.Font = Enum.Font.GothamBold
	autoSelectBtn.Text = (selectedSongId == "AUTO") and "AKTIF" or "PILIH"
	autoSelectBtn.TextColor3 = (selectedSongId == "AUTO") and Color3.fromRGB(15, 23, 42) or Color3.fromRGB(240, 249, 255)
	autoSelectBtn.TextSize = 11
	autoSelectBtn.Parent = autoCard
	Instance.new("UICorner", autoSelectBtn).CornerRadius = UDim.new(0, 6)

	autoSelectBtn.MouseButton1Click:Connect(function()
		SongSelectionUI.SelectSong("AUTO")
	end)

	songCardsMap["AUTO"] = { card = autoCard, stroke = autoStroke, button = autoSelectBtn }

	-- 2. Daftar Lagu dari Katalog
	local allSongs = SongChartCatalog.GetAllSongs()
	local order = 1

	for _, song in ipairs(allSongs) do
		local matchFilter = true
		if currentFilter ~= "ALL" then
			matchFilter = (song.charts and song.charts[currentFilter] ~= nil)
		end

		local matchSearch = true
		if searchQuery ~= "" then
			local titleMatch = song.title:lower():find(searchQuery, 1, true)
			local artistMatch = song.artist and song.artist:lower():find(searchQuery, 1, true)
			local genreMatch = song.genre and song.genre:lower():find(searchQuery, 1, true)
			matchSearch = (titleMatch ~= nil or artistMatch ~= nil or genreMatch ~= nil)
		end

		if matchFilter and matchSearch then
			order = order + 1
			local isSelected = (selectedSongId == song.id)
			local isInspecting = (inspectingSongId == song.id)

			local card = Instance.new("Frame")
			card.Name = "Card_" .. song.id
			card.Size = UDim2.new(1, -8, 0, 72)
			card.BackgroundColor3 = isSelected and Color3.fromRGB(20, 35, 55) or (isInspecting and Color3.fromRGB(18, 28, 44) or Color3.fromRGB(15, 23, 42))
			card.BackgroundTransparency = 0.2
			card.LayoutOrder = order
			card.Parent = cardsContainer
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

			local cStroke = Instance.new("UIStroke")
			cStroke.Color = isSelected and Color3.fromRGB(56, 189, 248) or (isInspecting and Color3.fromRGB(14, 165, 233) or Color3.fromRGB(30, 41, 59))
			cStroke.Thickness = isSelected and 1.8 or 1.0
			cStroke.Parent = card

			-- Genre / Instrument Badge Icon
			local iconBg = Instance.new("Frame")
			iconBg.Size = UDim2.new(0, 46, 0, 46)
			iconBg.Position = UDim2.new(0, 12, 0.5, -23)
			iconBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
			iconBg.Parent = card
			Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)

			local iconLabel = Instance.new("TextLabel")
			iconLabel.Size = UDim2.new(1, 0, 1, 0)
			iconLabel.BackgroundTransparency = 1
			iconLabel.Font = Enum.Font.GothamBlack
			iconLabel.Text = (song.genre == "Classical" and "🎹") or (song.genre == "Rock" and "🎸") or (song.genre == "Synthwave" and "🌌") or "🎶"
			iconLabel.TextSize = 22
			iconLabel.Parent = iconBg

			-- Title & Artist
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -170, 0, 20)
			title.Position = UDim2.new(0, 68, 0, 12)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBold
			title.Text = song.title
			title.TextColor3 = isSelected and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(240, 249, 255)
			title.TextSize = 13
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextTruncate = Enum.TextTruncate.AtEnd
			title.Parent = card

			-- Metadata Subtitle: Stars + BPM + Genre
			local starsText = song.starRating or "★★☆☆☆"
			local bpmText = tostring(song.bpm or 120) .. " BPM"
			local genreText = song.genre or "General"

			local meta = Instance.new("TextLabel")
			meta.Size = UDim2.new(1, -170, 0, 16)
			meta.Position = UDim2.new(0, 68, 0, 36)
			meta.BackgroundTransparency = 1
			meta.Font = Enum.Font.Gotham
			meta.Text = string.format("<font color='#fde047'>%s</font>  •  %s  •  <font color='#94a3b8'>%s</font>", starsText, bpmText, genreText)
			meta.TextColor3 = Color3.fromRGB(203, 213, 225)
			meta.TextSize = 10
			meta.RichText = true
			meta.TextXAlignment = Enum.TextXAlignment.Left
			meta.Parent = card

			-- Action / Select Button
			local selectBtn = Instance.new("TextButton")
			selectBtn.Size = UDim2.new(0, 72, 0, 30)
			selectBtn.Position = UDim2.new(1, -84, 0.5, -15)
			selectBtn.BackgroundColor3 = isSelected and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(30, 41, 59)
			selectBtn.Font = Enum.Font.GothamBold
			selectBtn.Text = isSelected and "AKTIF" or "PILIH"
			selectBtn.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(203, 213, 225)
			selectBtn.TextSize = 11
			selectBtn.Parent = card
			Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)

			-- Click Card -> Inspect Song
			local cardClickBtn = Instance.new("TextButton")
			cardClickBtn.Size = UDim2.new(1, -90, 1, 0)
			cardClickBtn.BackgroundTransparency = 1
			cardClickBtn.Text = ""
			cardClickBtn.Parent = card

			cardClickBtn.MouseButton1Click:Connect(function()
				playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.4, 1.2)
				SongSelectionUI.InspectSong(song.id)
			end)

			selectBtn.MouseButton1Click:Connect(function()
				SongSelectionUI.SelectSong(song.id)
			end)

			songCardsMap[song.id] = { card = card, stroke = cStroke, button = selectBtn, title = title }
		end
	end

	SongSelectionUI.UpdateActiveBadge()
end

-- ============ INSPECT SONG (RIGHT PANEL) ============
function SongSelectionUI.InspectSong(songId)
	inspectingSongId = songId
	stopMelodyPreview()

	if not detailContainer then return end
	detailContainer:ClearAllChildren()

	local dPad = Instance.new("UIPadding")
	dPad.PaddingTop = UDim.new(0, 16)
	dPad.PaddingBottom = UDim.new(0, 16)
	dPad.PaddingLeft = UDim.new(0, 18)
	dPad.PaddingRight = UDim.new(0, 18)
	dPad.Parent = detailContainer

	local song = SongChartCatalog.GetSong(songId)
	if not song then
		-- Fallback detail untuk AUTO
		local autoTitle = Instance.new("TextLabel")
		autoTitle.Size = UDim2.new(1, 0, 0, 28)
		autoTitle.BackgroundTransparency = 1
		autoTitle.Font = Enum.Font.GothamBlack
		autoTitle.Text = "🎲 SELEKSI OTOMATIS"
		autoTitle.TextColor3 = Color3.fromRGB(253, 224, 71)
		autoTitle.TextSize = 18
		autoTitle.Parent = detailContainer

		local autoDesc = Instance.new("TextLabel")
		autoDesc.Size = UDim2.new(1, 0, 0, 140)
		autoDesc.Position = UDim2.new(0, 0, 0, 40)
		autoDesc.BackgroundTransparency = 1
		autoDesc.Font = Enum.Font.Gotham
		autoDesc.Text = "Ketika opsi ini aktif, FISH!TUNE secara otomatis memilih lagu dan tempo yang sesuai dengan:\n\n• Bioma & Pulau memancing\n• Tingkat kelangkaan ikan yang memakan kail\n• Jenis joran yang sedang digunakan"
		autoDesc.TextColor3 = Color3.fromRGB(203, 213, 225)
		autoDesc.TextSize = 12
		autoDesc.TextWrapped = true
		autoDesc.TextXAlignment = Enum.TextXAlignment.Left
		autoDesc.TextYAlignment = Enum.TextYAlignment.Top
		autoDesc.Parent = detailContainer

		local chooseBtn = Instance.new("TextButton")
		chooseBtn.Size = UDim2.new(1, 0, 0, 42)
		chooseBtn.Position = UDim2.new(0, 0, 1, -44)
		chooseBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
		chooseBtn.Font = Enum.Font.GothamBlack
		chooseBtn.Text = (selectedSongId == "AUTO") and "✅ SEDANG DIGUNAKAN" or "🎲 GUNAKAN MODE OTOMATIS"
		chooseBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
		chooseBtn.TextSize = 12
		chooseBtn.Parent = detailContainer
		Instance.new("UICorner", chooseBtn).CornerRadius = UDim.new(0, 8)

		chooseBtn.MouseButton1Click:Connect(function()
			SongSelectionUI.SelectSong("AUTO")
		end)
		return
	end

	-- 1. Vinyl Disc / Cover Icon Visual
	local discFrame = Instance.new("Frame")
	discFrame.Name = "VinylDisc"
	discFrame.Size = UDim2.new(0, 72, 0, 72)
	discFrame.Position = UDim2.new(0.5, -36, 0, 6)
	discFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
	discFrame.Parent = detailContainer
	Instance.new("UICorner", discFrame).CornerRadius = UDim.new(1, 0)

	local discStroke = Instance.new("UIStroke")
	discStroke.Color = Color3.fromRGB(56, 189, 248)
	discStroke.Thickness = 2.0
	discStroke.Parent = discFrame

	local discIcon = Instance.new("TextLabel")
	discIcon.Size = UDim2.new(1, 0, 1, 0)
	discIcon.BackgroundTransparency = 1
	discIcon.Font = Enum.Font.GothamBlack
	discIcon.Text = "💿"
	discIcon.TextSize = 34
	discIcon.Parent = discFrame

	-- 2. Song Title & Artist
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 22)
	titleLabel.Position = UDim2.new(0, 0, 0, 86)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = song.title
	titleLabel.TextColor3 = Color3.fromRGB(240, 249, 255)
	titleLabel.TextSize = 16
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Parent = detailContainer

	local artistLabel = Instance.new("TextLabel")
	artistLabel.Size = UDim2.new(1, 0, 0, 16)
	artistLabel.Position = UDim2.new(0, 0, 0, 110)
	artistLabel.BackgroundTransparency = 1
	artistLabel.Font = Enum.Font.GothamMedium
	artistLabel.Text = song.artist or "Artis Anonim"
	artistLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
	artistLabel.TextSize = 11
	artistLabel.TextTruncate = Enum.TextTruncate.AtEnd
	artistLabel.Parent = detailContainer

	-- 3. Song Specs Grid (Genre, BPM, Stars)
	local specsFrame = Instance.new("Frame")
	specsFrame.Size = UDim2.new(1, 0, 0, 60)
	specsFrame.Position = UDim2.new(0, 0, 0, 134)
	specsFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
	specsFrame.BackgroundTransparency = 0.4
	specsFrame.Parent = detailContainer
	Instance.new("UICorner", specsFrame).CornerRadius = UDim.new(0, 8)

	local specsText = Instance.new("TextLabel")
	specsText.Size = UDim2.new(1, -16, 1, 0)
	specsText.Position = UDim2.new(0, 8, 0, 0)
	specsText.BackgroundTransparency = 1
	specsText.Font = Enum.Font.Gotham
	specsText.RichText = true
	specsText.Text = string.format("<b>Genre:</b> %s   |   <b>Tempo:</b> %d BPM\n<b>Kesulitan:</b> <font color='#fde047'>%s</font>",
		song.genre or "General", song.bpm or 120, song.starRating or "★★☆☆☆")
	specsText.TextColor3 = Color3.fromRGB(203, 213, 225)
	specsText.TextSize = 11
	specsText.TextXAlignment = Enum.TextXAlignment.Center
	specsText.Parent = specsFrame

	-- 4. Supported Instruments Matrix
	local instLabel = Instance.new("TextLabel")
	instLabel.Size = UDim2.new(1, 0, 0, 16)
	instLabel.Position = UDim2.new(0, 0, 0, 204)
	instLabel.BackgroundTransparency = 1
	instLabel.Font = Enum.Font.GothamBold
	instLabel.Text = "INSTRUMEN DIDUKUNG:"
	instLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
	instLabel.TextSize = 10
	instLabel.TextXAlignment = Enum.TextXAlignment.Left
	instLabel.Parent = detailContainer

	local instContainer = Instance.new("Frame")
	instContainer.Size = UDim2.new(1, 0, 0, 30)
	instContainer.Position = UDim2.new(0, 0, 0, 222)
	instContainer.BackgroundTransparency = 1
	instContainer.Parent = detailContainer

	local iLayout = Instance.new("UIListLayout")
	iLayout.FillDirection = Enum.FillDirection.Horizontal
	iLayout.Padding = UDim.new(0, 6)
	iLayout.Parent = instContainer

	local insts = {
		{ id = "PIANO", name = "Piano Tiles", icon = "🎹" },
		{ id = "GUITAR", name = "Guitar Riff", icon = "🎸" },
		{ id = "DRUM", name = "Drum Beat", icon = "🥁" },
	}

	for _, item in ipairs(insts) do
		local hasChart = song.charts and song.charts[item.id] ~= nil
		local pill = Instance.new("Frame")
		pill.Size = UDim2.new(0, 88, 0, 26)
		pill.BackgroundColor3 = hasChart and Color3.fromRGB(30, 41, 59) or Color3.fromRGB(20, 24, 34)
		pill.BackgroundTransparency = 0.3
		pill.Parent = instContainer
		Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 6)

		local pillText = Instance.new("TextLabel")
		pillText.Size = UDim2.new(1, 0, 1, 0)
		pillText.BackgroundTransparency = 1
		pillText.Font = Enum.Font.GothamBold
		pillText.Text = item.icon .. " " .. item.id
		pillText.TextColor3 = hasChart and Color3.fromRGB(186, 230, 253) or Color3.fromRGB(100, 116, 139)
		pillText.TextSize = 10
		pillText.Parent = pill
	end

	-- 5. Audio Preview Button
	local previewBtn = Instance.new("TextButton")
	previewBtn.Name = "PreviewBtn"
	previewBtn.Size = UDim2.new(1, 0, 0, 38)
	previewBtn.Position = UDim2.new(0, 0, 0, 264)
	previewBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
	previewBtn.Font = Enum.Font.GothamBold
	previewBtn.Text = "▶️ DENGARKAN SAMPEL MELODI"
	previewBtn.TextColor3 = Color3.fromRGB(186, 230, 253)
	previewBtn.TextSize = 11
	previewBtn.Parent = detailContainer
	Instance.new("UICorner", previewBtn).CornerRadius = UDim.new(0, 8)

	local prevStroke = Instance.new("UIStroke")
	prevStroke.Color = Color3.fromRGB(56, 189, 248)
	prevStroke.Thickness = 1.2
	prevStroke.Transparency = 0.5
	prevStroke.Parent = previewBtn

	previewBtn.MouseButton1Click:Connect(function()
		if isPreviewPlaying then
			stopMelodyPreview()
			previewBtn.Text = "▶️ DENGARKAN SAMPEL MELODI"
			previewBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
		else
			previewBtn.Text = "⏹️ HENTIKAN SAMPEL"
			previewBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
			playMelodyPreview(song)
		end
	end)

	-- 6. Select / Set Song Action Button
	local isCurrentSelected = (selectedSongId == song.id)
	local chooseBtn = Instance.new("TextButton")
	chooseBtn.Name = "ChooseBtn"
	chooseBtn.Size = UDim2.new(1, 0, 0, 42)
	chooseBtn.Position = UDim2.new(0, 0, 1, -44)
	chooseBtn.BackgroundColor3 = isCurrentSelected and Color3.fromRGB(2, 132, 199) or Color3.fromRGB(16, 185, 129)
	chooseBtn.Font = Enum.Font.GothamBlack
	chooseBtn.Text = isCurrentSelected and "✅ SEDANG DIGUNAKAN" or "🎶 GUNAKAN LAGU INI"
	chooseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	chooseBtn.TextSize = 12
	chooseBtn.Parent = detailContainer
	Instance.new("UICorner", chooseBtn).CornerRadius = UDim.new(0, 8)

	chooseBtn.MouseButton1Click:Connect(function()
		SongSelectionUI.SelectSong(song.id)
	end)
end

-- ============ SELECT SONG ============
function SongSelectionUI.SelectSong(songId)
	selectedSongId = songId or "AUTO"
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.8, 1.6)

	-- Kirim remote event otoritatif ke server (FISH-046)
	RemoteContract.Client.SelectSong(selectedSongId)

	-- Perbarui tampilan visual
	SongSelectionUI.UpdateActiveBadge()

	-- Perbarui status tombol pada seluruh kartu
	for id, item in pairs(songCardsMap) do
		local isSel = (id == selectedSongId)
		if item.card and item.stroke and item.button then
			item.card.BackgroundColor3 = isSel and Color3.fromRGB(20, 35, 55) or Color3.fromRGB(15, 23, 42)
			item.stroke.Color = isSel and (id == "AUTO" and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(56, 189, 248)) or Color3.fromRGB(30, 41, 59)
			item.stroke.Thickness = isSel and 1.8 or 1.0
			item.button.BackgroundColor3 = isSel and (id == "AUTO" and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(2, 132, 199)) or Color3.fromRGB(30, 41, 59)
			item.button.Text = isSel and "AKTIF" or "PILIH"
			item.button.TextColor3 = (isSel and id == "AUTO") and Color3.fromRGB(15, 23, 42) or Color3.fromRGB(255, 255, 255)
			if item.title then
				item.title.TextColor3 = isSel and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(240, 249, 255)
			end
		end
	end

	-- Refresh panel detail jika sedang melihat lagu tersebut
	if inspectingSongId then
		SongSelectionUI.InspectSong(inspectingSongId)
	end
end

-- ============ UPDATE ACTIVE BADGE ============
function SongSelectionUI.UpdateActiveBadge()
	if not activeTagLabel then return end
	if selectedSongId == "AUTO" or not selectedSongId then
		activeTagLabel.Text = "🎵 Aktif: 🎲 Otomatis (Zona & Rarity)"
		activeTagLabel.TextColor3 = Color3.fromRGB(253, 224, 71)
	else
		local song = SongChartCatalog.GetSong(selectedSongId)
		if song then
			activeTagLabel.Text = string.format("🎵 Aktif: %s", song.title)
			activeTagLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
		else
			activeTagLabel.Text = "🎵 Aktif: 🎲 Otomatis"
			activeTagLabel.TextColor3 = Color3.fromRGB(253, 224, 71)
		end
	end
end

-- ============ UPDATE FROM SERVER ============
function SongSelectionUI.UpdateSelectedSong(songId)
	selectedSongId = songId or "AUTO"
	SongSelectionUI.UpdateActiveBadge()
	if activeModal and activeModal.Parent then
		SongSelectionUI.RefreshSongList()
		if inspectingSongId then
			SongSelectionUI.InspectSong(inspectingSongId)
		end
	end
end

-- ============ LIFECYCLE API ============
function SongSelectionUI.Show(targetGui, playerData)
	if isClosing then return end
	local overlay = SongSelectionUI.Create(targetGui, playerData)
	if not overlay or not activeModal then return end

	stopMelodyPreview()
	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.2)

	overlay.Visible = true
	activeModal.Position = UDim2.new(0.5, 0, 0.55, 0)
	activeModal.BackgroundTransparency = 1

	TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.4,
	}):Play()

	TweenService:Create(activeModal, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 0.12,
	}):Play()
end

function SongSelectionUI.Hide()
	if isClosing or not activeOverlay or not activeOverlay.Visible then return end
	isClosing = true
	stopMelodyPreview()

	playLocalSound("rbxasset://sounds/electronicpingshort.wav", 0.5, 0.9)

	local fadeTween = TweenService:Create(activeOverlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})

	local modalTween = TweenService:Create(activeModal, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 0.55, 0),
		BackgroundTransparency = 1,
	})

	fadeTween:Play()
	modalTween:Play()

	modalTween.Completed:Once(function()
		if activeOverlay then
			activeOverlay.Visible = false
		end
		isClosing = false
	end)
end

function SongSelectionUI.Toggle(targetGui, playerData)
	if SongSelectionUI.IsOpen() then
		SongSelectionUI.Hide()
	else
		SongSelectionUI.Show(targetGui, playerData)
	end
end

function SongSelectionUI.IsOpen()
	return activeOverlay ~= nil and activeOverlay.Visible == true and isClosing == false
end

function SongSelectionUI.GetSelectedSong()
	return selectedSongId
end

return SongSelectionUI
