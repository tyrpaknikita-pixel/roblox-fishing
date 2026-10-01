local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("FishingRemotes")
local Catalog = require(remotes:WaitForChild("Catalog"))
local action = remotes:WaitForChild("FishingAction")
local feedback = remotes:WaitForChild("FishingFeedback")

local gui = Instance.new("ScreenGui")
gui.Name = "FishingHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function make(className, parent, props)
	local object = Instance.new(className)
	for key, value in pairs(props) do object[key] = value end
	object.Parent = parent
	return object
end

local ink = Color3.fromRGB(235, 246, 246)
local muted = Color3.fromRGB(159, 194, 198)
local sea = Color3.fromRGB(22, 47, 55)
local accent = Color3.fromRGB(90, 222, 196)

local function round(frame, radius)
	make("UICorner", frame, {CornerRadius = UDim.new(0, radius)})
end

local function label(parent, text, size, color, height)
	return make("TextLabel", parent, {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height), Text = text,
		Font = Enum.Font.Gotham, TextSize = size, TextColor3 = color,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local function button(parent, text, height, callback)
	local b = make("TextButton", parent, {
		Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Color3.fromRGB(46, 84, 91),
		Text = text, TextColor3 = ink, TextSize = 15, Font = Enum.Font.GothamSemibold,
		AutoButtonColor = true,
	})
	round(b, 10)
	b.Activated:Connect(callback)
	return b
end

local function stack(parent, padding)
	make("UIListLayout", parent, {Padding = UDim.new(0, padding), SortOrder = Enum.SortOrder.LayoutOrder})
end

local panel = make("Frame", gui, {
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(410, 178), BackgroundColor3 = sea, BackgroundTransparency = 0.04,
})
round(panel, 18)
make("UIStroke", panel, {Color = accent, Transparency = 0.55, Thickness = 1.5})
make("UIPadding", panel, {PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16)})
stack(panel, 5)
local heading = label(panel, "ТИХАЯ БУХТА", 20, accent, 26)
heading.Font = Enum.Font.GothamBold
local stats = label(panel, "Монеты: 0   •   Корзина: 0", 15, ink, 22)
local status = label(panel, "Возьмите удочку и подойдите к воде", 14, muted, 36)
local castButton

local drawer = make("Frame", gui, {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 120),
	Size = UDim2.fromOffset(330, 465), BackgroundColor3 = sea, Visible = false,
})
round(drawer, 16)
make("UIPadding", drawer, {PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})
stack(drawer, 8)
local drawerTitle = label(drawer, "СНАРЯЖЕНИЕ И УЛОВ", 17, accent, 25)
drawerTitle.Font = Enum.Font.GothamBold
local tabs = make("Frame", drawer, {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1})
make("UIListLayout", tabs, {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)})
local list = make("ScrollingFrame", drawer, {
	Size = UDim2.new(1, 0, 1, -77), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
})
stack(list, 7)
make("UIPadding", list, {PaddingRight = UDim.new(0, 6)})

local state = {phase = "idle", coins = 0, rod = "bamboo", float = "cork", bait = "bread", baitCounts = {bread = 10}, ownedRods = {bamboo = true}, ownedFloats = {cork = true}, count = 0, value = 0, fish = {}}
local activeTab = "rod"
local render

local function send(verb, category, id)
	action:FireServer(verb, category, id)
end

local function equipRod()
	local character = player.Character
	if character and character:FindFirstChild("FishingRod") then return true end
	local backpack = player:FindFirstChildOfClass("Backpack")
	local tool = backpack and backpack:FindFirstChild("FishingRod")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if tool and humanoid then
		humanoid:EquipTool(tool)
		return true
	end
	return false
end

local function cast()
	if state.phase == "waiting" then
		send("cancel")
	elseif equipRod() then
		send("cast")
	else
		status.Text = "Удочка ещё не готова"
	end
end

castButton = button(panel, "ЗАБРОСИТЬ  •  F", 42, cast)
castButton.BackgroundColor3 = Color3.fromRGB(33, 130, 124)

local toggle = make("TextButton", gui, {
	AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 72),
	Size = UDim2.fromOffset(146, 40), BackgroundColor3 = sea,
	Text = "🎣 Снаряжение", TextColor3 = ink, Font = Enum.Font.GothamSemibold, TextSize = 14,
})
round(toggle, 12)
toggle.Activated:Connect(function() drawer.Visible = not drawer.Visible end)

local tabNames = {rod = "Удочки", float = "Поплавки", bait = "Наживка", basket = "Корзина"}
for _, id in ipairs({"rod", "float", "bait", "basket"}) do
	local tab = make("TextButton", tabs, {
		Size = UDim2.new(0.25, -5, 1, 0), BackgroundColor3 = Color3.fromRGB(41, 72, 79),
		Text = tabNames[id], TextColor3 = ink, Font = Enum.Font.GothamMedium, TextSize = 12,
	})
	round(tab, 8)
	tab.Activated:Connect(function() activeTab = id; render() end)
end

local function clearList()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
	end
end

