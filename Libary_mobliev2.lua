--!native
--!nocheck
-- ==============================================================================
-- Omen UI Library — Mobile Compact Rewrite
-- Tối ưu cho mobile: menu nhỏ, 1 cột, touch-friendly, tab scroll ngang
-- Giữ nguyên API gốc để tương thích ngược
-- ==============================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==============================================================================
-- 1. SAFE CONTAINER
-- ==============================================================================

local function getSafeGui(): Instance
	local success, hui = pcall(function()
		return (gethui and gethui()) or CoreGui
	end)
	if success and hui then
		return hui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

-- ==============================================================================
-- 2. THEME
-- ==============================================================================

local Theme = {
	Accent                   = Color3.fromRGB(115, 36, 223),
	Background               = Color3.fromRGB(14, 14, 16),
	Section_background       = Color3.fromRGB(22, 22, 26),
	ComponentBackground      = Color3.fromRGB(40, 40, 46),
	Tab_Background           = Color3.fromRGB(30, 30, 36),
	Tab_Active               = Color3.fromRGB(48, 48, 58),
	tab_unselected           = Color3.fromRGB(51, 51, 51),
	DropdownoptionBackground = Color3.fromRGB(58, 58, 66),
	Outline                  = Color3.fromRGB(42, 42, 50),
	Outline2                 = Color3.fromRGB(0, 0, 0),
	TopBarBackground         = Color3.fromRGB(27, 25, 33),
	Text_light               = Color3.fromRGB(240, 240, 245),
	Text_dark                = Color3.fromRGB(140, 140, 150),
	Risky_Text               = Color3.fromRGB(200, 0, 0),
	White                    = Color3.fromRGB(255, 255, 255),
	Success                  = Color3.fromRGB(80, 200, 120),
	Danger                   = Color3.fromRGB(220, 80, 80),
}

local short_keybind_names = {
	[Enum.KeyCode.LeftControl]  = "LC",
	[Enum.KeyCode.RightControl] = "RC",
	[Enum.KeyCode.LeftShift]    = "LS",
	[Enum.KeyCode.RightShift]   = "RS",
	[Enum.KeyCode.LeftAlt]      = "LALT",
	[Enum.KeyCode.RightAlt]     = "RALT",
	[Enum.KeyCode.CapsLock]     = "CAPS",
	[Enum.KeyCode.Return]       = "RET",
	[Enum.KeyCode.Backspace]    = "BSP",
	[Enum.KeyCode.BackSlash]    = "BS",
	[Enum.KeyCode.Insert]       = "INS",
	[Enum.UserInputType.MouseButton1] = "MB1",
	[Enum.UserInputType.MouseButton2] = "MB2",
	[Enum.UserInputType.MouseButton3] = "MB3",
}

local BlacklistedKeys = {
	Enum.KeyCode.Unknown,
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right,
	Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape,
}

local WhitelistedMouse = {
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.MouseButton2,
	Enum.UserInputType.MouseButton3,
}

-- ==============================================================================
-- 3. HELPERS (internal)
-- ==============================================================================

local function create(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

local function round(v, places)
	places = places or 0
	if places == 0 then
		return math.floor(v + 0.5)
	end
	local m = 10 ^ places
	return math.floor(v * m + 0.5) / m
end

-- ==============================================================================
-- 4. LIBRARY CORE
-- ==============================================================================

local Library = {
	Flags = {},
	Elements = {},
	Elementsopened = {},
	InstanceStorage = {},
	Connections = {},
	Tabs = {},
	sections = {},
	short_keybind_names = short_keybind_names,
	BlacklistedKeys = BlacklistedKeys,
	WhitelistedMouse = WhitelistedMouse,
	Keybind = Enum.KeyCode.RightControl,
}
Library.__index = Library
Library.Tabs.__index = Library.Tabs
Library.sections.__index = Library.sections

local Helpers = {
	Theme = Theme,
}

-- ==============================================================================
-- 5. UTILITIES
-- ==============================================================================

function Helpers.TableToColor(tbl)
	if typeof(tbl) == "Color3" then return tbl end
	return Color3.fromRGB(tbl[1] or 255, tbl[2] or 255, tbl[3] or 255)
end

function Helpers.UpdateObject(obj, props)
	for prop, val in pairs(props) do
		pcall(function()
			obj[prop] = val
		end)
	end
end

function Helpers.SetTheme(themeName, color)
	if Theme[themeName] then
		Theme[themeName] = color
		for _, data in ipairs(Library.InstanceStorage) do
			if data.ThemeTag == themeName then
				pcall(function()
					data.Instance[data.Property] = color
				end)
			end
		end
	end
end

function Helpers.Fade(inst, state)
	TweenService:Create(inst, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = state and 0 or 1,
	}):Play()
