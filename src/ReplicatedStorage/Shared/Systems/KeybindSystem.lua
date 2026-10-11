--[[
	KeybindSystem (ModuleScript)
	FISH!TUNE — Central Rhythm Keybind & Control Customization System (FISH-045)

	Sistem Sentral Pengaturan Tombol Rhythm (Piano, Gitar, Drum):
	1. Definisi Keybind Otoritatif per Jalur (Kolom 1, 2, 3, 4).
	2. Preset Standar Bawaan:
	   - WASD  : [A] [W] [S] [D] (Bawaan Studio FISH!TUNE)
	   - DFJK  : [D] [F] [J] [K] (Standar Rhythm Game 4K / Osu!Mania)
	   - ASKL  : [A] [S] [K] [L] (Ergonomic Home Row)
	   - QWER  : [Q] [W] [E] [R] (MOBA / Linear Style)
	   - PANAH : [←] [↑] [↓] [→] (Arrow Keys)
	   - NUMPAD: [1] [2] [3] [4] (Numpad 10-Key)
	3. Kustomisasi Bebas: Pemain dapat mengubah tombol apapun sesuai preferensi.
	4. Auxiliary / Secondary Keys: Tombol angka 1-4 dan Keypad 1-4 selalu didukung.
	5. Sinyal Real-time (OnKeybindsChanged): Memperbarui visual ReceptorPad dan input loop seketika.
	6. Sinkronisasi Persistence: Kompatibel dengan PlayerDataSchema.settings.rhythmKeybinds.
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KeybindSystem = {}

-- ============ DEFAULT PRESETS ============
KeybindSystem.PRESETS = {
	DFJK = {
		name = "DFJK (Bawaan 4K)",
		keys = { Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K },
		labels = { "D", "F", "J", "K" },
	},
	WASD = {
		name = "WASD (Alternatif)",
		keys = { Enum.KeyCode.A, Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.D },
		labels = { "A", "W", "S", "D" },
	},
	ASKL = {
		name = "ASKL (Ergonomis)",
		keys = { Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.K, Enum.KeyCode.L },
		labels = { "A", "S", "K", "L" },
	},
	QWER = {
		name = "QWER (Linear)",
		keys = { Enum.KeyCode.Q, Enum.KeyCode.W, Enum.KeyCode.E, Enum.KeyCode.R },
		labels = { "Q", "W", "E", "R" },
	},
	ARROWS = {
		name = "Panah (← ↑ ↓ →)",
		keys = { Enum.KeyCode.Left, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Right },
		labels = { "←", "↑", "↓", "→" },
	},
	NUMPAD = {
		name = "Numpad (1 2 3 4)",
		keys = { Enum.KeyCode.KeypadOne, Enum.KeyCode.KeypadTwo, Enum.KeyCode.KeypadThree, Enum.KeyCode.KeypadFour },
		labels = { "N1", "N2", "N3", "N4" },
	},
}

-- Blacklisted keys (tombol terlarang untuk kontrol agar tidak bentrok dengan sistem OS/Roblox)
local BLACKLISTED_KEYS = {
	[Enum.KeyCode.Escape] = true,
	[Enum.KeyCode.Backquote] = true, -- Console
	[Enum.KeyCode.F11] = true,       -- Fullscreen
	[Enum.KeyCode.F9] = true,        -- DevConsole
	[Enum.KeyCode.Print] = true,
	[Enum.KeyCode.LeftSuper] = true,
	[Enum.KeyCode.RightSuper] = true,
}

-- Friendly Display Label Map
local KEYCODE_TO_LABEL = {
	[Enum.KeyCode.Left] = "←",
	[Enum.KeyCode.Up] = "↑",
	[Enum.KeyCode.Down] = "↓",
	[Enum.KeyCode.Right] = "→",
	[Enum.KeyCode.KeypadOne] = "N1",
	[Enum.KeyCode.KeypadTwo] = "N2",
	[Enum.KeyCode.KeypadThree] = "N3",
	[Enum.KeyCode.KeypadFour] = "N4",
	[Enum.KeyCode.KeypadFive] = "N5",
	[Enum.KeyCode.KeypadSix] = "N6",
	[Enum.KeyCode.KeypadSeven] = "N7",
	[Enum.KeyCode.KeypadEight] = "N8",
	[Enum.KeyCode.KeypadNine] = "N9",
	[Enum.KeyCode.KeypadZero] = "N0",
	[Enum.KeyCode.One] = "1",
	[Enum.KeyCode.Two] = "2",
	[Enum.KeyCode.Three] = "3",
	[Enum.KeyCode.Four] = "4",
	[Enum.KeyCode.Five] = "5",
	[Enum.KeyCode.Six] = "6",
	[Enum.KeyCode.Seven] = "7",
	[Enum.KeyCode.Eight] = "8",
	[Enum.KeyCode.Nine] = "9",
	[Enum.KeyCode.Zero] = "0",
	[Enum.KeyCode.Semicolon] = ";",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.Comma] = ",",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.Space] = "SPC",
	[Enum.KeyCode.Return] = "RET",
	[Enum.KeyCode.Tab] = "TAB",
}

