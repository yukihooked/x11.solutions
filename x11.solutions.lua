-- Yukihook UI Library

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local nInstance = Instance.new

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local library = {
	windows = {
	},
	accents = {
	},
	flags = {
	},
	theme = {
		font = Enum.Font.RobotoMono,
		fontSize = 14,
		fontStroke = true,
		fontColor = Color3.fromRGB(255,255,255),
		menuAccent = Color3.fromRGB(244, 117, 11),
		objectColorSequence = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(100,100,100))},
		defaultColorSequence = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(90,90,90))},
		selectedColorSequence = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)), ColorSequenceKeypoint.new(1,Color3.fromRGB(60,60,60))}
	}
}

local gui

local dragging
local dragInput
local dragStart
local startPos

local focused
local subFocused
local highest
local focusedBox

local function updateDrag(input)
	local delta = input.Position - dragStart
	gui.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
end

local function focusOnOption(obj)
	if highest then
		highest.ZIndex = highest.ZIndex - 5
		for _,v in next, highest:GetDescendants() do
			pcall(function()
				v.ZIndex = v.ZIndex +- 5
			end)
		end
	end
	highest = obj
	highest.ZIndex = highest.ZIndex + 5
	for _,v in next, highest:GetDescendants() do
		pcall(function()
			v.ZIndex = v.ZIndex + 5
		end)
	end
end

local function focusOnWindow(obj)
	if focused then
		focused.ZIndex = focused.ZIndex - 10
		for _,v in next, focused:GetDescendants() do
			pcall(function()
				v.ZIndex = v.ZIndex - 10
			end)
		end
	end
	focused = obj
	focused.ZIndex = focused.ZIndex + 10
	for _,v in next, focused:GetDescendants() do
		pcall(function()
			v.ZIndex = v.ZIndex + 10
		end)
	end
end

local function isEvenOrOdd(int)
	if int%2 == 0 then
		return "Right"
	else
		return "Left"
	end
end

function library:Create(class, properties)
	properties = typeof(properties) == "table" and properties or {}
	local inst = nInstance(class)
	for property, value in next, properties do
		inst[property] = value
	end
	return inst
end

function library:CreateLabel(lName, lText, lPos, lAnchor)
	local label = {name = lName or "ScreenLabel",anchorPoint = lAnchor or Vector2.new(0,0), text = lText or "Screen Label", position = lPos or Vector2.new(0,0)}
	local textBound = TextService:GetTextSize(label.text, library.theme.fontSize, self.theme.font, Vector2.new(math.huge, math.huge))

	label.main = self:Create("Frame", {
		Name = "ScreenLabel",
		AnchorPoint = label.anchorPoint,
		Size = UDim2.new(0,textBound.X+8,0,20),
		BackgroundColor3 = Color3.fromRGB(28,28,28),
		Position = UDim2.new(0,label.position.X,0,label.position.Y),
		BorderSizePixel = 1,
		ZIndex = 999998,
		BorderColor3 = Color3.fromRGB(20,20,20),
		Parent = self.base,
	})

	label.gradient = self:Create("UIGradient", {
		Rotation = 90,
		Color = library.theme.defaultColorSequence,
		Parent = label.main,
	})

	label.color = self:Create("Frame", {
		Size = UDim2.new(1,0,0,2),
		Name = "Color",
		BackgroundColor3 = self.theme.menuAccent,
		BorderSizePixel = 0,
		ZIndex = 999999,
		Parent = label.main,
	})

	label.colorGradient = library:Create("UIGradient", {
		Rotation = 90,
		Color = library.theme.defaultColorSequence,
		Parent = label.color,
	})

	label.textContainer = self:Create("Frame", {
		Position = UDim2.new(0,0,0,4),
		Size = UDim2.new(1,0,0,14),
		BackgroundTransparency = 1,
		Name = "TextContainer",
		Parent = label.main,
	})

	label.textPadding = self:Create("UIPadding", {
		PaddingLeft = UDim.new(0,4),
		Parent = label.textContainer,
	})

	label.text = self:Create("TextLabel", {
		Size = UDim2.new(1,0,1,0),
		TextXAlignment = "Left",	
		TextColor3 = library.theme.fontColor,
		TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
		Font = library.theme.font,
		TextSize = library.theme.fontSize,
		Name = "Text",
		ZIndex = 999999,
		Text = label.text,
		BackgroundTransparency = 1,
		Parent = label.textContainer,
	})

	table.insert(library.accents, label.color)

	function label:Set(text)
		local textSize = TextService:GetTextSize(text, library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))
		label.main.Size = UDim2.new(0,textSize.X+8,0,20)
		label.text.Text = text
	end

	function label:SetVisible(value)
		label.main.Visible = value
	end

	function label:Get()
		return label.text.Text
	end

	return label
end

