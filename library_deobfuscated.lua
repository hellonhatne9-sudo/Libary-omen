--!native
--!nocheck
-- ==============================================================================
-- Omen UI Library (LinoriaLib Fork / Omen Edition)
-- Deobfuscated & Fully Reconstructed from Luraph v14.3
-- Source: /storage/emulated/0/Omen xưa/library_obfuscated.lua.txt
-- ==============================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Safe container helper (gethui / CoreGui fallback)
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
-- 1. THEMES & COLOR PALETTE
-- ==============================================================================

local Theme = {
	Accent                   = Color3.fromRGB(115, 36, 223),  -- Signature Omen Purple
	Background               = Color3.fromRGB(12, 12, 12),
	Section_background       = Color3.fromRGB(20, 20, 20),
	ComponentBackground      = Color3.fromRGB(38, 38, 38),
	Tab_Background           = Color3.fromRGB(41, 41, 41),
	tab_unselected           = Color3.fromRGB(51, 51, 51),
	DropdownoptionBackground = Color3.fromRGB(60, 60, 60),
	Outline                  = Color3.fromRGB(29, 29, 29),
	Outline2                 = Color3.fromRGB(0, 0, 0),
	TopBarBackground         = Color3.fromRGB(27, 25, 33),
	Text_light               = Color3.fromRGB(255, 255, 255),
	Text_dark                = Color3.fromRGB(144, 144, 144),
	Risky_Text               = Color3.fromRGB(200, 0, 0),
	White                    = Color3.fromRGB(255, 255, 255),
}

-- Keybind abbreviations mapping
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
	Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape
}

local WhitelistedMouse = {
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.MouseButton2,
	Enum.UserInputType.MouseButton3,
}

-- ==============================================================================
-- 2. CUSTOM SIGNAL IMPLEMENTATION
-- ==============================================================================

local function createSignal()
	local bindable = Instance.new("BindableEvent")
	local sig = {}
	function sig:Connect(fn)
		return bindable.Event:Connect(fn)
	end
	function sig:Fire(...)
		bindable:Fire(...)
	end
	function sig:Destroy()
		bindable:Destroy()
	end
	return sig
end

-- ==============================================================================
-- 3. LIBRARY CORE DATA STRUCTURE
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
-- 4. UTILITIES & ANIMATIONS
-- ==============================================================================

function Helpers.TableToColor(tbl: { number }): Color3
	if typeof(tbl) == "Color3" then return tbl end
	return Color3.fromRGB(tbl[1] or 255, tbl[2] or 255, tbl[3] or 255)
end

function Helpers.UpdateObject(obj: Instance, props: { [string]: any })
	for prop, val in pairs(props) do
		pcall(function()
			(obj :: any)[prop] = val
		end)
	end
end

function Helpers.SetTheme(themeName: string, color: Color3)
	if Theme[themeName] then
		Theme[themeName] = color
		for _, data in ipairs(Library.InstanceStorage) do
			if data.ThemeTag == themeName then
				pcall(function()
					(data.Instance :: any)[data.Property] = color
				end)
			end
		end
	end
end

function Helpers.Fade(inst: GuiObject, state: boolean)
	local target = state and 0 or 1
	TweenService:Create(inst, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = target
	}):Play()
end

function Helpers.MakeDraggable(frame: GuiObject, handle: GuiObject)
	local dragging = false
	local dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Helpers.MakeResizeable(frame: GuiObject, handle: GuiObject)
	local resizing = false
	local startSize, startMouse

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			startSize = frame.Size
			startMouse = UserInputService:GetMouseLocation()
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					resizing = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local currentMouse = UserInputService:GetMouseLocation()
			local delta = currentMouse - startMouse
			frame.Size = UDim2.new(
				startSize.X.Scale, math.max(300, startSize.X.Offset + delta.X),
				startSize.Y.Scale, math.max(250, startSize.Y.Offset + delta.Y)
			)
		end
	end)
end