-- ============ INTERNAL STATE ============
local activeKeys = {
	Enum.KeyCode.D,
	Enum.KeyCode.F,
	Enum.KeyCode.J,
	Enum.KeyCode.K,
}

local activeLabels = { "D", "F", "J", "K" }

-- Event Signal
local onKeybindsChangedBindable = Instance.new("BindableEvent")
KeybindSystem.OnKeybindsChanged = onKeybindsChangedBindable.Event

-- Cached Key-to-Column map
local cachedKeyMap = {}

-- ============ REBUILD KEY MAP ============
local function rebuildKeyMap()
	table.clear(cachedKeyMap)

	-- 1. Primary User Keys
	for colIndex = 1, 4 do
		local kc = activeKeys[colIndex]
		if kc and kc ~= Enum.KeyCode.Unknown then
			cachedKeyMap[kc] = colIndex
		end
	end

	-- 2. Universal Auxiliary Keys (Nomor 1-4 & Keypad 1-4)
	-- Hanya ditambahkan jika belum digunakan oleh kolom lain
	local auxMappings = {
		{ Enum.KeyCode.One, Enum.KeyCode.KeypadOne },       -- Col 1
		{ Enum.KeyCode.Two, Enum.KeyCode.KeypadTwo },       -- Col 2
		{ Enum.KeyCode.Three, Enum.KeyCode.KeypadThree },   -- Col 3
		{ Enum.KeyCode.Four, Enum.KeyCode.KeypadFour },     -- Col 4
	}

	for colIndex, keys in ipairs(auxMappings) do
		for _, kc in ipairs(keys) do
			if cachedKeyMap[kc] == nil then
				cachedKeyMap[kc] = colIndex
			end
		end
	end
end

rebuildKeyMap()

-- ============ PUBLIC CONVERTER HELPERS ============

--- Mengubah Enum.KeyCode menjadi label teks ringkas yang ramah tampilan UI
function KeybindSystem.KeyCodeToLabel(keyCode)
	if not keyCode or keyCode == Enum.KeyCode.Unknown then
		return "?"
	end
	if KEYCODE_TO_LABEL[keyCode] then
		return KEYCODE_TO_LABEL[keyCode]
	end
	local name = keyCode.Name
	if #name == 1 then
		return name:upper()
	end
	return name
end

--- Mengonversi string label / nama ke Enum.KeyCode
function KeybindSystem.StringToKeyCode(str)
	if not str or typeof(str) ~= "string" then
		return Enum.KeyCode.Unknown
	end
	str = str:upper():gsub("%s+", "")

	-- Cek alias khusus
	if str == "←" or str == "LEFT" then return Enum.KeyCode.Left end
	if str == "↑" or str == "UP" then return Enum.KeyCode.Up end
	if str == "↓" or str == "DOWN" then return Enum.KeyCode.Down end
	if str == "→" or str == "RIGHT" then return Enum.KeyCode.Right end
	if str == "N1" or str == "KEYPADONE" then return Enum.KeyCode.KeypadOne end
	if str == "N2" or str == "KEYPADTWO" then return Enum.KeyCode.KeypadTwo end
	if str == "N3" or str == "KEYPADTHREE" then return Enum.KeyCode.KeypadThree end
	if str == "N4" or str == "KEYPADFOUR" then return Enum.KeyCode.KeypadFour end
	if str == "1" or str == "ONE" then return Enum.KeyCode.One end
	if str == "2" or str == "TWO" then return Enum.KeyCode.Two end
	if str == "3" or str == "THREE" then return Enum.KeyCode.Three end
	if str == "4" or str == "FOUR" then return Enum.KeyCode.Four end
	if str == "SPC" or str == "SPACE" then return Enum.KeyCode.Space end

	-- Cek langsung pada Enum.KeyCode
	local success, kc = pcall(function()
		return Enum.KeyCode[str]
	end)
	if success and kc then
		return kc
	end

	-- Jika single char
	for _, enumItem in ipairs(Enum.KeyCode:GetEnumItems()) do
		if enumItem.Name:upper() == str then
			return enumItem
		end
	end

	return Enum.KeyCode.Unknown
end

--- Validasi apakah sebuah KeyCode valid untuk dijadikan keybind rhythm
function KeybindSystem.IsValidKey(keyCode)
	if not keyCode or keyCode == Enum.KeyCode.Unknown then
		return false, "Tombol tidak terdeteksi."
	end
	if BLACKLISTED_KEYS[keyCode] then
		return false, "Tombol ini dilindungi oleh sistem."
	end
	return true
end

-- ============ PUBLIC GETTERS ============

--- Mengembalikan array 4 Enum.KeyCode aktif
function KeybindSystem.GetActiveKeys()
	return { activeKeys[1], activeKeys[2], activeKeys[3], activeKeys[4] }
end

--- Mengembalikan array 4 label string aktif
function KeybindSystem.GetActiveLabels()
	return { activeLabels[1], activeLabels[2], activeLabels[3], activeLabels[4] }
end

--- Mengembalikan label untuk kolom tertentu (1-4)
function KeybindSystem.GetKeyLabel(column)
	return activeLabels[column] or "A"
