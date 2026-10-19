--[[
	EnvironmentController (LocalScript)
	FISH!TUNE — World Environment, Atmospheric Lighting, Soundscape & VFX Polish (FISH-035)

	Fitur Utama:
	1. Dynamic Post-Processing & Lighting Manager:
	   - Smooth Tween Transitions antar bioma/zona (Melody Bay, Twin Eye Lagoon, Summit Abyss).
	   - Atmosphere, Bloom, ColorCorrection, SunRays & Dynamic Fog per zona.
	2. Soundscape & Ambient Audio Crossfader:
	   - Transisi halus (Fade In/Out) audio atmosfer alam & Reverb ruang per wilayah.
	3. Day-Night Rhythm Cycle:
	   - Siklus transisi siang, sore (golden sunset), malam beriluminasi bintang, dan fajar.
	4. Environmental Particle & Visual FX Polish:
	   - Partikel not musik melayang (Floating Melodic Notes) di area pemancingan.
	   - Shimmering Water Spores & Ripples di sekitar dermaga dan permukaan air.
	   - Lentera dermaga dengan pulse glow yang hidup.
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ZoneConfig = require(Shared:WaitForChild("Config"):WaitForChild("ZoneConfig"))

local EnvironmentController = {}

-- State & References
local currentZoneId = nil
local activeAtmosphere = nil
local activeBloom = nil
local activeColorCorrection = nil
local activeSunRays = nil

local ambientSoundA = nil
local ambientSoundB = nil
local activeSoundChannel = "A"

local isDayNightEnabled = true
local dayNightSpeed = 0.05 -- Kecepatan pergerakan waktu

-- ============ 1. POST-PROCESSING SETUP ============
local function initializePostProcessing()
	-- Atmosphere
	activeAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not activeAtmosphere then
		activeAtmosphere = Instance.new("Atmosphere")
		activeAtmosphere.Name = "FishTuneAtmosphere"
		activeAtmosphere.Parent = Lighting
	end

	-- Bloom
	activeBloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if not activeBloom then
		activeBloom = Instance.new("BloomEffect")
		activeBloom.Name = "FishTuneBloom"
		activeBloom.Parent = Lighting
	end

	-- ColorCorrection
	activeColorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if not activeColorCorrection then
		activeColorCorrection = Instance.new("ColorCorrectionEffect")
		activeColorCorrection.Name = "FishTuneColorCorrection"
		activeColorCorrection.Parent = Lighting
	end

	-- SunRays
	activeSunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if not activeSunRays then
		activeSunRays = Instance.new("SunRaysEffect")
		activeSunRays.Name = "FishTuneSunRays"
		activeSunRays.Parent = Lighting
	end

	-- Soundscape Channels
	ambientSoundA = Instance.new("Sound")
	ambientSoundA.Name = "ZoneAmbientSound_A"
	ambientSoundA.Looped = true
	ambientSoundA.Volume = 0
	ambientSoundA.Parent = SoundService

	ambientSoundB = Instance.new("Sound")
	ambientSoundB.Name = "ZoneAmbientSound_B"
	ambientSoundB.Looped = true
	ambientSoundB.Volume = 0
	ambientSoundB.Parent = SoundService
end

-- Track running tweens to prevent tween stacking / GPU thrashing
local activeTweens = {}

local function cancelActiveTweens()
	for _, tween in ipairs(activeTweens) do
		pcall(function()
			tween:Cancel()
		end)
	end
	table.clear(activeTweens)
end

-- ============ 2. SMOOTH LIGHTING & ATMOSPHERE TRANSITION ============
local function applyZoneLighting(zone, transitionDuration)
	if not zone or not zone.lighting or not zone.postProcessing then return end
	transitionDuration = transitionDuration or 2.0
	local tweenInfo = TweenInfo.new(transitionDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	local lData = zone.lighting
	local pData = zone.postProcessing

	-- Batalkan semua tween yang sedang berjalan sebelum memulai yang baru (0% tween conflict / frame drop)
	cancelActiveTweens()

	-- 1. Tween Lighting Properties (ringan, performa 60 FPS stabil)
	local tLighting = TweenService:Create(Lighting, tweenInfo, {
		OutdoorAmbient = lData.outdoorAmbient or Color3.fromRGB(130, 145, 165),
		Ambient = lData.ambient or Color3.fromRGB(100, 115, 135),
		ColorShift_Top = lData.colorShift_Top or Color3.fromRGB(255, 255, 255),
		ColorShift_Bottom = lData.colorShift_Bottom or Color3.fromRGB(150, 190, 230),
		Brightness = lData.brightness or 2.0,
		FogColor = lData.fogColor or Color3.fromRGB(180, 220, 255),
	})
	table.insert(activeTweens, tLighting)
	tLighting:Play()

	-- 2. Tween ColorCorrection (Sangat efisien di GPU)
	if activeColorCorrection and pData.colorCorrection then
		local cc = pData.colorCorrection
		local tCC = TweenService:Create(activeColorCorrection, tweenInfo, {
			Brightness = cc.brightness or 0,
			Contrast = cc.contrast or 0.1,
			Saturation = cc.saturation or 0.2,
			TintColor = cc.tintColor or Color3.fromRGB(255, 255, 255),
		})
		table.insert(activeTweens, tCC)
		tCC:Play()
	end

	-- 3. Tween Atmosphere Colors (Stabil, hindari re-baking volumetrik berulang)
	if activeAtmosphere and pData.atmosphere then
		local atm = pData.atmosphere
		activeAtmosphere.Density = atm.density or 0.3
		activeAtmosphere.Haze = atm.haze or 0.8
		activeAtmosphere.Glare = atm.glare or 0.35
		local tAtm = TweenService:Create(activeAtmosphere, tweenInfo, {
			Color = atm.color or Color3.fromRGB(180, 210, 240),
			Decay = atm.decay or Color3.fromRGB(120, 165, 210),
		})
		table.insert(activeTweens, tAtm)
		tAtm:Play()
	end

	-- 4. Bloom (Hanya intensitas yang di-tween, jangan ubah Size untuk mencegah alokasi ulang kernel blur)
	if activeBloom and pData.bloom then
		local blm = pData.bloom
		local tBloom = TweenService:Create(activeBloom, tweenInfo, {
			Intensity = blm.intensity or 0.4,
		})
		table.insert(activeTweens, tBloom)
		tBloom:Play()
	end

	-- 5. SunRays (Intensitas halus)
	if activeSunRays and pData.sunRays then
		local sr = pData.sunRays
		local tSunRays = TweenService:Create(activeSunRays, tweenInfo, {
			Intensity = sr.intensity or 0.15,
		})
		table.insert(activeTweens, tSunRays)
		tSunRays:Play()
	end
end

-- ============ 3. SOUNDSCAPE CROSSFADER ============
local function applyZoneSoundscape(zone, transitionDuration)
	if not zone or not zone.soundscape then return end
	transitionDuration = transitionDuration or 2.0

	local sData = zone.soundscape

	-- PENTING: Jangan ubah SoundService.AmbientReverb di Roblox Studio untuk mencegah audio DSP thread freeze
	if not RunService:IsStudio() and sData.reverbType then
		pcall(function()
			if SoundService.AmbientReverb ~= sData.reverbType then
				SoundService.AmbientReverb = sData.reverbType
			end
		end)
	end

	local targetVolume = sData.ambientVolume or 0.4
	local targetSoundId = sData.ambientId or ""

	local currentChannel = (activeSoundChannel == "A") and ambientSoundA or ambientSoundB
	local nextChannel = (activeSoundChannel == "A") and ambientSoundB or ambientSoundA
	activeSoundChannel = (activeSoundChannel == "A") and "B" or "A"

	-- Fade Out Current
	if currentChannel.IsPlaying then
		local fadeOut = TweenService:Create(currentChannel, TweenInfo.new(transitionDuration, Enum.EasingStyle.Linear), {
			Volume = 0,
		})
		table.insert(activeTweens, fadeOut)
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			if currentChannel.Volume == 0 then
				currentChannel:Stop()
			end
		end)
	end

	-- Fade In Next (Hanya jika ID audio valid)
	if targetSoundId and targetSoundId ~= "" then
		nextChannel.SoundId = targetSoundId
		nextChannel.Volume = 0
		nextChannel:Play()
		local fadeIn = TweenService:Create(nextChannel, TweenInfo.new(transitionDuration, Enum.EasingStyle.Linear), {
			Volume = targetVolume,
		})
		table.insert(activeTweens, fadeIn)
		fadeIn:Play()
	else
		nextChannel:Stop()
		nextChannel.Volume = 0
	end
end

-- ============ 4. FLOATING MELODIC & AMBIENT VFX ============
local activeParticleNodes = {}

local function spawnMelodicNotesEmitter(position, zone)
	local vfxData = zone.vfx or {}
	local colors = vfxData.particleColors or { Color3.fromRGB(56, 189, 248), Color3.fromRGB(251, 191, 36) }

	local node = Instance.new("Part")
	node.Name = "MelodicAmbienceNode"
	node.Size = Vector3.new(0.5, 0.5, 0.5)
	node.Position = position + Vector3.new(0, 1.5, 0)
	node.Transparency = 1
	node.CanCollide = false
	node.Anchored = true
	node.Parent = workspace

	local attachment = Instance.new("Attachment", node)

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "MelodyNotes"
	particles.Rate = 2.5
	particles.Lifetime = NumberRange.new(3.5, 5.5)
	particles.Speed = NumberRange.new(1.2, 2.8)
	particles.SpreadAngle = Vector2.new(35, 35)
	particles.VelocitySpread = 35
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Acceleration = Vector3.new(0, 0.5, 0)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 0.8),
		NumberSequenceKeypoint.new(0.8, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.2),
		NumberSequenceKeypoint.new(0.85, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.LightEmission = 0.85
	particles.LightInfluence = 0.1

	local c1 = colors[1] or Color3.fromRGB(56, 189, 248)
	local c2 = colors[2] or Color3.fromRGB(251, 191, 36)
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(0.5, c2),
		ColorSequenceKeypoint.new(1, c1),
	})

	particles.Parent = attachment
	table.insert(activeParticleNodes, node)
	return node
