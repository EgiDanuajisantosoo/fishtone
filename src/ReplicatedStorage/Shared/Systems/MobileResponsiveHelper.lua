--[[
	MobileResponsiveHelper (ModuleScript)
	FISH!TUNE — Centralized Mobile UX & Responsive Adaptation Engine (FISH-037)

	Fitur Utama:
	1. Device Capability Detection:
	   - IsTouchDevice(): Memeriksa apakah perangkat menggunakan layar sentuh (HP / Tablet).
	   - IsSmallScreen(): Memeriksa apakah viewport tergolong smartphone (< 768w atau < 500h).
	2. Dynamic Viewport-Aware Responsive UIScale:
	   - AttachResponsiveScale(): Memasang UIScale otomatis pada Frame/Modal agar tidak terpotong (overflow)
	     pada layar smartphone dengan resolusi terbatas atau rasio layar memanjang (19.5:9 notch).
	   - Menghitung rasio skala optimal dengan batas minimum 0.5x dan maksimum 1.0x serta safe margins.
	3. Safe Area Inset Management:
	   - Memperhitungkan notch / dynamic island dan top bar Roblox (GuiService:GetGuiInset()).
	4. Dedicated Mobile Action Button (Touch-Friendly Contextual Action):
	   - Menyediakan tombol sentuh ergonomis di sisi kanan bawah untuk Lempar Kail, Kunci Meteran, dan Hook Strike
	     sehingga pemain mobile tidak perlu mengetuk sembarang area layar saat menggerakkan kamera.
]]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MobileResponsiveHelper = {}

-- ============ 1. DEVICE CAPABILITY DETECTION ============
function MobileResponsiveHelper.IsTouchDevice()
	return UserInputService.TouchEnabled
end

function MobileResponsiveHelper.IsSmallScreen()
	local cam = workspace.CurrentCamera
	if not cam then return false end
	local vp = cam.ViewportSize
	return vp.Y < 520 or vp.X < 768
end

function MobileResponsiveHelper.GetSafeAreaInset()
	local insetTop, insetBottom = Vector2.zero, Vector2.zero
	pcall(function()
		local topLeft, bottomRight = GuiService:GetGuiInset()
		insetTop = topLeft
		insetBottom = bottomRight
	end)
	return insetTop, insetBottom
end

-- ============ 2. RESPONSIVE MODAL UISCALE ENGINE ============
--[[
	AttachResponsiveScale:
	Menempelkan atau memperbarui objek UIScale pada frame target agar ukuran konten
	selalu pas (contain) di dalam viewport layar tanpa memotong header atau footer.
]]
function MobileResponsiveHelper.AttachResponsiveScale(frame, designWidth, designHeight, optMaxScale, optMargin)
	if not frame or not frame:IsA("GuiObject") then return nil end

	designWidth = designWidth or frame.AbsoluteSize.X or 600
	designHeight = designHeight or frame.AbsoluteSize.Y or 450
	optMaxScale = optMaxScale or 1.0
	optMargin = optMargin or 32

	local uiScale = frame:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "ResponsiveScale"
		uiScale.Scale = 1.0
		uiScale.Parent = frame
	end

	local function updateScale()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local vp = cam.ViewportSize
		if vp.X <= 0 or vp.Y <= 0 then return end

		local topInset, _ = MobileResponsiveHelper.GetSafeAreaInset()
		local availableW = math.max(120, vp.X - optMargin)
		local availableH = math.max(120, vp.Y - optMargin - (topInset.Y or 0))

		local scaleW = availableW / designWidth
		local scaleH = availableH / designHeight
		local bestScale = math.clamp(math.min(scaleW, scaleH), 0.45, optMaxScale)

		uiScale.Scale = bestScale
	end

	updateScale()

	local conn
	local cam = workspace.CurrentCamera
	if cam then
		conn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end

	frame.Destroying:Once(function()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end)

	return uiScale
end

-- ============ 3. ADAPTIVE TEXT FOR MOBILE (NO PC HOTKEYS) ============
function MobileResponsiveHelper.CleanHotkeysForMobile(text)
	if not text then return "" end
	if not MobileResponsiveHelper.IsTouchDevice() then
		return text
	end
	-- Menghapus bracket hotkey seperti [B], [K], [H], [J], [E] dari label tombol untuk pemain mobile
	local cleaned = text:gsub("%s*%[[%a%d]%]", "")
	return cleaned
end

