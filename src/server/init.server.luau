-- init.server.luau
-- Brainrot Base Tycoon: server bootstrap only. Creates the remotes,
-- requires the feature modules, wires them together and handles the
-- player join/leave lifecycle. All real logic lives in the modules.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local PlayerData = require(script:WaitForChild("PlayerData"))
local Spawner = require(script:WaitForChild("BrainrotSpawner"))
local BaseManager = require(script:WaitForChild("BaseManager"))
local WaveEvent = require(script:WaitForChild("WaveEvent"))
local ShopAndRebirth = require(script:WaitForChild("ShopAndRebirth"))

-- Remotes (created here so every module shares the same instances).
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = remotes

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "StateChanged"
stateEvent.Parent = remotes

local shopFunction = Instance.new("RemoteFunction")
shopFunction.Name = "ShopAction"
shopFunction.Parent = remotes

local lockEvent = Instance.new("RemoteEvent")
lockEvent.Name = "LockBase"
lockEvent.Parent = remotes

BaseManager.NotifyEvent = notifyEvent
BaseManager.StateEvent = stateEvent
WaveEvent.NotifyEvent = notifyEvent
WaveEvent.BaseManager = BaseManager
ShopAndRebirth.ShopFunction = shopFunction
ShopAndRebirth.LockEvent = lockEvent

-- World first, then the systems that depend on it.
WorldBuilder.Build()
BaseManager.Start()
Spawner.Start()
WaveEvent.Start()
ShopAndRebirth.Start()

PlayerData.StartLoops(function(player)
	return BaseManager.PlacedList(player)
end)
PlayerData.BindClose()

local function onPlayerAdded(player)
	-- The project sets Players.CharacterAutoLoads = false, so characters
	-- are loaded explicitly below once data and the base are ready.
	PlayerData.Load(player)
	local function onCharacterAdded(_character)
		-- (Re)assign on first spawn only; respawns keep the same base.
		if not BaseManager.Assignments[player] then
			BaseManager.AssignBase(player)
			BaseManager.RestorePlaced(player)
		end
		BaseManager.RefreshSpeed(player, false)
		BaseManager.PushState(player)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player:LoadCharacter()
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("[Brainrot] Brainrot Base Tycoon server is up.")
