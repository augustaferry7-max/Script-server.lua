local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:FindFirstChild("TrainingControl")
if remote and not remote:IsA("RemoteEvent") then
	error("ReplicatedStorage.TrainingControl must be a RemoteEvent")
end
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "TrainingControl"
	remote.Parent = ReplicatedStorage
end

local TICK_SECONDS = 0.5
local POINTS_PER_TICK = 1
local MAX_STRENGTH = 1_000_000
local REQUEST_COOLDOWN = 0.2

local playerState = {}
local lastRequest = {}

local function getStrengthValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local strength = leaderstats:FindFirstChild("Strength")
	if not strength then
		strength = Instance.new("IntValue")
		strength.Name = "Strength"
		strength.Value = 0
		strength.Parent = leaderstats
	end

	if not strength:IsA("IntValue") then
		warn(("Strength must be an IntValue for %s"):format(player.Name))
		return nil
	end

	return strength
end

local function sendState(player)
	local state = playerState[player]
	if not state then
		return
	end

	local unlocked = player:GetAttribute("TripleTrainingUnlocked") == true
	if not unlocked then
		state.triple = false
	end

	remote:FireClient(player, "State", state.auto, state.triple, unlocked)
end

local function setupPlayer(player)
	if playerState[player] then
		return
	end
	if not getStrengthValue(player) then
		return
	end

	-- Set this to true only from trusted server-side progression or entitlement code.
	if player:GetAttribute("TripleTrainingUnlocked") == nil then
		player:SetAttribute("TripleTrainingUnlocked", false)
	end

	playerState[player] = { auto = false, triple = false }

	player:GetAttributeChangedSignal("TripleTrainingUnlocked"):Connect(function()
		sendState(player)
	end)

	task.spawn(function()
		while player.Parent == Players do
			task.wait(TICK_SECONDS)

			local state = playerState[player]
			if not state or not state.auto then
				continue
			end

			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				continue
			end

			local strength = getStrengthValue(player)
			if strength then
				local isTripleUnlocked =
					player:GetAttribute("TripleTrainingUnlocked") == true
				local multiplier = state.triple and isTripleUnlocked and 3 or 1

				strength.Value = math.min(
					strength.Value + POINTS_PER_TICK * multiplier,
					MAX_STRENGTH
				)
			end
		end
	end)

	sendState(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
	lastRequest[player] = nil
end)

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

remote.OnServerEvent:Connect(function(player, action)
	if action ~= "GetState"
		and action ~= "ToggleAuto"
		and action ~= "ToggleTriple" then
		return
	end

	local now = os.clock()
	if now - (lastRequest[player] or 0) < REQUEST_COOLDOWN then
		return
	end
	lastRequest[player] = now

	local state = playerState[player]
	if not state then
		return
	end

	if action == "ToggleAuto" then
		state.auto = not state.auto
	elseif action == "ToggleTriple" then
		if player:GetAttribute("TripleTrainingUnlocked") == true then
			state.triple = not state.triple
		else
			state.triple = false
		end
	end

	sendState(player)
end)
