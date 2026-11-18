-- BaseManager.luau
-- Brainrot Base Tycoon: owns everything about bases — assigning one to
-- each player, the Brainrot a player carries on their back, placing it on
-- a pad, locking the force-field door, and stealing from unlocked bases.
-- The server is authoritative here: clients only hear about results
-- through the Notify / StateChanged remotes created in init.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local Spawner = require(script.Parent:WaitForChild("BrainrotSpawner"))

local BaseManager = {}

BaseManager.Assignments = {} -- [Player] = baseIndex
BaseManager.Placed = {} -- [Player] = { [padIndex] = { Id=..., Mutation=..., Model=Model } }
BaseManager.Carrying = {} -- [Player] = Model
BaseManager.LockedUntil = {} -- [Player] = os.clock() timestamp
BaseManager.LockReadyAt = {} -- [Player] = os.clock() timestamp (cooldown end)

BaseManager.NotifyEvent = nil -- RemoteEvent, set by init
BaseManager.StateEvent = nil -- RemoteEvent, set by init

local baseOwners = {} -- [baseIndex] = Player

local function notify(player, kind, text)
	if BaseManager.NotifyEvent then
		BaseManager.NotifyEvent:FireClient(player, kind, text)
	end
end
BaseManager.Notify = notify

local function rootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
end