function Helpers.Tooltip(parent: GuiObject, text: string)
	local tipFrame = Instance.new("Frame")
	tipFrame.Name = "TooltipFrame"
	tipFrame.Visible = false
	tipFrame.Size = UDim2.new(0, 60, 0, 16)
	tipFrame.AutomaticSize = Enum.AutomaticSize.XY
	tipFrame.BackgroundColor3 = Theme.Background
	tipFrame.BorderColor3 = Theme.Outline
	tipFrame.ZIndex = 100
	tipFrame.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = tipFrame

	local label = Instance.new("TextLabel")
	label.Text = text
	label.TextSize = 13
	label.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	label.TextColor3 = Theme.Text_light
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.ZIndex = 101
	label.Parent = tipFrame

	parent.MouseEnter:Connect(function()
		tipFrame.Visible = true
	end)
	parent.MouseLeave:Connect(function()
		tipFrame.Visible = false
	end)
end

function Helpers.ripple(button: GuiButton)
	local circle = Instance.new("ImageLabel")
	circle.Name = "Ripple"
	circle.BackgroundTransparency = 1
	circle.Image = "rbxassetid://266543268"
	circle.ImageColor3 = Theme.Accent
	circle.ImageTransparency = 0.8
	circle.Size = UDim2.new(0, 0, 0, 0)
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.new(0.5, 0, 0.5, 0)
	circle.Parent = button

	TweenService:Create(circle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1.5, 0, 1.5, 0),
		ImageTransparency = 1
	}):Play()
	task.delay(0.4, function()
		circle:Destroy()
	end)
end

function Helpers.MouseIsOverOpenedFrame(): boolean
	for frame, isOpen in pairs(Library.Elementsopened) do
		if isOpen and frame.Visible then
			local mousePos = UserInputService:GetMouseLocation()
			local pos = frame.AbsolutePosition
			local sz = frame.AbsoluteSize
			if mousePos.X >= pos.X and mousePos.X <= pos.X + sz.X and
			   mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + sz.Y then
				return true
			end
		end
	end
	return false
end

function Helpers.FindElementByFlag(flagName: string)
	return Library.Elements[flagName]
end

function Helpers.GetConfigs(): { [string]: any }
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
-- 5. WINDOW BUILDER (CreateWindow)
-- ==============================================================================

