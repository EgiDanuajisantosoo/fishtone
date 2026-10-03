--[[
	ZoneController (LocalScript)
	FISH!TUNE — Client Zone Detection & Immersion Controller (FISH-006)

	Mengelola pengalaman imersif zona di sisi client:
	1. Mendeteksi posisi pemain secara real-time berdasarkan ZoneConfig.
	2. Menampilkan banner transisi zona bernuansa Glassmorphism yang halus saat memasuki wilayah baru.
	3. Memberikan feedback visual level minimal & tema zona kepada pemain.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZoneConfig = require(Shared:WaitForChild("Config"):WaitForChild("ZoneConfig"))

local pGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)

-- ============ GUI CREATION ============
local gui = pGui:FindFirstChild("ZoneBannerGui")
if gui then
	gui:Destroy()
end

gui = Instance.new("ScreenGui")
gui.Name = "ZoneBannerGui"
gui.ResetOnSpawn = false
gui.Enabled = true
gui.Parent = pGui

local bannerFrame = Instance.new("Frame")
bannerFrame.Name = "ZoneBanner"
bannerFrame.Size = UDim2.new(0, 360, 0, 68)
bannerFrame.Position = UDim2.new(0.5, -180, -0.15, 0) -- Hidden above screen
bannerFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 32)
bannerFrame.BackgroundTransparency = 0.2
bannerFrame.BorderSizePixel = 0
bannerFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = bannerFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 200, 255)
stroke.Transparency = 0.4
stroke.Thickness = 1.5
stroke.Parent = bannerFrame

local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "ZoneIcon"
iconLabel.Size = UDim2.new(0, 48, 1, 0)
iconLabel.Position = UDim2.new(0, 10, 0, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "⚓"
iconLabel.TextSize = 32
iconLabel.Font = Enum.Font.GothamBlack
iconLabel.Parent = bannerFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "ZoneTitle"
titleLabel.Size = UDim2.new(1, -70, 0, 28)
titleLabel.Position = UDim2.new(0, 62, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MELODY BAY"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 18
titleLabel.Parent = bannerFrame

local subLabel = Instance.new("TextLabel")
subLabel.Name = "ZoneSubtitle"
subLabel.Size = UDim2.new(1, -70, 0, 22)
subLabel.Position = UDim2.new(0, 62, 0, 34)
subLabel.BackgroundTransparency = 1
subLabel.Text = "Dermaga Harmoni & Zona Pemula (Lv. 1+)"
subLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.Font = Enum.Font.GothamMedium
subLabel.TextSize = 12
subLabel.Parent = bannerFrame

-- ============ TRANSITION ANIMATIONS ============
local currentZoneId = nil
local isAnimating = false

local function showZoneBanner(zone)
	if not zone or zone.id == currentZoneId then return end
	currentZoneId = zone.id

	iconLabel.Text = zone.badgeIcon or "⚓"
	titleLabel.Text = string.upper(zone.displayName or "MELODY BAY")
	titleLabel.TextColor3 = zone.themeColor or Color3.fromRGB(255, 255, 255)
	stroke.Color = zone.themeColor or Color3.fromRGB(0, 200, 255)

	local levelText = zone.minLevel and string.format(" (Lv. %d+)", zone.minLevel) or ""
	subLabel.Text = (zone.subtitle or "") .. levelText

	-- Animasi Muncul ke Layar
	bannerFrame.Position = UDim2.new(0.5, -180, -0.15, 0)
	local tweenIn = TweenService:Create(
		bannerFrame,
		TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -180, 0.03, 0) }
	)
	tweenIn:Play()

	-- Suara Ding Notifikasi Lembut
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = 0.5
	sound.PlaybackSpeed = 1.9
	sound.Parent = Workspace
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 2)

	-- Hilang Otomatis setelah 4 Detik
	task.delay(4.0, function()
		if currentZoneId == zone.id then
			local tweenOut = TweenService:Create(
				bannerFrame,
				TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, -180, -0.15, 0) }
			)
			tweenOut:Play()
		end
	end)
end

-- ============ DETECTION LOOP ============
task.spawn(function()
	while true do
		task.wait(1.0)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local zone = ZoneConfig.GetZoneAtPosition(hrp.Position)
			if zone and zone.id ~= currentZoneId then
				showZoneBanner(zone)
			end
		end
	end
end)

print("[ZoneController] Inisialisasi Zone Controller selesai.")
