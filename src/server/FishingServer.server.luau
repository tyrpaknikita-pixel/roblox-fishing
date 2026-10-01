-- Gameplay only. Permanent scenery is authored and saved in Edit mode.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local remotes = RS:WaitForChild("FishingRemotes")
local Catalog = require(remotes:WaitForChild("Catalog"))
local action = remotes:WaitForChild("FishingAction")
local feedback = remotes:WaitForChild("FishingFeedback")
local world = workspace:WaitForChild("FishingWorld")
local sessions = {}
local rng = Random.new()

local function clearCast(s)
	s.serial += 1
	s.phase = "idle"
	s.biteEndsAt = nil
	if s.visual then s.visual:Destroy(); s.visual = nil end
end

local function rootOf(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0 and char:FindFirstChild("HumanoidRootPart") or nil
end

local function hasRod(player)
	local rod = player.Character and player.Character:FindFirstChild("FishingRod")
	return rod and rod:IsA("Tool") and rod
end

local function nearPart(player, part, distance)
	local root = rootOf(player)
	return root and part and (root.Position - part.Position).Magnitude <= distance
end

local function nearestWater(player)
	local root = rootOf(player)
	if not root then return nil end
	local best, bestDistance = nil, 26
	local zones = world:FindFirstChild("Zones")
	for _, zone in ipairs(zones and zones:GetChildren() or {}) do
		local water = zone:FindFirstChild("Water")
		if water and water:IsA("BasePart") and Catalog.Zones[water:GetAttribute("ZoneId")] then
			local p = water.CFrame:PointToObjectSpace(root.Position)
			local dx = math.max(math.abs(p.X) - water.Size.X / 2, 0)
			local dz = math.max(math.abs(p.Z) - water.Size.Z / 2, 0)
			local d = math.sqrt(dx * dx + dz * dz)
			if d < bestDistance and math.abs(p.Y) < 22 then best, bestDistance = water, d end
		end
	end
	return best
end

local function publish(player, message)
	local s = sessions[player]
	if not s then return end
	local rod = hasRod(player) or (player:FindFirstChild("Backpack") and player.Backpack:FindFirstChild("FishingRod"))
	local rodColors = {bamboo = Color3.fromRGB(117, 83, 49), river = Color3.fromRGB(50, 145, 156), master = Color3.fromRGB(160, 99, 195)}
	if rod and rod:FindFirstChild("Handle") then
		rod.Handle.Color = rodColors[s.rod]
		rod.ToolTip = Catalog.Rods[s.rod].name
	end
	local count, value, list, names = 0, 0, {}, {}
	for _, item in ipairs(s.fish) do
		count += 1; value += item.value
		names[item.name] = (names[item.name] or 0) + 1
	end
	for name, n in pairs(names) do table.insert(list, {name = name, count = n}) end
	table.sort(list, function(a, b) return a.name < b.name end)
	local water = nearestWater(player)
	feedback:FireClient(player, {
		phase = s.phase, message = message or "", coins = s.coins,
		rod = s.rod, float = s.float, bait = s.bait, baitCounts = s.baitCounts,
		ownedRods = s.ownedRods, ownedFloats = s.ownedFloats,
		count = count, value = value, fish = list,
		zone = water and water:GetAttribute("ZoneId"), biteEndsAt = s.biteEndsAt,
	})
	local stats = player:FindFirstChild("leaderstats")
	if stats then stats.Coins.Value = s.coins; stats.Fish.Value = count end
	player:SetAttribute("FishingPhase", s.phase)
end

local function setup(player)
	if sessions[player] then return end
	local s = {coins = 30, rod = "bamboo", float = "cork", bait = "bread",
		baitCounts = {bread = 10, worm = 0, luminous = 0},
		ownedRods = {bamboo = true}, ownedFloats = {cork = true},
		fish = {}, phase = "idle", serial = 0, lastAction = 0}
	sessions[player] = s
	local stats = Instance.new("Folder"); stats.Name = "leaderstats"; stats.Parent = player
	for _, name in ipairs({"Coins", "Fish"}) do local v = Instance.new("IntValue"); v.Name = name; v.Parent = stats end
	local function characterAdded(character)
		clearCast(s)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and child.Name == "FishingRod" then clearCast(s); publish(player, "Заброс отменён: удочка убрана") end
		end)
		local hum = character:WaitForChild("Humanoid", 10)
		if hum then hum.Died:Connect(function() clearCast(s); publish(player, "Заброс отменён") end) end
	end
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then task.spawn(characterAdded, player.Character) end
	publish(player, "Добро пожаловать! Возьмите удочку и подойдите к воде")