function Library:CreateWindow(cfg: { Title: string?, Center: boolean?, AutoShow: boolean?, Size: UDim2? })
	local titleText = (cfg and cfg.Title) or "Omen Hub"
	local winSize = (cfg and cfg.Size) or UDim2.new(0, 700, 0, 640)

	local rootGui = Instance.new("ScreenGui")
	rootGui.Name = "OmenUI_" .. HttpService:GenerateGUID(false):sub(1, 8)
	rootGui.ResetOnSpawn = false
	rootGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	rootGui.Parent = getSafeGui()

	-- Main Window Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = winSize
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Theme.Background
	MainFrame.BorderColor3 = Theme.Outline2
	MainFrame.BorderSizePixel = 2
	MainFrame.Parent = rootGui

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = Theme.Outline
	MainStroke.Parent = MainFrame

	-- TopBar
	local TopBar = Instance.new("TextButton")
	TopBar.Name = "TopBar"
	TopBar.Text = ""
	TopBar.Size = UDim2.new(1, -80, 0, 22)
	TopBar.Position = UDim2.new(0, 0, 0, 0)
	TopBar.BackgroundTransparency = 1
	TopBar.BorderSizePixel = 0
	TopBar.Parent = MainFrame

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Text = titleText
	TitleLabel.TextSize = 13
	TitleLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	TitleLabel.TextColor3 = Theme.Text_light
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Position = UDim2.new(0, 8, 0, 0)
	TitleLabel.Size = UDim2.new(0, 0, 0, 20)
	TitleLabel.AutomaticSize = Enum.AutomaticSize.X
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Parent = MainFrame

	local Separator = Instance.new("TextLabel")
	Separator.Text = "|"
	Separator.TextSize = 13
	Separator.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	Separator.TextColor3 = Theme.Text_dark
	Separator.TextXAlignment = Enum.TextXAlignment.Center
	Separator.Position = UDim2.new(1, 6, 0, 0)
	Separator.Size = UDim2.new(0, 10, 0, 20)
	Separator.BackgroundTransparency = 1
	Separator.Parent = TitleLabel

	local GameLabel = Instance.new("TextLabel")
	GameLabel.Text = "universal"
	GameLabel.TextSize = 13
	GameLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	GameLabel.TextColor3 = Theme.Accent
	GameLabel.TextXAlignment = Enum.TextXAlignment.Left
	GameLabel.Position = UDim2.new(1, 6, 0, 0)
	GameLabel.Size = UDim2.new(0, 0, 0, 20)
	GameLabel.AutomaticSize = Enum.AutomaticSize.X
	GameLabel.BackgroundTransparency = 1
	GameLabel.Parent = Separator

	local Divider = Instance.new("Frame")
	Divider.Size = UDim2.new(1, 0, 0, 2)
	Divider.Position = UDim2.new(0, 0, 0, 22)
	Divider.BackgroundColor3 = Theme.Outline
	Divider.BorderSizePixel = 0
	Divider.Parent = MainFrame

	-- Resize Handle
	local ResizeButton = Instance.new("ImageButton")
	ResizeButton.Name = "ResizeHandle"
	ResizeButton.Size = UDim2.new(0, 10, 0, 10)
	ResizeButton.Position = UDim2.new(1, 0, 1, 0)
	ResizeButton.AnchorPoint = Vector2.new(1, 1)
	ResizeButton.BackgroundTransparency = 1
	ResizeButton.Parent = MainFrame

	Helpers.MakeDraggable(MainFrame, TopBar)
	Helpers.MakeResizeable(MainFrame, ResizeButton)

	-- Tabs Holder
	local TabsBar = Instance.new("Frame")
	TabsBar.Name = "TabsBar"
	TabsBar.Size = UDim2.new(1, 0, 0, 24)
	TabsBar.Position = UDim2.new(0, 0, 0, 26)
	TabsBar.BackgroundTransparency = 1
	TabsBar.Parent = MainFrame

	local TabsLayout = Instance.new("UIListLayout")
	TabsLayout.FillDirection = Enum.FillDirection.Horizontal
	TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	TabsLayout.Padding = UDim.new(0, 6)
	TabsLayout.Parent = TabsBar

	local TabsPadding = Instance.new("UIPadding")
	TabsPadding.PaddingLeft = UDim.new(0, 8)
	TabsPadding.Parent = TabsBar

	-- Container Holder for Page Frames
	local Container = Instance.new("Frame")
	Container.Name = "Container"
	Container.Size = UDim2.new(1, -16, 1, -56)
	Container.Position = UDim2.new(0, 8, 0, 52)
	Container.BackgroundTransparency = 1
	Container.Parent = MainFrame

	-- Keybind Toggle Listener
	UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == Library.Keybind then
			MainFrame.Visible = not MainFrame.Visible
		end
	end)

	local Window = {
		MainFrame = MainFrame,
		Container = Container,
		TabsBar = TabsBar,
		Tabs = {},
		ActiveTab = nil,
	}

	-- AddTab Method
	function Window:AddTab(tabName: string)
		local tabButton = Instance.new("TextButton")
		tabButton.Name = "TabButton_" .. tabName
		tabButton.Text = tabName
		tabButton.TextSize = 13
		tabButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
		tabButton.TextColor3 = Theme.Text_dark
		tabButton.BackgroundColor3 = Theme.Tab_Background
		tabButton.BorderSizePixel = 0
		tabButton.Size = UDim2.new(0, 0, 1, -4)
		tabButton.AutomaticSize = Enum.AutomaticSize.X
		tabButton.Parent = TabsBar

		local tabPadding = Instance.new("UIPadding")
		tabPadding.PaddingLeft = UDim.new(0, 10)
		tabPadding.PaddingRight = UDim.new(0, 10)
		tabPadding.Parent = tabButton

		local PageFrame = Instance.new("Frame")
		PageFrame.Name = "Page_" .. tabName
		PageFrame.Size = UDim2.new(1, 0, 1, 0)
		PageFrame.BackgroundTransparency = 1
		PageFrame.Visible = false
		PageFrame.Parent = Container

		local LeftColumn = Instance.new("ScrollingFrame")
		LeftColumn.Name = "LeftColumn"
		LeftColumn.Size = UDim2.new(0.5, -4, 1, 0)
		LeftColumn.Position = UDim2.new(0, 0, 0, 0)
		LeftColumn.BackgroundTransparency = 1
		LeftColumn.BorderSizePixel = 0
		LeftColumn.ScrollBarThickness = 2
		LeftColumn.ScrollBarImageColor3 = Theme.Accent
		LeftColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
		LeftColumn.Parent = PageFrame

		local LeftLayout = Instance.new("UIListLayout")
		LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		LeftLayout.Padding = UDim.new(0, 8)
		LeftLayout.Parent = LeftColumn

		local RightColumn = Instance.new("ScrollingFrame")
		RightColumn.Name = "RightColumn"
		RightColumn.Size = UDim2.new(0.5, -4, 1, 0)
		RightColumn.Position = UDim2.new(0.5, 4, 0, 0)
		RightColumn.BackgroundTransparency = 1
		RightColumn.BorderSizePixel = 0
		RightColumn.ScrollBarThickness = 2
		RightColumn.ScrollBarImageColor3 = Theme.Accent
		RightColumn.AutomaticCanvasSize = Enum.AutomaticSize.Y
		RightColumn.Parent = PageFrame

		local RightLayout = Instance.new("UIListLayout")
		RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RightLayout.Padding = UDim.new(0, 8)
		RightLayout.Parent = RightColumn

		local TabObject = {
			PageFrame = PageFrame,
			LeftColumn = LeftColumn,
			RightColumn = RightColumn,
		}

		local function selectTab()
			for _, tab in pairs(Window.Tabs) do
				tab.PageFrame.Visible = false
				tab.Button.TextColor3 = Theme.Text_dark
			end
			PageFrame.Visible = true
			tabButton.TextColor3 = Theme.Accent
			Window.ActiveTab = TabObject
		end

		tabButton.MouseButton1Click:Connect(selectTab)
		TabObject.Button = tabButton

		if #TabsBar:GetChildren() <= 3 then
			selectTab()
		end

		table.insert(Window.Tabs, TabObject)

		-- AddGroupBox Method
		function TabObject:AddGroupBox(groupTitle: string, side: string?)
			local parentColumn = (side == "right") and RightColumn or LeftColumn

			local GroupBox = Instance.new("Frame")
			GroupBox.Name = "GroupBox_" .. groupTitle
			GroupBox.Size = UDim2.new(1, -6, 0, 0)
			GroupBox.AutomaticSize = Enum.AutomaticSize.Y
			GroupBox.BackgroundColor3 = Theme.Section_background
			GroupBox.BorderColor3 = Theme.Outline
			GroupBox.BorderSizePixel = 1
			GroupBox.Parent = parentColumn

			local GroupPadding = Instance.new("UIPadding")
			GroupPadding.PaddingTop = UDim.new(0, 20)
			GroupPadding.PaddingBottom = UDim.new(0, 8)
			GroupPadding.PaddingLeft = UDim.new(0, 8)
			GroupPadding.PaddingRight = UDim.new(0, 8)
			GroupPadding.Parent = GroupBox

			local GroupLayout = Instance.new("UIListLayout")
			GroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
			GroupLayout.Padding = UDim.new(0, 6)
			GroupLayout.Parent = GroupBox

			local TitleBox = Instance.new("TextLabel")
			TitleBox.Text = groupTitle
			TitleBox.TextSize = 13
			TitleBox.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
			TitleBox.TextColor3 = Theme.Text_light
			TitleBox.TextXAlignment = Enum.TextXAlignment.Left
			TitleBox.Position = UDim2.new(0, 8, 0, 2)
			TitleBox.Size = UDim2.new(1, 0, 0, 16)
			TitleBox.BackgroundTransparency = 1
			TitleBox.Parent = GroupBox

			local GroupObject = {}

			-- AddToggle
			function GroupObject:AddToggle(flagName: string, options: { Text: string, Default: boolean?, Tooltip: string?, Callback: ((boolean) -> ())? })
				local text = options.Text or flagName
				local defaultState = options.Default or false
				local callback = options.Callback or function() end

				Library.Flags[flagName] = defaultState

				local ToggleRow = Instance.new("TextButton")
				ToggleRow.Name = "Toggle_" .. flagName
				ToggleRow.Text = ""
				ToggleRow.Size = UDim2.new(1, 0, 0, 18)
				ToggleRow.BackgroundTransparency = 1
				ToggleRow.Parent = GroupBox

				local Indicator = Instance.new("Frame")
				Indicator.Size = UDim2.new(0, 12, 0, 12)
				Indicator.Position = UDim2.new(0, 0, 0.5, 0)
				Indicator.AnchorPoint = Vector2.new(0, 0.5)
				Indicator.BackgroundColor3 = defaultState and Theme.Accent or Theme.ComponentBackground
				Indicator.BorderColor3 = Theme.Outline
				Indicator.BorderSizePixel = 1
				Indicator.Parent = ToggleRow

				local Label = Instance.new("TextLabel")
				Label.Text = text
				Label.TextSize = 13
				Label.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Label.TextColor3 = defaultState and Theme.Text_light or Theme.Text_dark
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Position = UDim2.new(0, 18, 0, 0)
				Label.Size = UDim2.new(1, -18, 1, 0)
				Label.BackgroundTransparency = 1
				Label.Parent = ToggleRow

				if options.Tooltip then
					Helpers.Tooltip(ToggleRow, options.Tooltip)
				end

				local function setToggle(val: boolean)
					Library.Flags[flagName] = val
					Indicator.BackgroundColor3 = val and Theme.Accent or Theme.ComponentBackground
					Label.TextColor3 = val and Theme.Text_light or Theme.Text_dark
					callback(val)
				end

				ToggleRow.MouseButton1Click:Connect(function()
					setToggle(not Library.Flags[flagName])
				end)

				local ToggleItem = { SetValue = setToggle }
				Library.Elements[flagName] = ToggleItem
				return ToggleItem
			end

			-- AddSlider
			function GroupObject:AddSlider(flagName: string, options: { Text: string, Min: number, Max: number, Default: number?, Rounding: number?, Callback: ((number) -> ())? })
				local text = options.Text or flagName
				local minVal = options.Min or 0
				local maxVal = options.Max or 100
				local defaultVal = options.Default or minVal
				local rounding = options.Rounding or 0
				local callback = options.Callback or function() end

				Library.Flags[flagName] = defaultVal

				local SliderBox = Instance.new("Frame")
				SliderBox.Name = "Slider_" .. flagName
				SliderBox.Size = UDim2.new(1, 0, 0, 30)
				SliderBox.BackgroundTransparency = 1
				SliderBox.Parent = GroupBox

				local Label = Instance.new("TextLabel")
				Label.Text = text
				Label.TextSize = 13
				Label.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Label.TextColor3 = Theme.Text_light
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Size = UDim2.new(1, -40, 0, 14)
				Label.BackgroundTransparency = 1
				Label.Parent = SliderBox

				local ValueLabel = Instance.new("TextLabel")
				ValueLabel.Text = tostring(defaultVal)
				ValueLabel.TextSize = 13
				ValueLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				ValueLabel.TextColor3 = Theme.Accent
				ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
				ValueLabel.Position = UDim2.new(1, -40, 0, 0)
				ValueLabel.Size = UDim2.new(0, 40, 0, 14)
				ValueLabel.BackgroundTransparency = 1
				ValueLabel.Parent = SliderBox

				local BarBg = Instance.new("TextButton")
				BarBg.Name = "Bar"
				BarBg.Text = ""
				BarBg.Size = UDim2.new(1, 0, 0, 10)
				BarBg.Position = UDim2.new(0, 0, 0, 16)
				BarBg.BackgroundColor3 = Theme.ComponentBackground
				BarBg.BorderColor3 = Theme.Outline
				BarBg.BorderSizePixel = 1
				BarBg.Parent = SliderBox

				local Fill = Instance.new("Frame")
				local initPercent = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
				Fill.Size = UDim2.new(initPercent, 0, 1, 0)
				Fill.BackgroundColor3 = Theme.Accent
				Fill.BorderSizePixel = 0
				Fill.Parent = BarBg

				local function setSlider(val: number)
					local clamped = math.clamp(val, minVal, maxVal)
					if rounding == 0 then
						clamped = math.floor(clamped + 0.5)
					else
						local mult = 10 ^ rounding
						clamped = math.floor(clamped * mult + 0.5) / mult
					end
					Library.Flags[flagName] = clamped
					ValueLabel.Text = tostring(clamped)
					local p = (clamped - minVal) / (maxVal - minVal)
					Fill.Size = UDim2.new(p, 0, 1, 0)
					callback(clamped)
				end

				local dragging = false
				BarBg.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						local mouseX = input.Position.X
						local barX = BarBg.AbsolutePosition.X
						local barW = BarBg.AbsoluteSize.X
						local p = math.clamp((mouseX - barX) / barW, 0, 1)
						setSlider(minVal + p * (maxVal - minVal))
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						local mouseX = input.Position.X
						local barX = BarBg.AbsolutePosition.X
						local barW = BarBg.AbsoluteSize.X
						local p = math.clamp((mouseX - barX) / barW, 0, 1)
						setSlider(minVal + p * (maxVal - minVal))
					end
				end)

				local SliderItem = { SetValue = setSlider }
				Library.Elements[flagName] = SliderItem
				return SliderItem
			end

			-- AddButton
			function GroupObject:AddButton(options: { Text: string, Func: (() -> ())?, Tooltip: string? })
				local btnText = options.Text or "Button"
				local callback = options.Func or function() end

				local Button = Instance.new("TextButton")
				Button.Name = "Button_" .. btnText
				Button.Text = btnText
				Button.TextSize = 13
				Button.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Button.TextColor3 = Theme.Text_light
				Button.BackgroundColor3 = Theme.ComponentBackground
				Button.BorderColor3 = Theme.Outline
				Button.BorderSizePixel = 1
				Button.Size = UDim2.new(1, 0, 0, 20)
				Button.Parent = GroupBox

				if options.Tooltip then
					Helpers.Tooltip(Button, options.Tooltip)
				end

				Button.MouseButton1Click:Connect(function()
					Helpers.ripple(Button)
					callback()
				end)

				return Button
			end

			-- AddDropdown
			function GroupObject:AddDropdown(flagName: string, options: { Values: { string }, Default: any?, Text: string?, Callback: ((string) -> ())? })
				local values = options.Values or {}
				local defaultVal = options.Default or values[1]
				local dropdownText = options.Text or flagName
				local callback = options.Callback or function() end

				Library.Flags[flagName] = defaultVal

				local DropBox = Instance.new("Frame")
				DropBox.Name = "Dropdown_" .. flagName
				DropBox.Size = UDim2.new(1, 0, 0, 36)
				DropBox.BackgroundTransparency = 1
				DropBox.Parent = GroupBox

				local Label = Instance.new("TextLabel")
				Label.Text = dropdownText
				Label.TextSize = 13
				Label.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Label.TextColor3 = Theme.Text_light
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Size = UDim2.new(1, 0, 0, 14)
				Label.BackgroundTransparency = 1
				Label.Parent = DropBox

				local SelectButton = Instance.new("TextButton")
				SelectButton.Text = tostring(defaultVal)
				SelectButton.TextSize = 13
				SelectButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				SelectButton.TextColor3 = Theme.Text_dark
				SelectButton.BackgroundColor3 = Theme.ComponentBackground
				SelectButton.BorderColor3 = Theme.Outline
				SelectButton.BorderSizePixel = 1
				SelectButton.Position = UDim2.new(0, 0, 0, 16)
				SelectButton.Size = UDim2.new(1, 0, 0, 18)
				SelectButton.Parent = DropBox

				local DropList = Instance.new("Frame")
				DropList.Name = "DropList"
				DropList.Visible = false
				DropList.Size = UDim2.new(1, 0, 0, #values * 18)
				DropList.Position = UDim2.new(0, 0, 1, 2)
				DropList.BackgroundColor3 = Theme.DropdownoptionBackground
				DropList.BorderColor3 = Theme.Outline
				DropList.BorderSizePixel = 1
				DropList.ZIndex = 50
				DropList.Parent = SelectButton

				local DropLayout = Instance.new("UIListLayout")
				DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
				DropLayout.Parent = DropList

				for _, opt in ipairs(values) do
					local optBtn = Instance.new("TextButton")
					optBtn.Text = opt
					optBtn.TextSize = 12
					optBtn.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
					optBtn.TextColor3 = (opt == defaultVal) and Theme.Accent or Theme.Text_light
					optBtn.BackgroundColor3 = Theme.DropdownoptionBackground
					optBtn.BorderSizePixel = 0
					optBtn.Size = UDim2.new(1, 0, 0, 18)
					optBtn.ZIndex = 51
					optBtn.Parent = DropList

					optBtn.MouseButton1Click:Connect(function()
						Library.Flags[flagName] = opt
						SelectButton.Text = opt
						DropList.Visible = false
						Library.Elementsopened[DropList] = nil
						callback(opt)
					end)
				end

				SelectButton.MouseButton1Click:Connect(function()
					DropList.Visible = not DropList.Visible
					Library.Elementsopened[DropList] = DropList.Visible and true or nil
				end)

				return DropBox
			end

			-- AddInput
			function GroupObject:AddInput(flagName: string, options: { Text: string?, Default: string?, Placeholder: string?, Numeric: boolean?, Callback: ((string) -> ())? })
				local labelText = options.Text or flagName
				local defaultText = options.Default or ""
				local callback = options.Callback or function() end

				Library.Flags[flagName] = defaultText

				local InputRow = Instance.new("Frame")
				InputRow.Size = UDim2.new(1, 0, 0, 20)
				InputRow.BackgroundTransparency = 1
				InputRow.Parent = GroupBox

				local Label = Instance.new("TextLabel")
				Label.Text = labelText
				Label.TextSize = 13
				Label.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Label.TextColor3 = Theme.Text_light
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Size = UDim2.new(0.5, 0, 1, 0)
				Label.BackgroundTransparency = 1
				Label.Parent = InputRow

				local Box = Instance.new("TextBox")
				Box.Text = defaultText
				Box.PlaceholderText = options.Placeholder or "Input here..."
				Box.TextSize = 13
				Box.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Box.TextColor3 = Theme.Accent
				Box.BackgroundColor3 = Theme.ComponentBackground
				Box.BorderColor3 = Theme.Outline
				Box.BorderSizePixel = 1
				Box.Position = UDim2.new(0.5, 0, 0, 0)
				Box.Size = UDim2.new(0.5, 0, 1, 0)
				Box.Parent = InputRow

				Box.FocusLost:Connect(function()
					local val = Box.Text
					if options.Numeric then
						val = val:gsub("[^%d%.%-]", "")
						Box.Text = val
					end
					Library.Flags[flagName] = val
					callback(val)
				end)

				return InputRow
			end

			-- AddColorPicker
			function GroupObject:AddColorPicker(flagName: string, options: { Title: string?, Default: Color3?, Callback: ((Color3) -> ())? })
				local defaultColor = options.Default or Theme.Accent
				local callback = options.Callback or function() end

				Library.Flags[flagName] = defaultColor

				local ColorRow = Instance.new("Frame")
				ColorRow.Size = UDim2.new(1, 0, 0, 18)
				ColorRow.BackgroundTransparency = 1
				ColorRow.Parent = GroupBox

				local Label = Instance.new("TextLabel")
				Label.Text = options.Title or flagName
				Label.TextSize = 13
				Label.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Label.TextColor3 = Theme.Text_light
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Size = UDim2.new(1, -26, 1, 0)
				Label.BackgroundTransparency = 1
				Label.Parent = ColorRow

				local ColorSwatch = Instance.new("TextButton")
				ColorSwatch.Text = ""
				ColorSwatch.BackgroundColor3 = defaultColor
				ColorSwatch.BorderColor3 = Theme.Outline
				ColorSwatch.BorderSizePixel = 1
				ColorSwatch.AnchorPoint = Vector2.new(1, 0.5)
				ColorSwatch.Position = UDim2.new(1, 0, 0.5, 0)
				ColorSwatch.Size = UDim2.new(0, 22, 0, 12)
				ColorSwatch.Parent = ColorRow

				local function setColor(c: Color3)
					Library.Flags[flagName] = c
					ColorSwatch.BackgroundColor3 = c
					callback(c)
				end

				return { SetColor = setColor }
			end

			-- AddKeyPicker
			function GroupObject:AddKeyPicker(flagName: string, options: { Default: string?, Mode: string?, Text: string?, Callback: ((Enum.KeyCode) -> ())? })
				local defaultKey = options.Default or "MB2"
				local callback = options.Callback or function() end

				Library.Flags[flagName] = defaultKey

				local KeyRow = Instance.new("Frame")
				KeyRow.Size = UDim2.new(1, 0, 0, 18)
				KeyRow.BackgroundTransparency = 1
				KeyRow.Parent = GroupBox

				local Label = Instance.new("TextLabel")
				Label.Text = options.Text or flagName
				Label.TextSize = 13
				Label.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Label.TextColor3 = Theme.Text_light
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Size = UDim2.new(1, -50, 1, 0)
				Label.BackgroundTransparency = 1
				Label.Parent = KeyRow

				local KeyBtn = Instance.new("TextButton")
				KeyBtn.Text = "[" .. defaultKey .. "]"
				KeyBtn.TextSize = 12
				KeyBtn.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				KeyBtn.TextColor3 = Theme.Accent
				KeyBtn.BackgroundTransparency = 1
				KeyBtn.AnchorPoint = Vector2.new(1, 0.5)
				KeyBtn.Position = UDim2.new(1, 0, 0.5, 0)
				KeyBtn.Size = UDim2.new(0, 48, 1, 0)
				KeyBtn.Parent = KeyRow

				local listening = false
				KeyBtn.MouseButton1Click:Connect(function()
					listening = true
					KeyBtn.Text = "[...]"
				end)

				UserInputService.InputBegan:Connect(function(input, gpe)
					if listening and not gpe then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							local keyName = input.KeyCode.Name
							Library.Flags[flagName] = keyName
							KeyBtn.Text = "[" .. (short_keybind_names[input.KeyCode] or keyName) .. "]"
							listening = false
							callback(input.KeyCode)
						end
					end
				end)

				return KeyRow
			end

			-- AddLabel
			function GroupObject:AddLabel(labelText: string)
				local Label = Instance.new("TextLabel")
				Label.Text = labelText
				Label.TextSize = 13
				Label.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
				Label.TextColor3 = Theme.Text_light
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Size = UDim2.new(1, 0, 0, 16)
				Label.BackgroundTransparency = 1
				Label.Parent = GroupBox
				return Label
			end

			-- AddLine
			function GroupObject:AddLine()
				local Line = Instance.new("Frame")
				Line.Size = UDim2.new(1, 0, 0, 1)
				Line.BackgroundColor3 = Theme.Outline
				Line.BorderSizePixel = 0
				Line.Parent = GroupBox
				return Line
			end

			return GroupObject
		end

		return TabObject
	end

	return Window
end

-- ==============================================================================
-- 6. EXPORTS
-- ==============================================================================

print("Omen UI Library loaded successfully.")
return Library, Helpers
