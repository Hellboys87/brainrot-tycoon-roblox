-- WaveEvent.luau
-- Brainrot Base Tycoon: the Tsunami Wave. Every ~90 seconds a warning
-- banner goes out, then a wall of water sweeps across the map from west
-- to east. Anyone caught out in the open while carrying a Brainrot drops
-- it (it scampers back to the plaza). Players inside their base walls or
-- on the plaza ring's high fountain are safe.
-- TOUR.json calls startWaveNow() to bring the wave on demand.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local WaveEvent = {}

WaveEvent.INTERVAL_SECONDS = 90
WaveEvent.WARNING_SECONDS = 5
WaveEvent.SWEEP_SECONDS = 6

WaveEvent.NotifyEvent = nil -- RemoteEvent set by init (shared with BaseManager)
WaveEvent.BaseManager = nil -- set by init, avoids a require cycle

local waveRunning = false

local function broadcast(kind, text)
	if WaveEvent.NotifyEvent then
		WaveEvent.NotifyEvent:FireAllClients(kind, text)
	end
end

local function buildWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWave"
	wall.Size = Vector3.new(6, 16, 170)
	wall.Color = Color3.fromRGB(40, 140, 255)
	wall.Material = Enum.Material.Glass
	wall.Transparency = 0.25
	wall.Anchored = true
	wall.CanCollide = false
	wall.CFrame = CFrame.new(-95, 8, 0)
	local foam = Instance.new("Part")
	foam.Name = "Foam"
	foam.Size = Vector3.new(6.4, 3, 170)
	foam.Color = Color3.fromRGB(240, 250, 255)
	foam.Material = Enum.Material.Neon
	foam.Transparency = 0.2
	foam.Anchored = true
	foam.CanCollide = false
	foam.CFrame = CFrame.new(-95, 16.5, 0)
	foam.Parent = wall
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = wall
	weld.Part1 = foam
	weld.Parent = foam
	wall.Parent = Workspace
	return wall
end

local function isSheltered(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return true -- no character, nothing to punish
	end
	-- Inside any base footprint counts as sheltered: bases sit on a ring
	-- of radius 62 with a 13-stud half-width.
	local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
	local distance = flat.Magnitude
	if distance > 48 and distance < 78 then
		return true
	end
	-- Up on the fountain block in the middle of the plaza also works.
	if distance < 7 and root.Position.Y > 3 then
		return true
	end
	return false
end

function WaveEvent.startWaveNow(_reason)
	if waveRunning then
		return false
	end
	waveRunning = true
	task.spawn(function()
		broadcast("wave", "TSUNAMI WAVE INCOMING! Get to a base or drop nothing!")
		task.wait(WaveEvent.WARNING_SECONDS)
		local wall = buildWaveWall()
		local startX = -95
		local endX = 95
		local elapsed = 0
		local hit = {}
		while elapsed < WaveEvent.SWEEP_SECONDS do
			local dt = task.wait()
			elapsed += dt
			local alpha = math.clamp(elapsed / WaveEvent.SWEEP_SECONDS, 0, 1)
			local x = startX + (endX - startX) * alpha
			wall.CFrame = CFrame.new(x, 8, 0)
			-- The wave front knocks carried Brainrots loose, once each.
			for _, player in ipairs(Players:GetPlayers()) do
				if not hit[player] then
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if root and math.abs(root.Position.X - x) < 5 and math.abs(root.Position.Z) < 85 then
						hit[player] = true
						if not isSheltered(player) and WaveEvent.BaseManager then
							WaveEvent.BaseManager.DropCarried(player, "The Tsunami Wave knocked your Brainrot loose!")
						end
					end
				end
			end
		end
		wall:Destroy()
		broadcast("waveclear", "The wave has passed. The plaza is safe... for now.")
		waveRunning = false
	end)
	return true
end

function WaveEvent.Start()
	task.spawn(function()
		task.wait(20) -- grace period so screenshots and joins settle
		while true do
			WaveEvent.startWaveNow("scheduled")
			task.wait(WaveEvent.INTERVAL_SECONDS)
		end
	end)
end

return WaveEvent
