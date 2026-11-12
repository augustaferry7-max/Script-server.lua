local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("TrainingControl")

local gui = Instance.new("ScreenGui")
gui.Name = "TrainingWindow"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local window = Instance.new("Frame")
window.Name = "Window"
window.Position = UDim2.fromOffset(24, 160)
window.Size = UDim2.fromOffset(284, 200)
window.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
window.BorderSizePixel = 0
window.ClipsDescendants = true
window.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = window

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(75, 91, 120)
stroke.Thickness = 1
stroke.Parent = window

local title = Instance.new("TextLabel")
title.Name = "DragTitle"
title.Position = UDim2.fromOffset(10, 0)
title.Size = UDim2.new(1, -54, 0, 42)
title.BackgroundTransparency = 1
title.Text = "Training"
title.TextColor3 = Color3.fromRGB(245, 247, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamSemibold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Active = true
title.Parent = window

local minimize = Instance.new("TextButton")
minimize.Name = "Minimize"
minimize.Position = UDim2.new(1, -42, 0, 5)
minimize.Size = UDim2.fromOffset(32, 32)
minimize.BackgroundColor3 = Color3.fromRGB(48, 56, 74)
minimize.Text = "−"
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.TextSize = 20
minimize.Font = Enum.Font.GothamBold
minimize.Parent = window

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 7)
minimizeCorner.Parent = minimize

local body = Instance.new("Frame")
body.Position = UDim2.fromOffset(0, 42)
body.Size = UDim2.new(1, 0, 1, -42)
body.BackgroundTransparency = 1
body.Parent = window

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(12, 2)
status.Size = UDim2.new(1, -24, 0, 26)
status.BackgroundTransparency = 1
status.Text = "Connecting to server…"
status.TextColor3 = Color3.fromRGB(190, 201, 222)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = body

local function makeButton(name, y, initialText)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(12, y)
	button.Size = UDim2.new(1, -24, 0, 42)
	button.BackgroundColor3 = Color3.fromRGB(54, 91, 156)
	button.Text = initialText
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 13
	button.Font = Enum.Font.GothamSemibold
	button.AutoButtonColor = true
	button.Parent = body

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 7)
	buttonCorner.Parent = button

	return button
end

local autoButton = makeButton("AutoTraining", 34, "Auto fast training: OFF")
local tripleButton = makeButton("TripleTraining", 82, "3× training: LOCKED")

local minimized = false
minimize.Activated:Connect(function()
	minimized = not minimized
	body.Visible = not minimized
	minimize.Text = minimized and "+" or "−"

	TweenService:Create(
		window,
		TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(284, minimized and 42 or 200) }
	):Play()
end)

-- Drag the window by its title area.
local dragging = false
local dragInput
local dragStart
local startPosition

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
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

title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
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

autoButton.Activated:Connect(function()
	remote:FireServer("ToggleAuto")
end)

tripleButton.Activated:Connect(function()
	remote:FireServer("ToggleTriple")
end)

remote.OnClientEvent:Connect(function(message, autoOn, tripleOn, tripleUnlocked)
	if message ~= "State" then
		return
	end

	autoButton.Text = "Auto fast training: " .. (autoOn and "ON" or "OFF")

	if tripleUnlocked then
		tripleButton.Text = "3× training: " .. (tripleOn and "ON" or "OFF")
		tripleButton.BackgroundColor3 = Color3.fromRGB(54, 91, 156)
		status.Text = "Training controls ready"
	else
		tripleButton.Text = "3× training: LOCKED"
		tripleButton.BackgroundColor3 = Color3.fromRGB(70, 74, 84)
		status.Text = "3× requires a server-side unlock"
	end
end)

remote:FireServer("GetState")