-- ============ 4. DEDICATED CONTEXTUAL MOBILE ACTION BUTTON ============
--[[
	CreateMobileActionButton:
	Membuat tombol aksi sentuh melingkar modern & ergonomis di sisi kanan layar
	yang beradaptasi secara visual dengan status memancing saat ini.
]]
function MobileResponsiveHelper.CreateMobileActionButton(targetGui, onClickCallback)
	if not targetGui then return nil end

	local existing = targetGui:FindFirstChild("MobileActionButtonContainer")
	if existing then existing:Destroy() end

	local container = Instance.new("Frame")
	container.Name = "MobileActionButtonContainer"
	-- Posisi aman di sisi kanan bawah (di atas atau samping kanan area tombol loncat)
	container.AnchorPoint = Vector2.new(1, 1)
	container.Size = UDim2.new(0, 84, 0, 84)
	container.Position = UDim2.new(1, -24, 1, -80)
	container.BackgroundTransparency = 1
	container.ZIndex = 45
	container.Visible = MobileResponsiveHelper.IsTouchDevice()
	container.Parent = targetGui

	-- Tombol Utama Lingkaran
	local btn = Instance.new("TextButton")
	btn.Name = "ActionBtn"
	btn.Size = UDim2.fromScale(1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.ZIndex = 46
	btn.Parent = container
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(56, 189, 248)
	stroke.Thickness = 2.5
	stroke.Parent = btn

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 0, 36)
	iconLabel.Position = UDim2.new(0, 0, 0, 10)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "🎣"
	iconLabel.TextSize = 28
	iconLabel.ZIndex = 47
	iconLabel.Parent = btn

	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Label"
	textLabel.Size = UDim2.new(1, 0, 0, 22)
	textLabel.Position = UDim2.new(0, 0, 1, -30)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.Text = "LEMPAR"
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 13
	textLabel.ZIndex = 47
	textLabel.Parent = btn

	-- Efek Pulse Ring
	local pulseRing = Instance.new("Frame")
	pulseRing.Name = "PulseRing"
	pulseRing.Size = UDim2.fromScale(1, 1)
	pulseRing.AnchorPoint = Vector2.new(0.5, 0.5)
	pulseRing.Position = UDim2.fromScale(0.5, 0.5)
	pulseRing.BackgroundTransparency = 1
	pulseRing.ZIndex = 44
	pulseRing.Parent = container
	Instance.new("UICorner", pulseRing).CornerRadius = UDim.new(1, 0)
	local pStroke = Instance.new("UIStroke")
	pStroke.Color = Color3.fromRGB(56, 189, 248)
	pStroke.Thickness = 2
	pStroke.Transparency = 0.5
	pStroke.Parent = pulseRing

	-- Touch Press Bounce
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(0.90, 0.90),
				Position = UDim2.fromScale(0.05, 0.05),
			}):Play()
		end
	end)

	local function resetBounce()
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
		}):Play()
	end

	btn.InputEnded:Connect(resetBounce)

	btn.MouseButton1Click:Connect(function()
		if onClickCallback then
			onClickCallback()
		end
	end)

	local controller = {}

	function controller.SetState(stateKey)
		stateKey = tostring(stateKey or "IDLE"):upper()

		if stateKey == "IDLE" then
			container.Visible = MobileResponsiveHelper.IsTouchDevice()
			iconLabel.Text = "🎣"
			textLabel.Text = "LEMPAR"
			btn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
			stroke.Color = Color3.fromRGB(56, 189, 248)
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		elseif stateKey == "CHARGING_CAST" then
			container.Visible = true
			iconLabel.Text = "⭐"
			textLabel.Text = "KUNCI"
			btn.BackgroundColor3 = Color3.fromRGB(22, 101, 52)
			stroke.Color = Color3.fromRGB(74, 222, 128)
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		elseif stateKey == "WAITING_FOR_BITE" then
			container.Visible = true
			iconLabel.Text = "🌊"
			textLabel.Text = "TUNGGU"
			btn.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
			stroke.Color = Color3.fromRGB(100, 116, 139)
			textLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
		elseif stateKey == "BITING" then
			container.Visible = true
			iconLabel.Text = "⚡"
			textLabel.Text = "TARIK!"
			btn.BackgroundColor3 = Color3.fromRGB(185, 28, 28)
			stroke.Color = Color3.fromRGB(248, 113, 113)
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

			-- Trigger pulse shockwave
			pulseRing.Size = UDim2.fromScale(1, 1)
			pStroke.Transparency = 0.2
			pStroke.Color = Color3.fromRGB(248, 113, 113)
			TweenService:Create(pulseRing, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromScale(1.4, 1.4),
				Position = UDim2.fromScale(0.5, 0.5),
			}):Play()
			TweenService:Create(pStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
			}):Play()
		elseif stateKey == "MINIGAME" or stateKey == "HIDDEN" then
			container.Visible = false
		end
	end

	function controller.SetVisible(visible)
		container.Visible = visible and MobileResponsiveHelper.IsTouchDevice()
	end

	function controller.Destroy()
		if container and container.Parent then
			container:Destroy()
		end
	end

	return controller
end

return MobileResponsiveHelper