local function humanoid(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function BaseManager.MaxPads(player)
	local record = PlayerData.Get(player)
	local extra = record and record.ExtraPads or 0
	return WorldBuilder.PADS_PER_BASE + extra
end

function BaseManager.IsLocked(player)
	local until_ = BaseManager.LockedUntil[player]
	return until_ ~= nil and os.clock() < until_
end

-- Snapshot of placed Brainrots as plain data (for saving and income).
function BaseManager.PlacedList(player)
	local list = {}
	local placed = BaseManager.Placed[player]
	if placed then
		for _, item in pairs(placed) do
			table.insert(list, { Id = item.Id, Mutation = item.Mutation })
		end
	end
	return list
end

function BaseManager.PushState(player)
	if not BaseManager.StateEvent then
		return
	end
	local record = PlayerData.Get(player)
	if not record then
		return
	end
	local placed = BaseManager.PlacedList(player)
	BaseManager.StateEvent:FireClient(player, {
		Coins = math.floor(record.Coins),
		IncomePerSecond = PlayerData.IncomePerSecond(player, placed),
		Multiplier = Catalog.RebirthMultiplier(record.Rebirths),
		Rebirths = record.Rebirths,
		RebirthCost = Catalog.RebirthCost(record.Rebirths),
		Locked = BaseManager.IsLocked(player),
		Carrying = BaseManager.Carrying[player] ~= nil,
		PadsUsed = #placed,
		PadsMax = BaseManager.MaxPads(player),
	})
end

local function refreshPadVisual(baseIndex, padIndex, item)
	local base = WorldBuilder.GetBaseFolder(baseIndex)
	if not base then
		return
	end
	local pads = base:FindFirstChild("Pads")
	local pad = pads and pads:FindFirstChild("Pad" .. padIndex)
	if pad then
		pad:SetAttribute("OccupiedBy", item and item.Id or "")
		pad.Color = item and Color3.fromRGB(70, 255, 140) or Color3.fromRGB(45, 45, 55)
	end
end

-- Put a Brainrot record on the first free pad of the player's base.
-- Returns true when it fit. Builds a fresh anchored model on the pad.
function BaseManager.PlaceOnPad(player, id, mutationName)
	local baseIndex = BaseManager.Assignments[player]
	if not baseIndex then
		return false
	end
	local entry = Catalog.ById[id]
	if not entry then
		return false
	end
	BaseManager.Placed[player] = BaseManager.Placed[player] or {}
	local maxPads = BaseManager.MaxPads(player)
	for padIndex = 1, maxPads do
		if not BaseManager.Placed[player][padIndex] then
			local base = WorldBuilder.GetBaseFolder(baseIndex)
			local pads = base and base:FindFirstChild("Pads")
			local pad = pads and pads:FindFirstChild("Pad" .. padIndex)
			if not pad then
				-- Extra pads bought in the shop have no physical pad yet:
				-- grow one beside the originals.
				pad = Instance.new("Part")
				pad.Name = "Pad" .. padIndex
				pad.Size = Vector3.new(7, 1.1, 7)
				pad.Anchored = true
				pad.Material = Enum.Material.Neon
				pad.Color = Color3.fromRGB(45, 45, 55)
				pad:SetAttribute("PadIndex", padIndex)
				local center = WorldBuilder.BaseCenter(baseIndex)
				local look = CFrame.lookAt(center, Vector3.new(0, 0, 0))
				pad.CFrame = look * CFrame.new(Vector3.new(-6 + (padIndex - 1) % 2 * 12, 0.55, 8 + math.floor((padIndex - 1) / 2) * 6))
				pad.Parent = pads
			end
			local model = Spawner.BuildModel(entry, mutationName, pad.Position + Vector3.new(0, 1, 0), false)
			local body = model.PrimaryPart
			body.Anchored = true
			body.CFrame = CFrame.new(pad.Position + Vector3.new(0, body.Size.Y / 2 + 1.2, 0))
			model.Parent = Workspace
			BaseManager.Placed[player][padIndex] = { Id = id, Mutation = mutationName, Model = model }
			refreshPadVisual(baseIndex, padIndex, { Id = id })
			BaseManager.SyncRecord(player)
			BaseManager.PushState(player)
			return true
		end
	end
	return false
end

-- Keep the save record's Placed list in step with the live pads.
function BaseManager.SyncRecord(player)
	local record = PlayerData.Get(player)
	if record then
		record.Placed = BaseManager.PlacedList(player)
	end
end

local function setCarrySpeed(player, carrying)
	local hum = humanoid(player)
	if not hum then
		return
	end
	local record = PlayerData.Get(player)
	local base = 16 + ((record and record.HasSpeedBoost) and 6 or 0)
	hum.WalkSpeed = carrying and (base - 3) or base
end
BaseManager.RefreshSpeed = setCarrySpeed

-- The catch flow: called by the spawner when a player triggers a wild
-- Brainrot's prompt. One at a time, and only with a free pad waiting.
function BaseManager.TryCatch(player, model)
	if BaseManager.Carrying[player] then
		notify(player, "warn", "Your hands are full — deliver this one first!")
		return
	end
	local baseIndex = BaseManager.Assignments[player]
	if not baseIndex then
		return
	end
	local placedCount = 0
	for _ in pairs(BaseManager.Placed[player] or {}) do
		placedCount += 1
	end
	if placedCount >= BaseManager.MaxPads(player) then
		notify(player, "warn", "All your pads are full! Buy more in the shop.")
		return
	end
	local root = rootPart(player)
	local body = model.PrimaryPart
	if not root or not body then
		return
	end
	Spawner.ForgetWild(model)
	local prompt = body:FindFirstChild("CatchPrompt")
	if prompt then
		prompt:Destroy()
	end
	body.Anchored = false
	body.CanCollide = false
	body.CFrame = root.CFrame * CFrame.new(0, 2.6, 1.6)
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = body
	weld.C0 = CFrame.new(0, 2.6, 1.6)
	weld.Parent = body
	BaseManager.Carrying[player] = model
	setCarrySpeed(player, true)
	notify(player, "good", "Caught " .. model.Name .. "! Carry it to your base.")
	BaseManager.PushState(player)
end

-- Deliver whatever the player carries onto a free pad. Returns success.
function BaseManager.DeliverCarried(player)
	local model = BaseManager.Carrying[player]
	if not model then
		return false
	end
	local id = model:GetAttribute("BrainrotId")
	local mutationName = model:GetAttribute("Mutation") or "Normal"
	BaseManager.Carrying[player] = nil
	model:Destroy()
	setCarrySpeed(player, false)
	local placedOk = BaseManager.PlaceOnPad(player, id, mutationName)
	if placedOk then
		notify(player, "good", model.Name .. " is on a pad and earning!")
	else
		notify(player, "warn", "No free pad — it slipped back to the plaza!")
		local fresh = Spawner.BuildModel(Catalog.ById[id], mutationName, Vector3.new(0, 3, 0), true)
		fresh.Parent = Workspace
		Spawner.ReturnToPlaza(fresh)
	end
	BaseManager.PushState(player)
	return placedOk
end

-- The wave (or a disconnect) knocks a carried Brainrot loose.
function BaseManager.DropCarried(player, reason)
	local model = BaseManager.Carrying[player]
	if not model then
		return
	end
	BaseManager.Carrying[player] = nil
	setCarrySpeed(player, false)
	Spawner.ReturnToPlaza(model)
	notify(player, "bad", reason or "You dropped your Brainrot! It ran back to the plaza.")
	BaseManager.PushState(player)
end

-- Stealing: a thief with empty hands triggers a placed Brainrot's prompt
-- in someone else's base. Locked bases refuse; unlocked ones lose it.
function BaseManager.TrySteal(thief, owner, padIndex)
	if thief == owner then
		return
	end
	if BaseManager.Carrying[thief] then
		notify(thief, "warn", "Your hands are full!")
		return
	end
	if BaseManager.IsLocked(owner) then
		notify(thief, "warn", owner.Name .. "'s base is LOCKED.")
		return
	end
	local placed = BaseManager.Placed[owner]
	local item = placed and placed[padIndex]
	if not item then
		return
	end
	placed[padIndex] = nil
	if item.Model then
		item.Model:Destroy()
	end
	refreshPadVisual(BaseManager.Assignments[owner], padIndex, nil)
	BaseManager.SyncRecord(owner)
	BaseManager.PushState(owner)
	notify(owner, "bad", thief.Name .. " stole your " .. (Catalog.ById[item.Id] and Catalog.ById[item.Id].Name or "Brainrot") .. "!")

	-- The stolen Brainrot rides on the thief's back like a caught one.
	local root = rootPart(thief)
	if not root then
		return
	end
	local model = Spawner.BuildModel(Catalog.ById[item.Id], item.Mutation, root.Position, false)
	local body = model.PrimaryPart
	body.CanCollide = false
	body.CFrame = root.CFrame * CFrame.new(0, 2.6, 1.6)
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = body
	weld.C0 = CFrame.new(0, 2.6, 1.6)
	weld.Parent = body
	model.Parent = Workspace
	BaseManager.Carrying[thief] = model
	setCarrySpeed(thief, true)
	notify(thief, "good", "Stole " .. model.Name .. "! Run it home!")
	BaseManager.PushState(thief)
end

-- Add steal prompts to a placed model (called after placement refresh).
local function armStealPrompt(player, padIndex, item)
	local model = item.Model
	local body = model and model.PrimaryPart
	if not body then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = model.Name
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(thief)
		if thief ~= player then
			BaseManager.TrySteal(thief, player, padIndex)
		end
	end)