end

local function chooseFish(zoneId, baitId)
	local pool, total = {}, 0
	local boost = Catalog.Baits[baitId] and Catalog.Baits[baitId].boost or 0
	for _, f in ipairs(Catalog.Fish) do
		if f.zone == zoneId then
			local weight = f.weight * (f.weight <= 20 and (1 + boost) or 1)
			total += weight; table.insert(pool, {fish = f, upto = total})
		end
	end
	if total == 0 then return nil end
	local roll = rng:NextNumber(0, total)
	for _, item in ipairs(pool) do if roll <= item.upto then return item.fish end end
	return pool[#pool].fish
end

local function createFloat(player, s, water)
	local model = Instance.new("Model"); model.Name = "Cast_" .. player.UserId
	local bob = Instance.new("Part"); bob.Name = "Float"; bob.Shape = Enum.PartType.Ball
	bob.Size = Vector3.new(1, 1.4, 1); bob.Anchored = true; bob.CanCollide = false; bob.CanQuery = false
	bob.Color = Catalog.Floats[s.float].color or Color3.fromRGB(255, 125, 70)
	bob.Material = Enum.Material.SmoothPlastic
	bob.CFrame = water.CFrame * CFrame.new(rng:NextNumber(-7, 7), water.Size.Y / 2 + 0.6, rng:NextNumber(-5, 5))
	bob.Parent = model
	if s.float == "glow" then
		local light = Instance.new("PointLight"); light.Color = bob.Color; light.Range = 7; light.Brightness = 0.8; light.Parent = bob
	elseif s.float == "feather" then bob.Size = Vector3.new(0.45, 2, 0.45) end
	local attachment = Instance.new("Attachment"); attachment.Parent = bob
	local rod = hasRod(player)
	local tip = rod and rod:FindFirstChild("RodTip", true)
	if tip and tip:IsA("Attachment") then
		local beam = Instance.new("Beam"); beam.Name = "Line"; beam.Attachment0 = tip; beam.Attachment1 = attachment
		beam.Width0 = 0.045; beam.Width1 = 0.025; beam.FaceCamera = true
		beam.Color = ColorSequence.new(Color3.fromRGB(242, 235, 208)); beam.Parent = bob
	end
	model.Parent = world; s.visual = model
	return bob
end

local function cast(player)
	local s = sessions[player]
	local water = nearestWater(player)
	if not hasRod(player) then clearCast(s); publish(player, "Сначала возьмите удочку"); return end
	if not water then clearCast(s); publish(player, "Подойдите ближе к одному из трёх водоёмов"); return end
	if s.phase == "bite" then
		if workspace:GetServerTimeNow() > s.biteEndsAt or water ~= s.water then clearCast(s); publish(player, "Рыба ушла"); return end
		local fish = chooseFish(s.water:GetAttribute("ZoneId"), s.castBait)
		clearCast(s)
		if fish then
			local kg = math.floor(rng:NextNumber(fish.minWeight, fish.maxWeight) * 100) / 100
			local worth = math.max(1, math.floor(fish.value * (0.8 + kg / fish.maxWeight * 0.4)))
			table.insert(s.fish, {id = fish.id, name = fish.name, kg = kg, value = worth})
			publish(player, string.format("Поймано: %s · %.2f кг · %d монет", fish.name, kg, worth))
		end
		return
	elseif s.phase == "waiting" then
		clearCast(s); publish(player, "Рано! Дождитесь поклёвки"); return
	end
	if #s.fish >= 100 then publish(player, "Корзина полна — продайте улов"); return end
	s.serial += 1; local serial = s.serial
	s.phase = "waiting"; s.water = water
	s.castBait = s.baitCounts[s.bait] > 0 and s.bait or nil
	if s.castBait then s.baitCounts[s.bait] -= 1 end
	local bob = createFloat(player, s, water)
	publish(player, s.castBait and "Поплавок в воде. Ждите поклёвки…" or "Ловите без приманки — ожидание дольше")
	local waitTime = rng:NextNumber(2.5, 5) / Catalog.Rods[s.rod].speed + (s.castBait and 0 or 2)
	task.delay(waitTime, function()
		if sessions[player] ~= s or s.serial ~= serial then return end
		if not hasRod(player) or nearestWater(player) ~= water then clearCast(s); publish(player, "Заброс отменён: вы отошли от воды"); return end
		s.phase = "bite"; s.biteEndsAt = workspace:GetServerTimeNow() + Catalog.Floats[s.float].window
		bob.Color = Color3.fromRGB(255, 216, 86); bob.Material = Enum.Material.Neon
		bob.Position -= Vector3.new(0, 0.7, 0)
		publish(player, "КЛЮЁТ! Подсекайте!")
		task.delay(Catalog.Floats[s.float].window, function()
			if sessions[player] == s and s.serial == serial and s.phase == "bite" then clearCast(s); publish(player, "Не успели — рыба ушла") end
		end)
	end)
end

local function sell(player)
	local s = sessions[player]
	local counter = world:FindFirstChild("Fishmonger") and world.Fishmonger:FindFirstChild("Counter")
	if not nearPart(player, counter, 18) then publish(player, "Подойдите к рыбной лавке для продажи"); return end
	local worth = 0; for _, f in ipairs(s.fish) do worth += f.value end
	if worth == 0 then publish(player, "Корзина пока пуста"); return end
	s.coins += worth; s.fish = {}; publish(player, "Улов продан: +" .. worth .. " монет")
end

local tables = {rod = Catalog.Rods, float = Catalog.Floats, bait = Catalog.Baits}
action.OnServerEvent:Connect(function(player, verb, category, id)
	local s = sessions[player]
	if not s or type(verb) ~= "string" then return end
	local now = os.clock()
	if now - s.lastAction < 0.15 then return end
	s.lastAction = now
	if verb == "sync" then publish(player); return end
	if verb == "cast" then cast(player); return end
	if verb == "cancel" then clearCast(s); publish(player, "Заброс отменён"); return end
	if verb == "sell" then sell(player); return end
	if (verb ~= "buy" and verb ~= "equip") or type(category) ~= "string" or type(id) ~= "string" then return end
	local item = tables[category] and tables[category][id]
	if not item then return end
	if s.phase ~= "idle" then publish(player, "Сначала завершите или отмените заброс"); return end
	local owned = category == "rod" and s.ownedRods or category == "float" and s.ownedFloats or nil
	if verb == "buy" then
		if owned and owned[id] then publish(player, "Уже куплено — нажмите выбрать"); return end
		if s.coins < item.price then publish(player, "Недостаточно монет"); return end
		s.coins -= item.price
		if owned then owned[id] = true; s[category] = id
		else s.baitCounts[id] += item.amount; s.bait = id end
		publish(player, "Куплено: " .. item.name)
	else
		if (owned and not owned[id]) or (category == "bait" and s.baitCounts[id] <= 0) then publish(player, "Сначала купите эту снасть"); return end
		s[category] = id; publish(player, "Выбрано: " .. item.name)
	end
end)

local prompt = world:WaitForChild("Fishmonger"):WaitForChild("Counter"):FindFirstChild("SellPrompt")
if prompt then prompt.Triggered:Connect(function(player) if sessions[player] then sell(player) end end) end
Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do setup(player) end
Players.PlayerRemoving:Connect(function(player) local s = sessions[player]; if s then clearCast(s); sessions[player] = nil end end)
print("[Fishing] Server ready: three waters, equipment shop, session inventory")