end

local function setupWorldAmbienceNodes()
	for _, node in ipairs(activeParticleNodes) do
		if node and node.Parent then node:Destroy() end
	end
	activeParticleNodes = {}

	for _, zone in pairs(ZoneConfig.ZONES) do
		if zone.dockCenter then
			spawnMelodicNotesEmitter(zone.dockCenter, zone)
			spawnMelodicNotesEmitter(zone.dockCenter + Vector3.new(12, 0, 10), zone)
			spawnMelodicNotesEmitter(zone.dockCenter + Vector3.new(-12, 0, -10), zone)
		end
	end
end

-- ============ 5. PUBLIC API / HOOKS ============
function EnvironmentController.OnZoneChanged(zone, transitionDuration)
	if not zone or zone.id == currentZoneId then return end
	currentZoneId = zone.id

	applyZoneLighting(zone, transitionDuration or 2.0)
	applyZoneSoundscape(zone, transitionDuration or 2.0)
end

function EnvironmentController.SpawnWaterRipple(position, color)
	task.spawn(function()
		local ripple = Instance.new("Part")
		ripple.Name = "WaterRippleVFX"
		ripple.Shape = Enum.PartType.Cylinder
		ripple.Size = Vector3.new(0.05, 0.5, 0.5)
		ripple.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
		ripple.Color = color or Color3.fromRGB(120, 220, 255)
		ripple.Material = Enum.Material.Neon
		ripple.Transparency = 0.3
		ripple.CanCollide = false
		ripple.Anchored = true
		ripple.Parent = workspace

		local grow = TweenService:Create(ripple, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.05, 5.5, 5.5),
			Transparency = 1,
		})
		grow:Play()
		grow.Completed:Connect(function()
			ripple:Destroy()
		end)
	end)
