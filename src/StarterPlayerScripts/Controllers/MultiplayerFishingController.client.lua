--[[
	MultiplayerFishingController (Client Controller)
	FISH!TUNE — Real-time Multiplayer Fishing Presence & Global Announcements (FISH-038)

	Fitur Utama:
	1. Multiplayer Fishing Visual Presence:
	   - Mendeteksi kail pelampung (Bobber) pemain lain yang tereplikasi di workspace.FishingBobbers.
	   - Merender tali pancing lengkung (Curved Beam Fishing Line) dari ujung joran pemain lain ke pelampung mereka.
	   - Memainkan visual riak air & hentakan pelampung saat ikan menyambar kail pemain lain (Phase: "Biting").
	   - Membersihkan tali dan efek secara bersih saat pemain lain menyelesaikan memancing, membatalkan, atau meninggalkan server.
	2. Global Catch Celebration Broadcast (Kabar Samudra Raya):
	   - Mendengarkan event GLOBAL_CATCH_ANNOUNCEMENT dari server saat pemain lain menangkap ikan langka
	     (LEGENDARY, MYTHIC, SPECIAL, atau varian Mutasi Berharga).
	   - Menampilkan banner pop-up glassmorphism modern di bagian atas layar dengan aksen warna rarity,
	     audio fanfare perayaan, dan pesan resmi di sistem Chat Roblox.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

local localPlayer = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteContract = require(Shared:WaitForChild("Network"):WaitForChild("RemoteContract"))
local VisualEffectsSystem = require(Shared:WaitForChild("Systems"):WaitForChild("VisualEffectsSystem"))
local AudioEffectsSystem = require(Shared:WaitForChild("Systems"):WaitForChild("AudioEffectsSystem"))

local MultiplayerFishingController = {}

-- State pelacakan tali pancing pemain lain: [userId] = { beam, att0, att1, char, bobber, conn }
local otherPlayerLines = {}

-- ============ 1. MULTIPLAYER FISHING LINE & BOBBER SYNC ============

local function isRodTool(tool)
	if not tool or not tool:IsA("Tool") then return false end
	if tool:GetAttribute("IsFish") == true or tool:GetAttribute("IsLoot") == true then return false end
	local name = tool.Name:lower()
	return tool:GetAttribute("IsRod") == true or name:find("rod") ~= nil or name:find("pancing") ~= nil or name:find("joran") ~= nil
end

local function getCharacterRodPart(character)
	if not character then return nil end
	for _, child in ipairs(character:GetChildren()) do
		if isRodTool(child) then
			local rodPart = child:FindFirstChild("Rod") or child:FindFirstChild("Handle") or child:FindFirstChild("Line") or child:FindFirstChildWhichIsA("BasePart")
			if rodPart then return rodPart end
		end
	end
	return nil
end

local function removeOtherPlayerLine(userId)
	local record = otherPlayerLines[userId]
	if record then
		if record.conn then pcall(function() record.conn:Disconnect() end) end
		if record.beam and record.beam.Parent then pcall(function() record.beam:Destroy() end) end
		if record.att0 and record.att0.Parent then pcall(function() record.att0:Destroy() end) end
		if record.att1 and record.att1.Parent then pcall(function() record.att1:Destroy() end) end
		otherPlayerLines[userId] = nil
	end
end

local function attachOtherPlayerLine(otherPlayer, bobberPart)
	if not otherPlayer or not bobberPart or not bobberPart.Parent then return end
	local userId = otherPlayer.UserId
	removeOtherPlayerLine(userId)

	local char = otherPlayer.Character
	if not char then return end

	local rodPart = getCharacterRodPart(char)
	if not rodPart then return end

	-- Attachment pada ujung joran
	local att0 = rodPart:FindFirstChild("OtherRodTipAttachment")
	if not att0 then
		att0 = Instance.new("Attachment")
		att0.Name = "OtherRodTipAttachment"
		att0.Position = Vector3.new(0, rodPart.Size.Y / 2, 0)
		att0.Parent = rodPart
	end

	-- Attachment pada pelampung
	local att1 = bobberPart:FindFirstChild("BobberAttachment")
	if not att1 then
		att1 = Instance.new("Attachment")
		att1.Name = "BobberAttachment"
		att1.Position = Vector3.new(0, 0.4, 0)
		att1.Parent = bobberPart
	end

	-- Tali pancing lengkung dinamis (Beam)
	local beam = Instance.new("Beam")
	beam.Name = "OtherFishingLineBeam"
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = 0.04
	beam.Width1 = 0.04
	beam.Color = ColorSequence.new(Color3.fromRGB(225, 235, 255))
	beam.Transparency = NumberSequence.new(0.3)
	beam.FaceCamera = true
	beam.CurveSize0 = -1.2
	beam.CurveSize1 = 1.2
	beam.Segments = 16
	beam.Parent = rodPart

	local record = {
		beam = beam,
		att0 = att0,
		att1 = att1,
		char = char,
		bobber = bobberPart,
	}

	-- Dengarkan perubahan status pelampung (misal saat ikan menyambar)
	record.conn = bobberPart:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = bobberPart:GetAttribute("Phase")
		if phase == "Biting" then
			-- Visual cipratan air saat kail pemain lain ditarik ikan
			VisualEffectsSystem.CreateWaterSplash(bobberPart.Position, nil, 0.75)
			TweenService:Create(bobberPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = bobberPart.Position - Vector3.new(0, 0.8, 0)
			}):Play()
		end
	end)

	-- Bersihkan tali otomatis jika pelampung dihancurkan
	bobberPart.Destroying:Once(function()
		removeOtherPlayerLine(userId)
	end)

	otherPlayerLines[userId] = record