function library:CreateWindow(wName, hidebutton)
	local window = {name = wName or "Window",open = true, draggable = true, hidebutton = hidebutton or Enum.KeyCode.Home, OpenedColorPickers = {}, tabs = {}}
	table.insert(self.windows, window)

	self.base = self.base or self:Create("ScreenGui", {
		Name = "Yukihook",
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 9999999,
	})

	if syn and syn.protect_gui then
		syn.protect_gui(self.base)
	else
		game:GetService("Players").LocalPlayer:Kick("Error: protect_gui function not found")
		return
	end

	self.base.Parent = CoreGui

	self.cursor = self.cursor or self:Create("ImageLabel", {
		ZIndex = 99999999,
		AnchorPoint = Vector2.new(.5,.5),
		Size = UDim2.new(0,32,0,32),
		Name = "Cursor",
		BackgroundTransparency = 1,
		Image = "rbxassetid://7029971234",
		Parent = self.base
	})

	window.colorPickerContainer = self:Create("Frame", {
		Size = UDim2.new(0,0,0,0),
		Position = UDim2.new(0,0,0,0),
		BackgroundTransparency = 1,
		Parent = self.base
	})

	window.main = self:Create("TextButton", {
		Position = UDim2.new(0,500,0,500),
		Size = UDim2.new(0,725,0,465),
		BorderSizePixel = 1,
		AutoButtonColor = false,
		BorderColor3 = Color3.fromRGB(30,30,30),
		BackgroundColor3 = Color3.fromRGB(20,20,20),
		Text = "",
		Name = "Window",
		Parent = self.base,
	})

	window.titleFrame = self:Create("TextButton", {
		Size = UDim2.new(1,0,0,20),
		Name = "Title",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(36,36,36),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = window.main,
	})

	window.titleText = self:Create("TextLabel", {
		Size = UDim2.new(1,-10,1,0),
		Position = UDim2.new(0,10,0,0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Name = "Text",
		Text = window.name,
		TextXAlignment = "Left",	
		Font = self.theme.font,
		TextColor3 = self.theme.fontColor,
		TextStrokeTransparency = self.theme.fontStroke and 0 or 1,
		TextSize = self.theme.fontSize,
		ZIndex = 5,
		Parent = window.titleFrame,
	})

	window.titleBorder = self:Create("Frame", {
		Size = UDim2.new(1,0,0,2),
		Position = UDim2.new(0,0,1,0),
		Name = "Border",
		BackgroundColor3 = Color3.fromRGB(13,13,13),
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = window.titleFrame,
	})

	window.background = self:Create("Frame", {
		Size = UDim2.new(1,0,1,0),
		BackgroundColor3 = Color3.fromRGB(20,20,20),
		BorderColor3 = Color3.fromRGB(30, 30, 30),
		BorderSizePixel = 1,
		ZIndex = 3,
		Name = "Background",
		Parent = window.main
	})

	window.container = self:Create("Frame", {
		Position = UDim2.new(0,7,0,30),
		Size = UDim2.new(1,-14,1,-37),
		BackgroundTransparency = 1,
		Name = "Container",
		ZIndex = 4,
		Parent = window.main,
	})

	window.effectsFolder = self:Create("Folder", {
		Name = "Effects",
		Parent = window.main,
	})

	window.borderLight = self:Create("Frame", {
		Size = UDim2.new(1,4,1,4),
		Position = UDim2.new(0,-2,0,-2),
		BackgroundColor3 = Color3.fromRGB(6, 6, 6),
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = window.effectsFolder,
	})

	window.borderDark = self:Create("Frame" ,{
		Size = UDim2.new(1,4,1,4),
		Position = UDim2.new(0,-2,0,-2),
		BackgroundColor3 = Color3.fromRGB(6, 6, 6),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = window.effectsFolder,
	})

	window.notificationFrame = library:Create("Frame", {
		Position = UDim2.new(0,20,0,40),
		Name = "NotificationFrame",
		BackgroundTransparency = 1,
		Parent = self.base,
	})

	window.notificationLayout = library:Create("UIListLayout", {
		Padding = UDim.new(0,5),
		Parent = window.notificationFrame,
	})

	function window:CreateNotification(text)
		local notification = {text = text or ""}
		local textSize = TextService:GetTextSize(notification.text, library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))

		notification.main = library:Create("Frame", {
			Name = "Notification",
			Size = UDim2.new(0,textSize.X+8,0,20),
			BackgroundColor3 = Color3.fromRGB(28,28,28),
			BorderSizePixel = 1,
			ZIndex = 999998,
			BorderColor3 = Color3.fromRGB(20,20,20),
			Parent = window.notificationFrame,
		})

		notification.gradient = library:Create("UIGradient", {
			Rotation = 90,
			Color = library.theme.defaultColorSequence,
			Parent = notification.main,
		})

		notification.color = library:Create("Frame", {
			Size = UDim2.new(0,2,1,0),
			Name = "Color",
			BackgroundColor3 = library.theme.menuAccent,
			BorderSizePixel = 0,
			ZIndex = 999999,
			Parent = notification.main,
		})

		notification.colorGradient = library:Create("UIGradient", {
			Rotation = 90,
			Color = library.theme.defaultColorSequence,
			Parent = notification.color,
		})

		notification.textContainer = library:Create("Frame", {
			Size = UDim2.new(1,0,1,0),
			BackgroundTransparency = 1,
			Name = "TextContainer",
			Parent = notification.main,
		})

		notification.textPadding = library:Create("UIPadding", {
			PaddingLeft = UDim.new(0,4),
			Parent = notification.textContainer,
		})

		notification.text = library:Create("TextLabel", {
			Size = UDim2.new(1,0,1,0),
			TextXAlignment = "Left",
			TextColor3 = library.theme.fontColor,
			TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
			Font = library.theme.font,
			TextSize = library.theme.fontSize,
			Name = "Text",
			TextWrapped = true,
			ZIndex = 999999,
			Text = notification.text,
			BackgroundTransparency = 1,
			Parent = notification.textContainer,
		})

		table.insert(library.accents, notification.color)

		return notification
	end

	function window:SetVisible(value)
		if value then
			window.open = true
			window.main.Visible = window.open
			library.cursor.Visible = window.open
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		else
			window.open = false
			window.main.Visible = window.open
			library.cursor.Visible = window.open
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end
	window:SetVisible(window.open)

	UserInputService.InputBegan:Connect(function(key)
		if key.KeyCode == window.hidebutton then
			window:SetVisible(not window.open)
		end
	end)

	window.titleFrame.InputBegan:connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and window.draggable then
			gui = window.main
			dragging = true
			dragStart = input.Position
			startPos = gui.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	window.titleFrame.InputChanged:connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	window.main.InputBegan:connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			focusOnWindow(window.main)
		end
	end)

	function window:CreateTab(tName)
		local tab = {name = tName or "Tab", subTabs = {}}
		table.insert(window.tabs, tab)
		local numTabs = #window.tabs

		self.tabList = self.tabList or library:Create("Frame", {
			Size = UDim2.new(1,-3,0,20),
			BackgroundTransparency = 1,
			Name = "TabButtons",
			ZIndex = 30,
			Parent = window.container,
		})

		self.tabButtonLayout = self.tabButtonLayout or library:Create("UIListLayout", {
			Padding = UDim.new(0,1),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = self.tabList,
		})

		self.tabcontainers = self.tabcontainers or library:Create("Frame", {
			Size = UDim2.new(1,0,1,-30),
			Position = UDim2.new(0,0,0,30),
			Name = "Tabs",
			ZIndex = 30,
			BackgroundColor3 = Color3.fromRGB(28,28,28),
			BorderSizePixel = 0,
			Parent = window.container,
		})

		tab.button = library:Create("TextButton", {
			Text = "",
			Size = UDim2.new(1,0,1,0),
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(44,44,44),
			BorderSizePixel = 0,
			TextWrapped = true,
			ZIndex = 30,
			BorderColor3 = Color3.fromRGB(20,20,20),
			Name = tab.name,
			Parent = self.tabList,
		})

		tab.buttonGradient = library:Create("UIGradient", {
			Rotation = 90,
			Color = library.theme.defaultColorSequence,
			Parent = tab.button,
		})

		tab.color = library:Create("Frame", {
			Size = UDim2.new(1,0,0,2),
			Name = "Color",
			ZIndex = 31,
			BackgroundColor3 = library.theme.menuAccent,
			BorderSizePixel = 0,
			Visible = false,
			Parent = tab.button,
		})

		tab.colorGradient = library:Create("UIGradient", {
			Rotation = 90,
			Color = library.theme.defaultColorSequence,
			Parent = tab.color,
		})

		tab.textContainer = library:Create("Frame", {
			Position = UDim2.new(0,0,0,4),
			Size = UDim2.new(1,0,0,14),
			BackgroundTransparency = 1,
			ZIndex = 31,
			Name = "TextContainer",
			Parent = tab.button,
		})

		tab.textPadding = library:Create("UIPadding", {
			PaddingLeft = UDim.new(0,4),
			Parent = tab.textContainer,
		})

		tab.text = library:Create("TextLabel", {
			Size = UDim2.new(1,0,1,0),
			TextXAlignment = "Left",
			TextColor3 = Color3.new(255,255,255),
			TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
			Font = library.theme.font,
			TextSize = library.theme.fontSize,
			Name = "Text",
			ZIndex = 31,
			Text = tostring(tab.name),
			BackgroundTransparency = 1,
			Parent = tab.textContainer,
		})

		tab.container = library:Create("Frame", {
			Size = UDim2.new(1,0,1,0),
			Name = tab.name.."Tab",
			BackgroundTransparency = 1,
			ZIndex = 30,
			Visible = false,
			Parent = self.tabcontainers,
		})

		if numTabs == 1 then
			self.focused = tab
			self.focused.container.Visible = true
			self.focused.color.Visible = true
			self.focused.buttonGradient.Color = library.theme.selectedColorSequence
		end

		table.insert(library.accents, tab.color)

		for _,v in next, window.tabs do
			v.button.Size = UDim2.new(1/numTabs,0,1,0)
		end

		tab.button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self.focused.container.Visible = false
				self.focused.color.Visible = false
				self.focused.buttonGradient.Color = library.theme.defaultColorSequence
				self.focused = tab
				self.focused.container.Visible = true
				self.focused.color.Visible = true
				self.focused.buttonGradient.Color = library.theme.selectedColorSequence
			end
		end)

		tab.button.MouseEnter:Connect(function()
			if self.focused == tab then
				return
			end
			tab.color.Visible = true
		end)

		tab.button.MouseLeave:Connect(function()
			if self.focused == tab then
				return
			end
			tab.color.Visible = false
		end)

		function tab:CreateSubTab(stName)
			local subTab = {name = stName or "SubTab", sections = {}, sectionsLeft = {}, sectionsRight = {}}
			table.insert(tab.subTabs, subTab)
			local numSubTabs = #tab.subTabs

			self.subTabButtons = self.subTabButtons or library:Create("Frame", {
				Size = UDim2.new(1,-3,0,20),
				BackgroundTransparency = 1,
				Name = "SubTabButtons",
				Parent = tab.container,
			})

			self.subTabButtonLayout = self.subTabButtonLayout or library:Create("UIListLayout", {
				Padding = UDim.new(0,1),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = self.subTabButtons,
			})

			self.subTabContainers = self.subTabContainers or library:Create("Frame", {
				Size = UDim2.new(1,0,1,-30),
				Position = UDim2.new(0,0,0,30),
				Name = "SubTabs",
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.fromRGB(28,28,28),
				BorderSizePixel = 0,
				Parent = tab.container,
			})

			subTab.button = library:Create("TextButton", {
				Text = "",
				Size = UDim2.new(1,0,1,0),
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(44,44,44),
				BorderSizePixel = 0,
				ZIndex = 300,
				TextWrapped = true,
				BorderColor3 = Color3.fromRGB(20,20,20),
				Name = subTab.name,
				Parent = self.subTabButtons,
			})

			subTab.subTabGradient = library:Create("UIGradient", {
				Rotation = 90,
				Color = library.theme.defaultColorSequence,
				Parent = subTab.button,
			})

			subTab.color = library:Create("Frame", {
				Size = UDim2.new(1,0,0,2),
				Name = "Color",
				BackgroundColor3 = library.theme.menuAccent,
				BorderSizePixel = 0,
				ZIndex = 301,
				Visible = false,
				Parent = subTab.button,
			})

			subTab.colorGradient = library:Create("UIGradient", {
				Rotation = 90,
				Color = library.theme.defaultColorSequence,
				Parent = subTab.color,
			})

			subTab.textContainer = library:Create("Frame", {
				Position = UDim2.new(0,0,0,4),
				Size = UDim2.new(1,0,0,14),
				BackgroundTransparency = 1,
				ZIndex = 301,
				Name = "TextContainer",
				Parent = subTab.button,
			})

			subTab.textPadding = library:Create("UIPadding", {
				PaddingLeft = UDim.new(0,4),
				Parent = subTab.textContainer,
			})

			subTab.text = library:Create("TextLabel", {
				Size = UDim2.new(1,0,1,0),
				TextXAlignment = "Left",
				TextColor3 = Color3.new(255,255,255),
				TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
				Font = library.theme.font,
				TextSize = library.theme.fontSize,
				Name = "Text",
				Text = subTab.name,
				ZIndex = 301,
				BackgroundTransparency = 1,
				Parent = subTab.textContainer,
			})

			subTab.container = library:Create("ScrollingFrame", {
				Size = UDim2.new(1,0,1,0),
				BackgroundTransparency = 1,
				ScrollBarThickness = 1,
				ScrollBarImageTransparency = 1,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Name = subTab.name.."SubTab",
				Visible = false,
				Parent = self.subTabContainers,
			})

			subTab.containerLeft = library:Create("Frame", {
				Size = UDim2.new(0.5, 0,1, 0),
				BackgroundTransparency = 1,
				Name = "Left",
				Parent = subTab.container,
			})

			subTab.containerLeftLayout = library:Create("UIListLayout", {
				Padding = UDim.new(0,7),
				Parent = subTab.containerLeft,
			})

			subTab.containerLeftPadding = library:Create("UIPadding", {
				PaddingTop = UDim.new(0,7),
				PaddingLeft = UDim.new(0,5),
				Parent = subTab.containerLeft,
			})

			subTab.containerRight = library:Create("Frame", {
				Position = UDim2.new(0.5,0,0,0),
				Size = UDim2.new(0.5,0,1,0),
				BackgroundTransparency = 1,
				Name = "Right",
				Parent = subTab.container,
			})

			subTab.containerRightLayout = library:Create("UIListLayout", {
				Padding = UDim.new(0,10),
				Parent = subTab.containerRight,
			})

			subTab.containerRightPadding = library:Create("UIPadding", {
				PaddingTop = UDim.new(0,10),
				PaddingLeft = UDim.new(0,5),
				Parent = subTab.containerRight,
			})

			if numSubTabs == 1 then
				self.subFocused = subTab
				self.subFocused.container.Visible = true
				self.subFocused.color.Visible = true
				self.subFocused.subTabGradient.Color = library.theme.selectedColorSequence
			end

			table.insert(library.accents, subTab.color)

			for _,v in next, tab.subTabs do
				v.button.Size = UDim2.new(1/numSubTabs,0,1,0)
			end

			subTab.button.MouseEnter:Connect(function()
				if self.subFocused == subTab then
					return
				end
				subTab.color.Visible = true
			end)

			subTab.button.MouseLeave:Connect(function()
				if self.subFocused == subTab then
					return
				end
				subTab.color.Visible = false
			end)

			subTab.button.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					self.subFocused.container.Visible = false
					self.subFocused.color.Visible = false
					self.subFocused.subTabGradient.Color = library.theme.defaultColorSequence
					self.subFocused = subTab
					self.subFocused.container.Visible = true
					self.subFocused.color.Visible = true
					self.subFocused.subTabGradient.Color = library.theme.selectedColorSequence
				end
			end)

			subTab.containerLeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				if subTab.containerLeftLayout.AbsoluteContentSize.Y+20 > subTab.container.CanvasSize.Y.Offset then
					subTab.container.CanvasSize = UDim2.new(0,0,0,subTab.containerLeftLayout.AbsoluteContentSize.Y)
				end
			end)

			function subTab:CreateSection(sName)
				local section = {name = sName or "Section"}
				table.insert(subTab.sections, section)
				local textSize = TextService:GetTextSize(section.name, library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))
				local numSections = #subTab.sections
				local Side = isEvenOrOdd(numSections)

				section.main = library:Create("Frame", {
					Size = UDim2.new(1,-25,0,20),
					BackgroundTransparency = 1,
					Name = section.name:gsub(" ", "") .. "Section",
					Parent = subTab["container"..Side],
				})

				section.title = library:Create("TextLabel", {
					AnchorPoint = Vector2.new(0,0.5),
					Position = UDim2.new(0,12,0,0),
					Size = UDim2.new(0,textSize.X,0,20),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Name = "Text",
					Text = section.name,
					TextColor3 = library.theme.fontColor,
					TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
					Font = library.theme.font,
					ZIndex = 3001,
					TextSize = library.theme.fontSize,
					Parent = section.main,
				})

				section.background = library:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(30,30,30),
					Size = UDim2.new(1,0,1,0),
					Name = "Background",
					BorderSizePixel = 0,
					ZIndex = 3000,
					Parent = section.main,
				})

				section.effects = library:Create("Folder", {
					Name = "Effects",
					Parent = section.main,
				})

				section.border1 = library:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(60,60,60),
					Size = UDim2.new(1,2,1,2),
					Position = UDim2.new(0,-1,0,-1),
					BorderSizePixel = 0,
					ZIndex = 2999,
					Name = "border1",
					Parent = section.effects,
				})

				section.border2 = library:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(0,0,0),
					Size = UDim2.new(1,4,1,4),
					Position = UDim2.new(0,-2,0,-2),
					BorderSizePixel = 0,
					ZIndex = 2998,
					Name = "border2",
					Parent = section.effects,
				})
				section.container = library:Create("Frame", {
					Size = UDim2.new(1,0,1,0),
					Name = "Container",
					BackgroundColor3 = Color3.fromRGB(40, 40, 40),
					BackgroundTransparency = 1,
					Parent = section.main
				})

				section.layout = library:Create("UIListLayout", {
					Padding = UDim.new(0,10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = section.container
				})

				section.padding = library:Create("UIPadding", {
					PaddingLeft = UDim.new(0,6),
					PaddingRight = UDim.new(0,6),
					PaddingTop = UDim.new(0,12),
					Parent = section.container
				})

				function section:CreateLabel(text)
					local label = {text = text or ""}

					label.container = library:Create("Frame", {
						Size = UDim2.new(1,-20,0,15),
						BackgroundTransparency = 1,
						Name = "TextLabel",
						BorderSizePixel = 0,
						Parent = section.container,
					})

					label.textLabel = library:Create("TextLabel", {
						BackgroundTransparency = 1,
						Name = "Text",
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Text = label.text,
						Size = UDim2.new(1,0,1,0),
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 4000,
						Parent = label.container,
					})

					function label:Set(value)
						label.textLabel.Text = value
					end

					section.main.Size = UDim2.new(1,-20, 0, section.layout.AbsoluteContentSize.Y + 18)--UDim2.fromOffset(725 / 2 - 17, section.layout.AbsoluteContentSize.Y + 18)
					subTab.container.CanvasSize = section.main.Size

					return label
				end

				function section:CreateTextbox(text, default, placeholder, flag, _function)
					local textbox = {text = text or "", default = default or "",value = default, placeholder = placeholder or "", flag = flag or "", _function = _function or function() end}

					textbox.container = library:Create("Frame", {
						Name = "Textbox",
						Size = UDim2.new(1,-20,0,15),
						BackgroundTransparency = 1,
						Parent = section.container,
					})

					textbox.boxShell = library:Create("Frame", {
						AnchorPoint = Vector2.new(1,0),
						Position = UDim2.new(1,0,0,0),
						Size = UDim2.new(1,0,1,0),
						BackgroundTransparency = 1,
						Name = "BoxShell",
						Parent = textbox.container,
					})

					textbox.border1 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 3998,
						Parent = textbox.boxShell,
					})

					textbox.border2 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border2",
						ZIndex = 3997,
						Parent = textbox.boxShell,
					})

					textbox.fill = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundColor3 = Color3.fromRGB(13,13,13),
						BorderSizePixel = 0,
						Name = "Fill",
						ZIndex = 3999,
						Parent = textbox.boxShell,
					})

					textbox.textBox = library:Create("TextBox", {
						Size = UDim2.new(1,-5,1,0),
						Position = UDim2.new(0,5,0,0),
						BackgroundTransparency = 1,
						Name = "Text",
						ZIndex = 4000,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						PlaceholderText = textbox.placeholder,
						Text = textbox.default,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = textbox.boxShell,
					})

					function textbox:Set(value)
						textbox.textBox.Text = value
						pcall(textbox._function, value)
						library.flags[textbox.flag] = value
					end
					textbox:Set(textbox.default)

					function textbox:Get()
						return textbox.value
					end

					textbox.textBox.FocusLost:Connect(function()
						textbox:Set(textbox.textBox.Text)
					end)

					return textbox
				end

				function section:CreateButton(text, _function)
					local button = {text = text or "", _function = _function or function() end}
					local textSize = TextService:GetTextSize(button.text, library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))

					button.container = library:Create("Frame", {
						Size = UDim2.new(0,textSize.X+8,0,15),
						BackgroundTransparency = 1,
						Name = "TextButton",
						BorderSizePixel = 0,
						Parent = section.container,
					})

					button.fill = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundColor3 = Color3.fromRGB(13,13,13),
						BorderSizePixel = 0,
						Name = "Fill",
						ZIndex = 3999,
						Parent = button.container,
					})

					button.border1 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 3998,
						Parent = button.container,
					})

					button.border2 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 3997,
						Parent = button.container,
					})

					button.textButton = library:Create("TextButton", {
						BackgroundTransparency = 1,
						AutoButtonColor = false,
						Name = "Text",
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Text = button.text,
						Position = UDim2.new(0,4,0,0),
						Size = UDim2.new(1,-4,1,0),
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 4000,
						Parent = button.container,
					})

					button.container.MouseEnter:Connect(function()
						button.border2.BackgroundColor3 = library.theme.menuAccent
					end)

					button.container.MouseLeave:Connect(function()
						button.border2.BackgroundColor3 = Color3.fromRGB(6,6,6)
					end)

					button.textButton.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							pcall(button._function)
						end
					end)

					section.main.Size = UDim2.new(1,-20, 0, section.layout.AbsoluteContentSize.Y + 18)--UDim2.fromOffset(725 / 2 - 17, section.layout.AbsoluteContentSize.Y + 18)
					subTab.container.CanvasSize = section.main.Size

					return button
				end

				function section:CreateKeybind(text, default, _function)
					local keybind = {text = text or "", default = default or false, value = default, _function = _function or function() end}

					keybind.container = library:Create("Frame", {
						Size = UDim2.new(1,-20,0,15),
						Name = "Keybind",
						BackgroundTransparency = 1,
						Parent = section.container,
					})

					keybind.title = library:Create("TextLabel", {
						Size = UDim2.new(1,0,0,10),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Name = "Text",
						ZIndex = 4000,
						Text = keybind.text,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = keybind.container,
					})

					keybind.keyShell = library:Create("Frame", {
						AnchorPoint = Vector2.new(1,0),
						Position = UDim2.new(1,0,0,0),
						Size = UDim2.new(0,30,1,0),
						BackgroundTransparency = 1,
						Name = "KeyShell",
						Parent = keybind.container,
					})

					keybind.border1 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 3998,
						Parent = keybind.keyShell,
					})

					keybind.border2 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border2",
						ZIndex = 3997,
						Parent = keybind.keyShell,
					})

					keybind.fill = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundColor3 = Color3.fromRGB(13,13,13),
						BorderSizePixel = 0,
						Name = "Fill",
						ZIndex = 3999,
						Parent = keybind.keyShell,
					})

					keybind.textButton = library:Create("TextButton", {
						Size = UDim2.new(1,-5,1,0),
						Position = UDim2.new(0,5,0,0),
						BackgroundTransparency = 1,
						AutoButtonColor = false,
						Name = "Text",
						ZIndex = 4000,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Right,
						Parent = keybind.keyShell,
					})

					function keybind:Set(value)
						if value ~= "None" then
							local valueSize = TextService:GetTextSize("["..value.Name.."]", library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))
							keybind.keyShell.Size = UDim2.new(0,valueSize.X+2,1,0)
							keybind.textButton.Text = "["..value.Name.."]"
							keybind.value = value
						else
							local valueSize = TextService:GetTextSize("[None]", library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))
							keybind.keyShell.Size = UDim2.new(0,valueSize.X+2,1,0)
							keybind.textButton.Text = "[None]"
							keybind.value = "None"
						end
					end
					keybind:Set(keybind.default)

					function keybind:Get()
						return keybind.value
					end

					keybind.textButton.MouseButton1Down:Connect(function()
						local keySize = TextService:GetTextSize("[...]", library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))
						keybind.keyShell.Size = UDim2.new(0,keySize.X+2,1,0)
						keybind.textButton.Text = "[...]"
					end)

					keybind.keyShell.MouseEnter:Connect(function()
						keybind.border2.BackgroundColor3 = library.theme.menuAccent
					end)

					keybind.keyShell.MouseLeave:Connect(function()
						keybind.border2.BackgroundColor3 = Color3.fromRGB(6,6,6)
					end)

					UserInputService.InputBegan:Connect(function(input, gameProcessed)
						if not gameProcessed then
							if keybind.textButton.Text == "[...]" then
								if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name ~= "Backspace" then
									keybind:Set(input.KeyCode)
								else
									keybind:Set("None")
								end
								pcall(keybind._function, keybind.value)
							else
								if keybind.value ~= "None" and input.KeyCode == keybind.value then
									pcall(keybind._function)
								end
							end
						end
					end)

					section.main.Size = UDim2.new(1,-20, 0, section.layout.AbsoluteContentSize.Y + 18)--UDim2.fromOffset(725 / 2 - 17, section.layout.AbsoluteContentSize.Y + 18)
					subTab.container.CanvasSize = section.main.Size

					return keybind
				end

				function section:CreateToggle(text, default, flag, _function)
					local toggle = {text = text or "", default = default or false, flag = flag or "",items = {}, value = default, _function = _function or function() end}

					toggle.container = library:Create("Frame", {
						Size = UDim2.new(1,-20,0,15),
						BackgroundTransparency = 1,
						Name = "Toggle",
						BorderSizePixel = 0,
						Parent = section.container,
					})

					toggle.list = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						Name = "List",
						BackgroundTransparency = 1,
						Parent = toggle.container,
					})

					toggle.listLayout = library:Create("UIListLayout", {
						Padding = UDim.new(0,10),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = toggle.list
					})

					toggle.title = library:Create("TextLabel", {
						Size = UDim2.new(1,-20,1,0),
						Position = UDim2.new(0,20,0,0),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Name = "Text",
						Text = toggle.text,
						ZIndex = 4000,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = toggle.container,
					})

					toggle.capture = library:Create("TextButton", {
						Size = UDim2.new(1,0,1,0),
						Text = "",
						Name = "Capture",
						BackgroundTransparency = 1,
						Parent = toggle.container,
					})

					toggle.toggleShell = library:Create("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(0,15,0,15),
						Name = "ToggleShell",
						Parent = toggle.container
					})

					toggle.border1 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 3998,
						Parent = toggle.toggleShell,
					})

					toggle.border2 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border2",
						ZIndex = 3997,
						Parent = toggle.toggleShell,
					})

					toggle.fill = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundColor3 = library.theme.menuAccent,
						BorderSizePixel = 0,
						Name = "ToggleColor",
						ZIndex = 4000,
						Parent = toggle.toggleShell
					})
					table.insert(library.accents, toggle.fill)

					toggle.fillGradient = library:Create("UIGradient", {
						Color = library.theme.defaultColorSequence,
						Rotation = 90,
						Parent = toggle.fill,
					})

					function toggle:Set(value) 
						toggle.value = value
						toggle.fill.Visible = value
						pcall(toggle._function, value) 
						library.flags[toggle.flag] = value
					end
					toggle:Set(toggle.default)

					function toggle:Get()
						return toggle.value
					end

					function toggle:AddColorPicker(default, flag, _subFunction)
						local colorpicker = {default = default or Color3.fromRGB(255,255,255), value = default, color = default, draggingColor = false, draggingHue = false,flag = flag or "", _subFunction = _subFunction or function() end}
						if #toggle.items < 3 then
							table.insert(toggle.items, colorpicker)
						else
							return
						end

						colorpicker.colorShell = library:Create("Frame", {
							AnchorPoint = Vector2.new(1,0),
							Size = UDim2.new(0,30,1,0),
							BackgroundTransparency = 1,
							Name = "colorShell",
							Parent = toggle.list,
						})

						colorpicker.border1 = library:Create("Frame", {
							Position = UDim2.new(0,-1,0,-1),
							Size = UDim2.new(1,2,1,2),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderSizePixel = 0,
							Name = "Border",
							ZIndex = 3998,
							Parent = colorpicker.colorShell,
						})

						colorpicker.border2 = library:Create("Frame", {
							Position = UDim2.new(0,-2,0,-2),
							Size = UDim2.new(1,4,1,4),
							BackgroundColor3 = Color3.fromRGB(6, 6, 6),
							BorderSizePixel = 0,
							Name = "Border2",
							ZIndex = 3997,
							Parent = colorpicker.colorShell,
						})

						colorpicker.fill = library:Create("Frame", {
							Size = UDim2.new(1,0,1,0),
							BackgroundColor3 = colorpicker.value,
							BorderSizePixel = 0,
							Name = "Fill",
							ZIndex = 4000,
							Parent = colorpicker.colorShell,
						})

						colorpicker.mainPicker = library:Create("Frame", {
							Name = "colorWindow",
							ZIndex = 30000,
							Visible = false,
							Size = UDim2.fromOffset(160, 178),
							BorderSizePixel = 0,
							BackgroundColor3 = Color3.fromRGB(40, 40, 40),
							Position = UDim2.new(0,colorpicker.colorShell.AbsolutePosition.X+colorpicker.colorShell.AbsoluteSize.X,0,colorpicker.colorShell.AbsolutePosition.Y),
							Parent = window.colorPickerContainer
						})
						window.OpenedColorPickers[colorpicker.mainPicker] = false

						colorpicker.border3 = library:Create("Frame", {
							Position = UDim2.new(0,-1,0,-1),
							Size = UDim2.new(1,2,1,2),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderSizePixel = 0,
							Name = "Border",
							ZIndex = 29999,
							Parent = colorpicker.mainPicker,
						})

						colorpicker.border4 = library:Create("Frame", {
							Position = UDim2.new(0,-2,0,-2),
							Size = UDim2.new(1,4,1,4),
							BackgroundColor3 = Color3.fromRGB(6, 6, 6),
							BorderSizePixel = 0,
							Name = "Border2",
							ZIndex = 29998,
							Parent = colorpicker.mainPicker,
						})

						colorpicker.hue = library:Create("ImageLabel", {
							ZIndex = 30001,
							Position = UDim2.new(0,5,0,5),
							Size = UDim2.new(0,150,0,150),
							Name = "Hue",
							Image = "rbxassetid://4155801252",
							ScaleType = Enum.ScaleType.Stretch,
							BackgroundColor3 = Color3.new(1,0,0),
							BorderSizePixel = 0,
							Parent = colorpicker.mainPicker,
						})

						colorpicker.hueSelector = library:Create("ImageLabel", {
							ZIndex = 30002,
							Name = "HueSelector",
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Position = UDim2.new(0, 0, 0, 0),
							Size = UDim2.new(0, 7, 0, 7),
							Image = "rbxassetid://6885856475",
							Parent = colorpicker.mainPicker,
						})

						colorpicker.selector = library:Create("TextLabel", {
							ZIndex = 30001,
							Position = UDim2.new(0,5,0,163),
							Name = "ColorSelector",
							Size = UDim2.new(0,150,0,10),
							BackgroundColor3 = Color3.fromRGB(255,255,255),
							BorderSizePixel = 0,
							Text = "",
							Parent = colorpicker.mainPicker,
						})

						colorpicker.selectGradient = library:Create("UIGradient", {
							Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,0,0)), ColorSequenceKeypoint.new(0.25,Color3.new(1,0,1)), ColorSequenceKeypoint.new(0.5,Color3.new(0,1,1)), ColorSequenceKeypoint.new(0.75,Color3.new(1,1,0)), ColorSequenceKeypoint.new(1,Color3.new(1,0,0))}),
							Parent = colorpicker.selector,
						})

						colorpicker.pointer = library:Create("Frame", {
							ZIndex = 30050,
							BackgroundColor3 = Color3.fromRGB(13,13,13),
							Position = UDim2.new(0,0,0,0),
							Size = UDim2.new(0,2,0,10),
							Name = "Pointer",
							BorderSizePixel = 0,
							Parent = colorpicker.selector,
						})

						colorpicker.border5 = library:Create("Frame", {
							Position = UDim2.new(0,-1,0,-1),
							Size = UDim2.new(1,2,1,2),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderSizePixel = 0,
							Name = "Border",
							ZIndex = 30049,
							Parent = colorpicker.pointer,
						})

						colorpicker.border6 = library:Create("Frame", {
							Position = UDim2.new(0,-2,0,-2),
							Size = UDim2.new(1,4,1,4),
							BackgroundColor3 = Color3.fromRGB(6, 6, 6),
							BorderSizePixel = 0,
							Name = "Border2",
							ZIndex = 30048,
							Parent = colorpicker.pointer,
						})

						colorpicker.colorShell.MouseEnter:Connect(function()
							colorpicker.border2.BackgroundColor3 = library.theme.menuAccent
						end)

						colorpicker.colorShell.MouseLeave:Connect(function()
							colorpicker.border2.BackgroundColor3 = Color3.fromRGB(6,6,6)
						end)

						function colorpicker:Set(value)
							local color = Color3.new(math.clamp(value.r, 0, 1), math.clamp(value.g, 0, 1), math.clamp(value.b, 0, 1))
							colorpicker.value = color
							colorpicker.fill.BackgroundColor3 = color
							pcall(colorpicker._subFunction, color)
							library.flags[colorpicker.flag] = value
						end
						colorpicker:Set(colorpicker.default)

						function colorpicker:Get(value)
							return colorpicker.value
						end

						function colorpicker:RefreshHue()
							local x = (Mouse.X - colorpicker.hue.AbsolutePosition.X) / colorpicker.hue.AbsoluteSize.X
							local y = (Mouse.Y - colorpicker.hue.AbsolutePosition.Y) / colorpicker.hue.AbsoluteSize.Y
							colorpicker.hueSelector:TweenPosition(UDim2.new(math.clamp(x * colorpicker.hue.AbsoluteSize.X, 0.5, 0.945 * colorpicker.hue.AbsoluteSize.X) / colorpicker.hue.AbsoluteSize.X, 0, math.clamp(y * colorpicker.hue.AbsoluteSize.Y, 0.5, 0.855 * colorpicker.hue.AbsoluteSize.Y) / colorpicker.hue.AbsoluteSize.Y, 0), Enum.EasingDirection.In, Enum.EasingStyle.Sine, 0.05)
							colorpicker:Set(Color3.fromHSV(colorpicker.color, math.clamp(x * colorpicker.hue.AbsoluteSize.X, 0.5, 1 * colorpicker.hue.AbsoluteSize.X) / colorpicker.hue.AbsoluteSize.X, 1 - (math.clamp(y * colorpicker.hue.AbsoluteSize.Y, 0.5, 1 * colorpicker.hue.AbsoluteSize.Y) / colorpicker.hue.AbsoluteSize.Y)))
						end

						function colorpicker:RefreshSelector()
							local pos = math.clamp((Mouse.X - colorpicker.hue.AbsolutePosition.X) / colorpicker.hue.AbsoluteSize.X, 0, 1)
							colorpicker.color = 1 - pos
							colorpicker.pointer:TweenPosition(UDim2.new(pos, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Sine, 0.05)
							colorpicker.hue.BackgroundColor3 = Color3.fromHSV(1 - pos, 1, 1)
						end

						colorpicker.selector.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								colorpicker.draggingColor = true
								colorpicker:RefreshSelector()
							end
						end)

						colorpicker.selector.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								colorpicker.draggingColor = false
								colorpicker:RefreshSelector()
							end
						end)

						colorpicker.hue.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								colorpicker.draggingHue = true
								colorpicker:RefreshHue()
							end
						end)

						colorpicker.hue.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								colorpicker.draggingHue = false
								colorpicker:RefreshHue()
							end
						end)

						UserInputService.InputChanged:Connect(function(input)
							if colorpicker.draggingColor and input.UserInputType == Enum.UserInputType.MouseMovement then
								colorpicker:RefreshSelector()
							end
							if colorpicker.draggingHue and input.UserInputType == Enum.UserInputType.MouseMovement then
								colorpicker:RefreshHue()
							end
						end)

						colorpicker.colorShell.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								for i,v in pairs(window.OpenedColorPickers) do
									if v and i ~= colorpicker.mainPicker then
										i.Visible = false
										window.OpenedColorPickers[i] = false
									end
								end
								colorpicker.mainPicker.Visible = not colorpicker.mainPicker.Visible
								window.OpenedColorPickers[colorpicker.mainPicker] = colorpicker.mainPicker.Visible
							end
						end)

						return colorpicker
					end

					function toggle:AddKeybind(default, _subFunction)
						local keybind = { default = default or false, value = default, _subFunction = _subFunction or function() end}
						if #toggle.items < 3 then
							table.insert(toggle.items, keybind)
						else
							return
						end

						keybind.keyShell = library:Create("Frame", {
							AnchorPoint = Vector2.new(1,0),
							Size = UDim2.new(0,30,1,0),
							BackgroundTransparency = 1,
							Name = "KeyShell",
							Parent = toggle.list,
						})

						keybind.border1 = library:Create("Frame", {
							Position = UDim2.new(0,-1,0,-1),
							Size = UDim2.new(1,2,1,2),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderSizePixel = 0,
							Name = "Border",
							ZIndex = 3998,
							Parent = keybind.keyShell,
						})

						keybind.border2 = library:Create("Frame", {
							Position = UDim2.new(0,-2,0,-2),
							Size = UDim2.new(1,4,1,4),
							BackgroundColor3 = Color3.fromRGB(6, 6, 6),
							BorderSizePixel = 0,
							Name = "Border2",
							ZIndex = 3997,
							Parent = keybind.keyShell,
						})

						keybind.fill = library:Create("Frame", {
							Size = UDim2.new(1,0,1,0),
							BackgroundColor3 = Color3.fromRGB(13,13,13),
							BorderSizePixel = 0,
							Name = "Fill",
							ZIndex = 4000,
							Parent = keybind.keyShell,
						})

						keybind.textButton = library:Create("TextButton", {
							Size = UDim2.new(1,-5,1,0),
							Position = UDim2.new(0,5,0,0),
							BackgroundTransparency = 1,
							AutoButtonColor = false,
							Name = "Text",
							ZIndex = 4001,
							TextColor3 = library.theme.fontColor,
							TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
							Font = library.theme.font,
							TextSize = library.theme.fontSize,
							TextXAlignment = Enum.TextXAlignment.Right,
							Parent = keybind.keyShell,
						})

						function keybind:Set(value)
							if value ~= "None" then
								local valueSize = TextService:GetTextSize("["..value.Name.."]", library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))
								keybind.keyShell.Size = UDim2.new(0,valueSize.X+2,1,0)
								keybind.textButton.Text = "["..value.Name.."]"
								keybind.value = value
							else
								local valueSize = TextService:GetTextSize("[None]", library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))
								keybind.keyShell.Size = UDim2.new(0,valueSize.X+2,1,0)
								keybind.textButton.Text = "[None]"
								keybind.value = "None"
							end
						end
						keybind:Set(keybind.default)

						function keybind:Get()
							return keybind.value
						end

						keybind.textButton.MouseButton1Down:Connect(function()
							local keySize = TextService:GetTextSize("[...]", library.theme.fontSize, library.theme.font, Vector2.new(math.huge, math.huge))
							keybind.keyShell.Size = UDim2.new(0,keySize.X+2,1,0)
							keybind.textButton.Text = "[...]"
						end)

						keybind.textButton.MouseButton2Down:Connect(function()
							print("Replacement for later")
						end)

						keybind.keyShell.MouseEnter:Connect(function()
							keybind.border2.BackgroundColor3 = library.theme.menuAccent
						end)

						keybind.keyShell.MouseLeave:Connect(function()
							keybind.border2.BackgroundColor3 = Color3.fromRGB(6,6,6)
						end)

						UserInputService.InputBegan:Connect(function(input, gameProcessed)
							if not gameProcessed then
								if keybind.textButton.Text == "[...]" then
									if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name ~= "Backspace" then
										keybind:Set(input.KeyCode)
									else
										keybind:Set("None")
									end
								else
									if keybind.value ~= "None" and input.KeyCode == keybind.value then
										toggle:Set(not toggle.value)
									end
								end
							end
						end)

						return keybind
					end

					toggle.capture.MouseEnter:Connect(function()
						toggle.border2.BackgroundColor3 = library.theme.menuAccent
					end)

					toggle.capture.MouseLeave:Connect(function()
						toggle.border2.BackgroundColor3 = Color3.fromRGB(6,6,6)
					end)

					toggle.capture.MouseButton1Down:Connect(function()
						toggle:Set(not toggle.fill.Visible)
					end)

					toggle.listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
						toggle.capture.Size = UDim2.new(1,-toggle.listLayout.AbsoluteContentSize.X - 2,1,0)
					end)

					section.main.Size = UDim2.new(1,-20, 0, section.layout.AbsoluteContentSize.Y + 18)--UDim2.fromOffset(725 / 2 - 17, section.layout.AbsoluteContentSize.Y + 18)
					subTab.container.CanvasSize = section.main.Size

					return toggle
				end

				function section:CreateSlider(text, min, default, max, precision, unit, flag, _function)
					local slider = {text = text or "", min = min or 0, max = max or 10, default = default or min, precision = precision or 1,value = default or min, unit = unit or "", dragging = false, flag = flag or "", _function = _function or function() end}

					slider.container = library:Create("Frame", {
						Size = UDim2.new(1,-20,0,30),
						BackgroundTransparency = 1,
						Name = "Slider",
						Parent = section.container,
					})

					slider.title = library:Create("TextLabel", {
						Size = UDim2.new(1,0,0,10),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Name = "Text",
						ZIndex = 4000,
						Text = slider.text,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = slider.container,
					})

					slider.sliderShell = library:Create("Frame", {
						Position = UDim2.new(0,0,.5,0),
						Size = UDim2.new(1,0,.5,0),
						BackgroundTransparency = 1,
						Name = "SliderShell",
						Parent = slider.container,
					})

					slider.border1 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 3998,
						Parent = slider.sliderShell,
					})

					slider.border2 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border2",
						ZIndex = 3997,
						Parent = slider.sliderShell,
					})

					slider.fill = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundColor3 = Color3.fromRGB(13,13,13),
						BorderSizePixel = 0,
						Name = "Fill",
						ZIndex = 4000,
						Parent = slider.sliderShell,
					})

					slider.sliderColor = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundColor3 = library.theme.menuAccent,
						BorderSizePixel = 0,
						Name = "SliderColor",
						ZIndex = 4001,
						Parent = slider.sliderShell
					})

					slider.sliderColorGradient = library:Create("UIGradient", {
						Color = library.theme.defaultColorSequence,
						Rotation = 90,
						Parent = slider.sliderColor,
					})

					slider.sliderValue = library:Create("TextLabel", {
						Size = UDim2.new(1,-10,1,0),
						Position = UDim2.new(0,5,0,0),
						Text = "",
						BackgroundTransparency = 1,
						Name = "SliderValue",
						ZIndex = 4001,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Right,
						Parent = slider.sliderShell,
					})

					function slider:Set(value)
						if slider.precision < 2 then
							value = math.floor(value)
						end
						value = tonumber(string.format("%."..slider.precision.."f", value))
						local spercent = 1 - ((slider.max - value) / (slider.max - slider.min))
						slider.sliderColor.Size = UDim2.new(spercent,0,1,0)
						slider.sliderValue.Text = tostring(value)..slider.unit
						pcall(slider._function, value)
						library.flags[slider.flag] = value
					end
					slider:Set(slider.default)

					function slider:Refresh()
						local rpercent = math.clamp((Mouse.X - slider.sliderShell.AbsolutePosition.X) / (slider.sliderShell.AbsoluteSize.X), 0, 1)
						local rvalue = slider.min + (slider.max - slider.min) * rpercent
						slider:Set(rvalue)
					end

					function slider:Get()
						return slider.value
					end

					slider.sliderShell.MouseEnter:Connect(function()
						slider.border2.BackgroundColor3 = library.theme.menuAccent
					end)

					slider.sliderShell.MouseLeave:Connect(function()
						slider.border2.BackgroundColor3 = Color3.fromRGB(6,6,6)
					end)

					slider.sliderShell.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							slider.dragging = true
							slider:Refresh()
						end
					end)

					slider.sliderShell.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							slider.dragging = false
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if slider.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
							slider:Refresh()
						end
					end)

					section.main.Size = UDim2.new(1,-20, 0, section.layout.AbsoluteContentSize.Y + 18)--UDim2.fromOffset(725 / 2 - 17, section.layout.AbsoluteContentSize.Y + 18)
					subTab.container.CanvasSize = section.main.Size

					table.insert(library.accents, slider.sliderColor)

					return slider
				end

				function section:CreateDropdown(text, list, default, flag, _function)
					local dropdown = {text = text or "", list = list or {}, default = default or "", flag = flag or "",value = default, _function = _function or function() end}

					dropdown.container = library:Create("Frame", {
						Size = UDim2.new(1,-20,0,30),
						BackgroundTransparency = 1,
						Name = "Dropdown",
						Parent = section.container,
					})

					dropdown.title = library:Create("TextLabel", {
						Size = UDim2.new(1,0,0,10),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Name = "Text",
						ZIndex = 4000,
						Text = dropdown.text,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = dropdown.container,
					})

					dropdown.dropdownShell = library:Create("Frame", {
						Position = UDim2.new(0,0,0,10),
						Size = UDim2.new(1,0,1,-15),
						BackgroundTransparency = 1,
						Name = "DropdownShell",
						Parent = dropdown.container,
					})

					dropdown.border1 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 3998,
						Parent = dropdown.dropdownShell,
					})

					dropdown.border2 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border2",
						ZIndex = 3997,
						Parent = dropdown.dropdownShell,
					})

					dropdown.fill = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundColor3 = Color3.fromRGB(13,13,13),
						BorderSizePixel = 0,
						Name = "Fill",
						ZIndex = 3999,
						Parent = dropdown.dropdownShell,
					})

					dropdown.textValue = library:Create("TextLabel", {
						BackgroundTransparency = 1,
						Position = UDim2.new(0,5,0,0),
						Size = UDim2.new(1,-25,1,0),
						Name = "Listing",
						Text = "",
						ZIndex = 4005,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = dropdown.dropdownShell
					})

					dropdown.arrow = library:Create("ImageLabel", {
						Image = "rbxassetid://6830101636",
						BackgroundTransparency = 1,
						Name = "Arrow",
						ZIndex = 4005,
						Position = UDim2.new(1, -14,0.5, -6),
						Size = UDim2.new(0, 12,0, 12),
						Parent = dropdown.dropdownShell,
					})

					dropdown.button = library:Create("TextButton", {
						AutoButtonColor = false,
						BackgroundTransparency = 1,
						Name = "Button",
						Text = "",
						ZIndex = 4010,
						Size = UDim2.new(1,0,0,20),
						Parent = dropdown.dropdownShell,
					})

					dropdown.listing = library:Create("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1,0,0,0),
						Name = "Listing",
						Visible = false,
						Position = UDim2.new(0,0,1,5),
						Parent = dropdown.dropdownShell
					})

					dropdown.listingLayout = library:Create("UIListLayout", {
						Padding = UDim.new(0,5),
						Parent = dropdown.listing
					})

					function dropdown:Set(value)
						if dropdown.listing.Visible then
							dropdown.listing.Visible = false
						end
						dropdown.textValue.Text = value
						dropdown.value = value
						library.flags[dropdown.flag] = value
						pcall(dropdown._function, value)
					end
					dropdown:Set(dropdown.default)

					function dropdown:Get()
						return dropdown.value
					end

					dropdown.button.MouseButton1Down:Connect(function()
						dropdown.listing.Visible = not dropdown.listing.Visible
					end)

					function dropdown:AddItem(iName)
						local item = {text = iName or ""}

						item.container = library:Create("Frame", {
							Size = UDim2.new(1,0,0,15),
							BackgroundTransparency = 1,
							Name = item.text,
							Parent = dropdown.listing,
						})

						item.border1 = library:Create("Frame", {
							Position = UDim2.new(0,-1,0,-1),
							Size = UDim2.new(1,2,1,2),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderSizePixel = 0,
							Name = "Border",
							ZIndex = 4999,
							Parent = item.container,
						})

						item.border2 = library:Create("Frame", {
							Position = UDim2.new(0,-2,0,-2),
							Size = UDim2.new(1,4,1,4),
							BackgroundColor3 = Color3.fromRGB(6, 6, 6),
							BorderSizePixel = 0,
							Name = "Border2",
							ZIndex = 4998,
							Parent = item.container,
						})

						item.fill = library:Create("Frame", {
							Size = UDim2.new(1,0,1,0),
							BackgroundColor3 = Color3.fromRGB(13,13,13),
							BorderSizePixel = 0,
							Name = "Fill",
							ZIndex = 5000,
							Parent = item.container,
						})

						item.textContainer = library:Create("Frame", {
							BackgroundTransparency = 1,
							Size = UDim2.new(1,0,1,0),
							Parent = item.container
						})

						item.textPadding = library:Create("UIPadding", {
							PaddingLeft = UDim.new(0,5),
							Parent = item.textContainer
						})

						item.textLabel = library:Create("TextLabel", {
							Size = UDim2.new(1,0,1,0),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							Name = "Text",
							ZIndex = 5050,
							Text = item.text,
							TextColor3 = library.theme.fontColor,
							TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
							Font = library.theme.font,
							TextSize = library.theme.fontSize,
							TextXAlignment = Enum.TextXAlignment.Left,
							Parent = item.textContainer,
						})

						item.button = library:Create("TextButton", {
							AutoButtonColor = false,
							BackgroundTransparency = 1,
							Name = "Button",
							Text = "",
							ZIndex = 5051,
							Size = UDim2.new(1,0,0,20),
							Parent = item.container,
						})

						item.button.MouseButton1Down:Connect(function()
							dropdown:Set(item.text)
						end)

						return item
					end

					for _,p in next, list do
						dropdown:AddItem(p)
					end

					section.main.Size = UDim2.new(1,-20, 0, section.layout.AbsoluteContentSize.Y + 18)--UDim2.fromOffset(725 / 2 - 17, section.layout.AbsoluteContentSize.Y + 18)
					subTab.container.CanvasSize = section.main.Size

					return dropdown
				end

				function section:CreateColorpicker(text, default, flag, _function)
					local colorpicker = {text = text or "", items = {}, default = default or Color3.fromRGB(255,255,255), value = default, color = default, draggingColor = false, draggingHue = false,flag = flag or "", _function = _function or function() end}

					colorpicker.container = library:Create("Frame", {
						Size = UDim2.new(1,-20,0,15),
						Name = "Colorpicker",
						BackgroundTransparency = 1,
						Parent = section.container,
					})

					colorpicker.title = library:Create("TextLabel", {
						Size = UDim2.new(1,0,0,10),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Name = "Text",
						ZIndex = 4000,
						Text = colorpicker.text,
						TextColor3 = library.theme.fontColor,
						TextStrokeTransparency = library.theme.fontStroke and 0 or 1,
						Font = library.theme.font,
						TextSize = library.theme.fontSize,
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = colorpicker.container,
					})

					colorpicker.colorShell = library:Create("Frame", {
						AnchorPoint = Vector2.new(1,0),
						Position = UDim2.new(1,0,0,0),
						Size = UDim2.new(0,30,1,0),
						BackgroundTransparency = 1,
						Name = "colorShell",
						Parent = colorpicker.container,
					})

					colorpicker.border1 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 3998,
						Parent = colorpicker.colorShell,
					})

					colorpicker.border2 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border2",
						ZIndex = 3997,
						Parent = colorpicker.colorShell,
					})

					colorpicker.fill = library:Create("Frame", {
						Size = UDim2.new(1,0,1,0),
						BackgroundColor3 = colorpicker.value,
						BorderSizePixel = 0,
						Name = "Fill",
						ZIndex = 4000,
						Parent = colorpicker.colorShell,
					})

					colorpicker.mainPicker = library:Create("Frame", {
						Name = "colorWindow",
						ZIndex = 30000,
						Visible = false,
						Size = UDim2.fromOffset(160, 178),
						BorderSizePixel = 0,
						BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						Position = UDim2.new(0,colorpicker.colorShell.AbsolutePosition.X+colorpicker.colorShell.AbsoluteSize.X,0,colorpicker.colorShell.AbsolutePosition.Y),
						Parent = window.colorPickerContainer,
					})
					window.OpenedColorPickers[colorpicker.mainPicker] = false

					colorpicker.border3 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 29999,
						Parent = colorpicker.mainPicker,
					})

					colorpicker.border4 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border2",
						ZIndex = 29998,
						Parent = colorpicker.mainPicker,
					})

					colorpicker.hue = library:Create("ImageLabel", {
						ZIndex = 30001,
						Position = UDim2.new(0,5,0,5),
						Size = UDim2.new(0,150,0,150),
						Name = "Hue",
						Image = "rbxassetid://4155801252",
						ScaleType = Enum.ScaleType.Stretch,
						BackgroundColor3 = Color3.new(1,0,0),
						BorderSizePixel = 0,
						Parent = colorpicker.mainPicker,
					})

					colorpicker.hueSelector = library:Create("ImageLabel", {
						ZIndex = 30002,
						Name = "HueSelector",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Position = UDim2.new(0, 0, 0, 0),
						Size = UDim2.new(0, 7, 0, 7),
						Image = "rbxassetid://6885856475",
						Parent = colorpicker.mainPicker,
					})

					colorpicker.selector = library:Create("TextLabel", {
						ZIndex = 30001,
						Position = UDim2.new(0,5,0,163),
						Name = "ColorSelector",
						Size = UDim2.new(0,150,0,10),
						BackgroundColor3 = Color3.fromRGB(255,255,255),
						BorderSizePixel = 0,
						Text = "",
						Parent = colorpicker.mainPicker,
					})

					colorpicker.selectGradient = library:Create("UIGradient", {
						Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1,0,0)), ColorSequenceKeypoint.new(0.25,Color3.new(1,0,1)), ColorSequenceKeypoint.new(0.5,Color3.new(0,1,1)), ColorSequenceKeypoint.new(0.75,Color3.new(1,1,0)), ColorSequenceKeypoint.new(1,Color3.new(1,0,0))}),
						Parent = colorpicker.selector,
					})

					colorpicker.pointer = library:Create("Frame", {
						ZIndex = 30050,
						BackgroundColor3 = Color3.fromRGB(13,13,13),
						Position = UDim2.new(0,0,0,0),
						Size = UDim2.new(0,2,0,10),
						Name = "Pointer",
						BorderSizePixel = 0,
						Parent = colorpicker.selector,
					})

					colorpicker.border5 = library:Create("Frame", {
						Position = UDim2.new(0,-1,0,-1),
						Size = UDim2.new(1,2,1,2),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderSizePixel = 0,
						Name = "Border",
						ZIndex = 30049,
						Parent = colorpicker.pointer,
					})

					colorpicker.border6 = library:Create("Frame", {
						Position = UDim2.new(0,-2,0,-2),
						Size = UDim2.new(1,4,1,4),
						BackgroundColor3 = Color3.fromRGB(6, 6, 6),
						BorderSizePixel = 0,
						Name = "Border2",
						ZIndex = 30048,
						Parent = colorpicker.pointer,
					})

					colorpicker.colorShell.MouseEnter:Connect(function()
						colorpicker.border2.BackgroundColor3 = library.theme.menuAccent
					end)

					colorpicker.colorShell.MouseLeave:Connect(function()
						colorpicker.border2.BackgroundColor3 = Color3.fromRGB(6,6,6)
					end)

					function colorpicker:Set(value)
						local color = Color3.new(math.clamp(value.r, 0, 1), math.clamp(value.g, 0, 1), math.clamp(value.b, 0, 1))
						colorpicker.value = color
						colorpicker.fill.BackgroundColor3 = color
						pcall(colorpicker._function, color)
						library.flags[colorpicker.flag] = value

					end
					colorpicker:Set(colorpicker.default)

					function colorpicker:Get()
						return colorpicker.value
					end

					function colorpicker:RefreshHue()
						local x = (Mouse.X - colorpicker.hue.AbsolutePosition.X) / colorpicker.hue.AbsoluteSize.X
						local y = (Mouse.Y - colorpicker.hue.AbsolutePosition.Y) / colorpicker.hue.AbsoluteSize.Y
						colorpicker.hueSelector:TweenPosition(UDim2.new(math.clamp(x * colorpicker.hue.AbsoluteSize.X, 0.5, 0.945 * colorpicker.hue.AbsoluteSize.X) / colorpicker.hue.AbsoluteSize.X, 0, math.clamp(y * colorpicker.hue.AbsoluteSize.Y, 0.5, 0.855 * colorpicker.hue.AbsoluteSize.Y) / colorpicker.hue.AbsoluteSize.Y, 0), Enum.EasingDirection.In, Enum.EasingStyle.Sine, 0.05)
						colorpicker:Set(Color3.fromHSV(colorpicker.color, math.clamp(x * colorpicker.hue.AbsoluteSize.X, 0.5, 1 * colorpicker.hue.AbsoluteSize.X) / colorpicker.hue.AbsoluteSize.X, 1 - (math.clamp(y * colorpicker.hue.AbsoluteSize.Y, 0.5, 1 * colorpicker.hue.AbsoluteSize.Y) / colorpicker.hue.AbsoluteSize.Y)))
					end

					function colorpicker:RefreshSelector()
						local pos = math.clamp((Mouse.X - colorpicker.hue.AbsolutePosition.X) / colorpicker.hue.AbsoluteSize.X, 0, 1)
						colorpicker.color = 1 - pos
						colorpicker.pointer:TweenPosition(UDim2.new(pos, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Sine, 0.05)
						colorpicker.hue.BackgroundColor3 = Color3.fromHSV(1 - pos, 1, 1)

					end

					colorpicker.selector.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							colorpicker.draggingColor = true
							colorpicker:RefreshSelector()
						end
					end)

					colorpicker.selector.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							colorpicker.draggingColor = false
							colorpicker:RefreshSelector()
						end
					end)

					colorpicker.hue.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							colorpicker.draggingHue = true
							colorpicker:RefreshHue()
						end
					end)

					colorpicker.hue.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							colorpicker.draggingHue = false
							colorpicker:RefreshHue()
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if colorpicker.draggingColor and input.UserInputType == Enum.UserInputType.MouseMovement then
							colorpicker:RefreshSelector()
						end
						if colorpicker.draggingHue and input.UserInputType == Enum.UserInputType.MouseMovement then
							colorpicker:RefreshHue()
						end
					end)

					colorpicker.colorShell.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							for i,v in pairs(window.OpenedColorPickers) do
								if v and i ~= colorpicker.mainPicker then
									i.Visible = false
									window.OpenedColorPickers[i] = false
								end
							end
							colorpicker.mainPicker.Visible = not colorpicker.mainPicker.Visible
							window.OpenedColorPickers[colorpicker.mainPicker] = colorpicker.mainPicker.Visible
						end
					end)

					section.main.Size = UDim2.new(1,-20, 0, section.layout.AbsoluteContentSize.Y + 18)--UDim2.fromOffset(725 / 2 - 17, section.layout.AbsoluteContentSize.Y + 18)
					subTab.container.CanvasSize = section.main.Size

					return colorpicker
				end

				return section
			end

			return subTab
		end

		return tab
	end

	return window
end

function library:ChangeAccent(Color)
	library.theme.menuAccent = Color
	for _,v in next, library.accents do
		v.BackgroundColor3 = Color
	end
end

UserInputService.InputChanged:connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and library.cursor then
		local mouse = UserInputService:GetMouseLocation()
		library.cursor.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
	end
	if input == dragInput and dragging then
		updateDrag(input)
	end
end)

return library
