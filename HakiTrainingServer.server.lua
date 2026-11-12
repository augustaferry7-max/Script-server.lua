-- Server-authoritative training example for a Roblox experience you own.
-- Place in ServerScriptService. Never trust client-supplied stat values or multipliers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local TRAIN_INTERVAL = 1
local BASE_GAIN_PER_TICK = 1

-- Set this to your 3x-training game pass ID. Keep it at 0 until configured.
-- Optional developer/test access is controlled by this server-only list.
local THREE_X_GAMEPASS_ID = 0
local THREE_X_ALLOWED_USER_IDS = {
	-- [123456789] = true,
}

local REMOTE_FOLDER_NAME = "HakiTrainingRemotes"
local REQUEST_FUNCTION_NAME = "RequestTrainingState"

local remoteFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = REMOTE_FOLDER_NAME
	remoteFolder.Parent = ReplicatedStorage
end

local requestFunction = remoteFolder:FindFirstChild(REQUEST_FUNCTION_NAME)
if requestFunction and not requestFunction:IsA("RemoteFunction") then
	error(REQUEST_FUNCTION_NAME .. " must be a RemoteFunction")
end
if not requestFunction then
	requestFunction = Instance.new("RemoteFunction")
	requestFunction.Name = REQUEST_FUNCTION_NAME
	requestFunction.Parent = remoteFolder
end

local playerStates = {}
local lastRequestAt = {}
local REQUEST_COOLDOWN = 0.12

local function hasTripleAccess(player)
	if THREE_X_ALLOWED_USER_IDS[player.UserId] == true then
		return true
	end

	if THREE_X_GAMEPASS_ID <= 0 then
		return false
	end

	local ok, ownsPass = pcall(
		MarketplaceService.UserOwnsGamePassAsync,
		MarketplaceService,
		player.UserId,
		THREE_X_GAMEPASS_ID
	)
	return ok and ownsPass == true
end

local function getOrCreateHakiStat(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local haki = leaderstats:FindFirstChild("Haki")
	if haki then
		if haki:IsA("IntValue") or haki:IsA("NumberValue") then
			return haki
		end
		warn(("Haki must be an IntValue or NumberValue for %s"):format(player.Name))
		return nil
	end

	haki = Instance.new("IntValue")
	haki.Name = "Haki"
	haki.Value = 0
	haki.Parent = leaderstats
	return haki
end

local function getStateSnapshot(player)
	local state = playerStates[player]
	if not state then
		return nil
	end

	return {
		autoTraining = state.autoTraining,
		tripleTraining = state.tripleTraining,
		canUseTriple = state.canUseTriple,
	}
end

local function addTraining(player, state)
	if not state.autoTraining then
		return
	end

	local haki = getOrCreateHakiStat(player)
	if not haki then
		return
	end

	local multiplier = state.tripleTraining and state.canUseTriple and 3 or 1
	-- The server chooses the gain. The client cannot submit an amount.
	haki.Value += BASE_GAIN_PER_TICK * multiplier
end

local function onPlayerAdded(player)
	local state = {
		autoTraining = false,
		tripleTraining = false,
		canUseTriple = THREE_X_ALLOWED_USER_IDS[player.UserId] == true,
	}
	playerStates[player] = state
	getOrCreateHakiStat(player)

	if not state.canUseTriple and THREE_X_GAMEPASS_ID > 0 then
		task.spawn(function()
			state.canUseTriple = hasTripleAccess(player)
			if not state.canUseTriple then
				state.tripleTraining = false
			end
		end)
	end

	task.spawn(function()
		while player.Parent == Players do
			task.wait(TRAIN_INTERVAL)
			if player.Parent == Players and playerStates[player] == state then
				addTraining(player, state)
			end
		end
	end)
end

local function onPlayerRemoving(player)
	playerStates[player] = nil
	lastRequestAt[player] = nil
end

requestFunction.OnServerInvoke = function(player, action, requestedValue)
	if typeof(action) ~= "string" then
		return nil
	end

	local now = os.clock()
	local lastAt = lastRequestAt[player] or 0
	if now - lastAt < REQUEST_COOLDOWN then
		return getStateSnapshot(player)
	end
	lastRequestAt[player] = now

	local state = playerStates[player]
	if not state then
		return nil
	end

	if action == "get" then
		return getStateSnapshot(player)
	end

	if typeof(requestedValue) ~= "boolean" then
		return getStateSnapshot(player)
	end

	if action == "setAuto" then
		state.autoTraining = requestedValue
	elseif action == "setTriple" then
		-- Entitlement is checked on the server; a modified client cannot bypass it.
		if state.canUseTriple then
			state.tripleTraining = requestedValue
		else
			state.tripleTraining = false
		end
	end

	return getStateSnapshot(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
