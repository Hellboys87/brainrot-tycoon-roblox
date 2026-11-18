-- BrainrotSpawner.luau
-- Brainrot Base Tycoon: builds blocky Brainrot models from the catalog's
-- shape recipes, spawns wild ones wandering the plaza, and runs their
-- simple steering (pick a point, drift toward it, bob, repeat).
-- Catching is delegated: BaseManager registers a handler and decides
-- whether the player may pick a wild Brainrot up.

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local BrainrotSpawner = {}

BrainrotSpawner.MAX_WILD = 10
BrainrotSpawner.SPAWN_EVERY_SECONDS = 4

local rng = Random.new()
local wild = {} -- [Model] = { Entry=..., Mutation=..., Target=Vector3, Speed=number, BobPhase=number }
BrainrotSpawner.Wild = wild

BrainrotSpawner.CatchHandler = nil -- fn(player, model, record) -> boolean caught

local function tinted(baseColor, mutation)
	if mutation and mutation.Tint then
		return mutation.Tint
	end
	return baseColor
end

local function addPart(model, name, size, offset, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Massless = true
	if shape then
		part.Shape = shape
	end
	part:SetAttribute("LocalOffset", offset) -- read by nothing; kept for debugging
	part.Parent = model
	return part
end

-- Assemble one Brainrot model at `position`. withPrompt adds the Catch
-- ProximityPrompt used for wild ones. The returned model has attributes
-- BrainrotId and Mutation so any system can identify it.
function BrainrotSpawner.BuildModel(entry, mutationName, position, withPrompt)
	local mutation = Catalog.MutationByName(mutationName or "Normal")
	local model = Instance.new("Model")
	model.Name = entry.Name
	model:SetAttribute("BrainrotId", entry.Id)
	model:SetAttribute("Mutation", mutation.Name)

	local bodyColor = tinted(entry.BodyColor, mutation)
	local bodyMaterial = Enum.Material.SmoothPlastic
	if mutation.Name == "Golden" then
		bodyMaterial = Enum.Material.Metal
	elseif mutation.Name == "Diamond" then
		bodyMaterial = Enum.Material.Glass
	end

	local bodySize
	if entry.Shape == "tall" then
		bodySize = Vector3.new(2.2, 4.4, 2.2)
	elseif entry.Shape == "wide" then
		bodySize = Vector3.new(4.6, 2.2, 3)
	elseif entry.Shape == "round" then
		bodySize = Vector3.new(3.6, 3.6, 3.6)
	elseif entry.Shape == "cone" then
		bodySize = Vector3.new(3, 2.6, 3)
	else -- box
		bodySize = Vector3.new(3, 3, 3)
	end

	local body = addPart(model, "Body", bodySize, Vector3.zero, bodyColor, bodyMaterial)
	if entry.Shape == "round" then
		body.Shape = Enum.PartType.Ball
	end
	body.CanCollide = true
	body.Anchored = false
	model.PrimaryPart = body

	local topY = bodySize.Y / 2
	-- Accent extra on top: a hat, tuft or antenna depending on shape.
	if entry.Shape == "cone" then
		local hat = addPart(model, "ConeHat", Vector3.new(2.4, 2.2, 2.4), Vector3.new(0, topY + 1, 0), entry.AccentColor, Enum.Material.SmoothPlastic)
		hat.Shape = Enum.PartType.Cylinder
	else
		addPart(model, "Hat", Vector3.new(bodySize.X * 0.7, 0.7, bodySize.Z * 0.7), Vector3.new(0, topY + 0.35, 0), entry.AccentColor, Enum.Material.SmoothPlastic)
	end
	-- Sneaker feet, because every Brainrot here has places to be.
	local footY = -bodySize.Y / 2 - 0.3
	addPart(model, "LeftShoe", Vector3.new(1, 0.6, 1.6), Vector3.new(-bodySize.X * 0.25, footY, 0.3), entry.AccentColor, Enum.Material.SmoothPlastic)
	addPart(model, "RightShoe", Vector3.new(1, 0.6, 1.6), Vector3.new(bodySize.X * 0.25, footY, 0.3), entry.AccentColor, Enum.Material.SmoothPlastic)
	-- Eyes on the front face.
	local eyeZ = bodySize.Z / 2 + 0.06
	addPart(model, "LeftEye", Vector3.new(0.45, 0.45, 0.12), Vector3.new(-0.6, 0.5, eyeZ), Color3.fromRGB(20, 20, 20), Enum.Material.Neon)
	addPart(model, "RightEye", Vector3.new(0.45, 0.45, 0.12), Vector3.new(0.6, 0.5, eyeZ), Color3.fromRGB(20, 20, 20), Enum.Material.Neon)

	-- Weld every extra to the body so the model moves as one piece.
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") and child ~= body then
			local offset = child:GetAttribute("LocalOffset")
			child.CFrame = body.CFrame * CFrame.new(offset)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = child
			weld.Parent = child
		end
	end
	body.CFrame = CFrame.new(position + Vector3.new(0, bodySize.Y / 2 + 0.7, 0))

	-- Name / rarity / income label floating over the model.
	local rarity = Catalog.RarityByName[entry.Rarity]
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(220, 64)
	billboard.StudsOffset = Vector3.new(0, bodySize.Y / 2 + 1.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 90
	billboard.Parent = body

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.55, 0)
	title.BackgroundTransparency = 1
	title.Text = (mutation.Name ~= "Normal" and (mutation.Name .. " ") or "") .. entry.Name
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.4
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.Parent = billboard

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.Size = UDim2.new(1, 0, 0.45, 0)
	sub.BackgroundTransparency = 1
	sub.Text = entry.Rarity .. "  ·  $" .. Catalog.EarningsPerSecond(entry, mutation.Name) .. "/s"
	sub.TextColor3 = rarity and rarity.Color or Color3.fromRGB(255, 255, 255)
	sub.TextStrokeTransparency = 0.4
	sub.TextScaled = true
	sub.Font = Enum.Font.FredokaOne
	sub.Parent = billboard

	if withPrompt then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CatchPrompt"
		prompt.ActionText = "Catch"
		prompt.ObjectText = entry.Name
		prompt.HoldDuration = 0.35
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = body
		prompt.Triggered:Connect(function(player)
			if BrainrotSpawner.CatchHandler then
				BrainrotSpawner.CatchHandler(player, model)
			end
		end)
	end

	return model
end

local function plazaPoint()
	local angle = rng:NextNumber(0, math.pi * 2)
	local radius = rng:NextNumber(4, 26)
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

function BrainrotSpawner.SpawnWild()
	local entry = Catalog.RandomOfRarity(Catalog.RollWildRarity(rng), rng)
	local mutation = Catalog.RollMutation(rng)
	local model = BrainrotSpawner.BuildModel(entry, mutation.Name, plazaPoint(), true)
	model.Parent = Workspace
	wild[model] = {
		Entry = entry,
		Mutation = mutation.Name,
		Target = plazaPoint(),
		Speed = rng:NextNumber(2.2, 4),
		BobPhase = rng:NextNumber(0, math.pi * 2),
	}
	return model
end

-- Stop treating a model as wild (it was caught, bought away or removed).
function BrainrotSpawner.ForgetWild(model)
	wild[model] = nil
end

-- A dropped Brainrot scampers back to the plaza and becomes catchable.
function BrainrotSpawner.ReturnToPlaza(model)
	local body = model.PrimaryPart
	if not body then
		model:Destroy()
		return
	end
	for _, weld in ipairs(model:GetDescendants()) do
		if weld:IsA("Weld") and weld.Name == "CarryWeld" then
			weld:Destroy()
		end
	end
	body.Anchored = false
	local spot = plazaPoint()
	body.CFrame = CFrame.new(spot + Vector3.new(0, 3, 0))
	if not body:FindFirstChild("CatchPrompt") then
		local entry = Catalog.ById[model:GetAttribute("BrainrotId")]
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CatchPrompt"
		prompt.ActionText = "Catch"
		prompt.ObjectText = entry and entry.Name or "Brainrot"
		prompt.HoldDuration = 0.35
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = body
		prompt.Triggered:Connect(function(player)
			if BrainrotSpawner.CatchHandler then
				BrainrotSpawner.CatchHandler(player, model)
			end
		end)
	end
	wild[model] = {
		Entry = Catalog.ById[model:GetAttribute("BrainrotId")],
		Mutation = model:GetAttribute("Mutation") or "Normal",
		Target = plazaPoint(),
		Speed = rng:NextNumber(2.2, 4),
		BobPhase = rng:NextNumber(0, math.pi * 2),
	}
	if not model.Parent then
		model.Parent = Workspace
	end
end

function BrainrotSpawner.WildCount()
	local count = 0
	for _ in pairs(wild) do
		count += 1
	end
	return count
end

function BrainrotSpawner.Start()
	-- Wandering: steer each wild model toward its target on Heartbeat.
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for model, record in pairs(wild) do
			local body = model.PrimaryPart
			if not body or not model.Parent then
				wild[model] = nil
			else
				local pos = body.Position
				local flat = Vector3.new(record.Target.X - pos.X, 0, record.Target.Z - pos.Z)
				if flat.Magnitude < 2 then
					record.Target = plazaPoint()
				else
					local step = flat.Unit * math.min(record.Speed * dt, flat.Magnitude)
					local bob = math.abs(math.sin(now * 6 + record.BobPhase)) * 0.35
					local groundY = body.Size.Y / 2 + 0.7
					local newPos = Vector3.new(pos.X + step.X, groundY + bob, pos.Z + step.Z)
					local facing = CFrame.lookAt(newPos, newPos + flat.Unit)
					body.CFrame = facing
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			if BrainrotSpawner.WildCount() < BrainrotSpawner.MAX_WILD then
				BrainrotSpawner.SpawnWild()
			end
			task.wait(BrainrotSpawner.SPAWN_EVERY_SECONDS)
		end
	end)
end

return BrainrotSpawner