end

local function setupBobberWatcher()
	local function onBobberAdded(bobber)
		if not bobber:IsA("BasePart") then return end
		local ownerUserId = bobber:GetAttribute("OwnerUserId")
		if not ownerUserId or ownerUserId == localPlayer.UserId then
			return
		end

		local otherPlayer = Players:GetPlayerByUserId(ownerUserId)
		if not otherPlayer then
			task.spawn(function()
				for _ = 1, 10 do
					task.wait(0.5)
					otherPlayer = Players:GetPlayerByUserId(ownerUserId)
					if otherPlayer then break end
				end
				if otherPlayer and bobber.Parent then
					attachOtherPlayerLine(otherPlayer, bobber)
				end
			end)
		else
			attachOtherPlayerLine(otherPlayer, bobber)
		end
	end

	local function watchFolder(folder)
		if not folder then return end
		for _, child in ipairs(folder:GetChildren()) do
			task.spawn(onBobberAdded, child)
		end
		folder.ChildAdded:Connect(onBobberAdded)
		folder.ChildRemoved:Connect(function(child)
			local uId = child:GetAttribute("OwnerUserId")
			if uId and uId ~= localPlayer.UserId then
				removeOtherPlayerLine(uId)
			end
		end)
	end

	local bobbersFolder = workspace:FindFirstChild("FishingBobbers")
	if bobbersFolder then
		watchFolder(bobbersFolder)
	else
		workspace.ChildAdded:Connect(function(child)
			if child.Name == "FishingBobbers" then
				watchFolder(child)
			end
		end)
	end

	-- Pantau perubahan karakter pemain lain (misal unequip joran atau respawn)
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.3)
			local bFolder = workspace:FindFirstChild("FishingBobbers")
			if bFolder then
				local existing = bFolder:FindFirstChild("Bobber_" .. tostring(p.UserId))
				if existing then
					attachOtherPlayerLine(p, existing)
				end
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(p)
		removeOtherPlayerLine(p.UserId)
	end)
end

-- ============ 2. GLOBAL CATCH ANNOUNCEMENT BANNER ============

local announceQueue = {}
local isShowingAnnounce = false

