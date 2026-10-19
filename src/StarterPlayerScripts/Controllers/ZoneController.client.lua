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
local Debris = game:GetService("Debris")

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
bannerFrame.Size = UDim2.new(0, 420, 0, 72)
bannerFrame.Position = UDim2.new(0.5, -210, -0.15, 0) -- Hidden above screen
bannerFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
bannerFrame.BackgroundTransparency = 0.15
bannerFrame.BorderSizePixel = 0
bannerFrame.Parent = gui
Instance.new("UICorner", bannerFrame).CornerRadius = UDim.new(0, 16)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 200, 255)
stroke.Transparency = 0.3
stroke.Thickness = 1.8
stroke.Parent = bannerFrame

local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 220, 255)),
})
bgGradient.Parent = bannerFrame

local iconBadge = Instance.new("Frame")
iconBadge.Name = "IconBadge"
iconBadge.Size = UDim2.new(0, 52, 0, 52)
iconBadge.Position = UDim2.new(0, 10, 0.5, -26)
iconBadge.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
iconBadge.BorderSizePixel = 0
iconBadge.Parent = bannerFrame
Instance.new("UICorner", iconBadge).CornerRadius = UDim.new(0, 12)

local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "ZoneIcon"
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "⚓"
iconLabel.TextSize = 28
iconLabel.Parent = iconBadge

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "ZoneTitle"
titleLabel.Size = UDim2.new(1, -78, 0, 26)
titleLabel.Position = UDim2.new(0, 70, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MELODY BAY"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 17
titleLabel.Parent = bannerFrame

local subLabel = Instance.new("TextLabel")
subLabel.Name = "ZoneSubtitle"
subLabel.Size = UDim2.new(1, -78, 0, 22)
subLabel.Position = UDim2.new(0, 70, 0, 36)
subLabel.BackgroundTransparency = 1
subLabel.Text = "Dermaga Harmoni & Zona Pemula (Lv. 1+)"
subLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.Font = Enum.Font.GothamMedium
subLabel.TextSize = 11.5
subLabel.Parent = bannerFrame

-- ============ TRANSITION ANIMATIONS ============
-- ============ SOUND & ANIMATION POOL ============
local SoundService = game:GetService("SoundService")
local notificationSound = Instance.new("Sound")
notificationSound.Name = "ZoneTransitionSound"
notificationSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
notificationSound.Volume = 0.4
notificationSound.PlaybackSpeed = 1.6
notificationSound.Parent = SoundService

local currentZoneId = nil
local activeBannerTween = nil
local bannerHideToken = 0

local function showZoneBanner(zone)
	if not zone then return end

	iconLabel.Text = zone.badgeIcon or "⚓"
	titleLabel.Text = string.upper(zone.displayName or "MELODY BAY")
	titleLabel.TextColor3 = zone.themeColor or Color3.fromRGB(255, 255, 255)
	stroke.Color = zone.themeColor or Color3.fromRGB(0, 200, 255)

	local levelText = zone.minLevel and string.format(" • Min. Lv. %d", zone.minLevel) or ""
	local luckText = (zone.luckBonus and zone.luckBonus > 0) and string.format(" [🍀 +%d Luck]", zone.luckBonus) or ""
	subLabel.Text = string.format("%s%s%s", zone.subtitle or "", levelText, luckText)

	-- Batalkan tween banner sebelumnya jika masih berjalan
	if activeBannerTween then
		pcall(function() activeBannerTween:Cancel() end)
		activeBannerTween = nil
	end

	-- Animasi Muncul ke Layar
	bannerFrame.Position = UDim2.new(0.5, -210, -0.15, 0)
	activeBannerTween = TweenService:Create(
		bannerFrame,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -210, 0.035, 0) }
	)
	activeBannerTween:Play()

	-- Suara Ding Notifikasi Menggunakan Instance Pool (0% Memory Leak)
	notificationSound:Play()

	-- Hilang Otomatis setelah 4 Detik dengan Validasi Token Unik
	bannerHideToken = bannerHideToken + 1
	local myToken = bannerHideToken

	task.delay(4.0, function()
		if bannerHideToken == myToken then
			activeBannerTween = TweenService:Create(
				bannerFrame,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, -210, -0.15, 0) }
			)
			activeBannerTween:Play()
		end
	end)
end

-- ============ DETECTION LOOP WITH HYSTERESIS & DEBOUNCE (0% LAG / 0% FLAPPING) ============
task.spawn(function()
	print("🌊 [ZoneController v2.1] Aktif dengan Anti-Flapping Hysteresis & Direct Environment Sync.")

	local pendingZone = nil
	local pendingZoneVotes = 0
	local lastTransitionTime = 0
	local TRANSITION_COOLDOWN = 3.0 -- Cooldown minimal 3 detik antar transisi zona

	while true do
		task.wait(1.0)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local detectedZone = ZoneConfig.GetZoneAtPosition(hrp.Position)
			if detectedZone then
				if currentZoneId == nil then
					-- Inisialisasi awal saat pertama kali spawn
					currentZoneId = detectedZone.id
					showZoneBanner(detectedZone)
				elseif detectedZone.id ~= currentZoneId then
					local now = os.clock()
					if (now - lastTransitionTime) >= TRANSITION_COOLDOWN then
						if pendingZone and pendingZone.id == detectedZone.id then
							pendingZoneVotes = pendingZoneVotes + 1
						else
							pendingZone = detectedZone
							pendingZoneVotes = 1
						end

						-- Hysteresis: Karakter harus berada di zona baru minimal 2x deteksi berturut-turut
						if pendingZoneVotes >= 2 then
							currentZoneId = detectedZone.id
							lastTransitionTime = now
							pendingZone = nil
							pendingZoneVotes = 0

							print(string.format("🗺️ [ZoneController] Zona Terkonfirmasi: %s (%s) di Posisi: (%.1f, %.1f, %.1f)", 
								tostring(detectedZone.displayName), tostring(detectedZone.id), hrp.Position.X, hrp.Position.Y, hrp.Position.Z))

							showZoneBanner(detectedZone)

							-- Notifikasi EnvironmentController secara langsung & sinkron
							local envCtrl = script.Parent:FindFirstChild("EnvironmentController")
							if envCtrl then
								local ok, mod = pcall(require, envCtrl)
								if ok and mod and mod.OnZoneChanged then
									mod.OnZoneChanged(detectedZone, 2.0)
								end
							end
						end
					end
				else
					-- Pemain stabil di zona saat ini, reset pending vote
					pendingZone = nil
					pendingZoneVotes = 0
				end
			end
		end
	end
end)

print("[ZoneController] Inisialisasi Zone Controller selesai.")
