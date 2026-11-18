-- BrainrotCatalog.luau
-- Brainrot Base Tycoon: the shared cast, rarities, mutations and prices.
-- This ModuleScript lives in ReplicatedStorage.Shared so both the server
-- (which builds the 3D models and runs the economy) and the client (which
-- renders shop cards and labels) read the exact same numbers.

local BrainrotCatalog = {}

-- Rarity ladder, cheapest to rarest. Order drives shop pricing and the
-- colour used on BillboardGui labels and shop cards.
BrainrotCatalog.Rarities = {
	{ Name = "Common", Order = 1, Color = Color3.fromRGB(190, 195, 205), ShopPrice = 50 },
	{ Name = "Rare", Order = 2, Color = Color3.fromRGB(70, 150, 255), ShopPrice = 250 },
	{ Name = "Epic", Order = 3, Color = Color3.fromRGB(175, 90, 255), ShopPrice = 1200 },
	{ Name = "Legendary", Order = 4, Color = Color3.fromRGB(255, 190, 40), ShopPrice = 6000 },
	{ Name = "Mythic", Order = 5, Color = Color3.fromRGB(255, 80, 120), ShopPrice = 30000 },
	{ Name = "Brainrot God", Order = 6, Color = Color3.fromRGB(80, 255, 220), ShopPrice = 150000 },
}

BrainrotCatalog.RarityByName = {}
for _, rarity in ipairs(BrainrotCatalog.Rarities) do
	BrainrotCatalog.RarityByName[rarity.Name] = rarity
end

-- Mutations rolled when a Brainrot spawns in the wild or is bought.
-- Multiplier applies to Coins per second and tints the model.
BrainrotCatalog.Mutations = {
	{ Name = "Normal", Multiplier = 1, Chance = 0.89, Tint = nil },
	{ Name = "Golden", Multiplier = 5, Chance = 0.08, Tint = Color3.fromRGB(255, 205, 45) },
	{ Name = "Diamond", Multiplier = 10, Chance = 0.03, Tint = Color3.fromRGB(140, 235, 255) },
}

-- The cast. Every entry is an original absurd character invented for this
-- game. Shape is a recipe the server uses to assemble a blocky model from
-- Parts: "box" (cube body), "tall" (long body, little head), "round"
-- (sphere body), "wide" (flat wide body) or "cone" (cone hat body).
-- BodyColor paints the body, AccentColor paints the hat / shoes / extras.
BrainrotCatalog.Cast = {
	{
		Id = "cappuccino_ballerina",
		Name = "Cappuccino Ballerina",
		Rarity = "Common",
		CoinsPerSecond = 1,
		Shape = "tall",
		BodyColor = Color3.fromRGB(240, 225, 200),
		AccentColor = Color3.fromRGB(255, 150, 190),
		Blurb = "Spins for tips. Froth everywhere.",
	},
	{
		Id = "shark_sneakers",
		Name = "Shark in Sneakers",
		Rarity = "Common",
		CoinsPerSecond = 2,
		Shape = "wide",
		BodyColor = Color3.fromRGB(110, 160, 200),
		AccentColor = Color3.fromRGB(255, 80, 80),
		Blurb = "Fastest fins on land. Still cannot swim.",
	},
	{
		Id = "banana_chimp",
		Name = "Banana Peel Chimp",
		Rarity = "Common",
		CoinsPerSecond = 2,
		Shape = "box",
		BodyColor = Color3.fromRGB(255, 220, 70),
		AccentColor = Color3.fromRGB(150, 100, 60),
		Blurb = "Slips on himself at least twice a day.",
	},
	{
		Id = "toaster_goblin",
		Name = "Toaster Goblin",
		Rarity = "Rare",
		CoinsPerSecond = 5,
		Shape = "box",
		BodyColor = Color3.fromRGB(200, 200, 210),
		AccentColor = Color3.fromRGB(255, 140, 40),
		Blurb = "Pops up. Demands butter. Pops down.",
	},
	{
		Id = "cactus_elephant",
		Name = "Cactus Elephant",
		Rarity = "Rare",
		CoinsPerSecond = 6,
		Shape = "wide",
		BodyColor = Color3.fromRGB(80, 180, 90),
		AccentColor = Color3.fromRGB(255, 120, 170),
		Blurb = "Hugs are a medical event.",
	},
	{
		Id = "fridge_penguin",
		Name = "Fridge Penguin CEO",
		Rarity = "Rare",
		CoinsPerSecond = 7,
		Shape = "tall",
		BodyColor = Color3.fromRGB(60, 70, 90),
		AccentColor = Color3.fromRGB(240, 240, 245),
		Blurb = "Runs a cold storage empire. Literally cold.",
	},
	{
		Id = "traffic_cone_wizard",
		Name = "Traffic Cone Wizard",
		Rarity = "Epic",
		CoinsPerSecond = 14,
		Shape = "cone",
		BodyColor = Color3.fromRGB(255, 120, 30),
		AccentColor = Color3.fromRGB(245, 245, 245),
		Blurb = "Casts one spell: roadworks.",
	},
	{
		Id = "disco_potato",
		Name = "Disco Potato",
		Rarity = "Epic",
		CoinsPerSecond = 16,
		Shape = "round",
		BodyColor = Color3.fromRGB(190, 150, 90),
		AccentColor = Color3.fromRGB(200, 120, 255),
		Blurb = "Boogies at 120 BPM, even asleep.",
	},
	{
		Id = "sushi_samurai",
		Name = "Sushi Samurai",
		Rarity = "Epic",
		CoinsPerSecond = 18,
		Shape = "tall",
		BodyColor = Color3.fromRGB(255, 160, 120),
		AccentColor = Color3.fromRGB(60, 160, 90),
		Blurb = "His blade is a very sharp cucumber.",
	},
	{
		Id = "ufo_cow",
		Name = "UFO Abducted Cow",
		Rarity = "Legendary",
		CoinsPerSecond = 35,
		Shape = "wide",
		BodyColor = Color3.fromRGB(245, 245, 240),
		AccentColor = Color3.fromRGB(120, 255, 170),
		Blurb = "Came back with stories and a glow.",
	},
	{
		Id = "golden_toilet_king",
		Name = "Golden Toilet King",
		Rarity = "Legendary",
		CoinsPerSecond = 42,
		Shape = "box",
		BodyColor = Color3.fromRGB(255, 200, 60),
		AccentColor = Color3.fromRGB(150, 220, 255),
		Blurb = "His throne flushes with fanfare.",
	},
	{
		Id = "laser_giraffe",
		Name = "Laser Giraffe DJ",
		Rarity = "Mythic",
		CoinsPerSecond = 80,
		Shape = "tall",
		BodyColor = Color3.fromRGB(255, 215, 120),
		AccentColor = Color3.fromRGB(255, 60, 160),
		Blurb = "Neck so long the drop arrives late.",
	},
	{
		Id = "void_capybara",
		Name = "Void Capybara",
		Rarity = "Mythic",
		CoinsPerSecond = 95,
		Shape = "round",
		BodyColor = Color3.fromRGB(140, 100, 70),
		AccentColor = Color3.fromRGB(120, 60, 220),
		Blurb = "Chill so deep it bends gravity.",
	},
	{
		Id = "galaxy_noodle_dragon",
		Name = "Galaxy Noodle Dragon",
		Rarity = "Brainrot God",
		CoinsPerSecond = 220,
		Shape = "cone",
		BodyColor = Color3.fromRGB(90, 70, 200),
		AccentColor = Color3.fromRGB(255, 230, 120),
		Blurb = "Slurps entire star systems. Politely.",
	},
}

