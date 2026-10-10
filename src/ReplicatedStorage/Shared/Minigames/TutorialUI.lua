--[[
	TutorialUI (ModuleScript)
	FISH!TUNE — First-Time User Experience (FTUE) & Interactive Help Guide (FISH-033)

	Fitur Utama:
	1. Welcome Modal: Dialog sambutan ramah dari "Kapten Harmoni" untuk pemain baru.
	2. Floating Quest Guide Pill: Widget panduan objektif dinamis di layar atas/bawah.
	3. Contextual Step Guides: Petunjuk langkah 1–4 (Lemparan kail, Sambaran, Minigame Ritme, Jual Ikan).
	4. Completion Celebration Modal: Pop-up hadiah graduasi starter (+100 Koin, +5 Umpan).
	5. Interactive Help Modal: Buku panduan lengkap (Dasar Mancing, 3 Instrumen, Rarity & Pity, Toko, Hotkey).
	6. Tombol HUD & Hotkey [H]: Akses mudah ke panduan bermain kapan saja.
]]

local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local InstrumentDefinitions = require(Shared:WaitForChild("Definitions"):WaitForChild("InstrumentDefinitions"))
local MobileResponsiveHelper = require(Shared:WaitForChild("Systems"):WaitForChild("MobileResponsiveHelper"))

local TutorialUI = {}

-- State UI
local activeWelcomeModal = nil
local activeCelebrationModal = nil
local activeHelpModal = nil
local activeQuestPill = nil
local currentStep = 0
local isPillMinimized = false
local isClosingModal = false