end

--- Mengembalikan KeyCode untuk kolom tertentu (1-4)
function KeybindSystem.GetKeyCode(column)
	return activeKeys[column] or Enum.KeyCode.A
end

--- Mengembalikan map [KeyCode] = columnIndex (termasuk tombol pembantu 1-4)
function KeybindSystem.GetKeyMap()
	return cachedKeyMap
end

--- Mengembalikan indeks kolom (1-4) untuk sebuah KeyCode yang ditekan, atau nil
function KeybindSystem.GetColumnForKey(keyCode)
	return cachedKeyMap[keyCode]
end

--- Mendapatkan semua KeyCode yang perlu didaftarkan ke ContextActionService
function KeybindSystem.GetAllBindableKeys()
	local list = {}
	for kc, _ in pairs(cachedKeyMap) do
		table.insert(list, kc)
	end
	return list
end

-- ============ PUBLIC SETTERS & MUTATORS ============

--- Mengatur 4 KeyCode baru secara langsung
function KeybindSystem.SetActiveKeys(newKeys)
	if typeof(newKeys) ~= "table" or #newKeys < 4 then
		return false, "Membutuhkan 4 tombol."
	end

	-- Validasi setiap key
	local seen = {}
	for i = 1, 4 do
		local kc = newKeys[i]
		local ok, err = KeybindSystem.IsValidKey(kc)
		if not ok then return false, string.format("Kolom %d: %s", i, err) end
		if seen[kc] then
			return false, string.format("Tombol '%s' tidak boleh dipakai lebih dari satu kolom.", KeybindSystem.KeyCodeToLabel(kc))
		end
		seen[kc] = true
	end

	for i = 1, 4 do
		activeKeys[i] = newKeys[i]
		activeLabels[i] = KeybindSystem.KeyCodeToLabel(newKeys[i])
	end

	rebuildKeyMap()
	onKeybindsChangedBindable:Fire(KeybindSystem.GetActiveLabels(), KeybindSystem.GetActiveKeys())
	return true
end

--- Mengatur 1 kolom saja (1-4) dengan KeyCode baru
function KeybindSystem.SetColumnKey(colIndex, newKey)
	if colIndex < 1 or colIndex > 4 then return false, "Indeks kolom harus 1-4." end
	local ok, err = KeybindSystem.IsValidKey(newKey)
	if not ok then return false, err end

	-- Jika tombol sudah dipakai di kolom lain, lakukan swap (tukar tempat) otomatis yang intuitif
	for otherCol = 1, 4 do
		if otherCol ~= colIndex and activeKeys[otherCol] == newKey then
			activeKeys[otherCol] = activeKeys[colIndex]
			activeLabels[otherCol] = KeybindSystem.KeyCodeToLabel(activeKeys[otherCol])
			break
		end
	end

	activeKeys[colIndex] = newKey
	activeLabels[colIndex] = KeybindSystem.KeyCodeToLabel(newKey)

	rebuildKeyMap()
	onKeybindsChangedBindable:Fire(KeybindSystem.GetActiveLabels(), KeybindSystem.GetActiveKeys())
	return true
end

--- Menerapkan salah satu preset resmi (WASD, DFJK, ASKL, QWER, ARROWS, NUMPAD)
function KeybindSystem.ApplyPreset(presetId)
	local preset = KeybindSystem.PRESETS[presetId:upper()]
	if not preset then
		return false, "Preset tidak ditemukan: " .. tostring(presetId)
	end
	return KeybindSystem.SetActiveKeys(preset.keys)
end

--- Reset ke pengaturan default (DFJK)
function KeybindSystem.ResetToDefault()
	return KeybindSystem.ApplyPreset("DFJK")
end

--- Mengatur keybind dari array string (misal: {"D", "F", "J", "K"})
function KeybindSystem.SetFromLabels(labelArray)
	if typeof(labelArray) ~= "table" or #labelArray < 4 then
		return false, "Format label tidak valid."
	end

	local converted = {}
	for i = 1, 4 do
		local kc = KeybindSystem.StringToKeyCode(tostring(labelArray[i]))
		if kc == Enum.KeyCode.Unknown then
			return false, string.format("Label '%s' tidak valid.", tostring(labelArray[i]))
		end
		table.insert(converted, kc)
	end

	return KeybindSystem.SetActiveKeys(converted)
end

-- ============ PERSISTENCE INTEGRATION ============

--- Memuat keybinds dari tabel settings PlayerData (jika ada)
function KeybindSystem.LoadFromSettings(settingsTable)
	if not settingsTable then return end
	local rhythmKeys = settingsTable.rhythmKeybinds
	if rhythmKeys and typeof(rhythmKeys) == "table" and #rhythmKeys >= 4 then
		KeybindSystem.SetFromLabels(rhythmKeys)
	end
end

--- Menghasilkan array string untuk disimpan ke PlayerDataSchema.settings.rhythmKeybinds
function KeybindSystem.ExportSettings()
	return {
		activeLabels[1],
		activeLabels[2],
		activeLabels[3],
		activeLabels[4],
	}
end

return KeybindSystem
