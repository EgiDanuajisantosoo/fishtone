--[[
	AudioEffectsSystem (ModuleScript)
	FISH!TUNE — Central Sound Effects & Audio Synthesizer System (FISH-036)

	Fitur Utama:
	1. Dynamic Pitch & Volume Modulated SFX:
	   - Mencegah kebosanan audio repetitif dengan variasi pitch mikro (+/- 5%).
	2. Multi-Tier Catch Victory Fanfares:
	   - COMMON, RARE, SUPER_RARE, LEGENDARY, MYTHIC, SPECIAL dengan sekuens akor nada berlapis.
	3. Rhythm Minigame Hit Sounds:
	   - Resonansi ketukan PERFECT (Emas ⭐⭐⭐), GREAT (Cyan ⭐⭐), GOOD (Biru ⭐), dan MISS (Thud ❌).
	4. Fishing Lifecycle Soundscapes:
	   - Cast Swing (Whoosh sesuai power lemparan), Water Splash (Plop dinamis), Strike Alert (!).
	5. UI & Economy Audio Feedback:
	   - Button clicks, modal transitions, coin showers, item locks, dan level-up fanfare.
	6. Non-blocking & Automatic Debris Cleanup:
	   - Pembersihan otomatis tanpa memory leak.
]]

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local AudioEffectsSystem = {}

-- ============ PRESET AUDIO ASSETS ============
local SOUND_ASSETS = {
	PING = "rbxasset://sounds/electronicpingshort.wav",
	SPLASH = "rbxasset://sounds/splat.wav",
	SWING = "rbxasset://sounds/swordslash.wav",
}

-- ============ SOUND HELPER ENGINE ============
local function playRawSound(soundId, volume, pitch, optParent, optDuration)
	task.spawn(function()
		local snd = Instance.new("Sound")
		snd.SoundId = soundId
		snd.Volume = math.clamp(volume or 0.6, 0, 1.5)
		snd.PlaybackSpeed = math.clamp(pitch or 1.0, 0.2, 3.0)
		snd.Parent = optParent or SoundService
		snd:Play()

		local duration = optDuration or 2.5
		snd.Ended:Connect(function()
			if snd and snd.Parent then snd:Destroy() end
		end)
		Debris:AddItem(snd, duration)
	end)
end

local function addPitchJitter(basePitch, jitterAmount)
	jitterAmount = jitterAmount or 0.04
	local rnd = (math.random() - 0.5) * 2 * jitterAmount
	return math.max(0.2, basePitch + rnd)
end

-- ============ 1. FISHING LIFECYCLE SFX ============
function AudioEffectsSystem.PlayCastSwing(powerRatio)
	powerRatio = math.clamp(tonumber(powerRatio) or 0.5, 0, 1)
	local pitch = 1.1 + (powerRatio * 0.5)
	playRawSound(SOUND_ASSETS.SWING, 0.55, addPitchJitter(pitch, 0.05))
end

function AudioEffectsSystem.PlayWaterSplash(isHeavy)
	if isHeavy then
		playRawSound(SOUND_ASSETS.SPLASH, 0.75, addPitchJitter(1.0, 0.06))
	else
		playRawSound(SOUND_ASSETS.SPLASH, 0.50, addPitchJitter(1.3, 0.08))
	end
end

function AudioEffectsSystem.PlayBobberPlop()
	playRawSound(SOUND_ASSETS.SPLASH, 0.35, addPitchJitter(1.6, 0.08))
end

function AudioEffectsSystem.PlayStrikeAlert()
	playRawSound(SOUND_ASSETS.PING, 0.90, 1.7, nil, 1.8)
	task.delay(0.08, function()
		playRawSound(SOUND_ASSETS.PING, 0.75, 2.1, nil, 1.8)
	end)
end

function AudioEffectsSystem.PlayFishEscape()
	playRawSound(SOUND_ASSETS.SPLASH, 0.65, 0.8, nil, 2.0)
end