end

-- Lock flow driven by the client's Lock button remote.
function BaseManager.TryLock(player)
	local now = os.clock()
	if BaseManager.IsLocked(player) then
		notify(player, "warn", "Your base is already locked.")
		return
	end
	local readyAt = BaseManager.LockReadyAt[player] or 0
	if now < readyAt then
		notify(player, "warn", string.format("Lock recharging — %.0fs left.", readyAt - now))
		return
	end
	local seconds = Catalog.Prices.LockSeconds
	BaseManager.LockedUntil[player] = now + seconds
	BaseManager.LockReadyAt[player] = now + seconds + Catalog.Prices.LockCooldownSeconds
	local baseIndex = BaseManager.Assignments[player]
	local base = baseIndex and WorldBuilder.GetBaseFolder(baseIndex)
	local door = base and base:FindFirstChild("ForceFieldDoor")
	if door then
		door.Transparency = 0.35
		door.CanCollide = true
		door:SetAttribute("Locked", true)
		task.delay(seconds, function()
			if door.Parent then
				door.Transparency = 1
				door.CanCollide = false
				door:SetAttribute("Locked", false)
			end
			BaseManager.PushState(player)
		end)
	end
	notify(player, "good", "Base LOCKED for " .. seconds .. "s. Nobody steals today.")
	BaseManager.PushState(player)
end

-- Deliver check loop: standing in your own base with a catch delivers it.
local function startDeliverLoop()
	task.spawn(function()
		while true do
			task.wait(0.4)
			for player, model in pairs(BaseManager.Carrying) do
				local baseIndex = BaseManager.Assignments[player]
				local root = rootPart(player)
				if baseIndex and root and model then
					local center = WorldBuilder.BaseCenter(baseIndex)
					local flat = Vector3.new(root.Position.X - center.X, 0, root.Position.Z - center.Z)
					if flat.Magnitude < 13 then
						BaseManager.DeliverCarried(player)
					end
				end
			end
		end
	end)
