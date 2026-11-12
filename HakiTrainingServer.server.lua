-- Place in ServerScriptService.
-- Server-authoritative training for your own Roblox experience.
-- Clients can request a session, but the server controls timing and awards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_NAME = "TrainingToggle"
local STAT_NAME = "TrainingPower"
local BASE_RATE = 1 -- XP awarded per second at the normal rate
local TRAINING_MULTIPLIER = 9
local TICK_SECONDS = 1
local MAX_SESSION_SECONDS = 60 * 60 -- safely stop stale sessions after one hour

local toggleRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not toggleRemote then
    toggleRemote = Instance.new("RemoteEvent")
    toggleRemote.Name = REMOTE_NAME
    toggleRemote.Parent = ReplicatedStorage
end

local active = {}

local function getTrainingStat(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    local stat = leaderstats and leaderstats:FindFirstChild(STAT_NAME)
    if stat and (stat:IsA("IntValue") or stat:IsA("NumberValue")) then
        return stat
    end
    return nil
end

local function setSession(player, enabled)
    if enabled then
        if not getTrainingStat(player) then
            toggleRemote:FireClient(player, false, "TrainingPower stat not found")
            return
        end
        active[player] = os.clock()
        toggleRemote:FireClient(player, true)
    else
        active[player] = nil
        toggleRemote:FireClient(player, false)
    end
end

toggleRemote.OnServerEvent:Connect(function(player, requestedState)
    if typeof(requestedState) ~= "boolean" then
        return
    end
    setSession(player, requestedState)
end)

task.spawn(function()
    while true do
        task.wait(TICK_SECONDS)
        local now = os.clock()
        for player, startedAt in pairs(active) do
            if player.Parent ~= Players or now - startedAt >= MAX_SESSION_SECONDS then
                active[player] = nil
                if player.Parent == Players then
                    toggleRemote:FireClient(player, false, "Training session ended")
                end
            else
                local stat = getTrainingStat(player)
                if stat then
                    stat.Value += BASE_RATE * TRAINING_MULTIPLIER * TICK_SECONDS
                else
                    active[player] = nil
                    toggleRemote:FireClient(player, false, "TrainingPower stat not found")
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    active[player] = nil
end)

-- Minimal example stat. Remove this block if your game already creates TrainingPower.
Players.PlayerAdded:Connect(function(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    if not leaderstats:FindFirstChild(STAT_NAME) then
        local power = Instance.new("IntValue")
        power.Name = STAT_NAME
        power.Value = 0
        power.Parent = leaderstats
    end
end)
