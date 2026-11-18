-- ShopAndRebirth.luau
-- Brainrot Base Tycoon: the shop and the rebirth ladder, behind one
-- RemoteFunction so the client gets a real answer for every purchase.
-- The server re-checks every price here; the client only displays them.
--
-- Actions (first argument):
--   "BuyBrainrot", rarityName  -> random cast member of that rarity,
--                                 mutation rolled, placed on a free pad
--   "BuyPad"                   -> +1 pad slot (max +4), price scales
--   "BuySpeed"                 -> permanent +6 WalkSpeed until rebirth
--   "Rebirth"                  -> reset Coins and placed Brainrots for
--                                 a permanent x2 earnings multiplier

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))

local ShopAndRebirth = {}

ShopAndRebirth.ShopFunction = nil -- RemoteFunction, set by init
ShopAndRebirth.LockEvent = nil -- RemoteEvent, set by init

local rng = Random.new()
local MAX_EXTRA_PADS = 4

local function reply(ok, text)
	return { Ok = ok, Text = text }
end

local function buyBrainrot(player, rarityName)
	local rarity = Catalog.RarityByName[rarityName]
	if not rarity then
		return reply(false, "Unknown rarity.")
	end
	local record = PlayerData.Get(player)
	if not record then
		return reply(false, "Your data is still loading.")
	end
	local placedCount = 0
	for _ in pairs(BaseManager.Placed[player] or {}) do
		placedCount += 1
	end
	if placedCount >= BaseManager.MaxPads(player) then
		return reply(false, "All your pads are full! Buy another pad first.")
	end
	if not PlayerData.AddCoins(player, -rarity.ShopPrice) then
		return reply(false, "Not enough Coins — you need $" .. rarity.ShopPrice .. ".")
	end
	local entry = Catalog.RandomOfRarity(rarityName, rng)
	local mutation = Catalog.RollMutation(rng)
	local placedOk = BaseManager.PlaceOnPad(player, entry.Id, mutation.Name)
	if not placedOk then
		PlayerData.AddCoins(player, rarity.ShopPrice) -- refund: no pad after all
		return reply(false, "No free pad — purchase refunded.")
	end
	local label = (mutation.Name ~= "Normal" and (mutation.Name .. " ") or "") .. entry.Name
	BaseManager.PushState(player)
	return reply(true, "Bought " .. label .. " (" .. rarityName .. ")!")
end

local function buyPad(player)
	local record = PlayerData.Get(player)
	if not record then
		return reply(false, "Your data is still loading.")
	end
	if record.ExtraPads >= MAX_EXTRA_PADS then
		return reply(false, "You already own every extra pad.")
	end
	local price = Catalog.Prices.ExtraPad * (record.ExtraPads + 1)
	if not PlayerData.AddCoins(player, -price) then
		return reply(false, "Not enough Coins — a pad costs $" .. price .. ".")
	end
	record.ExtraPads += 1
	BaseManager.SyncRecord(player)
	BaseManager.PushState(player)
	return reply(true, "New pad installed! You now have " .. BaseManager.MaxPads(player) .. " pads.")
end

local function buySpeed(player)
	local record = PlayerData.Get(player)
	if not record then
		return reply(false, "Your data is still loading.")
	end
	if record.HasSpeedBoost then
		return reply(false, "You already own the speed boost.")
	end
	if not PlayerData.AddCoins(player, -Catalog.Prices.SpeedBoost) then
		return reply(false, "Not enough Coins — speed costs $" .. Catalog.Prices.SpeedBoost .. ".")
	end
	record.HasSpeedBoost = true
	BaseManager.RefreshSpeed(player, BaseManager.Carrying[player] ~= nil)
	BaseManager.PushState(player)
	return reply(true, "Speed boost on! Zoom responsibly.")
end

local function rebirth(player)
	local record = PlayerData.Get(player)
	if not record then
		return reply(false, "Your data is still loading.")
	end
	local cost = Catalog.RebirthCost(record.Rebirths)
	if record.Coins < cost then
		return reply(false, "Rebirth needs $" .. cost .. " Coins.")
	end
	-- Clear the base: placed models go, carried model goes, pads empty.
	if BaseManager.Carrying[player] then
		BaseManager.Carrying[player]:Destroy()
		BaseManager.Carrying[player] = nil
		BaseManager.RefreshSpeed(player, false)
	end
	for padIndex, item in pairs(BaseManager.Placed[player] or {}) do
		if item.Model then
			item.Model:Destroy()
		end
		BaseManager.Placed[player][padIndex] = nil
	end
	BaseManager.RefreshAllPads(player)
	record.Coins = 25
	record.Rebirths += 1
	record.ExtraPads = 0
	record.HasSpeedBoost = false
	record.Placed = {}
	PlayerData.SyncLeaderstats(player)
	BaseManager.PushState(player)
	return reply(true, "REBIRTH! Earnings are now x" .. Catalog.RebirthMultiplier(record.Rebirths) .. " forever.")
end

function ShopAndRebirth.Start()
	if ShopAndRebirth.ShopFunction then
		ShopAndRebirth.ShopFunction.OnServerInvoke = function(player, action, arg)
			if action == "BuyBrainrot" then
				return buyBrainrot(player, arg)
			elseif action == "BuyPad" then
				return buyPad(player)
			elseif action == "BuySpeed" then
				return buySpeed(player)
			elseif action == "Rebirth" then
				return rebirth(player)
			end
			return reply(false, "Unknown shop action.")
		end
	end
	if ShopAndRebirth.LockEvent then
		ShopAndRebirth.LockEvent.OnServerEvent:Connect(function(player)
			BaseManager.TryLock(player)
		end)
	end
end

return ShopAndRebirth