-- Audio Helper
local function playSound(soundId, volume, pitch)
	task.spawn(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume or 0.5
		sound.Pitch = pitch or 1
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

-- ============ DATA LANGKAH TUTORIAL ============
local TUTORIAL_STEPS = {
	[1] = {
		step = 1,
		title = "Langkah 1/4: Tahan & Lempar Kail",
		badge = "🎣 LEMPAR KAIL",
		icon = "🎣",
		color = Color3.fromRGB(56, 189, 248),
		shortDesc = "Tahan tombol <b>[MANCING]</b> / <b>[KLIK / SPASI]</b> dan lepas di zona <b>PERFECT (Hijau)</b>!",
		longDesc = "Arahkan pandangan ke lautan. Tahan tombol mancing untuk mengisi meter lemparan. Lepaskan tepat saat jarum indikator berada di zona hijau/PERFECT untuk mendapat bonus jangkauan & keberuntungan!",
	},
	[2] = {
		step = 2,
		title = "Langkah 2/4: Tunggu Sambaran Ikan",
		badge = "🌊 SAMBARAN IKAN",
		icon = "🌊",
		color = Color3.fromRGB(245, 158, 11),
		shortDesc = "Perhatikan gelembung air & seruan <b>(!) MERAH</b> di atas pelampung!",
		longDesc = "Pelampungmu telah mendarat di laut. Tetap tenang dan tunggu hingga ikan terpikat. Saat tanda seru merah (!) muncul dan suara sambaran berbunyi, minigame ritme akan segera dimulai!",
	},
	[3] = {
		step = 3,
		title = "Langkah 3/4: Mainkan Ritme Melodi",
		badge = "🎵 MINIGAME RITME",
		icon = "🎵",
		color = Color3.fromRGB(168, 85, 247),
		shortDesc = "Tekan not tuts/ketukan sesuai alunan musik untuk menaklukkan ikan!",
		longDesc = "Ikan di Teluk Melodi tertarik pada musik! Tekan not tuts [A][W][S][D] (Piano) atau ketukan [Spasi/Klik] (Drum) dengan presisi. Raih Akurasi & Combo tinggi untuk bonus Luck!",
	},
	[4] = {
		step = 4,
		title = "Langkah 4/4: Kunjungi Toko & Jual Ikan",
		badge = "🏪 TOKO & EKONOMI",
		icon = "🏪",
		color = Color3.fromRGB(74, 222, 128),
		shortDesc = "Buka <b>[🛒 TOKO]</b> di menu kiri atau dekati pedagang di dermaga untuk menjual hasil tangkapan!",
		longDesc = "Selamat atas tangkapan pertamamu! Kunjungi pedagang ikan di dermaga atau buka menu Toko samping [K] untuk menukar ikan dengan Koin Emas & membeli joran baru!",
	},
}

-- ============ 1. FLOATING QUEST GUIDE PILL ============
function TutorialUI.CreateOrUpdateQuestPill(targetGui, stepNumber, customText)
	if not targetGui then return end
	if stepNumber < 1 or stepNumber > 4 then
		TutorialUI.HideQuestPill()
		return
	end

	currentStep = stepNumber
	local stepData = TUTORIAL_STEPS[stepNumber] or TUTORIAL_STEPS[1]

	if not activeQuestPill or not activeQuestPill.Parent then
		local pillContainer = Instance.new("Frame")
		pillContainer.Name = "TutorialQuestPill"
		pillContainer.AnchorPoint = Vector2.new(0.5, 0)
		pillContainer.Position = UDim2.new(0.5, 0, 0, 70)
		pillContainer.Size = UDim2.new(0, 460, 0, 52)
		pillContainer.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
		pillContainer.BackgroundTransparency = 0.15
		pillContainer.BorderSizePixel = 0
		pillContainer.ZIndex = 40
		pillContainer.Parent = targetGui
		Instance.new("UICorner", pillContainer).CornerRadius = UDim.new(0, 14)

		local pStroke = Instance.new("UIStroke")
		pStroke.Name = "PillStroke"
		pStroke.Color = stepData.color
		pStroke.Thickness = 1.8
		pStroke.Transparency = 0.2
		pStroke.Parent = pillContainer

		local pGrad = Instance.new("UIGradient")
		pGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 240)),
		})
		pGrad.Parent = pillContainer

		local contentLayout = Instance.new("Frame")
		contentLayout.Name = "Content"
		contentLayout.Size = UDim2.new(1, -24, 1, 0)
		contentLayout.Position = UDim2.new(0, 12, 0, 0)
		contentLayout.BackgroundTransparency = 1
		contentLayout.ZIndex = 41
		contentLayout.Parent = pillContainer

		-- Icon Badge
		local iconFrame = Instance.new("Frame")
		iconFrame.Name = "IconFrame"
		iconFrame.Size = UDim2.new(0, 36, 0, 36)
		iconFrame.Position = UDim2.new(0, 0, 0.5, -18)
		iconFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
		iconFrame.BorderSizePixel = 0
		iconFrame.ZIndex = 42
		iconFrame.Parent = contentLayout
		Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 10)

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Size = UDim2.new(1, 0, 1, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = stepData.icon
		iconLabel.TextSize = 18
		iconLabel.ZIndex = 43
		iconLabel.Parent = iconFrame

		-- Text Stack
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, -140, 0, 18)
		titleLabel.Position = UDim2.new(0, 46, 0, 7)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBlack
		titleLabel.Text = stepData.title:upper()
		titleLabel.TextColor3 = stepData.color
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.ZIndex = 42
		titleLabel.Parent = contentLayout

		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "DescLabel"
		descLabel.Size = UDim2.new(1, -140, 0, 20)
		descLabel.Position = UDim2.new(0, 46, 0, 25)
		descLabel.BackgroundTransparency = 1
		descLabel.Font = Enum.Font.GothamMedium
		descLabel.RichText = true
		descLabel.Text = customText or stepData.shortDesc
		descLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
		descLabel.TextSize = 11
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextTruncate = Enum.TextTruncate.AtEnd
		descLabel.ZIndex = 42
		descLabel.Parent = contentLayout

		-- Button Action Group (Panduan Detail + Lewati)
		local btnGroup = Instance.new("Frame")
		btnGroup.Name = "BtnGroup"
		btnGroup.AnchorPoint = Vector2.new(1, 0.5)
		btnGroup.Position = UDim2.new(1, 0, 0.5, 0)
		btnGroup.Size = UDim2.new(0, 90, 0, 32)
		btnGroup.BackgroundTransparency = 1
		btnGroup.ZIndex = 42
		btnGroup.Parent = contentLayout

		local helpBtn = Instance.new("TextButton")
		helpBtn.Name = "HelpBtn"
		helpBtn.Size = UDim2.new(1, 0, 1, 0)
		helpBtn.BackgroundColor3 = Color3.fromRGB(30, 45, 70)
		helpBtn.BorderSizePixel = 0
		helpBtn.Font = Enum.Font.GothamBold
		helpBtn.Text = "❓ DETAIL"
		helpBtn.TextColor3 = Color3.fromRGB(220, 240, 255)
		helpBtn.TextSize = 11
		helpBtn.ZIndex = 43
		helpBtn.Parent = btnGroup
		Instance.new("UICorner", helpBtn).CornerRadius = UDim.new(0, 8)

		local hStroke = Instance.new("UIStroke")
		hStroke.Color = Color3.fromRGB(100, 160, 230)
		hStroke.Thickness = 1
		hStroke.Parent = helpBtn

		helpBtn.MouseButton1Click:Connect(function()
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.2)
			TutorialUI.ShowHelpGuide(targetGui, "BASICS")
		end)

		-- Animasi Pop-in Masuk
		pillContainer.Position = UDim2.new(0.5, 0, 0, 40)
		pillContainer.BackgroundTransparency = 1
		TweenService:Create(pillContainer, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 70),
			BackgroundTransparency = 0.15,
		}):Play()

		activeQuestPill = pillContainer
	else
		-- Update Konten Pill yang sudah ada
		local content = activeQuestPill:FindFirstChild("Content")
		if content then
			local iconFrame = content:FindFirstChild("IconFrame")
			local iconLabel = iconFrame and iconFrame:FindFirstChild("IconLabel")
			local titleLabel = content:FindFirstChild("TitleLabel")
			local descLabel = content:FindFirstChild("DescLabel")
			local pStroke = activeQuestPill:FindFirstChild("PillStroke")

			if iconLabel then iconLabel.Text = stepData.icon end
			if titleLabel then
				titleLabel.Text = stepData.title:upper()
				titleLabel.TextColor3 = stepData.color
			end
			if descLabel then
				descLabel.Text = customText or stepData.shortDesc
			end
			if pStroke then
				pStroke.Color = stepData.color
			end

			-- Flash pulse animasi saat step berganti
			activeQuestPill.Size = UDim2.new(0, 480, 0, 56)
			TweenService:Create(activeQuestPill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 460, 0, 52),
			}):Play()
		end
	end
end

function TutorialUI.HideQuestPill()
	if activeQuestPill and activeQuestPill.Parent then
		local pill = activeQuestPill
		activeQuestPill = nil
		local tween = TweenService:Create(pill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, 30),
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function()
			pill:Destroy()
		end)
	end
end

