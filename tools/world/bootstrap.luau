assert(not game:GetService("RunService"):IsRunning(), "Run this authoring tool in Studio Edit mode only")
-- Explicit Edit-only migration. Back up the place before the first run.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local Lighting = game:GetService("Lighting")

local function ensure(class, parent, name, properties)
	local object = parent:FindFirstChild(name)
	if object then return object, false end
	object = Instance.new(class)
	object.Name = name
	for key, value in pairs(properties or {}) do object[key] = value end
	object.Parent = parent
	return object, true
end

local function part(parent, name, size, cf, color, material, shape)
	return ensure("Part", parent, name, {
		Anchored = true, Size = size, CFrame = cf, Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Shape = shape or Enum.PartType.Block,
		TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
	})
end

local world = ensure("Model", Workspace, "FishingWorld")
local migrated = false
if world:GetAttribute("AuthoringVersion") == nil then
	-- Existing island, dock, hut, spawn and loose scenery were authored 14 studs too low.
	for _, child in ipairs(world:GetChildren()) do
		if child:IsA("BasePart") then
			child.CFrame += Vector3.new(0, 14, 0)
		elseif child:IsA("Model") then
			child:PivotTo(child:GetPivot() + Vector3.new(0, 14, 0))
		elseif child.Name == "Nature" and child:IsA("Folder") then
			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("BasePart") then descendant.CFrame += Vector3.new(0, 14, 0) end
			end
		end
	end
	for index = 0, 6 do
		local stone = world:FindFirstChild("PathStone" .. index)
		if stone and stone:IsA("BasePart") then stone.Size = Vector3.new(0.45, 5.5, 4.2) end
	end
	local oldWater = world:FindFirstChild("Water")
	if oldWater and oldWater:IsA("BasePart") then
		oldWater.Transparency = 0.05
		oldWater.Material = Enum.Material.SmoothPlastic
		oldWater.Color = Color3.fromRGB(41, 133, 152)
		oldWater.CanCollide = false
	end
	local shop = world:FindFirstChild("Fishmonger")
	if shop then
		local sign = shop:FindFirstChild("Sign")
		local label = sign and sign:FindFirstChild("Label")
		if label and label:IsA("SurfaceGui") then label.Face = Enum.NormalId.Back end
	end
	world:SetAttribute("AuthoringVersion", 2)
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.5
	migrated = true
end

local wood = Color3.fromRGB(126, 87, 55)
local darkWood = Color3.fromRGB(82, 57, 38)
local stone = Color3.fromRGB(159, 151, 127)
local sand = Color3.fromRGB(216, 191, 139)
local function boardwalk(parent, name, a, b, width, y)
	local midpoint = (a + b) / 2
	local length = (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
	local cf = CFrame.lookAt(Vector3.new(midpoint.X, y, midpoint.Z), Vector3.new(b.X, y, b.Z))
	part(parent, name .. "Deck", Vector3.new(width, 1, length), cf, wood, Enum.Material.WoodPlanks)
	for i = 1, 2 do
		for side, offset in ipairs({-1, 1}) do
			local postCf = cf * CFrame.new(offset * (width / 2 - 0.5), -3.4, i == 1 and length / 2 or -length / 2)
			part(parent, name .. "Post" .. i .. side, Vector3.new(0.9, 7, 0.9), postCf, darkWood, Enum.Material.Wood)
		end
	end
end

local zones = ensure("Folder", world, "Zones")
local definitions = {
	{"Lagoon", "lagoon", Vector3.new(65, 12, 0), Color3.fromRGB(60, 197, 213), Color3.fromRGB(67, 145, 106)},
	{"ReedPond", "pond", Vector3.new(-50, 12, 68), Color3.fromRGB(92, 168, 108), Color3.fromRGB(94, 143, 75)},
	{"MysticPool", "mystic", Vector3.new(55, 12, 88), Color3.fromRGB(162, 125, 212), Color3.fromRGB(100, 94, 153)},
}
for _, data in ipairs(definitions) do
	local name, id, center, color, leafColor = table.unpack(data)
	local zone, created = ensure("Model", zones, name)
	if created then
		zone:SetAttribute("ZoneId", id)
		local water = part(zone, "Water", Vector3.new(44, 2, 34), CFrame.new(center + Vector3.new(0, 0.2, 0)), color)
		water.Transparency = 0.1
		water.CanCollide = false
		water:SetAttribute("ZoneId", id)
		zone.PrimaryPart = water
		for _, bank in ipairs({
			{"NorthBank", Vector3.new(44, 2, 4), Vector3.new(0, 0, -19)},
			{"SouthWestBank", Vector3.new(16, 2, 4), Vector3.new(-14, 0, 19)},
			{"SouthEastBank", Vector3.new(16, 2, 4), Vector3.new(14, 0, 19)},
			{"WestBank", Vector3.new(4, 2, 34), Vector3.new(-24, 0, 0)},
			{"EastBank", Vector3.new(4, 2, 34), Vector3.new(24, 0, 0)},
		}) do
			part(zone, bank[1], bank[2], CFrame.new(center + bank[3]), sand, Enum.Material.Sand)
		end
		for i = 1, 9 do
			local angle = i * 2.399
			local radius = i % 2 == 0 and 30 or 27
			local p = center + Vector3.new(math.cos(angle) * radius, 5, math.sin(angle) * 22)
			local trunk = part(zone, "TreeTrunk" .. i, Vector3.new(1.1, 7, 1.1), CFrame.new(p), darkWood, Enum.Material.Wood)
			trunk.CanCollide = false
			local crown = part(zone, "TreeCrown" .. i, Vector3.new(5, 6, 5), CFrame.new(p + Vector3.new(0, 5.5, 0)), leafColor, Enum.Material.Grass, Enum.PartType.Ball)
			crown.CanCollide = false
			local rock = part(zone, "Rock" .. i, Vector3.new(2.2, 1.8, 2.7), CFrame.new(p + Vector3.new(2, -2.8, 2)), stone, Enum.Material.Rock, Enum.PartType.Ball)
			rock.CanCollide = false
		end
		boardwalk(zone, "FishingPier", center + Vector3.new(0, 6, 24), center + Vector3.new(0, 6, 5), 8, 18)
	end
end

local paths = ensure("Model", world, "Boardwalks")
local connections = {
	{"LagoonWalk", Vector3.new(28, 0, 8), Vector3.new(65, 0, 24), 8},
	{"PondWalk", Vector3.new(-35, 0, 23), Vector3.new(-50, 0, 92), 7},
	{"MysticWalk", Vector3.new(0, 0, 38), Vector3.new(55, 0, 112), 7},
}
for _, connection in ipairs(connections) do
	local name, a, b, width = table.unpack(connection)
	local path, created = ensure("Model", paths, name)
	if created then boardwalk(path, name, a, b, width, 19) end
end

local shop = world:FindFirstChild("Fishmonger")
if shop then
	local counter = shop:FindFirstChild("Counter")
	if counter then
		ensure("ProximityPrompt", counter, "SellPrompt", {
			ActionText = "Sell catch", ObjectText = "Fishmonger", HoldDuration = 0.35, MaxActivationDistance = 12,
		})
	end
	local sign = shop:FindFirstChild("Sign")
	if sign then
		local gui = ensure("SurfaceGui", sign, "Label", {Face = Enum.NormalId.Back, AlwaysOnTop = true})
		ensure("TextLabel", gui, "Text", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			Text = "FISH MARKET", TextColor3 = darkWood, TextScaled = true, Font = Enum.Font.GothamBold})
	end
