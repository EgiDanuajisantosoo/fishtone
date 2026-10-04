--[[
	PerformanceCalculator (ModuleScript)
	FISH!TUNE — Rhythm Performance Calculator & Rating Engine (FISH-013)

	Sistem Sentral Evaluasi Performa Rhythm & Rating Penilaian:
	1. Kalkulasi Akurasi Terbobot (Perfect: 100%, Great: 80%, Good: 50%, Miss: 0%).
	2. Penentuan Grade / Peringkat (S+, S, A, B, C, D) dengan Warna & Gelar.
	3. Pengganda Bonus EXP, Koin & Performa Luck (Hingga +25 Luck untuk sesi selanjutnya).
	4. Deteksi Full Combo (FC) & All Perfect (AP).
	5. Laporan Metrik Lengkap untuk Klien & Validasi Server.
]]

local PerformanceCalculator = {}

-- ============ GRADE DEFINITIONS ============
PerformanceCalculator.GRADES = {
	S_PLUS = {
		grade = "S+",
		title = "ALL PERFECT",
		minAccuracy = 98,
		maxMisses = 0,
		color = Color3.fromRGB(255, 215, 0), -- Gold
		glowColor = Color3.fromRGB(255, 235, 120),
		xpMultiplier = 1.35,
		coinMultiplier = 1.30,
	},
	S = {
		grade = "S",
		title = "MASTER RHYTHM",
		minAccuracy = 92,
		maxMisses = 1,
		color = Color3.fromRGB(0, 230, 255), -- Cyan
		glowColor = Color3.fromRGB(150, 240, 255),
		xpMultiplier = 1.25,
		coinMultiplier = 1.20,
	},
	A = {
		grade = "A",
		title = "GREAT TIMING",
		minAccuracy = 82,
		maxMisses = 3,
		color = Color3.fromRGB(80, 235, 120), -- Green
		glowColor = Color3.fromRGB(170, 255, 190),
		xpMultiplier = 1.15,
		coinMultiplier = 1.10,
	},
	B = {
		grade = "B",
		title = "GOOD CATCH",
		minAccuracy = 70,
		maxMisses = 5,
		color = Color3.fromRGB(255, 190, 40), -- Amber
		glowColor = Color3.fromRGB(255, 220, 120),
		xpMultiplier = 1.00,
		coinMultiplier = 1.00,
	},
	C = {
		grade = "C",
		title = "PASSED",
		minAccuracy = 50,
		maxMisses = 999,
		color = Color3.fromRGB(220, 130, 240), -- Purple
		glowColor = Color3.fromRGB(240, 180, 255),
		xpMultiplier = 0.90,
		coinMultiplier = 0.90,
	},
	D = {
		grade = "D",
		title = "POOR RHYTHM",
		minAccuracy = 0,
		maxMisses = 999,
		color = Color3.fromRGB(230, 75, 75), -- Red
		glowColor = Color3.fromRGB(255, 130, 130),
		xpMultiplier = 0.75,
		coinMultiplier = 0.75,
	},
}