BrainrotCatalog.ById = {}
BrainrotCatalog.ByRarity = {}
for _, entry in ipairs(BrainrotCatalog.Cast) do
	BrainrotCatalog.ById[entry.Id] = entry
	if not BrainrotCatalog.ByRarity[entry.Rarity] then
		BrainrotCatalog.ByRarity[entry.Rarity] = {}
	end
	table.insert(BrainrotCatalog.ByRarity[entry.Rarity], entry)
end

-- Weighted rarity roll for wild plaza spawns: commons flood the plaza,
-- Brainrot Gods almost never wander in.
local SPAWN_WEIGHTS = {
	{ Rarity = "Common", Weight = 55 },
	{ Rarity = "Rare", Weight = 26 },
	{ Rarity = "Epic", Weight = 12 },
	{ Rarity = "Legendary", Weight = 5 },
	{ Rarity = "Mythic", Weight = 1.7 },
	{ Rarity = "Brainrot God", Weight = 0.3 },
}

function BrainrotCatalog.RollWildRarity(rng)
	local total = 0
	for _, row in ipairs(SPAWN_WEIGHTS) do
		total += row.Weight
	end
	local roll = rng:NextNumber(0, total)
	local running = 0
	for _, row in ipairs(SPAWN_WEIGHTS) do
		running += row.Weight
		if roll <= running then
			return row.Rarity
		end
	end
	return "Common"
end

function BrainrotCatalog.RandomOfRarity(rarityName, rng)
	local pool = BrainrotCatalog.ByRarity[rarityName]
	if not pool or #pool == 0 then
		return BrainrotCatalog.Cast[1]
	end
	return pool[rng:NextInteger(1, #pool)]
end

function BrainrotCatalog.RollMutation(rng)
	local roll = rng:NextNumber()
	local running = 0
	for _, mutation in ipairs(BrainrotCatalog.Mutations) do
		running += mutation.Chance
		if roll <= running then
			return mutation
		end
	end
	return BrainrotCatalog.Mutations[1]
end

function BrainrotCatalog.MutationByName(name)
	for _, mutation in ipairs(BrainrotCatalog.Mutations) do
		if mutation.Name == name then
			return mutation
		end
	end
	return BrainrotCatalog.Mutations[1]
end

-- Coins per second a placed Brainrot actually earns, before the owner's
-- rebirth multiplier is applied by the server tick.
function BrainrotCatalog.EarningsPerSecond(entry, mutationName)
	local mutation = BrainrotCatalog.MutationByName(mutationName or "Normal")
	return entry.CoinsPerSecond * mutation.Multiplier
end

-- Shop and progression prices shared by server checks and client display.
BrainrotCatalog.Prices = {
	ExtraPad = 750, -- multiplied by pads already bought, see ShopAndRebirth
	SpeedBoost = 400, -- one-time +6 WalkSpeed until rebirth
	LockSeconds = 60,
	LockCooldownSeconds = 45,
}

-- Cost of the next rebirth when the player already has `rebirths` of them.
function BrainrotCatalog.RebirthCost(rebirths)
	return 5000 * (4 ^ rebirths)
end

-- Permanent earnings multiplier from rebirths: x2 per rebirth.
function BrainrotCatalog.RebirthMultiplier(rebirths)
	return 2 ^ rebirths
end

return BrainrotCatalog
