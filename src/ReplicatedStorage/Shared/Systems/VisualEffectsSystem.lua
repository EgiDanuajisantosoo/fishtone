--[[
	VisualEffectsSystem (ModuleScript)
	FISH!TUNE — Central Visual Effects, Particles & Celebration Engine (FISH-036)

	Fitur Utama:
	1. Multi-Layer Dynamic Water Splashes & Ripples:
	   - Expanding neon cylinder rings + particle spray with realistic gravity.
	2. Bobber Buoyancy Ambient Pulses:
	   - Riak air lembut periodik saat kail mengapung di permukaan air.
	3. High-Intensity Strike Alert Shockwave:
	   - Expanding radial shockwave part + red exclamation icon burst.
	4. Tier-Specific Catch Victory Celebrations:
	   - Fireworks, confetti, glowing halos & celestial sparkles disesuaikan dengan Rarity (Common hingga Special).
	5. 3D Floating Reward Numbers & Coins:
	   - Animated 3D Floating billboard for Koin & EXP.
	6. Non-blocking & Automatic Debris Cleanup:
	   - Seluruh instance partikel dibersihkan secara otomatis.
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local VisualEffectsSystem = {}

-- ============ RARITY COLOR MAP ============
local RARITY_COLORS = {
	COMMON = Color3.fromRGB(180, 210, 240),
	RARE = Color3.fromRGB(0, 215, 255),
	SUPER_RARE = Color3.fromRGB(185, 90, 255),
	LEGENDARY = Color3.fromRGB(255, 215, 0),
	MYTHIC = Color3.fromRGB(255, 50, 80),
	SPECIAL = Color3.fromRGB(255, 80, 220),
}

-- ============ 1. WATER SPLASH & EXPANDING RIPPLE ============
function VisualEffectsSystem.CreateWaterSplash(pos, customColor, scale)
	scale = scale or 1.0
	local color = customColor or Color3.fromRGB(180, 235, 255)

	local emitterPart = Instance.new("Part")
	emitterPart.Name = "WaterSplashVFX"
	emitterPart.Size = Vector3.new(1, 0.2, 1)
	emitterPart.Position = pos
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.Transparency = 1
	emitterPart.Parent = workspace

	-- Partikel Tetesan Air
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4 * scale),
		NumberSequenceKeypoint.new(0.4, 1.6 * scale),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Speed = NumberRange.new(8 * scale, 15 * scale)
	emitter.SpreadAngle = Vector2.new(50, 50)
	emitter.Acceleration = Vector3.new(0, -32, 0)
	emitter.Lifetime = NumberRange.new(0.5, 0.8)
	emitter.Rate = 0
	emitter.LightEmission = 0.6
	emitter.Parent = emitterPart
	emitter:Emit(math.floor(30 * scale))

	-- Riak Gelombang Air Melingkar
	VisualEffectsSystem.SpawnWaterRipple(pos, color, scale)

	Debris:AddItem(emitterPart, 1.8)
end

function VisualEffectsSystem.SpawnWaterRipple(pos, customColor, scale)
	scale = scale or 1.0
	local color = customColor or Color3.fromRGB(130, 225, 255)

	task.spawn(function()
		local ripple = Instance.new("Part")
		ripple.Name = "WaterRippleRing"
		ripple.Shape = Enum.PartType.Cylinder
		ripple.Size = Vector3.new(0.04, 0.6 * scale, 0.6 * scale)
		ripple.CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ripple.Color = color
		ripple.Material = Enum.Material.Neon
		ripple.Transparency = 0.35
		ripple.CanCollide = false
		ripple.Anchored = true
		ripple.Parent = workspace

		local targetSize = 6.0 * scale
		local grow = TweenService:Create(ripple, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.04, targetSize, targetSize),
			Transparency = 1,
		})
		grow:Play()
		grow.Completed:Connect(function()
			ripple:Destroy()
		end)
	end)
end

-- ============ 2. BOBBER IDLE WATER PULSE ============
function VisualEffectsSystem.SpawnBobberPulse(bobberPart)
	if not bobberPart or not bobberPart.Parent then return end
	local pos = bobberPart.Position
	VisualEffectsSystem.SpawnWaterRipple(pos - Vector3.new(0, 0.3, 0), Color3.fromRGB(160, 230, 255), 0.6)
end