-- ============ 2. WELCOME ONBOARDING MODAL ============
function TutorialUI.ShowWelcomeModal(targetGui, onStartCallback, onSkipCallback)
	if activeWelcomeModal and activeWelcomeModal.Parent then return end
	if not targetGui then return end

	playSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.0)

	local overlay = Instance.new("Frame")
	overlay.Name = "TutorialWelcomeOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(5, 8, 14)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 60
	overlay.Parent = targetGui

	local modal = Instance.new("Frame")
	modal.Name = "WelcomeCard"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.new(0.5, 0, 0.55, 0)
	modal.Size = UDim2.new(0, 520, 0, 420)
	modal.BackgroundColor3 = Color3.fromRGB(15, 22, 36)
	modal.BackgroundTransparency = 0.05
	modal.BorderSizePixel = 0
	modal.ZIndex = 61
	modal.Parent = overlay
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 18)

	-- Responsive Auto-Fit untuk Layar HP / Tablet (FISH-037)
	MobileResponsiveHelper.AttachResponsiveScale(modal, 520, 420)

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = Color3.fromRGB(56, 189, 248)
	mStroke.Thickness = 2
	mStroke.Transparency = 0.2
	mStroke.Parent = modal

	-- Header Banner
	local headerBanner = Instance.new("Frame")
	headerBanner.Name = "HeaderBanner"
	headerBanner.Size = UDim2.new(1, 0, 0, 90)
	headerBanner.BackgroundColor3 = Color3.fromRGB(18, 30, 50)
	headerBanner.BorderSizePixel = 0
	headerBanner.ZIndex = 62
	headerBanner.Parent = modal
	Instance.new("UICorner", headerBanner).CornerRadius = UDim.new(0, 18)

	local avatarBadge = Instance.new("Frame")
	avatarBadge.Name = "AvatarBadge"
	avatarBadge.Size = UDim2.new(0, 56, 0, 56)
	avatarBadge.Position = UDim2.new(0, 20, 0.5, -28)
	avatarBadge.BackgroundColor3 = Color3.fromRGB(30, 50, 80)
	avatarBadge.BorderSizePixel = 0
	avatarBadge.ZIndex = 63
	avatarBadge.Parent = headerBanner
	Instance.new("UICorner", avatarBadge).CornerRadius = UDim.new(0, 14)

	local avatarIcon = Instance.new("TextLabel")
	avatarIcon.Size = UDim2.new(1, 0, 1, 0)
	avatarIcon.BackgroundTransparency = 1
	avatarIcon.Text = "🧙‍♂️"
	avatarIcon.TextSize = 30
	avatarIcon.ZIndex = 64
	avatarIcon.Parent = avatarBadge

	local titleStack = Instance.new("Frame")
	titleStack.Size = UDim2.new(1, -100, 1, 0)
	titleStack.Position = UDim2.new(0, 88, 0, 0)
	titleStack.BackgroundTransparency = 1
	titleStack.ZIndex = 63
	titleStack.Parent = headerBanner

	local superTitle = Instance.new("TextLabel")
	superTitle.Size = UDim2.new(1, 0, 0, 20)
	superTitle.Position = UDim2.new(0, 0, 0, 22)
	superTitle.BackgroundTransparency = 1
	superTitle.Font = Enum.Font.GothamBlack
	superTitle.Text = "KAPTEN HARMONI — TELUK MELODI"
	superTitle.TextColor3 = Color3.fromRGB(56, 189, 248)
	superTitle.TextSize = 12
	superTitle.TextXAlignment = Enum.TextXAlignment.Left
	superTitle.ZIndex = 64
	superTitle.Parent = titleStack

	local mainTitle = Instance.new("TextLabel")
	mainTitle.Size = UDim2.new(1, 0, 0, 26)
	mainTitle.Position = UDim2.new(0, 0, 0, 42)
	mainTitle.BackgroundTransparency = 1
	mainTitle.Font = Enum.Font.GothamBlack
	mainTitle.Text = "Selamat Datang di FISH!TUNE! 🎣🎵"
	mainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	mainTitle.TextSize = 18
	mainTitle.TextXAlignment = Enum.TextXAlignment.Left
	mainTitle.ZIndex = 64
	mainTitle.Parent = titleStack

	-- Dialogue Body Content
	local bodyFrame = Instance.new("Frame")
	bodyFrame.Size = UDim2.new(1, -40, 0, 200)
	bodyFrame.Position = UDim2.new(0, 20, 0, 105)
	bodyFrame.BackgroundTransparency = 1
	bodyFrame.ZIndex = 62
	bodyFrame.Parent = modal

	local dialogueText = Instance.new("TextLabel")
	dialogueText.Size = UDim2.new(1, 0, 0, 85)
	dialogueText.BackgroundTransparency = 1
	dialogueText.Font = Enum.Font.GothamMedium
	dialogueText.RichText = true
	dialogueText.Text = "<i>\"Ahoy, Nelayan Muda! Di samudera Teluk Melodi ini, ikan-ikan tidak hanya memakan umpan biasa—mereka berenang mendekat saat mendengar petikan melodi alat musikmu!\"</i>\n\nIkuti 4 langkah singkat untuk menguasai seni memancing harmoni dan raih hadiah starter!"
	dialogueText.TextColor3 = Color3.fromRGB(225, 235, 248)
	dialogueText.TextSize = 13
	dialogueText.TextWrapped = true
	dialogueText.TextXAlignment = Enum.TextXAlignment.Left
	dialogueText.TextYAlignment = Enum.TextYAlignment.Top
	dialogueText.ZIndex = 63
	dialogueText.Parent = bodyFrame

	-- Steps Feature List Preview
	local stepListFrame = Instance.new("Frame")
	stepListFrame.Size = UDim2.new(1, 0, 0, 100)
	stepListFrame.Position = UDim2.new(0, 0, 0, 95)
	stepListFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
	stepListFrame.BorderSizePixel = 0
	stepListFrame.ZIndex = 63
	stepListFrame.Parent = bodyFrame
	Instance.new("UICorner", stepListFrame).CornerRadius = UDim.new(0, 12)

	local sLayout = Instance.new("UIGridLayout")
	sLayout.CellSize = UDim2.new(0.5, -6, 0, 42)
	sLayout.CellPadding = UDim2.new(0, 12, 0, 8)
	sLayout.Parent = stepListFrame

	local sPad = Instance.new("UIPadding")
	sPad.PaddingTop = UDim.new(0, 8)
	sPad.PaddingBottom = UDim.new(0, 8)
	sPad.PaddingLeft = UDim.new(0, 10)
	sPad.PaddingRight = UDim.new(0, 10)
	sPad.Parent = stepListFrame

	local previewSteps = {
		{ icon = "🎣", title = "1. Lemparan Kail", desc = "Akurasi Zona Hijau" },
		{ icon = "🌊", title = "2. Sambaran Ikan", desc = "Tanda (!) di Pelampung" },
		{ icon = "🎹", title = "3. Minigame Ritme", desc = "Piano/Gitar/Drum Beats" },
		{ icon = "💰", title = "4. Jual & Raup Koin", desc = "Pasar & Upgrade Joran" },
	}

	for _, item in ipairs(previewSteps) do
		local cell = Instance.new("Frame")
		cell.BackgroundColor3 = Color3.fromRGB(18, 26, 42)
		cell.BorderSizePixel = 0
		cell.ZIndex = 64
		cell.Parent = stepListFrame
		Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 8)

		local cIcon = Instance.new("TextLabel")
		cIcon.Size = UDim2.new(0, 28, 1, 0)
		cIcon.Position = UDim2.new(0, 6, 0, 0)
		cIcon.BackgroundTransparency = 1
		cIcon.Text = item.icon
		cIcon.TextSize = 16
		cIcon.ZIndex = 65
		cIcon.Parent = cell

		local cTitle = Instance.new("TextLabel")
		cTitle.Size = UDim2.new(1, -38, 0, 16)
		cTitle.Position = UDim2.new(0, 36, 0, 4)
		cTitle.BackgroundTransparency = 1
		cTitle.Font = Enum.Font.GothamBold
		cTitle.Text = item.title
		cTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
		cTitle.TextSize = 11
		cTitle.TextXAlignment = Enum.TextXAlignment.Left
		cTitle.ZIndex = 65
		cTitle.Parent = cell

		local cDesc = Instance.new("TextLabel")
		cDesc.Size = UDim2.new(1, -38, 0, 14)
		cDesc.Position = UDim2.new(0, 36, 0, 20)
		cDesc.BackgroundTransparency = 1
		cDesc.Font = Enum.Font.Gotham
		cDesc.Text = item.desc
		cDesc.TextColor3 = Color3.fromRGB(148, 163, 184)
		cDesc.TextSize = 10
		cDesc.TextXAlignment = Enum.TextXAlignment.Left
		cDesc.ZIndex = 65
		cDesc.Parent = cell
	end

	-- Footer Action Buttons
	local footerFrame = Instance.new("Frame")
	footerFrame.Size = UDim2.new(1, -40, 0, 75)
	footerFrame.Position = UDim2.new(0, 20, 1, -85)
	footerFrame.BackgroundTransparency = 1
	footerFrame.ZIndex = 62
	footerFrame.Parent = modal

	local startBtn = Instance.new("TextButton")
	startBtn.Name = "StartTutorialBtn"
	startBtn.Size = UDim2.new(1, 0, 0, 42)
	startBtn.Position = UDim2.new(0, 0, 0, 0)
	startBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
	startBtn.BorderSizePixel = 0
	startBtn.Font = Enum.Font.GothamBlack
	startBtn.Text = "🎣 MULAI PETUALANGAN (TUTORIAL)"
	startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	startBtn.TextSize = 13
	startBtn.ZIndex = 64
	startBtn.Parent = footerFrame
	Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 12)

	local sBtnStroke = Instance.new("UIStroke")
	sBtnStroke.Color = Color3.fromRGB(134, 239, 172)
	sBtnStroke.Thickness = 1.6
	sBtnStroke.Parent = startBtn

	local skipBtn = Instance.new("TextButton")
	skipBtn.Name = "SkipTutorialBtn"
	skipBtn.Size = UDim2.new(1, 0, 0, 24)
	skipBtn.Position = UDim2.new(0, 0, 0, 48)
	skipBtn.BackgroundTransparency = 1
	skipBtn.Font = Enum.Font.GothamMedium
	skipBtn.Text = "⏩ Lewati Tutorial (Saya Sudah Paham Cara Bermain)"
	skipBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
	skipBtn.TextSize = 11
	skipBtn.ZIndex = 64
	skipBtn.Parent = footerFrame

	-- Close Animation Helper
	local function closeModal(callback)
		if isClosingModal then return end
		isClosingModal = true
		TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		local t = TweenService:Create(modal, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.6, 0),
			Size = UDim2.new(0, 480, 0, 380),
		})
		t:Play()
		t.Completed:Connect(function()
			overlay:Destroy()
			activeWelcomeModal = nil
			isClosingModal = false
			if callback then callback() end
		end)
	end

	startBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.6, 1.4)
		closeModal(function()
			if onStartCallback then
				onStartCallback()
			else
				TutorialUI.CreateOrUpdateQuestPill(targetGui, 1)
			end
		end)
	end)

	skipBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.4, 0.9)
		closeModal(function()
			if onSkipCallback then
				onSkipCallback()
			end
		end)
	end)

	-- Entrance Animation
	TweenService:Create(overlay, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.45,
	}):Play()
	TweenService:Create(modal, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()

	activeWelcomeModal = overlay
end

-- ============ 3. CELEBRATION COMPLETION MODAL ============
function TutorialUI.ShowCelebrationModal(targetGui, rewardData, onClaimCallback)
	if activeCelebrationModal and activeCelebrationModal.Parent then return end
	if not targetGui then return end

	playSound("rbxasset://sounds/electronicpingshort.wav", 0.8, 1.6)

	local overlay = Instance.new("Frame")
	overlay.Name = "TutorialCelebrationOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(5, 8, 14)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 65
	overlay.Parent = targetGui

	local modal = Instance.new("Frame")
	modal.Name = "CelebrationCard"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.new(0.5, 0, 0.55, 0)
	modal.Size = UDim2.new(0, 480, 0, 360)
	modal.BackgroundColor3 = Color3.fromRGB(15, 24, 38)
	modal.BackgroundTransparency = 0.05
	modal.BorderSizePixel = 0
	modal.ZIndex = 66
	modal.Parent = overlay
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 18)

	-- Responsive Auto-Fit untuk Layar HP / Tablet (FISH-037)
	MobileResponsiveHelper.AttachResponsiveScale(modal, 480, 360)

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = Color3.fromRGB(245, 158, 11)
	mStroke.Thickness = 2.4
	mStroke.Parent = modal

	-- Trophy Icon Header
	local trophyLabel = Instance.new("TextLabel")
	trophyLabel.Size = UDim2.new(1, 0, 0, 60)
	trophyLabel.Position = UDim2.new(0, 0, 0, 20)
	trophyLabel.BackgroundTransparency = 1
	trophyLabel.Text = "🏆"
	trophyLabel.TextSize = 48
	trophyLabel.ZIndex = 67
	trophyLabel.Parent = modal

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 28)
	titleLabel.Position = UDim2.new(0, 0, 0, 85)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = "TUTORIAL SELESAI!"
	titleLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
	titleLabel.TextSize = 22
	titleLabel.ZIndex = 67
	titleLabel.Parent = modal

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -40, 0, 40)
	descLabel.Position = UDim2.new(0, 20, 0, 118)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.GothamMedium
	descLabel.Text = "Luar biasa! Kamu telah menguasai seni memancing harmoni Teluk Melodi. Terimalah hadiah starter ini untuk memulai petualangan baharimu!"
	descLabel.TextColor3 = Color3.fromRGB(225, 235, 248)
	descLabel.TextSize = 12
	descLabel.TextWrapped = true
	descLabel.ZIndex = 67
	descLabel.Parent = modal

	-- Reward Box Container
	local rewardBox = Instance.new("Frame")
	rewardBox.Size = UDim2.new(1, -40, 0, 75)
	rewardBox.Position = UDim2.new(0, 20, 0, 168)
	rewardBox.BackgroundColor3 = Color3.fromRGB(10, 16, 26)
	rewardBox.BorderSizePixel = 0
	rewardBox.ZIndex = 67
	rewardBox.Parent = modal
	Instance.new("UICorner", rewardBox).CornerRadius = UDim.new(0, 12)

	local rLayout = Instance.new("UIListLayout")
	rLayout.FillDirection = Enum.FillDirection.Horizontal
	rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rLayout.Padding = UDim.new(0, 20)
	rLayout.Parent = rewardBox

	-- Item 1: Coins
	local coinItem = Instance.new("Frame")
	coinItem.Size = UDim2.new(0, 180, 0, 50)
	coinItem.BackgroundColor3 = Color3.fromRGB(20, 32, 50)
	coinItem.BorderSizePixel = 0
	coinItem.ZIndex = 68
	coinItem.Parent = rewardBox
	Instance.new("UICorner", coinItem).CornerRadius = UDim.new(0, 10)

	local cLabel = Instance.new("TextLabel")
	cLabel.Size = UDim2.new(1, 0, 1, 0)
	cLabel.BackgroundTransparency = 1
	cLabel.Font = Enum.Font.GothamBlack
	cLabel.RichText = true
	local coinsAmt = (rewardData and rewardData.coins) or 100
	cLabel.Text = string.format("💰 <b>+%d KOIN</b>", coinsAmt)
	cLabel.TextColor3 = Color3.fromRGB(251, 191, 36)
	cLabel.TextSize = 13
	cLabel.ZIndex = 69
	cLabel.Parent = coinItem

	-- Item 2: Bait
	local baitItem = Instance.new("Frame")
	baitItem.Size = UDim2.new(0, 180, 0, 50)
	baitItem.BackgroundColor3 = Color3.fromRGB(20, 32, 50)
	baitItem.BorderSizePixel = 0
	baitItem.ZIndex = 68
	baitItem.Parent = rewardBox
	Instance.new("UICorner", baitItem).CornerRadius = UDim.new(0, 10)

	local bLabel = Instance.new("TextLabel")
	bLabel.Size = UDim2.new(1, 0, 1, 0)
	bLabel.BackgroundTransparency = 1
	bLabel.Font = Enum.Font.GothamBlack
	bLabel.RichText = true
	local baitAmt = (rewardData and rewardData.baitCount) or 5
	bLabel.Text = string.format("🪱 <b>+%d UMPAN CACING</b>", baitAmt)
	bLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
	bLabel.TextSize = 12
	bLabel.ZIndex = 69
	bLabel.Parent = baitItem

	-- Claim Button
	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimRewardBtn"
	claimBtn.Size = UDim2.new(1, -40, 0, 48)
	claimBtn.Position = UDim2.new(0, 20, 1, -64)
	claimBtn.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
	claimBtn.BorderSizePixel = 0
	claimBtn.Font = Enum.Font.GothamBlack
	claimBtn.Text = "🎉 KLAIM HADIAH & JELAJAHI SAMUDRA"
	claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	claimBtn.TextSize = 13
	claimBtn.ZIndex = 68
	claimBtn.Parent = modal
	Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 12)

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(253, 224, 71)
	cStroke.Thickness = 1.6
	cStroke.Parent = claimBtn

	claimBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.7, 1.5)
		TutorialUI.HideQuestPill()
		TweenService:Create(overlay, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		local t = TweenService:Create(modal, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.6, 0),
			Size = UDim2.new(0, 440, 0, 320),
		})
		t:Play()
		t.Completed:Connect(function()
			overlay:Destroy()
			activeCelebrationModal = nil
			if onClaimCallback then onClaimCallback() end
		end)
	end)

	-- Entrance Animation
	TweenService:Create(overlay, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.45,
	}):Play()
	TweenService:Create(modal, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()

	activeCelebrationModal = overlay
end

-- ============ 4. INTERACTIVE HELP & REFERENCE MODAL ============
local HELP_TABS = {
	{
		id = "BASICS",
		title = "🎣 Dasar Mancing",
		content = {
			{
				header = "1. Lemparan Kail (Casting Meter)",
				body = "Arahkan kamera ke air dan tahan tombol mancing. Meter lemparan memiliki 3 zona: <b>GOOD (Biru)</b>, <b>GREAT (Cyan)</b>, dan <b>PERFECT (Hijau)</b>. Lepaskan saat indikator di zona PERFECT untuk jangkauan terjauh dan sambaran kilat!",
			},
			{
				header = "2. Waktu Tunggu & Sambaran (Bite)",
				body = "Saat pelampung mengapung, ikan akan mendekat. Tanda seru merah <b>(!)</b> dan percikan air menandakan ikan telah menyambar. Minigame ritme akan otomatis aktif.",
			},
			{
				header = "3. Sesi & Pembatalan",
				body = "Jika karakter bergerak terlalu jauh atau melompat keluar dari area memancing, sesi akan dibatalkan secara aman tanpa kehilangan umpan berlebih.",
			},
		},
	},
	{
		id = "INSTRUMENTS",
		title = "🎵 3 Instrumen",
		content = {
			{
				header = "🎹 Grand Piano (Level 1+)",
				body = "<b>Tipe:</b> Precision 4-Lanes.\n<b>Kontrol:</b> [A] [W] [S] [D] atau [D] [F] [J] [K] (juga mendukung Sentuhan & Klik Mouse).\nTekan tuts tepat saat not melodi menyentuh garis target bawah.",
			},
			{
				header = "🎸 Gitar Akustik & Elektrik (Level 2+)",
				body = "<b>Tipe:</b> Pattern / Sequence Fretboard.\n<b>Kontrol:</b> Fret 1–4 [1][2][3][4] atau [A][S][D][F].\nTekan urutan not fretboard yang menyala sebelum nada menghilang.",
			},
			{
				header = "🥁 Drum Perkusi & Synthwave (Level 4+)",
				body = "<b>Tipe:</b> Reaction Concentric Ring.\n<b>Kontrol:</b> [Spasi] / [Klik Kiri] / [Sentuh Layar].\nTekan ketukan saat lingkaran konsentris tepat menyatu dengan ring target di zona PERFECT.",
			},
		},
	},
	{
		id = "RARITY",
		title = "⭐ Kelangkaan & Pity",
		content = {
			{
				header = "Kanonikal Rarity Tiers",
				body = "<b>COMMON</b> (Abu-abu) ➔ <b>RARE</b> (Biru) ➔ <b>SUPER RARE</b> (Ungu) ➔ <b>LEGENDARY</b> (Emas) ➔ <b>MYTHIC</b> (Merah) ➔ <b>SPECIAL</b> (Pelangi).",
			},
			{
				header = "Sistem Garansi Pity 100%",
				body = "Setiap tangkapan tanpa ikan langka akan mengisi meteran Pity. Saat mencapai batas threshold, kamu dijamin mendapatkan ikan Legendary atau Mythic pada tangkapan berikutnya!",
			},
			{
				header = "Ikan Bermutasi (Special Mutations)",
				body = "Ikan langka berpeluang memiliki mutasi spesial: <b>Golden</b> (Nilai Jual 2.5x), <b>Rainbow</b> (EXP 3.0x), <b>Cosmic</b> (Pengganda 5.0x), dan <b>Shadow</b>.",
			},
		},
	},
	{
		id = "SHOP",
		title = "🏪 Toko & Ekonomi",
		content = {
			{
				header = "Menjual Hasil Tangkapan",
				body = "Buka menu Toko [K] atau dekati lapak Nelayan di dermaga. Kamu bisa menggunakan <b>[Jual Semua]</b> atau memilih ikan satu per satu.",
			},
			{
				header = "Proteksi Kunci Item (Lock)",
				body = "Klik ikon gembok 🔒 pada kartu ikan di Inventory untuk mengunci ikan favoritmu agar tidak sengaja terjual saat menekan 'Jual Semua'.",
			},
			{
				header = "Upgrade Kapasitas Tas & Joran",
				body = "Tingkatkan kapasitas tasmu dari 35 hingga 100 slot dan beli joran berkualitas tinggi untuk meningkatkan base Luck dan pengganda lemparan.",
			},
		},
	},
	{
		id = "HOTKEYS",
		title = "⌨️ Daftar Kontrol",
		content = {
			{
				header = "Navigasi Keyboard & Mouse (PC)",
				body = "• <b>[E] / [Klik Kiri] / [Spasi]</b>: Mancing & Kunci Lemparan\n• <b>[B] / [I]</b>: Buka/Tutup Inventory Tas\n• <b>[J]</b>: Buka/Tutup FishDex (Jurnal Tangkapan)\n• <b>[K]</b>: Buka Toko Samudra & Lapak Ikan\n• <b>[P] / [L]</b>: Buka Jalur Progresi & Roadmap Level\n• <b>[H]</b>: Buka Buku Panduan Bermain",
			},
			{
				header = "Navigasi Sentuh (Mobile / Tablet)",
				body = "Semua tombol aksi, tombol mancing, not ritme, dan menu samping kiri telah dioptimalkan secara responsif dengan tombol sentuh yang nyaman di jari.",
			},
		},
	},
}

function TutorialUI.IsOpen()
	return activeHelpModal ~= nil
end

function TutorialUI.HideHelpGuide(callback)
	if not activeHelpModal or isClosingModal then return end
	isClosingModal = true

	local overlay = activeHelpModal
	local modal = overlay:FindFirstChild("HelpCard")

	TweenService:Create(overlay, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	}):Play()

	if modal then
		local t = TweenService:Create(modal, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.55, 0),
			Size = UDim2.new(0, 680, 0, 440),
		})
		t:Play()
		t.Completed:Connect(function()
			overlay:Destroy()
			activeHelpModal = nil
			isClosingModal = false
			if callback then callback() end
		end)
	else
		overlay:Destroy()
		activeHelpModal = nil
		isClosingModal = false
	end