end

function Helpers.ripple(button)
	local circle = create("ImageLabel", {
		Name = "Ripple",
		BackgroundTransparency = 1,
		Image = "rbxassetid://266543268",
		ImageColor3 = Theme.Accent,
		ImageTransparency = 0.7,
		Size = UDim2.new(0, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		ZIndex = 5,
		Parent = button,
	})
	TweenService:Create(circle, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1.2, 0, 1.2, 0),
		ImageTransparency = 1,
	}):Play()
	task.delay(0.35, function() circle:Destroy() end)
end

function Helpers.MakeDraggable(frame, handle)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Helpers.MakeResizeable(frame, handle, minSize)
	minSize = minSize or Vector2.new(240, 200)
	local resizing, startSize, startMouse
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startSize = frame.AbsoluteSize
			startMouse = input.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startMouse
			frame.Size = UDim2.new(
				0, math.max(minSize.X, startSize.X + delta.X),
				0, math.max(minSize.Y, startSize.Y + delta.Y)
			)
		end
	end)
end

function Helpers.Tooltip(parent, text)
	local tip = create("Frame", {
		Name = "TooltipFrame",
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ZIndex = 100,
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tip })
	create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = tip })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
		Parent = tip,
	})
	create("TextLabel", {
		Text = text,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextColor3 = Theme.Text_light,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 101,
		Parent = tip,
	})
	parent.MouseEnter:Connect(function() tip.Visible = true end)
	parent.MouseLeave:Connect(function() tip.Visible = false end)
end

function Helpers.MouseIsOverOpenedFrame()
	for frame, isOpen in pairs(Library.Elementsopened) do
		if isOpen and frame.Visible then
			local mp = UserInputService:GetMouseLocation()
			local pos = frame.AbsolutePosition
			local sz = frame.AbsoluteSize
			if mp.X >= pos.X and mp.X <= pos.X + sz.X
				and mp.Y >= pos.Y and mp.Y <= pos.Y + sz.Y then
				return true
			end
		end
	end
	return false
end

function Helpers.FindElementByFlag(flagName)
	return Library.Elements[flagName]
end

function Helpers.GetConfigs()
	local configs = {}
	for flag, val in pairs(Library.Flags) do
		if typeof(val) == "Color3" then
			configs[flag] = { val.R * 255, val.G * 255, val.B * 255 }
		elseif typeof(val) == "EnumItem" then
			configs[flag] = val.Name
		else
			configs[flag] = val
		end
	end
	return configs
end

-- ==============================================================================
-- 6. MOBILE TOGGLE BUTTON
-- ==============================================================================

local function CreateMobileToggle(rootGui, mainFrame, opts)
	opts = opts or {}
	local color = opts.Color or Theme.Accent
	local size = opts.Size or 46

	local btn = create("TextButton", {
		Name = "OmenMobileToggle",
		Text = "≡",
		TextSize = math.floor(size * 0.55),
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.White,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.new(0, size, 0, size),
		Position = UDim2.new(1, -16, 1, -16),
		AnchorPoint = Vector2.new(1, 1),
		AutoButtonColor = false,
		ZIndex = 9999,
		ClipsDescendants = true,
		Parent = rootGui,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = btn })
	create("UIStroke", { Color = Theme.Outline2, Thickness = 2, Parent = btn })

	create("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 16, 1, 16),
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.5,
		ZIndex = 0,
		Parent = btn,
	})

	local dragging, dragStart, startPos
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = btn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			btn.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	local lastClick = 0
	btn.MouseButton1Click:Connect(function()
		local now = tick()
		if now - lastClick < 0.12 then return end
		lastClick = now
		mainFrame.Visible = not mainFrame.Visible
	end)

	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), {
			Size = UDim2.new(0, size - 4, 0, size - 4),
		}):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, size, 0, size),
		}):Play()
	end)

	return btn
end