-- ============ 3. STRIKE SHOCKWAVE ALERT (!) ============
function VisualEffectsSystem.CreateStrikeShockwave(pos)
	-- 1. Expanding Shockwave Disc
	task.spawn(function()
		local shockwave = Instance.new("Part")
		shockwave.Name = "StrikeShockwave"
		shockwave.Shape = Enum.PartType.Cylinder
		shockwave.Size = Vector3.new(0.06, 1.0, 1.0)
		shockwave.CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
		shockwave.Color = Color3.fromRGB(255, 60, 60)
		shockwave.Material = Enum.Material.Neon
		shockwave.Transparency = 0.2
		shockwave.CanCollide = false
		shockwave.Anchored = true
		shockwave.Parent = workspace

		local tween = TweenService:Create(shockwave, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.06, 9.0, 9.0),
			Transparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function()
			shockwave:Destroy()
		end)
	end)

	-- 2. Water Splash Explosion
	VisualEffectsSystem.CreateWaterSplash(pos, Color3.fromRGB(255, 120, 120), 1.4)
end

-- ============ 4. CATCH VICTORY CELEBRATION VFX ============
function VisualEffectsSystem.CreateCatchCelebration(character, rarity, customColor)
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	if not hrp then return end

	local tierKey = tostring(rarity or "COMMON"):upper():gsub("%s+", "_")
	local color = customColor or RARITY_COLORS[tierKey] or Color3.fromRGB(255, 215, 0)

	task.spawn(function()
		local node = Instance.new("Part")
		node.Name = "CelebrationVFXNode"
		node.Size = Vector3.new(0.1, 0.1, 0.1)
		node.Position = hrp.Position + Vector3.new(0, 1.5, 0)
		node.Transparency = 1
		node.CanCollide = false
		node.Anchored = true
		node.Parent = workspace

		local att = Instance.new("Attachment", node)

		-- 1. Fireworks Burst Particles
		local burst = Instance.new("ParticleEmitter")
		burst.Name = "RarityBurst"
		burst.Texture = "rbxasset://textures/particles/smoke_main.dds"
		burst.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
		burst.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.5, 1.2),
			NumberSequenceKeypoint.new(1, 0),
		})
		burst.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		burst.Speed = NumberRange.new(10, 22)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Acceleration = Vector3.new(0, -18, 0)
		burst.Lifetime = NumberRange.new(0.8, 1.5)
		burst.Rate = 0
		burst.LightEmission = 0.95
		burst.Parent = att

		local count = (tierKey == "SPECIAL" and 80) or (tierKey == "MYTHIC" and 60) or (tierKey == "LEGENDARY" and 45) or 30
		burst:Emit(count)

		-- 2. Expanding Radiant Aura Ring
		local halo = Instance.new("Part")
		halo.Name = "CelebrationHalo"
		halo.Shape = Enum.PartType.Cylinder
		halo.Size = Vector3.new(0.05, 0.5, 0.5)
		halo.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, 0, math.rad(90))
		halo.Color = color
		halo.Material = Enum.Material.Neon
		halo.Transparency = 0.2
		halo.CanCollide = false
		halo.Anchored = true
		halo.Parent = workspace

		local haloTween = TweenService:Create(halo, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.05, 12.0, 12.0),
			Transparency = 1,
		})
		haloTween:Play()
		haloTween.Completed:Connect(function()
			halo:Destroy()
		end)

		Debris:AddItem(node, 2.5)
	end)
end

-- ============ 5. FLOATING 3D REWARD TEXT ============
function VisualEffectsSystem.SpawnFloatingReward(character, text, color)
	if not character then return end
	local head = character:FindFirstChild("Head") or character.PrimaryPart
	if not head then return end

	task.spawn(function()
		local bb = Instance.new("BillboardGui")
		bb.Name = "FloatingRewardBB"
		bb.Size = UDim2.new(0, 180, 0, 40)
		bb.StudsOffset = Vector3.new(0, 2.2, 0)
		bb.AlwaysOnTop = true
		bb.Adornee = head
		bb.Parent = head

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = color or Color3.fromRGB(255, 215, 0)
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextSize = 22
		lbl.TextTransparency = 0
		lbl.Parent = bb

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(0, 0, 0)
		stroke.Thickness = 2
		stroke.Transparency = 0.2
		stroke.Parent = lbl

		local floatTween = TweenService:Create(bb, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			StudsOffset = Vector3.new(0, 4.5, 0)
		})
		local fadeTween = TweenService:Create(lbl, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1
		})
		floatTween:Play()
		fadeTween:Play()

		task.delay(1.5, function()
			bb:Destroy()
		end)
	end)
end

return VisualEffectsSystem
