--[[
	VehicleConfig (ModuleScript)
	FISH!TUNE — Water Vehicle & Jet Ski Configuration
	
	Konfigurasi terpusat untuk kendaraan air (Jet Ski / Perahu):
	1. Kecepatan, Akselerasi, dan Pengereman.
	2. Kecepatan Belok (Steering) & Efek Miring (Banking Tilt).
	3. Parameter Fisika Buoyancy (Densitas ringan untuk Terrain Water).
	4. Pengaturan ProximityPrompt dan Lokasi Turun (Dismount Offset).
]]

local VehicleConfig = {}

-- Identifikasi Model / Tag
VehicleConfig.TAGS = {
	"JetSki",
	"Boat",
	"Vehicle",
}

VehicleConfig.MODEL_NAMES = {
	"Jet_Ski",
	"JetSki",
	"Boat",
	"Speedboat",
}

-- Pengaturan Mesin & Kecepatan (Studs per detik)
VehicleConfig.SPEED = {
	MAX_FORWARD = 65,       -- Kecepatan maksimal maju (lincah dan dinamis)
	MAX_REVERSE = 20,       -- Kecepatan maksimal mundur
	ACCELERATION = 45,      -- Nilai percepatan saat menekan tombol maju (W)
	BRAKE_DECEL = 65,       -- Nilai perlambatan saat menekan mundur/rem (S)
	COAST_DECEL = 18,       -- Hambatan air alami saat melepas gas
}

-- Pengaturan Kemudi & Kestabilan
VehicleConfig.STEERING = {
	TURN_SPEED = 2.4,       -- Kecepatan putar sudut setir (radian/detik)
	BANK_MAX_ANGLE = 0.22,  -- Kemiringan bodi saat belok kencang (~12.6 derajat)
	BANK_SPEED = 6.0,       -- Kehalusan transisi kemiringan bodi
}

-- Pengaturan Fisika & Terrain Water Buoyancy
VehicleConfig.PHYSICS = {
	-- Ketinggian bodi di atas permukaan air (studs)
	FLOAT_OFFSET = 0.6,
	
	-- Densitas < 1.0 agar mengapung alami di Roblox Terrain Water (air densitas 1.0)
	BUOYANCY_DENSITY = 0.25,
	FRICTION = 0.3,
	ELASTICITY = 0.05,
	
	-- Gaya dorong maksimal motor constraint
	MAX_DRIVE_FORCE = 300000,
	MAX_VERTICAL_FORCE = 250000, -- Gaya apung penahan air
	
	-- Kestabilan penyeimbang (mencegah jet ski terbalik)
	ALIGN_MAX_TORQUE = 600000,
	ALIGN_RESPONSIVENESS = 35,
	
	-- Batas jatuh void untuk auto-respawn
	VOID_Y_THRESHOLD = -50,
}

-- Pengaturan Interaksi ProximityPrompt
VehicleConfig.PROXIMITY_PROMPT = {
	ACTION_TEXT = "Kendarai",
	OBJECT_TEXT = "Jet Ski",
	KEYCODE = Enum.KeyCode.E,
	MAX_DISTANCE = 15,          -- Jangkauan luas agar mudah ditekan dari dermaga/air
	HOLD_DURATION = 0,          -- Tekan instan tanpa perlu menahan tombol
}

-- Offset Posisi Turun (Dismount)
-- Menghindari karakter terjebak di dalam bodi jet ski saat menekan Space/Lompat
VehicleConfig.DISMOUNT = {
	SIDE_OFFSET = Vector3.new(4.5, 2, 0), -- 4.5 studs ke kanan, 2 studs ke atas
}

return VehicleConfig