end

local decor = ensure("Model", world, "ParkDetails")
for i, p in ipairs({Vector3.new(-23, 22, 17), Vector3.new(8, 22, 20)}) do
	local bench, created = ensure("Model", decor, "Bench" .. i)
	if created then
		part(bench, "Seat", Vector3.new(8, 0.8, 2), CFrame.new(p), wood, Enum.Material.WoodPlanks)
		part(bench, "Back", Vector3.new(8, 3, 0.6), CFrame.new(p + Vector3.new(0, 1.8, -0.8)), darkWood, Enum.Material.Wood)
		for side, x in ipairs({-3, 3}) do
			part(bench, "Leg" .. side, Vector3.new(0.7, 3, 0.7), CFrame.new(p + Vector3.new(x, -1.6, 0)), darkWood, Enum.Material.Wood)
		end
	end
end

local remotes = ensure("Folder", ReplicatedStorage, "FishingRemotes")
for _, name in ipairs({"FishingAction", "FishingFeedback"}) do ensure("RemoteEvent", remotes, name) end

local rod, newRod = ensure("Tool", StarterPack, "FishingRod", {ToolTip = "Cast near water", CanBeDropped = false})
local handle, newHandle = ensure("Part", rod, "Handle", {
	Size = Vector3.new(0.36, 0.36, 4.6), Color = darkWood, Material = Enum.Material.Wood,
	CanCollide = false, Massless = true,
})
if migrated and not newHandle then
	handle.Size = Vector3.new(0.36, 0.36, 4.6)
	handle.Color = darkWood
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
end
if newRod or newHandle then rod.Grip = CFrame.new(0, -1.4, -1) * CFrame.Angles(math.rad(-72), 0, 0) end
local function rodPiece(name, size, offset, color, material)
	local piece, created = part(rod, name, size, handle.CFrame * CFrame.new(offset), color, material)
	if created then
		piece.Anchored = false
		piece.CanCollide = false
		piece.Massless = true
		ensure("WeldConstraint", piece, "HandleWeld", {Part0 = handle, Part1 = piece})
	end
end
rodPiece("RodShaft", Vector3.new(0.18, 0.18, 5), Vector3.new(0, 0, -4.3), Color3.fromRGB(63, 69, 66), Enum.Material.Metal)
rodPiece("RodReel", Vector3.new(1, 0.8, 0.8), Vector3.new(0, -0.45, -1), Color3.fromRGB(220, 178, 85), Enum.Material.Metal)
rodPiece("RodAccent", Vector3.new(0.45, 0.45, 0.55), Vector3.new(0, 0, -2), Color3.fromRGB(225, 177, 79), Enum.Material.Metal)
local tip = ensure("Attachment", handle, "RodTip", {Position = Vector3.new(0, 0, -6.8)})
if migrated then tip.Position = Vector3.new(0, 0, -6.8) end

ensure("Atmosphere", Lighting, "FishingAtmosphere", {Density = 0.28, Haze = 1.25,
	Color = Color3.fromRGB(205, 230, 235), Decay = Color3.fromRGB(100, 132, 145)})
ensure("BloomEffect", Lighting, "FishingBloom", {Intensity = 0.18, Size = 28, Threshold = 1.1})
ensure("ColorCorrectionEffect", Lighting, "FishingColor", {Brightness = 0.025, Contrast = 0.06,
	Saturation = 0.08, TintColor = Color3.fromRGB(255, 244, 220)})
return migrated and "FishingWorld migrated to v2 and editable zones added" or "FishingWorld v2 checked; existing edits preserved"