-- ============ CALCULATOR CORE ============
function PerformanceCalculator.Calculate(rawMetrics)
	rawMetrics = rawMetrics or {}

	local won = rawMetrics.won == true or (rawMetrics.won ~= false and (rawMetrics.score or 0) > 0)
	local perfectHits = math.max(0, tonumber(rawMetrics.perfectHits) or 0)
	local greatHits = math.max(0, tonumber(rawMetrics.greatHits) or 0)
	local goodHits = math.max(0, tonumber(rawMetrics.goodHits) or 0)
	local mistakes = math.max(0, tonumber(rawMetrics.mistakes) or 0)
	local maxCombo = math.max(0, tonumber(rawMetrics.maxCombo) or 0)
	local targetNotes = math.max(1, tonumber(rawMetrics.targetNotes) or 30)
	local duration = math.max(0.1, tonumber(rawMetrics.duration) or 1.0)

	local totalHits = perfectHits + greatHits + goodHits
	if totalHits == 0 and (rawMetrics.hits or rawMetrics.score) then
		totalHits = math.max(0, tonumber(rawMetrics.hits or rawMetrics.score) or 0)
		-- Estimasi fallback jika breakdown tidak lengkap
		perfectHits = math.floor(totalHits * 0.6)
		greatHits = math.floor(totalHits * 0.3)
		goodHits = totalHits - perfectHits - greatHits
	end

	local totalAttempts = totalHits + mistakes
	if totalAttempts == 0 then
		totalAttempts = 1
	end

	-- 1. Hitung Akurasi Terbobot (Weighted Accuracy)
	local weightedSum = (perfectHits * 1.0) + (greatHits * 0.8) + (goodHits * 0.5)
	local weightedAccuracy = math.clamp((weightedSum / totalAttempts) * 100, 0, 100)

	-- 2. Performance Score (0 - 100)
	local comboFactor = math.clamp(maxCombo / targetNotes, 0, 1)
	local performanceScore = math.clamp((weightedAccuracy * 0.85) + (comboFactor * 15), 0, 100)

	-- 3. Flags Khusus
	local isAllPerfect = (perfectHits >= targetNotes and mistakes == 0 and greatHits == 0 and goodHits == 0)
	local isFullCombo = (mistakes == 0 and totalHits >= targetNotes)

	-- 4. Tentukan Grade
	local gradeInfo = PerformanceCalculator.GRADES.D
	if not won then
		gradeInfo = PerformanceCalculator.GRADES.D
	elseif isAllPerfect or (weightedAccuracy >= PerformanceCalculator.GRADES.S_PLUS.minAccuracy and mistakes <= PerformanceCalculator.GRADES.S_PLUS.maxMisses) then
		gradeInfo = PerformanceCalculator.GRADES.S_PLUS
	elseif weightedAccuracy >= PerformanceCalculator.GRADES.S.minAccuracy and mistakes <= PerformanceCalculator.GRADES.S.maxMisses then
		gradeInfo = PerformanceCalculator.GRADES.S
	elseif weightedAccuracy >= PerformanceCalculator.GRADES.A.minAccuracy and mistakes <= PerformanceCalculator.GRADES.A.maxMisses then
		gradeInfo = PerformanceCalculator.GRADES.A
	elseif weightedAccuracy >= PerformanceCalculator.GRADES.B.minAccuracy and mistakes <= PerformanceCalculator.GRADES.B.maxMisses then
		gradeInfo = PerformanceCalculator.GRADES.B
	elseif weightedAccuracy >= PerformanceCalculator.GRADES.C.minAccuracy then
		gradeInfo = PerformanceCalculator.GRADES.C
	else
		gradeInfo = PerformanceCalculator.GRADES.D
	end

	-- 5. Performance Luck Bonus (Maksimal +25 Luck untuk tangkapan / sesi selanjutnya)
	local performanceLuckBonus = math.floor(performanceScore * 0.25 * 10) / 10

	-- 6. Raw Score Computation
	local rawScore = (perfectHits * 300) + (greatHits * 180) + (goodHits * 80) + (maxCombo * 25)

	return {
		won = won,
		performanceScore = math.floor(performanceScore * 10) / 10,
		accuracy = math.floor(weightedAccuracy * 10) / 10,
		grade = gradeInfo.grade,
		gradeTitle = gradeInfo.title,
		gradeColor = gradeInfo.color,
		glowColor = gradeInfo.glowColor,
		xpMultiplier = gradeInfo.xpMultiplier,
		coinMultiplier = gradeInfo.coinMultiplier,
		performanceLuckBonus = performanceLuckBonus,
		isFullCombo = isFullCombo,
		isAllPerfect = isAllPerfect,
		rawScore = rawScore,
		breakdown = {
			perfect = perfectHits,
			great = greatHits,
			good = goodHits,
			miss = mistakes,
			totalHits = totalHits,
			maxCombo = maxCombo,
			targetNotes = targetNotes,
			duration = math.floor(duration * 10) / 10,
		}
	}
end

-- ============ UTILITY HELPERS ============
function PerformanceCalculator.GetGradeData(grade)
	grade = tostring(grade or ""):upper()
	if grade == "S+" or grade == "S_PLUS" then
		return PerformanceCalculator.GRADES.S_PLUS
	elseif grade == "S" then
		return PerformanceCalculator.GRADES.S
	elseif grade == "A" then
		return PerformanceCalculator.GRADES.A
	elseif grade == "B" then
		return PerformanceCalculator.GRADES.B
	elseif grade == "C" then
		return PerformanceCalculator.GRADES.C
	else
		return PerformanceCalculator.GRADES.D
	end
end

function PerformanceCalculator.GetGradeColor(grade)
	local data = PerformanceCalculator.GetGradeData(grade)
	return data and data.color or Color3.fromRGB(230, 75, 75)
end

function PerformanceCalculator.FormatMultiplierText(performance)
	if not performance then return "" end
	local xp = performance.xpMultiplier or 1.0
	local coin = performance.coinMultiplier or 1.0
	local luck = performance.performanceLuckBonus or 0
	return string.format("EXP x%.2f  •  Koin x%.2f  •  +%.1f Luck", xp, coin, luck)
end

return PerformanceCalculator