local function showNextAnnouncement()
	if isShowingAnnounce or #announceQueue == 0 then return end
	isShowingAnnounce = true

	local data = table.remove(announceQueue, 1)
	local playerName = data.playerName or "Seseorang"
	local fish = data.fishData or {}

	local rarity = tostring(fish.rarity or "RARE"):upper()
	local fishName = fish.name or "Ikan Langka"
	local weight = tonumber(fish.weight) or 1.0
	local stars = fish.stars or "⭐⭐⭐"
	local isMutated = fish.isMutated == true
	local mutationPrefix = isMutated and (fish.mutationPrefix or "[MUTASI] ") or ""

	local rarityColors = {
		RARE = Color3.fromRGB(0, 215, 255),
		SUPER_RARE = Color3.fromRGB(185, 90, 255),
		LEGENDARY = Color3.fromRGB(255, 215, 0),
		MYTHIC = Color3.fromRGB(255, 50, 80),
		SPECIAL = Color3.fromRGB(255, 80, 220),
	}
	local accentColor = rarityColors[rarity] or Color3.fromRGB(255, 215, 0)
	local hexColor = string.format("#%02X%02X%02X", math.floor(accentColor.R * 255), math.floor(accentColor.G * 255), math.floor(accentColor.B * 255))

	-- Buat UI Banner Pengumuman
	local pGui = localPlayer:FindFirstChild("PlayerGui")
	if not pGui then
		isShowingAnnounce = false
		return
	end

	local announceGui = pGui:FindFirstChild("GlobalAnnounceGui")
	if not announceGui then
		announceGui = Instance.new("ScreenGui")
		announceGui.Name = "GlobalAnnounceGui"
		announceGui.ResetOnSpawn = false
		announceGui.DisplayOrder = 35
		announceGui.Parent = pGui
	end

	local banner = Instance.new("Frame")
	banner.Name = "AnnounceBanner"
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Size = UDim2.new(0, 480, 0, 68)
	banner.Position = UDim2.new(0.5, 0, -0.15, 0) -- Mulai di luar atas layar
	banner.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
	banner.BackgroundTransparency = 0.12
	banner.BorderSizePixel = 0
	banner.ZIndex = 50
	banner.Parent = announceGui
	Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 14)

	local stroke = Instance.new("UIStroke")
	stroke.Color = accentColor
	stroke.Thickness = 2
	stroke.Transparency = 0.2
	stroke.Parent = banner

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 48, 1, 0)
	iconLabel.Position = UDim2.new(0, 12, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = (rarity == "SPECIAL" and "👑") or (rarity == "MYTHIC" and "🔥") or "🌟"
	iconLabel.TextSize = 30
	iconLabel.ZIndex = 51
	iconLabel.Parent = banner

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -70, 0, 22)
	titleLabel.Position = UDim2.new(0, 60, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.RichText = true
	titleLabel.Text = string.format("<b><font color=\"#FBBF24\">🌟 KABAR SAMUDRA RAYA</font></b> • <font color=\"#94A3B8\">Tangkapan Spesial!</font>")
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 51
	titleLabel.Parent = banner

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -70, 0, 26)
	descLabel.Position = UDim2.new(0, 60, 0, 32)
	descLabel.BackgroundTransparency = 1
	descLabel.RichText = true
	descLabel.Text = string.format("<font color=\"#38BDF8\"><b>%s</b></font> berhasil mengangkat <font color=\"%s\"><b>%s%s</b></font> (%s) • <b>%.1f kg</b>!", playerName, hexColor, mutationPrefix, fishName, rarity, weight)
	descLabel.Font = Enum.Font.GothamMedium
	descLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	descLabel.TextSize = 12
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 51
	descLabel.Parent = banner

	-- Audio Fanfare Perayaan Lintas Server (FISH-036 / FISH-038)
	AudioEffectsSystem.PlayCatchFanfare(rarity, "S+")

	-- Kirim pesan ke Roblox Chat System
	pcall(function()
		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = string.format("🌊 [KABAR SAMUDRA] %s berhasil menangkap %s%s (%s ⭐) seberat %.1f kg!", playerName, mutationPrefix, fishName, rarity, weight),
			Color = accentColor,
			Font = Enum.Font.GothamBold,
			FontSize = Enum.FontSize.Size18,
		})
	end)

	-- Animasi Masuk (Drop Down Back)
	local tweenIn = TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.05, 0)
	})
	tweenIn:Play()

	-- Tahan selama 4.5 detik lalu Animasi Keluar
	task.delay(4.5, function()
		if banner and banner.Parent then
			local tweenOut = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, -0.15, 0),
				BackgroundTransparency = 1,
			})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				banner:Destroy()
				isShowingAnnounce = false
				task.wait(0.3)
				showNextAnnouncement()
			end)
		else
			isShowingAnnounce = false
			showNextAnnouncement()
		end
	end)
end

local function onGlobalCatchAnnouncement(playerName, fishData)
	table.insert(announceQueue, {
		playerName = playerName,
		fishData = fishData,
	})
	showNextAnnouncement()
end

-- ============ 3. INISIALISASI CONTROLLER ============
function MultiplayerFishingController.Init()
	setupBobberWatcher()

	-- Pasang listener remote broadcast
	local remote = RemoteContract.GetRemote()
	if remote then
		remote.OnClientEvent:Connect(function(action, arg1, arg2)
			if action == RemoteContract.S2C.GLOBAL_CATCH_ANNOUNCEMENT then
				onGlobalCatchAnnouncement(arg1, arg2)
			end
		end)
	end

	print("[MultiplayerFishingController] Inisialisasi Multiplayer Fishing Controller selesai (FISH-038).")
end

task.spawn(function()
	MultiplayerFishingController.Init()
end)

return MultiplayerFishingController