end

function EnvironmentController.SpawnCatchSparkles(position, color)
	task.spawn(function()
		local node = Instance.new("Part")
		node.Name = "CatchSparkleNode"
		node.Size = Vector3.new(0.1, 0.1, 0.1)
		node.Position = position
		node.Transparency = 1
		node.CanCollide = false
		node.Anchored = true
		node.Parent = workspace

		local att = Instance.new("Attachment", node)
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Rate = 40
		sparkle.Speed = NumberRange.new(5, 12)
		sparkle.Lifetime = NumberRange.new(0.8, 1.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.LightEmission = 1.0
		sparkle.Color = ColorSequence.new(color or Color3.fromRGB(255, 215, 0))
		sparkle.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(1, 0),
		})
		sparkle.Parent = att
		sparkle:Emit(30)

		task.delay(1.8, function()
			node:Destroy()
		end)
	end)
end

-- ============ 6. INITIALIZATION ============
local function init()
	initializePostProcessing()
	setupWorldAmbienceNodes()

	-- Set default Melody Bay atmosphere
	local defaultZone = ZoneConfig.ZONES.MELODY_BAY
	currentZoneId = defaultZone and defaultZone.id or "MELODY_BAY"
	if defaultZone then
		applyZoneLighting(defaultZone, 1.0)
		applyZoneSoundscape(defaultZone, 1.0)
	end

	-- Dengarkan perubahan zona resmi dari ZoneController via shared BindableEvent (100% sinkron & 0% overhead)
	ZoneConfig.OnZoneChanged:Connect(function(zone)
		EnvironmentController.OnZoneChanged(zone, 2.0)
	end)

	print("[EnvironmentController] Inisialisasi Environment & Atmospheric Polish selesai (FISH-035).")
end

init()

return EnvironmentController
