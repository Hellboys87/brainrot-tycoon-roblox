-- Game.client.luau
-- Brainrot Base Tycoon: the whole client. Builds the HUD (Coins, income,
-- multiplier), the shop panel, the lock and rebirth controls, the tsunami
-- warning banner and toast notifications, and plays little sounds made in
-- code. The server stays authoritative: this script only sends intents
-- through the remotes and renders the state the server pushes back.
-- Nothing is placed in the top-left corner — the Roblox menu lives there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local notifyEvent = remotes:WaitForChild("Notify")
local stateEvent = remotes:WaitForChild("StateChanged")
local shopFunction = remotes:WaitForChild("ShopAction")
local lockEvent = remotes:WaitForChild("LockBase")

-- Sounds created in code (library jingles; if one is unavailable it just
-- stays silent, the game does not depend on them).
local function makeSound(name, id, pitch)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = 0.5
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	return sound
end
local sounds = {
	good = makeSound("NotifyGood", "rbxassetid://12221944", 1.1),
	bad = makeSound("NotifyBad", "rbxassetid://12221944", 0.7),
	wave = makeSound("WaveAlarm", "rbxassetid://12221944", 0.5),
	buy = makeSound("BuyChaChing", "rbxassetid://12221944", 1.4),
}

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, size, position, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.FredokaOne
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, name, size, position, text, bg)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.Text = text
	button.TextSize = 20
	button.Font = Enum.Font.FredokaOne
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundColor3 = bg
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Parent = parent
	return button
end

local function panel(parent, name, size, position, bg)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = bg
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

-- Stats panel, top-right (clear of the Roblox menu in the top-left).
local stats = panel(gui, "Stats", UDim2.fromOffset(250, 108), UDim2.new(1, -262, 0, 12), Color3.fromRGB(30, 30, 45))
local coinsLabel = makeLabel(stats, "Coins", UDim2.new(1, -16, 0, 32), UDim2.fromOffset(10, 6), "Coins: $0", 26, Color3.fromRGB(255, 225, 110))
local incomeLabel = makeLabel(stats, "Income", UDim2.new(1, -16, 0, 24), UDim2.fromOffset(10, 42), "Income: $0/s", 18)
local multLabel = makeLabel(stats, "Multiplier", UDim2.new(1, -16, 0, 24), UDim2.fromOffset(10, 66), "Rebirth multiplier: x1", 18, Color3.fromRGB(140, 255, 220))
local padsLabel = makeLabel(stats, "Pads", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(10, 88), "Pads: 0/4", 14, Color3.fromRGB(200, 200, 210))

-- Action buttons down the right side.
local shopButton = makeButton(gui, "ShopButton", UDim2.fromOffset(150, 48), UDim2.new(1, -162, 0, 132), "SHOP", Color3.fromRGB(60, 160, 80))
local lockButton = makeButton(gui, "LockButton", UDim2.fromOffset(150, 48), UDim2.new(1, -162, 0, 188), "LOCK BASE", Color3.fromRGB(50, 130, 200))

-- Carrying hint, bottom centre.
local carryLabel = makeLabel(gui, "CarryHint", UDim2.fromOffset(520, 34), UDim2.new(0.5, -260, 1, -120), "", 22, Color3.fromRGB(255, 240, 150))
carryLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Toast line above the carrying hint.
local toastLabel = makeLabel(gui, "Toast", UDim2.fromOffset(640, 30), UDim2.new(0.5, -320, 1, -84), "", 20)
toastLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Tsunami banner, top centre, hidden until a wave is announced.
local banner = panel(gui, "WaveBanner", UDim2.fromOffset(560, 54), UDim2.new(0.5, -280, 0, 12), Color3.fromRGB(20, 90, 180))
banner.Visible = false
local bannerText = makeLabel(banner, "Text", UDim2.new(1, -20, 1, 0), UDim2.fromOffset(10, 0), "", 24)
bannerText.TextXAlignment = Enum.TextXAlignment.Center

-- Shop panel, centre screen, toggled by the SHOP button.
local shop = panel(gui, "ShopPanel", UDim2.fromOffset(430, 500), UDim2.new(0.5, -215, 0.5, -250), Color3.fromRGB(35, 35, 55))
shop.Visible = false
local shopTitle = makeLabel(shop, "Title", UDim2.new(1, -20, 0, 34), UDim2.fromOffset(12, 8), "BRAINROT SHOP", 26, Color3.fromRGB(255, 225, 110))
shopTitle.TextXAlignment = Enum.TextXAlignment.Center