end

function TutorialUI.ToggleHelpGuide(targetGui, initialTab)
	if TutorialUI.IsOpen() then
		TutorialUI.HideHelpGuide()
	else
		TutorialUI.ShowHelpGuide(targetGui, initialTab)
	end
end

function TutorialUI.ShowHelpGuide(targetGui, initialTab)
	if activeHelpModal and activeHelpModal.Parent then return end
	if not targetGui then return end

	playSound("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.2)

	local selectedTabId = initialTab or "BASICS"

	local overlay = Instance.new("Frame")
	overlay.Name = "TutorialHelpOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(5, 8, 14)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 70
	overlay.Parent = targetGui

	local modal = Instance.new("Frame")
	modal.Name = "HelpCard"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.new(0.5, 0, 0.53, 0)
	modal.Size = UDim2.new(0, 720, 0, 480)
	modal.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	modal.BackgroundTransparency = 0.05
	modal.BorderSizePixel = 0
	modal.ZIndex = 71
	modal.Parent = overlay
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 16)

	-- Responsive Auto-Fit untuk Layar HP / Tablet (FISH-037)
	MobileResponsiveHelper.AttachResponsiveScale(modal, 720, 480)

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = Color3.fromRGB(56, 189, 248)
	mStroke.Thickness = 2
	mStroke.Parent = modal

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
	header.BorderSizePixel = 0
	header.ZIndex = 72
	header.Parent = modal
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

	local hTitle = Instance.new("TextLabel")
	hTitle.Size = UDim2.new(1, -80, 1, 0)
	hTitle.Position = UDim2.new(0, 20, 0, 0)
	hTitle.BackgroundTransparency = 1
	hTitle.Font = Enum.Font.GothamBlack
	hTitle.Text = "📖 BUKU PANDUAN NELAYAN TELUK MELODI"
	hTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	hTitle.TextSize = 16
	hTitle.TextXAlignment = Enum.TextXAlignment.Left
	hTitle.ZIndex = 73
	hTitle.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -48, 0.5, -18)
	closeBtn.BackgroundColor3 = Color3.fromRGB(30, 42, 64)
	closeBtn.BorderSizePixel = 0
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(220, 230, 245)
	closeBtn.TextSize = 16
	closeBtn.ZIndex = 73
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	closeBtn.MouseButton1Click:Connect(function()
		playSound("rbxasset://sounds/electronicpingshort.wav", 0.4, 0.9)
		TutorialUI.HideHelpGuide()
	end)

	-- Sidebar Tab List
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 190, 1, -72)
	sidebar.Position = UDim2.new(0, 16, 0, 64)
	sidebar.BackgroundColor3 = Color3.fromRGB(10, 16, 26)
	sidebar.BorderSizePixel = 0
	sidebar.ZIndex = 72
	sidebar.Parent = modal
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 12)

	local sLayout = Instance.new("UIListLayout")
	sLayout.FillDirection = Enum.FillDirection.Vertical
	sLayout.Padding = UDim.new(0, 6)
	sLayout.Parent = sidebar

	local sPad = Instance.new("UIPadding")
	sPad.PaddingTop = UDim.new(0, 8)
	sPad.PaddingBottom = UDim.new(0, 8)
	sPad.PaddingLeft = UDim.new(0, 8)
	sPad.PaddingRight = UDim.new(0, 8)
	sPad.Parent = sidebar

	-- Main Scroll Content Area
	local contentScroll = Instance.new("ScrollingFrame")
	contentScroll.Name = "ContentScroll"
	contentScroll.Size = UDim2.new(1, -238, 1, -72)
	contentScroll.Position = UDim2.new(0, 222, 0, 64)
	contentScroll.BackgroundColor3 = Color3.fromRGB(10, 16, 26)
	contentScroll.BorderSizePixel = 0
	contentScroll.ScrollBarThickness = 5
	contentScroll.ScrollBarImageColor3 = Color3.fromRGB(56, 189, 248)
	contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	contentScroll.ZIndex = 72
	contentScroll.Parent = modal
	Instance.new("UICorner", contentScroll).CornerRadius = UDim.new(0, 12)

	local cLayout = Instance.new("UIListLayout")
	cLayout.FillDirection = Enum.FillDirection.Vertical
	cLayout.Padding = UDim.new(0, 12)
	cLayout.Parent = contentScroll

	local cPad = Instance.new("UIPadding")
	cPad.PaddingTop = UDim.new(0, 14)
	cPad.PaddingBottom = UDim.new(0, 14)
	cPad.PaddingLeft = UDim.new(0, 14)
	cPad.PaddingRight = UDim.new(0, 14)
	cPad.Parent = contentScroll

	local tabButtons = {}

	local function renderTabContent(tabId)
		for _, child in ipairs(contentScroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local tabData = nil
		for _, tab in ipairs(HELP_TABS) do
			if tab.id == tabId then
				tabData = tab
				break
			end
		end
		if not tabData then return end

		for idx, section in ipairs(tabData.content) do
			local secCard = Instance.new("Frame")
			secCard.Name = "Section_" .. idx
			secCard.Size = UDim2.new(1, 0, 0, 0)
			secCard.AutomaticSize = Enum.AutomaticSize.Y
			secCard.BackgroundColor3 = Color3.fromRGB(18, 26, 42)
			secCard.BorderSizePixel = 0
			secCard.ZIndex = 73
			secCard.Parent = contentScroll
			Instance.new("UICorner", secCard).CornerRadius = UDim.new(0, 10)

			local cardPad = Instance.new("UIPadding")
			cardPad.PaddingTop = UDim.new(0, 10)
			cardPad.PaddingBottom = UDim.new(0, 10)
			cardPad.PaddingLeft = UDim.new(0, 12)
			cardPad.PaddingRight = UDim.new(0, 12)
			cardPad.Parent = secCard

			local cardTitle = Instance.new("TextLabel")
			cardTitle.Size = UDim2.new(1, 0, 0, 20)
			cardTitle.BackgroundTransparency = 1
			cardTitle.Font = Enum.Font.GothamBold
			cardTitle.Text = section.header
			cardTitle.TextColor3 = Color3.fromRGB(56, 189, 248)
			cardTitle.TextSize = 13
			cardTitle.TextXAlignment = Enum.TextXAlignment.Left
			cardTitle.ZIndex = 74
			cardTitle.Parent = secCard

			local cardBody = Instance.new("TextLabel")
			cardBody.Size = UDim2.new(1, 0, 0, 0)
			cardBody.Position = UDim2.new(0, 0, 0, 24)
			cardBody.AutomaticSize = Enum.AutomaticSize.Y
			cardBody.BackgroundTransparency = 1
			cardBody.Font = Enum.Font.GothamMedium
			cardBody.RichText = true
			cardBody.Text = section.body
			cardBody.TextColor3 = Color3.fromRGB(225, 235, 248)
			cardBody.TextSize = 11.5
			cardBody.TextWrapped = true
			cardBody.TextXAlignment = Enum.TextXAlignment.Left
			cardBody.ZIndex = 74
			cardBody.Parent = secCard
		end
	end

	-- Buat Sidebar Tab Buttons
	for _, tab in ipairs(HELP_TABS) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Tab_" .. tab.id
		tabBtn.Size = UDim2.new(1, 0, 0, 36)
		tabBtn.BackgroundColor3 = (tab.id == selectedTabId) and Color3.fromRGB(30, 48, 76) or Color3.fromRGB(15, 22, 34)
		tabBtn.BorderSizePixel = 0
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.Text = "  " .. tab.title
		tabBtn.TextColor3 = (tab.id == selectedTabId) and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(160, 175, 200)
		tabBtn.TextSize = 11.5
		tabBtn.TextXAlignment = Enum.TextXAlignment.Left
		tabBtn.ZIndex = 73
		tabBtn.Parent = sidebar
		Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

		tabButtons[tab.id] = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			playSound("rbxasset://sounds/electronicpingshort.wav", 0.4, 1.3)
			selectedTabId = tab.id
			for id, btn in pairs(tabButtons) do
				local isActive = (id == selectedTabId)
				btn.BackgroundColor3 = isActive and Color3.fromRGB(30, 48, 76) or Color3.fromRGB(15, 22, 34)
				btn.TextColor3 = isActive and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(160, 175, 200)
			end
			renderTabContent(selectedTabId)
		end)
	end

	renderTabContent(selectedTabId)

	-- Entrance Animation
	TweenService:Create(overlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.4,
	}):Play()
	TweenService:Create(modal, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}):Play()

	activeHelpModal = overlay
end

return TutorialUI