-- ==============================================================================
-- 7. CREATE WINDOW
-- ==============================================================================

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local titleText = cfg.Title or "Omen Hub"
	local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

	local defaultSize
	if isMobile then
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
		local w = math.clamp(math.floor(vp.X * 0.72), 260, 420)
		local h = math.clamp(math.floor(vp.Y * 0.62), 260, 460)
		defaultSize = UDim2.new(0, w, 0, h)
	else
		defaultSize = UDim2.new(0, 520, 0, 480)
	end
	local winSize = cfg.Size or defaultSize

	local rootGui = create("ScreenGui", {
		Name = "OmenUI_" .. HttpService:GenerateGUID(false):sub(1, 8),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
		Parent = getSafeGui(),
	})

	-- Main frame
	local MainFrame = create("Frame", {
		Name = "MainFrame",
		Size = winSize,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = rootGui,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MainFrame })
	create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = MainFrame })

	-- Header (drag handle)
	local Header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Theme.Tab_Background,
		BorderSizePixel = 0,
		Parent = MainFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Header })

	create("TextLabel", {
		Text = titleText,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.Text_light,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Parent = Header,
	})

	-- Close button
	local CloseBtn = create("TextButton", {
		Text = "×",
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.Text_dark,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 28, 1, 0),
		Position = UDim2.new(1, -28, 0, 0),
		Parent = Header,
	})
	CloseBtn.MouseButton1Click:Connect(function()
		MainFrame.Visible = false
	end)

	Helpers.MakeDraggable(MainFrame, Header)

	-- Tabs bar (scrollable horizontally)
	local TabsBar = create("ScrollingFrame", {
		Name = "TabsBar",
		Size = UDim2.new(1, -8, 0, 26),
		Position = UDim2.new(0, 4, 0, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		Parent = MainFrame,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
		Parent = TabsBar,
	})

	-- Content container
	local Container = create("Frame", {
		Name = "Container",
		Size = UDim2.new(1, -8, 1, -64),
		Position = UDim2.new(0, 4, 0, 60),
		BackgroundTransparency = 1,
		Parent = MainFrame,
	})

	-- Resize handle
	local ResizeHandle = create("Frame", {
		Name = "ResizeHandle",
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(1, -2, 1, -2),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Parent = MainFrame,
	})
	Helpers.MakeResizeable(MainFrame, ResizeHandle)

	-- PC keybind toggle
	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == Library.Keybind then
			MainFrame.Visible = not MainFrame.Visible
		end
	end)

	-- Mobile button
	local mobileToggle = nil
	if cfg.MobileButton ~= false then
		mobileToggle = CreateMobileToggle(rootGui, MainFrame, {
			Color = cfg.MobileButtonColor or Theme.Accent,
			Size = cfg.MobileButtonSize or (isMobile and 46 or 0),
		})
		if isMobile then
			MainFrame.Visible = false
		else
			mobileToggle.Visible = false
		end
	end

	local Window = {
		MainFrame = MainFrame,
		Container = Container,
		TabsBar = TabsBar,
		Tabs = {},
		ActiveTab = nil,
		MobileToggle = mobileToggle,
		RootGui = rootGui,
	}

	-- ==========================================================================
	-- AddTab
	-- ==========================================================================
	function Window:AddTab(tabName)
		local tabBtn = create("TextButton", {
			Name = "Tab_" .. tabName,
			Text = tabName,
			TextSize = 12,
			Font = Enum.Font.Gotham,
			TextColor3 = Theme.Text_dark,
			BackgroundColor3 = Theme.Tab_Background,
			BorderSizePixel = 0,
			Size = UDim2.new(0, 0, 1, -4),
			AutoButtonColor = false,
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = TabsBar,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tabBtn })
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			Parent = tabBtn,
		})

		local PageFrame = create("Frame", {
			Name = "Page_" .. tabName,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = Container,
		})

		-- Single column scroll (compact cho mobile)
		local Column = create("ScrollingFrame", {
			Name = "Column",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = PageFrame,
		})
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = Column,
		})

		local TabObj = {
			PageFrame = PageFrame,
			LeftColumn = Column,   -- giữ tương thích
			RightColumn = Column,  -- cùng cột
			Column = Column,
			Button = tabBtn,
			Name = tabName,
		}

		local function selectTab()
			for _, t in ipairs(Window.Tabs) do
				t.PageFrame.Visible = false
				t.Button.TextColor3 = Theme.Text_dark
				t.Button.BackgroundColor3 = Theme.Tab_Background
			end
			PageFrame.Visible = true
			tabBtn.TextColor3 = Theme.Accent
			tabBtn.BackgroundColor3 = Theme.Tab_Active
			Window.ActiveTab = TabObj
		end

		tabBtn.MouseButton1Click:Connect(function()
			Helpers.ripple(tabBtn)
			selectTab()
		end)

		table.insert(Window.Tabs, TabObj)
		if #Window.Tabs == 1 then selectTab() end

		-- ======================================================================
		-- AddGroupBox
		-- ======================================================================
		function TabObj:AddGroupBox(groupTitle, side)
			-- side bị bỏ qua (compact 1 cột) nhưng giữ tham số để tương thích
			local GroupBox = create("Frame", {
				Name = "GroupBox_" .. groupTitle,
				Size = UDim2.new(1, -6, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Section_background,
				BorderSizePixel = 0,
				Parent = Column,
			})
			create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = GroupBox })
			create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = GroupBox })
			create("UIPadding", {
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				Parent = GroupBox,
			})
			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 5),
				Parent = GroupBox,
			})

			create("TextLabel", {
				Text = groupTitle,
				TextSize = 12,
				Font = Enum.Font.GothamBold,
				TextColor3 = Theme.Text_light,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				Parent = GroupBox,
			})

			local GroupObject = {}

			-- ==================================================================
			-- AddToggle
			-- ==================================================================
			function GroupObject:AddToggle(flagName, options)
				options = options or {}
				local text = options.Text or flagName
				local state = options.Default or false
				local callback = options.Callback or function() end
				Library.Flags[flagName] = state

				local row = create("TextButton", {
					Name = "Toggle_" .. flagName,
					Text = "",
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Parent = GroupBox,
				})

				local indicator = create("Frame", {
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(0, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = state and Theme.Accent or Theme.ComponentBackground,
					BorderSizePixel = 0,
					Parent = row,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = indicator })
				create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = indicator })

				local check = create("TextLabel", {
					Text = "✓",
					TextSize = 12,
					Font = Enum.Font.GothamBold,
					TextColor3 = Theme.White,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 1, 0),
					Visible = state,
					Parent = indicator,
				})

				local label = create("TextLabel", {
					Text = text,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = state and Theme.Text_light or Theme.Text_dark,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 24, 0, 0),
					Size = UDim2.new(1, -24, 1, 0),
					Parent = row,
				})

				if options.Tooltip then
					Helpers.Tooltip(row, options.Tooltip)
				end

				local function set(val)
					Library.Flags[flagName] = val
					indicator.BackgroundColor3 = val and Theme.Accent or Theme.ComponentBackground
					label.TextColor3 = val and Theme.Text_light or Theme.Text_dark
					check.Visible = val
					callback(val)
				end

				row.MouseButton1Click:Connect(function()
					set(not Library.Flags[flagName])
					Helpers.ripple(row)
				end)

				local item = { SetValue = set, Set = set }
				Library.Elements[flagName] = item
				return item
			end

			-- ==================================================================
			-- AddSlider
			-- ==================================================================
			function GroupObject:AddSlider(flagName, options)
				options = options or {}
				local text = options.Text or flagName
				local minV = options.Min or 0
				local maxV = options.Max or 100
				local default = options.Default or minV
				local rounding = options.Rounding or 0
				local callback = options.Callback or function() end
				Library.Flags[flagName] = default

				local box = create("Frame", {
					Name = "Slider_" .. flagName,
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					Parent = GroupBox,
				})

				create("TextLabel", {
					Text = text,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Text_light,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -50, 0, 14),
					Parent = box,
				})

				local valLabel = create("TextLabel", {
					Text = tostring(default),
					TextSize = 12,
					Font = Enum.Font.GothamBold,
					TextColor3 = Theme.Accent,
					TextXAlignment = Enum.TextXAlignment.Right,
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -50, 0, 0),
					Size = UDim2.new(0, 50, 0, 14),
					Parent = box,
				})

				local bar = create("TextButton", {
					Name = "Bar",
					Text = "",
					Size = UDim2.new(1, 0, 0, 12),
					Position = UDim2.new(0, 0, 0, 18),
					BackgroundColor3 = Theme.ComponentBackground,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Parent = box,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = bar })

				local fill = create("Frame", {
					Size = UDim2.new(math.clamp((default - minV) / (maxV - minV), 0, 1), 0, 1, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Parent = bar,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = fill })

				local knob = create("Frame", {
					Size = UDim2.new(0, 14, 0, 14),
					Position = UDim2.new(1, -7, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Theme.White,
					BorderSizePixel = 0,
					Parent = bar,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

				local function set(val)
					local clamped = math.clamp(val, minV, maxV)
					clamped = round(clamped, rounding)
					Library.Flags[flagName] = clamped
					valLabel.Text = tostring(clamped)
					fill.Size = UDim2.new((clamped - minV) / (maxV - minV), 0, 1, 0)
					callback(clamped)
				end

				local dragging = false
				local function update(input)
					local x = input.Position.X
					local bx = bar.AbsolutePosition.X
					local bw = bar.AbsoluteSize.X
					local p = math.clamp((x - bx) / bw, 0, 1)
					set(minV + p * (maxV - minV))
				end

				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						update(input)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
						or input.UserInputType == Enum.UserInputType.Touch) then
						update(input)
					end
				end)

				local item = { SetValue = set, Set = set }
				Library.Elements[flagName] = item
				return item
			end

			-- ==================================================================
			-- AddButton
			-- ==================================================================
			function GroupObject:AddButton(options)
				options = options or {}
				local btn = create("TextButton", {
					Name = "Button_" .. (options.Text or "Button"),
					Text = options.Text or "Button",
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Text_light,
					BackgroundColor3 = Theme.ComponentBackground,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 24),
					AutoButtonColor = false,
					Parent = GroupBox,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })

				if options.Tooltip then
					Helpers.Tooltip(btn, options.Tooltip)
				end

				btn.MouseButton1Click:Connect(function()
					Helpers.ripple(btn)
					if options.Func then options.Func() end
				end)
				return btn
			end

			-- ==================================================================
			-- AddDropdown
			-- ==================================================================
			function GroupObject:AddDropdown(flagName, options)
				options = options or {}
				local values = options.Values or {}
				local default = options.Default or values[1]
				local callback = options.Callback or function() end
				Library.Flags[flagName] = default

				local box = create("Frame", {
					Name = "Dropdown_" .. flagName,
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
					Parent = GroupBox,
				})

				create("TextLabel", {
					Text = options.Text or flagName,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Text_light,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 14),
					Parent = box,
				})

				local select = create("TextButton", {
					Text = "  " .. tostring(default),
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Text_dark,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundColor3 = Theme.ComponentBackground,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0, 17),
					Size = UDim2.new(1, 0, 0, 20),
					AutoButtonColor = false,
					Parent = box,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = select })

				local list = create("Frame", {
					Name = "DropList",
					Visible = false,
					Size = UDim2.new(1, 0, 0, #values * 20),
					Position = UDim2.new(0, 0, 1, 2),
					BackgroundColor3 = Theme.DropdownoptionBackground,
					BorderSizePixel = 0,
					ZIndex = 50,
					Parent = select,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = list })
				create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = list })
				create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = list,
				})

				for _, opt in ipairs(values) do
					local optBtn = create("TextButton", {
						Text = "  " .. opt,
						TextSize = 11,
						Font = Enum.Font.Gotham,
						TextColor3 = (opt == default) and Theme.Accent or Theme.Text_light,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundColor3 = Theme.DropdownoptionBackground,
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 20),
						ZIndex = 51,
						AutoButtonColor = false,
						Parent = list,
					})
					optBtn.MouseButton1Click:Connect(function()
						Library.Flags[flagName] = opt
						select.Text = "  " .. opt
						list.Visible = false
						Library.Elementsopened[list] = nil
						for _, c in ipairs(list:GetChildren()) do
							if c:IsA("TextButton") then
								c.TextColor3 = (c.Text == "  " .. opt) and Theme.Accent or Theme.Text_light
							end
						end
						callback(opt)
					end)
				end

				select.MouseButton1Click:Connect(function()
					list.Visible = not list.Visible
					Library.Elementsopened[list] = list.Visible and true or nil
				end)

				return box
			end

			-- ==================================================================
			-- AddInput
			-- ==================================================================
			function GroupObject:AddInput(flagName, options)
				options = options or {}
				local default = options.Default or ""
				local callback = options.Callback or function() end
				Library.Flags[flagName] = default

				local row = create("Frame", {
					Size = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					Parent = GroupBox,
				})

				create("TextLabel", {
					Text = options.Text or flagName,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Text_light,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.45, 0, 1, 0),
					Parent = row,
				})

				local box = create("TextBox", {
					Text = default,
					PlaceholderText = options.Placeholder or "...",
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Accent,
					BackgroundColor3 = Theme.ComponentBackground,
					BorderSizePixel = 0,
					Position = UDim2.new(0.45, 0, 0, 0),
					Size = UDim2.new(0.55, 0, 1, 0),
					ClearTextOnFocus = false,
					Parent = row,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })

				box.FocusLost:Connect(function()
					local v = box.Text
					if options.Numeric then
						v = v:gsub("[^%d%.%-]", "")
						box.Text = v
					end
					Library.Flags[flagName] = v
					callback(v)
				end)
				return box
			end

			-- ==================================================================
			-- AddColorPicker (mini: swatch click để xoay màu + 3 slider RGB)
			-- ==================================================================
			function GroupObject:AddColorPicker(flagName, options)
				options = options or {}
				local default = options.Default or Theme.Accent
				local callback = options.Callback or function() end
				Library.Flags[flagName] = default

				local row = create("Frame", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Parent = GroupBox,
				})

				create("TextLabel", {
					Text = options.Title or flagName,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Text_light,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -30, 1, 0),
					Parent = row,
				})

				local swatch = create("TextButton", {
					Text = "",
					BackgroundColor3 = default,
					BorderSizePixel = 0,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 24, 0, 14),
					AutoButtonColor = false,
					Parent = row,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = swatch })
				create("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = swatch })

				local function setColor(c)
					Library.Flags[flagName] = c
					swatch.BackgroundColor3 = c
					callback(c)
				end

				-- Click để xoay hue (đơn giản, không cần UI picker phức tạp)
				swatch.MouseButton1Click:Connect(function()
					local h, s, v = Color3.toHSV(swatch.BackgroundColor3)
					h = (h + 0.15) % 1
					setColor(Color3.fromHSV(h, s, v))
				end)

				return { SetColor = setColor }
			end

			-- ==================================================================
			-- AddKeyPicker
			-- ==================================================================
			function GroupObject:AddKeyPicker(flagName, options)
				options = options or {}
				local defaultKey = options.Default or "MB2"
				local callback = options.Callback or function() end
				Library.Flags[flagName] = defaultKey

				local row = create("Frame", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Parent = GroupBox,
				})

				create("TextLabel", {
					Text = options.Text or flagName,
					TextSize = 12,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Text_light,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -52, 1, 0),
					Parent = row,
				})

				local keyBtn = create("TextButton", {
					Text = "[" .. defaultKey .. "]",
					TextSize = 11,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Accent,
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 50, 1, 0),
					Parent = row,
				})

				local listening = false
				keyBtn.MouseButton1Click:Connect(function()
					listening = true
					keyBtn.Text = "[...]"
				end)

				UserInputService.InputBegan:Connect(function(input, gpe)
					if listening and not gpe then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							local keyName = input.KeyCode.Name
							Library.Flags[flagName] = keyName
							keyBtn.Text = "[" .. (short_keybind_names[input.KeyCode] or keyName) .. "]"
							listening = false
							callback(input.KeyCode)
						end
					end
				end)

				return row
			end

			-- ==================================================================
			-- AddLabel
			-- ==================================================================
			function GroupObject:AddLabel(labelText)
				local lbl = create("TextLabel", {
					Text = labelText,
					TextSize = 11,
					Font = Enum.Font.Gotham,
					TextColor3 = Theme.Text_dark,
					TextXAlignment = Enum.TextXAlignment.Left,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 14),
					TextWrapped = true,
					Parent = GroupBox,
				})
				return lbl
			end

			-- ==================================================================
			-- AddLine
			-- ==================================================================
			function GroupObject:AddLine()
				create("Frame", {
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = Theme.Outline,
					BorderSizePixel = 0,
					Parent = GroupBox,
				})
			end

			return GroupObject
		end

		return TabObj
	end

	return Window
end

-- ==============================================================================
-- 8. EXPORTS
-- ==============================================================================

print("[Omen Mobile Compact] Library loaded successfully.")
return Library, Helpers