end

function BaseManager.AssignBase(player)
	for index = 1, WorldBuilder.BASE_COUNT do
		if not baseOwners[index] then
			baseOwners[index] = player
			BaseManager.Assignments[player] = index
			BaseManager.Placed[player] = {}
			local base = WorldBuilder.GetBaseFolder(index)
			if base then
				local sign = base:FindFirstChild("OwnerSign")
				local gui = sign and sign:FindFirstChild("SignGui")
				local label = gui and gui:FindFirstChild("Text")
				if label then
					label.Text = player.DisplayName .. "'s BASE"
				end
				local door = base:FindFirstChild("ForceFieldDoor")
				if door then
					door.Transparency = 1
					door.CanCollide = false
				end
			end
			-- Teleport the character in front of its base.
			local character = player.Character
			local root = rootPart(player)
			if character and root then
				local center = WorldBuilder.BaseCenter(index)
				local look = CFrame.lookAt(center + Vector3.new(0, 3, 0), Vector3.new(0, 3, 0))
				root.CFrame = look * CFrame.new(0, 0, -16)
			end
			return index
		end
	end
	return nil -- server fuller than six: spectate from the plaza
end

-- Restore saved Brainrots onto pads after a join.
function BaseManager.RestorePlaced(player)
	local record = PlayerData.Get(player)
	if not record then
		return
	end
	local saved = record.Placed
	record.Placed = {}
	for _, item in ipairs(saved) do
		local okPlaced = BaseManager.PlaceOnPad(player, item.Id, item.Mutation)
		if not okPlaced then
			break
		end
	end
	-- Arm steal prompts on everything that was restored.
	for padIndex, item in pairs(BaseManager.Placed[player] or {}) do
		armStealPrompt(player, padIndex, item)
	end
end

-- Patch PlaceOnPad so every fresh placement also gets its steal prompt.
local rawPlace = BaseManager.PlaceOnPad
BaseManager.PlaceOnPad = function(player, id, mutationName)
	local okPlaced = rawPlace(player, id, mutationName)
	if okPlaced then
		for padIndex, item in pairs(BaseManager.Placed[player]) do
			local body = item.Model and item.Model.PrimaryPart
			if body and not body:FindFirstChild("StealPrompt") then
				armStealPrompt(player, padIndex, item)
			end
		end
	end
	return okPlaced
end

function BaseManager.ReleaseBase(player)
	local index = BaseManager.Assignments[player]
	if index then
		baseOwners[index] = nil
		local base = WorldBuilder.GetBaseFolder(index)
		if base then
			local sign = base:FindFirstChild("OwnerSign")
			local gui = sign and sign:FindFirstChild("SignGui")
			local label = gui and gui:FindFirstChild("Text")
			if label then
				label.Text = "BASE " .. index
			end
		end
	end
	if BaseManager.Carrying[player] then
		BaseManager.Carrying[player]:Destroy()
	end
	for padIndex, item in pairs(BaseManager.Placed[player] or {}) do
		if item.Model then
			item.Model:Destroy()
		end
		if index then
			refreshPadVisual(index, padIndex, nil)
		end
	end
	BaseManager.Assignments[player] = nil
	BaseManager.Placed[player] = nil
	BaseManager.Carrying[player] = nil
	BaseManager.LockedUntil[player] = nil
	BaseManager.LockReadyAt[player] = nil
end

-- Re-sync every pad's colour/occupancy with the live Placed table.
-- Used after a rebirth empties the base so no pad stays lit green.
function BaseManager.RefreshAllPads(player)
	local index = BaseManager.Assignments[player]
	if not index then
		return
	end
	for padIndex = 1, 8 do
		local item = BaseManager.Placed[player] and BaseManager.Placed[player][padIndex]
		refreshPadVisual(index, padIndex, item)
	end
end

function BaseManager.Start()
	Spawner.CatchHandler = function(player, model)
		BaseManager.TryCatch(player, model)
	end
	startDeliverLoop()
	Players.PlayerRemoving:Connect(function(player)
		BaseManager.ReleaseBase(player)
	end)
end

return BaseManager