local function item(id, data, category)
	local card = make("Frame", list, {Size = UDim2.new(1, 0, 0, category == "bait" and 114 or 86), BackgroundColor3 = Color3.fromRGB(34, 65, 72)})
	round(card, 10)
	make("UIPadding", card, {PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
	stack(card, 3)
	local title = label(card, data.name, 15, ink, 21)
	title.Font = Enum.Font.GothamSemibold
	local detail
	if category == "rod" then detail = string.format("Ожидание быстрее ×%.2g", data.speed)
	elseif category == "float" then detail = string.format("Окно поклёвки %.1f сек", data.window)
	else detail = string.format("%d шт. • вес редких +%d%% • есть %d", data.amount, math.floor(data.boost * 100), (state.baitCounts or {})[id] or 0) end
	label(card, detail, 12, muted, 17)
	local owned = category == "rod" and (state.ownedRods or {})[id] or category == "float" and (state.ownedFloats or {})[id] or ((state.baitCounts or {})[id] or 0) > 0
	local equipped = state[category] == id
	local caption = equipped and "Выбрано" or owned and "Выбрать" or string.format("Купить • %d монет", data.price)
	if category == "bait" then caption = equipped and "Наживка выбрана" or owned and "Выбрать наживку" or "Нет в запасе" end
	local control = button(card, caption, 25, function()
		if equipped then return end
		if owned then send("equip", category, id) elseif category ~= "bait" then send("buy", category, id) end
	end)
	control.TextSize = 12
	control.BackgroundColor3 = equipped and Color3.fromRGB(53, 106, 99) or Color3.fromRGB(54, 100, 111)
	if category == "bait" then
		local buy = button(card, string.format("Купить %d шт. • %d монет", data.amount, data.price), 25, function() send("buy", category, id) end)
		buy.TextSize = 12
	end
end

render = function()
	stats.Text = string.format("Монеты: %d   •   Корзина: %d рыб / %d монет", state.coins or 0, state.count or 0, state.value or 0)
	castButton.Text = state.phase == "bite" and "ПОДСЕЧЬ!  •  F" or state.phase == "waiting" and "СМОТАТЬ  •  F" or "ЗАБРОСИТЬ  •  F"
	castButton.BackgroundColor3 = state.phase == "bite" and Color3.fromRGB(194, 113, 59) or Color3.fromRGB(33, 130, 124)
	clearList()
	if activeTab == "basket" then
		label(list, string.format("Улов: %d рыб • %d монет", state.count or 0, state.value or 0), 15, ink, 26)
		local entries = state.fish or {}
		if #entries == 0 then label(list, "Корзина пуста. Попробуйте забросить удочку!", 13, muted, 42) end
		for _, entry in ipairs(entries) do
			label(list, string.format("%s  × %d", entry.name, entry.count), 14, ink, 25)
		end
		button(list, "Продать улов у рыбного рынка", 38, function() send("sell") end)
		label(list, "Для продажи подойдите к прилавку.", 12, muted, 25)
	else
		local catalog = activeTab == "rod" and Catalog.Rods or activeTab == "float" and Catalog.Floats or Catalog.Baits
		local order = activeTab == "rod" and {"bamboo", "river", "master"} or activeTab == "float" and {"cork", "feather", "glow"} or {"bread", "worm", "luminous"}
		if activeTab == "bait" then label(list, "Бонус увеличивает относительный вес редких рыб при выборе улова.", 12, muted, 38) end
		for _, id in ipairs(order) do item(id, catalog[id], activeTab) end
	end
end

feedback.OnClientEvent:Connect(function(snapshot)
	if typeof(snapshot) ~= "table" then return end
	for key, value in pairs(snapshot) do state[key] = value end
	if snapshot.message and snapshot.message ~= "" then status.Text = snapshot.message end
	render()
end)

local connected = {}
local function connectTool(tool)
	if not tool:IsA("Tool") or tool.Name ~= "FishingRod" or connected[tool] then return end
	connected[tool] = true
	tool.Activated:Connect(cast)
end

local backpack = player:WaitForChild("Backpack")
for _, tool in ipairs(backpack:GetChildren()) do connectTool(tool) end
backpack.ChildAdded:Connect(connectTool)
local function onCharacter(character)
	for _, tool in ipairs(character:GetChildren()) do connectTool(tool) end
	character.ChildAdded:Connect(connectTool)
end
if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.F then cast() end
end)

local function resize()
	local width = gui.AbsoluteSize.X
	local height = gui.AbsoluteSize.Y
	if width < 800 then
		panel.Size = UDim2.new(1, -24, 0, 178)
		drawer.Size = UDim2.new(1, -24, 0, math.max(86, math.min(440, height - 314)))
		drawer.Position = UDim2.new(1, -12, 0, 120)
		toggle.Position = UDim2.new(1, -12, 0, 72)
	else
		panel.Size = UDim2.fromOffset(410, 178)
		drawer.Size = UDim2.fromOffset(330, math.max(86, math.min(465, height - 314)))
		drawer.Position = UDim2.new(1, -16, 0, 120)
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
render()
send("sync")