-- ============ 2. RHYTHM MINIGAME SFX ============
function AudioEffectsSystem.PlayNoteHit(ratingKey)
	ratingKey = tostring(ratingKey or "GOOD"):upper()

	if ratingKey == "PERFECT" then
		playRawSound(SOUND_ASSETS.PING, 0.85, addPitchJitter(2.0, 0.03))
	elseif ratingKey == "GREAT" then
		playRawSound(SOUND_ASSETS.PING, 0.70, addPitchJitter(1.6, 0.03))
	elseif ratingKey == "GOOD" then
		playRawSound(SOUND_ASSETS.PING, 0.55, addPitchJitter(1.3, 0.03))
	else -- MISS
		playRawSound(SOUND_ASSETS.SPLASH, 0.60, 0.65, nil, 1.5)
	end
end

function AudioEffectsSystem.PlayComboStreak(comboCount)
	comboCount = tonumber(comboCount) or 0
	local pitch = math.clamp(1.4 + (comboCount * 0.04), 1.4, 2.6)
	playRawSound(SOUND_ASSETS.PING, 0.65, pitch, nil, 1.5)
end

-- ============ 3. CATCH VICTORY FANFARES ============
function AudioEffectsSystem.PlayCatchFanfare(rarity, grade)
	rarity = tostring(rarity or "COMMON"):upper():gsub("%s+", "_")
	grade = tostring(grade or "A"):upper()

	if rarity == "SPECIAL" or rarity == "EX" then
		-- Sekuens Akor Pusaka Dewa Laut (Harmoni 5 Nada)
		local chords = { 1.0, 1.33, 1.60, 2.0, 2.5 }
		for i, p in ipairs(chords) do
			task.delay((i - 1) * 0.10, function()
				playRawSound(SOUND_ASSETS.PING, 0.95, p, nil, 3.5)
			end)
		end
	elseif rarity == "MYTHIC" or rarity == "UR" then
		-- Sekuens Akor Mitos Palung (Harmoni 4 Nada)
		local chords = { 1.1, 1.45, 1.82, 2.3 }
		for i, p in ipairs(chords) do
			task.delay((i - 1) * 0.11, function()
				playRawSound(SOUND_ASSETS.PING, 0.90, p, nil, 3.0)
			end)
		end
	elseif rarity == "LEGENDARY" or rarity == "SSR" then
		-- Sekuens Akor Legenda Samudra (Harmoni 3 Nada Emas)
		local chords = { 1.3, 1.65, 2.1 }
		for i, p in ipairs(chords) do
			task.delay((i - 1) * 0.12, function()
				playRawSound(SOUND_ASSETS.PING, 0.85, p, nil, 2.5)
			end)
		end
	elseif rarity == "SUPER_RARE" or rarity == "SR" then
		-- Sekuens Akor 2 Nada
		playRawSound(SOUND_ASSETS.PING, 0.80, 1.5, nil, 2.0)
		task.delay(0.12, function()
			playRawSound(SOUND_ASSETS.PING, 0.85, 1.9, nil, 2.0)
		end)
	else
		-- COMMON / RARE: Nada ceria tunggal
		playRawSound(SOUND_ASSETS.PING, 0.75, 1.8, nil, 2.0)
	end
end

-- ============ 4. UI & ECONOMY SFX ============
function AudioEffectsSystem.PlayButtonClick()
	playRawSound(SOUND_ASSETS.PING, 0.45, addPitchJitter(1.6, 0.05), nil, 1.0)
end

function AudioEffectsSystem.PlayModalOpen()
	playRawSound(SOUND_ASSETS.PING, 0.55, 1.3, nil, 1.2)
end

function AudioEffectsSystem.PlayModalClose()
	playRawSound(SOUND_ASSETS.PING, 0.40, 1.0, nil, 1.0)
end

function AudioEffectsSystem.PlayCoinGain()
	playRawSound(SOUND_ASSETS.PING, 0.70, addPitchJitter(2.2, 0.08), nil, 1.5)
end

function AudioEffectsSystem.PlayItemSell()
	playRawSound(SOUND_ASSETS.PING, 0.75, 1.7, nil, 1.5)
	task.delay(0.06, function()
		playRawSound(SOUND_ASSETS.PING, 0.80, 2.1, nil, 1.5)
	end)
end

function AudioEffectsSystem.PlayLevelUp()
	local fanfare = { 1.2, 1.5, 1.8, 2.4 }
	for i, p in ipairs(fanfare) do
		task.delay((i - 1) * 0.13, function()
			playRawSound(SOUND_ASSETS.PING, 0.90, p, nil, 3.0)
		end)
	end
end

return AudioEffectsSystem
