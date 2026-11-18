-- WorldBuilder.luau
-- Brainrot Base Tycoon: builds everything static in the world at runtime —
-- the plaza dressing, six base interiors (pads, doors, shop stands, signs),
-- fences and lamps. The ground and the six base platforms themselves are
-- declared in default.project.json so the place reads well even before the
-- server script runs; this module finds them by name and furnishes them.

local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

WorldBuilder.BASE_COUNT = 6
WorldBuilder.PADS_PER_BASE = 4 -- visible pads; extra pads are added by the shop
WorldBuilder.PLAZA_RADIUS = 34

local BASE_COLORS = {
	Color3.fromRGB(255, 110, 110),
	Color3.fromRGB(110, 170, 255),
	Color3.fromRGB(120, 230, 140),
	Color3.fromRGB(255, 205, 90),
	Color3.fromRGB(200, 130, 255),
	Color3.fromRGB(255, 150, 210),
}

local function makePart(parent, name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeSign(parent, name, position, size, text, textColor, bgColor)
	local board = makePart(parent, name, size, CFrame.new(position), bgColor, Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = gui
	return board
end

-- Base i sits on a ring around the plaza. Platform parts in the project
-- tree are named Base1..Base6 and positioned by this same formula.
function WorldBuilder.BaseCenter(index)
	local angle = math.rad((index - 1) * (360 / WorldBuilder.BASE_COUNT))
	local distance = 62
	return Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance), angle
end

function WorldBuilder.Build()
	local world = Workspace:FindFirstChild("BrainrotWorld")
	if world then
		return world
	end
	world = Instance.new("Folder")
	world.Name = "BrainrotWorld"
	world.Parent = Workspace

	-- Plaza dressing: a ring, a fountain block and the big welcome sign.
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = world
	local ring = makePart(plaza, "PlazaRing", Vector3.new(70, 0.6, 70), CFrame.new(0, 0.3, 0), Color3.fromRGB(245, 200, 90), Enum.Material.Neon)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.CanCollide = false
	local fountain = makePart(plaza, "Fountain", Vector3.new(8, 3, 8), CFrame.new(0, 1.5, 0), Color3.fromRGB(120, 200, 255), Enum.Material.Glass)
	fountain.Shape = Enum.PartType.Cylinder
	makeSign(plaza, "WelcomeSign", Vector3.new(0, 7, -30), Vector3.new(26, 5, 1), "BRAINROT BASE TYCOON", Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 60, 200))
	makeSign(plaza, "HowToSign", Vector3.new(-24, 4, 22), Vector3.new(16, 3.4, 1), "Catch one. Carry it home. Get rich.", Color3.fromRGB(40, 40, 40), Color3.fromRGB(255, 235, 150))

	-- Lamp posts around the plaza so night screenshots still read.
	for i = 1, 8 do
		local angle = math.rad(i * 45)
		local pos = Vector3.new(math.cos(angle) * 30, 0, math.sin(angle) * 30)
		local pole = makePart(plaza, "Lamp" .. i, Vector3.new(0.6, 7, 0.6), CFrame.new(pos + Vector3.new(0, 3.5, 0)), Color3.fromRGB(50, 50, 60), Enum.Material.Metal)
		local bulb = makePart(plaza, "LampBulb" .. i, Vector3.new(1.6, 1.6, 1.6), CFrame.new(pos + Vector3.new(0, 7.4, 0)), Color3.fromRGB(255, 240, 170), Enum.Material.Neon)
		bulb.Shape = Enum.PartType.Ball
		bulb.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 18
		light.Brightness = 1.2
		light.Color = Color3.fromRGB(255, 240, 190)
		light.Parent = bulb
		pole.CanCollide = false
	end

	-- Furnish each platform: pads, door frame, shop stand, owner sign.
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world

	for index = 1, WorldBuilder.BASE_COUNT do
		local center, angle = WorldBuilder.BaseCenter(index)
		local color = BASE_COLORS[index]
		local base = Instance.new("Folder")
		base.Name = "Base" .. index
		base:SetAttribute("BaseIndex", index)
		base.Parent = basesFolder

		-- Face the plaza: local -Z of the base looks toward the centre.
		local look = CFrame.lookAt(center, Vector3.new(0, 0, 0))
		local function at(offset)
			return look * CFrame.new(offset)
		end

		-- Back and side low walls, leaving the plaza side open for the door.
		makePart(base, "BackWall", Vector3.new(26, 5, 1), at(Vector3.new(0, 2.5, 11)), color, Enum.Material.Brick)
		makePart(base, "LeftWall", Vector3.new(1, 5, 22), at(Vector3.new(-12.5, 2.5, 0)), color, Enum.Material.Brick)
		makePart(base, "RightWall", Vector3.new(1, 5, 22), at(Vector3.new(12.5, 2.5, 0)), color, Enum.Material.Brick)

		-- Display pads in two rows.
		local pads = Instance.new("Folder")
		pads.Name = "Pads"
		pads.Parent = base
		for padIndex = 1, WorldBuilder.PADS_PER_BASE do
			local col = (padIndex - 1) % 2
			local row = math.floor((padIndex - 1) / 2)
			local offset = Vector3.new(-6 + col * 12, 0.55, 2 + row * 6)
			local pad = makePart(pads, "Pad" .. padIndex, Vector3.new(7, 1.1, 7), at(offset), Color3.fromRGB(45, 45, 55), Enum.Material.Neon)
			pad:SetAttribute("PadIndex", padIndex)
			pad:SetAttribute("OccupiedBy", "")
		end

		-- The lockable force-field door across the plaza-facing opening.
		local door = makePart(base, "Door", Vector3.new(24, 6, 0.8), at(Vector3.new(0, 3, -11)), Color3.fromRGB(90, 220, 255), Enum.Material.Neon)
		door.Name = "ForceFieldDoor"
		door.Transparency = 1
		door.CanCollide = false
		door:SetAttribute("Locked", false)

		-- Shop stand with a striped canopy near the door.
		local stand = makePart(base, "ShopStand", Vector3.new(6, 3, 3), at(Vector3.new(9, 1.5, -8)), Color3.fromRGB(150, 100, 60), Enum.Material.Wood)
		stand.Name = "ShopStand"
		local canopy = makePart(base, "ShopCanopy", Vector3.new(7, 0.5, 4), at(Vector3.new(9, 4.6, -8)), Color3.fromRGB(255, 90, 90), Enum.Material.Fabric)
		canopy.Name = "ShopCanopy"

		local signPos = (look * CFrame.new(Vector3.new(0, 8, -11))).Position
		makeSign(base, "OwnerSign", signPos, Vector3.new(18, 3.6, 1), "BASE " .. index, Color3.fromRGB(255, 255, 255), color)
	end

	-- Spawn location on the plaza edge.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PlazaSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.6, 26)
	spawn.Color = Color3.fromRGB(120, 255, 170)
	spawn.Material = Enum.Material.Neon
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world

	return world
end

function WorldBuilder.GetBaseFolder(index)
	local world = Workspace:FindFirstChild("BrainrotWorld")
	if not world then
		return nil
	end
	local bases = world:FindFirstChild("Bases")
	if not bases then
		return nil
	end
	return bases:FindFirstChild("Base" .. index)
end

return WorldBuilder