local toastToken = 0
local function toast(text, kind)
	toastToken += 1
	local myToken = toastToken
	toastLabel.Text = text
	if kind == "good" then
		toastLabel.TextColor3 = Color3.fromRGB(140, 255, 160)
		sounds.good:Play()
	elseif kind == "bad" or kind == "warn" then
		toastLabel.TextColor3 = Color3.fromRGB(255, 150, 130)
		sounds.bad:Play()
	else
		toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	task.delay(3.5, function()
		if toastToken == myToken then
			toastLabel.Text = ""
		end
	end)
end

local function doShop(action, arg)
	local result = shopFunction:InvokeServer(action, arg)
	if type(result) == "table" then
		toast(result.Text or "", result.Ok and "good" or "warn")
		if result.Ok then
			sounds.buy:Play()
		end
	end
end

-- One buy button per rarity tier, priced from the shared catalog.
local y = 52
for _, rarity in ipairs(Catalog.Rarities) do
	local button = makeButton(shop, "Buy" .. rarity.Name, UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, y),
		rarity.Name .. " Brainrot — $" .. rarity.ShopPrice, Color3.fromRGB(70, 70, 100))
	button.TextColor3 = rarity.Color
	button.MouseButton1Click:Connect(function()
		doShop("BuyBrainrot", rarity.Name)
	end)
	y += 48
end
local padButton = makeButton(shop, "BuyPad", UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, y), "+1 Pad — from $" .. Catalog.Prices.ExtraPad, Color3.fromRGB(70, 70, 100))
padButton.MouseButton1Click:Connect(function()
	doShop("BuyPad")
end)
y += 48
local speedButton = makeButton(shop, "BuySpeed", UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, y), "Speed Boost — $" .. Catalog.Prices.SpeedBoost, Color3.fromRGB(70, 70, 100))
speedButton.MouseButton1Click:Connect(function()
	doShop("BuySpeed")
end)
y += 48
local rebirthButton = makeButton(shop, "Rebirth", UDim2.new(1, -24, 0, 44), UDim2.fromOffset(12, y), "REBIRTH (reset for x2)", Color3.fromRGB(160, 60, 160))
rebirthButton.MouseButton1Click:Connect(function()
	doShop("Rebirth")
end)
local closeButton = makeButton(shop, "Close", UDim2.fromOffset(36, 36), UDim2.new(1, -44, 0, 6), "X", Color3.fromRGB(180, 60, 60))
closeButton.MouseButton1Click:Connect(function()
	shop.Visible = false
end)

shopButton.MouseButton1Click:Connect(function()
	shop.Visible = not shop.Visible
end)
lockButton.MouseButton1Click:Connect(function()
	lockEvent:FireServer()
end)

-- Server pushes: notifications and authoritative state snapshots.
notifyEvent.OnClientEvent:Connect(function(kind, text)
	if kind == "wave" then
		bannerText.Text = text
		banner.Visible = true
		sounds.wave:Play()
		local tween = TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -280, 0, 12) })
		tween:Play()
	elseif kind == "waveclear" then
		banner.Visible = false
		toast(text, "good")
	else
		toast(text, kind)
	end
end)

stateEvent.OnClientEvent:Connect(function(state)
	coinsLabel.Text = "Coins: $" .. tostring(state.Coins)
	incomeLabel.Text = "Income: $" .. tostring(state.IncomePerSecond) .. "/s"
	multLabel.Text = "Rebirth multiplier: x" .. tostring(state.Multiplier) .. "  (" .. tostring(state.Rebirths) .. " rebirths)"
	padsLabel.Text = "Pads: " .. tostring(state.PadsUsed) .. "/" .. tostring(state.PadsMax)
	rebirthButton.Text = "REBIRTH — $" .. tostring(state.RebirthCost) .. " for x" .. tostring(state.Multiplier * 2)
	if state.Carrying then
		carryLabel.Text = "Carrying a Brainrot! Run back to YOUR base to place it!"
	else
		carryLabel.Text = ""
	end
	lockButton.Text = state.Locked and "LOCKED!" or "LOCK BASE"
	lockButton.BackgroundColor3 = state.Locked and Color3.fromRGB(40, 180, 120) or Color3.fromRGB(50, 130, 200)
end)

toast("Welcome to Brainrot Base Tycoon! Catch a Brainrot in the plaza.", "good")
