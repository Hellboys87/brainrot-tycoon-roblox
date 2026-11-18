-- PlayerData.luau
-- Brainrot Base Tycoon: per-player state — leaderstats, the DataStore
-- load/save cycle and the live earnings state other modules read.
-- DataStore calls are always pcall-wrapped: in Studio (or with API access
-- off) they fail, we warn once and the game runs on session-only data.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local PlayerData = {}

local STORE_NAME = "BrainrotBaseTycoon_v1"
local AUTOSAVE_SECONDS = 60

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[Brainrot] DataStore unavailable, progress will not persist: " .. tostring(result))
	end
end

-- Live records keyed by Player. A record holds:
--   Coins (number, mirrored into leaderstats), Rebirths, ExtraPads,
--   HasSpeedBoost, Placed = { {Id=..., Mutation=...}, ... } restored on join.
PlayerData.Records = {}

local function defaultData()
	return {
		Coins = 25, -- enough for a first Common from the shop, or save up
		Rebirths = 0,
		ExtraPads = 0,
		HasSpeedBoost = false,
		Placed = {},
	}
end

local function applyLeaderstats(player, record)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = leaderstats
	end
	coins.Value = math.floor(record.Coins)
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if not rebirths then
		rebirths = Instance.new("IntValue")
		rebirths.Name = "Rebirths"
		rebirths.Parent = leaderstats
	end
	rebirths.Value = record.Rebirths
end

function PlayerData.SyncLeaderstats(player)
	local record = PlayerData.Records[player]
	if record then
		applyLeaderstats(player, record)
	end
end

function PlayerData.Load(player)
	local data = defaultData()
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			if type(saved.Coins) == "number" then
				data.Coins = saved.Coins
			end
			if type(saved.Rebirths) == "number" then
				data.Rebirths = saved.Rebirths
			end
			if type(saved.ExtraPads) == "number" then
				data.ExtraPads = math.clamp(saved.ExtraPads, 0, 4)
			end
			if saved.HasSpeedBoost == true then
				data.HasSpeedBoost = true
			end
			if type(saved.Placed) == "table" then
				for _, item in ipairs(saved.Placed) do
					if type(item) == "table" and Catalog.ById[item.Id] then
						table.insert(data.Placed, { Id = item.Id, Mutation = item.Mutation or "Normal" })
					end
				end
			end
		elseif not ok then
			warn("[Brainrot] Load failed for " .. player.Name .. ": " .. tostring(saved))
		end
	end
	PlayerData.Records[player] = data
	applyLeaderstats(player, data)
	return data
end

function PlayerData.Save(player)
	local record = PlayerData.Records[player]
	if not record or not store then
		return
	end
	local payload = {
		Coins = math.floor(record.Coins),
		Rebirths = record.Rebirths,
		ExtraPads = record.ExtraPads,
		HasSpeedBoost = record.HasSpeedBoost,
		Placed = record.Placed,
	}
	local ok, err = pcall(function()
		store:SetAsync("player_" .. player.UserId, payload)
	end)
	if not ok then
		warn("[Brainrot] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

function PlayerData.Forget(player)
	PlayerData.Records[player] = nil
end

function PlayerData.Get(player)
	return PlayerData.Records[player]
end

-- Add (or remove, with a negative amount) Coins and mirror to leaderstats.
function PlayerData.AddCoins(player, amount)
	local record = PlayerData.Records[player]
	if not record then
		return false
	end
	if amount < 0 and record.Coins < -amount then
		return false
	end
	record.Coins += amount
	applyLeaderstats(player, record)
	return true
end

-- Total Coins per second from a list of placed Brainrots, with the
-- rebirth multiplier applied. Used by the earnings tick and the HUD.
function PlayerData.IncomePerSecond(player, placedList)
	local record = PlayerData.Records[player]
	if not record then
		return 0
	end
	local sum = 0
	for _, item in ipairs(placedList) do
		local entry = Catalog.ById[item.Id]
		if entry then
			sum += Catalog.EarningsPerSecond(entry, item.Mutation)
		end
	end
	return sum * Catalog.RebirthMultiplier(record.Rebirths)
end

-- The repeating work: pay every player their per-second income and
-- autosave on a slower cadence.
function PlayerData.StartLoops(getPlacedList)
	task.spawn(function()
		local sinceSave = 0
		while true do
			task.wait(1)
			sinceSave += 1
			for player, record in pairs(PlayerData.Records) do
				local placed = getPlacedList(player)
				local income = PlayerData.IncomePerSecond(player, placed)
				if income > 0 then
					record.Coins += income
					applyLeaderstats(player, record)
				end
			end
			if sinceSave >= AUTOSAVE_SECONDS then
				sinceSave = 0
				for player in pairs(PlayerData.Records) do
					PlayerData.Save(player)
				end
			end
		end
	end)
end

function PlayerData.BindClose()
	game:BindToClose(function()
		for player in pairs(PlayerData.Records) do
			PlayerData.Save(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		PlayerData.Save(player)
	end)
end

return PlayerData
