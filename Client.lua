-- Place in StarterPlayer > StarterPlayerScripts.
-- Simple draggable training panel with an on/off button.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local toggleRemote = ReplicatedStorage:WaitForChild("TrainingToggle")

local gui = Instance.new("ScreenGui")
gui.Name = "TrainingPanel"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(280, 176)
panel.Position = UDim2.new(0.5, -140, 0.5, -88)
panel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(68, 82, 112)
stroke.Thickness = 1
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -28, 0, 34)
title.Position = UDim2.fromOffset(14, 12)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "TRAINING"
title.TextColor3 = Color3.fromRGB(245, 247, 255)
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local multiplier = Instance.new("TextLabel")
multiplier.Name = "Multiplier"
multiplier.Size = UDim2.new(1, -28, 0, 24)
multiplier.Position = UDim2.fromOffset(14, 54)
multiplier.BackgroundTransparency = 1
multiplier.Font = Enum.Font.GothamMedium
multiplier.Text = "Training rate: x9"
multiplier.TextColor3 = Color3.fromRGB(174, 187, 214)
multiplier.TextSize = 14
multiplier.TextXAlignment = Enum.TextXAlignment.Left
multiplier.Parent = panel

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -28, 0, 22)
status.Position = UDim2.fromOffset(14, 82)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.Text = "Status: OFF"
status.TextColor3 = Color3.fromRGB(255, 147, 147)
status.TextSize = 13
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = panel

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "Toggle"
toggleButton.Size = UDim2.new(1, -28, 0, 42)
toggleButton.Position = UDim2.fromOffset(14, 116)
toggleButton.BackgroundColor3 = Color3.fromRGB(43, 165, 112)
toggleButton.BorderSizePixel = 0
toggleButton.AutoButtonColor = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "TURN ON"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextSize = 14
toggleButton.Parent = panel

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = toggleButton

local enabled = false
local function updateButton()
    status.Text = enabled and "Status: ON" or "Status: OFF"
    status.TextColor3 = enabled and Color3.fromRGB(116, 232, 166) or Color3.fromRGB(255, 147, 147)
    toggleButton.Text = enabled and "TURN OFF" or "TURN ON"
    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(190, 77, 82) or Color3.fromRGB(43, 165, 112)
end

toggleButton.Activated:Connect(function()
    toggleRemote:FireServer(not enabled)
end)

toggleRemote.OnClientEvent:Connect(function(serverEnabled, message)
    enabled = serverEnabled == true
    updateButton()
    if message then
        status.Text = "Status: " .. tostring(message)
        status.TextColor3 = Color3.fromRGB(255, 198, 111)
    end
end)

-- Make the panel draggable on mouse or touch.
local dragging = false
local dragStart
local startPosition

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)
