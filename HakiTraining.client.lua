-- Floating, draggable training menu for your own Roblox experience.
-- Place as a LocalScript in StarterGui (or StarterPlayerScripts).
-- This UI only requests server state; it cannot grant stats or bypass entitlements.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remoteFolder = ReplicatedStorage:WaitForChild("HakiTrainingRemotes")
local requestFunction = remoteFolder:WaitForChild("RequestTrainingState")

local COLORS = {
	background = Color3.fromRGB(20, 23, 32),
	panel = Color3.fromRGB(30, 35, 48),
	accent = Color3.fromRGB(100, 221, 190),
	text = Color3.fromRGB(241, 245, 249),
	muted = Color3.fromRGB(159, 170, 190),
	red = Color3.fromRGB(240, 105, 105),
}

local function request(action, value)
	local ok, result = pcall(function()
		return requestFunction:InvokeServer(action, value)
	end)
	if ok then
		return result
	end
	warn("Haki training request failed:", result)
	return nil
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HakiTrainingMenu"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.fromOffset(300, 250)
window.Position = UDim2.new(0, 28, 0.5, -125)
window.BackgroundColor3 = COLORS.background
window.BorderSizePixel = 0
window.Parent = screenGui
Instance.new("UICorner", window).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(57, 67, 87)
stroke.Thickness = 1
stroke.Parent = window

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 = COLORS.panel
titleBar.BorderSizePixel = 0
titleBar.Parent = window
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -96, 1, 0)
title.Position = UDim2.fromOffset(16, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "HAKI TRAINING"
title.TextColor3 = COLORS.text
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minimize = Instance.new("TextButton")
minimize.Name = "Minimize"
minimize.Size = UDim2.fromOffset(32, 28)
minimize.Position = UDim2.new(1, -42, 0, 9)
minimize.BackgroundColor3 = Color3.fromRGB(48, 56, 73)
minimize.BorderSizePixel = 0
minimize.Font = Enum.Font.GothamBold
minimize.Text = "—"
minimize.TextColor3 = COLORS.text
minimize.TextSize = 16
minimize.Parent = titleBar
Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 7)

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -28, 1, -62)
content.Position = UDim2.fromOffset(14, 54)
content.BackgroundTransparency = 1
content.Parent = window

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

local function makeText(name, text, height, color, font, size)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color or COLORS.text
	label.TextSize = size or 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = content
	return label
end

local hakiLabel = makeText("HakiValue", "Haki: loading…", 22, COLORS.text, Enum.Font.GothamSemibold, 15)

local function makeToggle(name, labelText)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 42)
	button.BackgroundColor3 = COLORS.panel
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamSemibold
	button.TextColor3 = COLORS.text
	button.TextSize = 13
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Parent = content
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = button
	button:SetAttribute("Label", labelText)
	return button
end

local autoButton = makeToggle("AutoTraining", "Auto fast training")
local tripleButton = makeToggle("TripleTraining", "3x speed training")
local statusLabel = makeText("Status", "Connecting to secure server…", 28, COLORS.muted, Enum.Font.Gotham, 11)
statusLabel.TextWrapped = true
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

local currentState = {
	autoTraining = false,
	tripleTraining = false,
	canUseTriple = false,
}

local function paintToggle(button, enabled, allowed)
	local label = button:GetAttribute("Label")
	if allowed == false then
		button.Text = label .. "     LOCKED"
		button.BackgroundColor3 = Color3.fromRGB(42, 44, 52)
		button.TextColor3 = COLORS.muted
	else
		button.Text = label .. (enabled and "     ON" or "     OFF")
		button.BackgroundColor3 = enabled and Color3.fromRGB(35, 82, 73) or COLORS.panel
		button.TextColor3 = enabled and COLORS.accent or COLORS.text
	end
end

local function applyState(state)
	if typeof(state) ~= "table" then
		statusLabel.Text = "Server unavailable. Try again shortly."
		statusLabel.TextColor3 = COLORS.red
		return
	end
	currentState = state
	paintToggle(autoButton, state.autoTraining == true)
	paintToggle(tripleButton, state.tripleTraining == true, state.canUseTriple == true)
	statusLabel.Text = state.canUseTriple and "Training settings are verified by the server." or "3x requires your game's approved entitlement."
	statusLabel.TextColor3 = COLORS.muted
end

local function refreshHaki()
	local leaderstats = player:FindFirstChild("leaderstats")
	local haki = leaderstats and leaderstats:FindFirstChild("Haki")
	if haki and (haki:IsA("IntValue") or haki:IsA("NumberValue")) then
		hakiLabel.Text = "Haki: " .. tostring(haki.Value)
	else
		hakiLabel.Text = "Haki: —"
	end
end

local function watchHaki()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		return
	end
	local haki = leaderstats:WaitForChild("Haki", 10)
	if haki and (haki:IsA("IntValue") or haki:IsA("NumberValue")) then
		haki:GetPropertyChangedSignal("Value"):Connect(refreshHaki)
	end
	refreshHaki()
end

task.spawn(watchHaki)

local busy = false
local function setOption(action, value)
	if busy then
		return
	end
	busy = true
	local state = request(action, value)
	applyState(state)
	busy = false
end

autoButton.Activated:Connect(function()
	setOption("setAuto", not currentState.autoTraining)
end)

tripleButton.Activated:Connect(function()
	if not currentState.canUseTriple then
		statusLabel.Text = "3x training is locked until approved by the server."
		statusLabel.TextColor3 = COLORS.red
		return
	end
	setOption("setTriple", not currentState.tripleTraining)
end)

local minimized = false
minimize.Activated:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	window.Size = minimized and UDim2.fromOffset(300, 46) or UDim2.fromOffset(300, 250)
	minimize.Text = minimized and "+" or "—"
end)

-- Drag by the header; supports mouse and touch.
local dragging = false
local dragInput
local dragStart
local startPosition

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = window.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		window.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

applyState(request("get"))
refreshHaki()
