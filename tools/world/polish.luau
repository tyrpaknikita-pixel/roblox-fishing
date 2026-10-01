assert(not game:GetService("RunService"):IsRunning(), "Run this authoring tool in Studio Edit mode only")

-- Add-only visual pass. Existing DetailProps and hand-moved zone pieces are never reset.
local world = workspace:WaitForChild("FishingWorld")
local zones = world:WaitForChild("Zones")
local palette = {
	Lagoon = {title = "ЛАЗУРНАЯ ЛАГУНА", accent = Color3.fromRGB(78, 201, 219), fish = {Color3.fromRGB(194, 219, 227), Color3.fromRGB(90, 158, 211), Color3.fromRGB(230, 220, 240)}},
	ReedPond = {title = "ИЗУМРУДНЫЙ ПРУД", accent = Color3.fromRGB(91, 174, 123), fish = {Color3.fromRGB(236, 187, 74), Color3.fromRGB(207, 133, 53), Color3.fromRGB(255, 220, 104)}},
	MysticPool = {title = "ЛИЛОВЫЙ ОМУТ", accent = Color3.fromRGB(157, 125, 213), fish = {Color3.fromRGB(166, 131, 213), Color3.fromRGB(164, 175, 238), Color3.fromRGB(198, 164, 255)}},
}

local function part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.Anchored, p.CanCollide = true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function wedge(parent, name, size, cf, color)
	local p = Instance.new("WedgePart")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide = true, false
	p.Parent = parent
	return p
end

local wood = Color3.fromRGB(121, 84, 54)
local darkWood = Color3.fromRGB(80, 57, 42)
local sand = Color3.fromRGB(205, 185, 143)
local slate = Color3.fromRGB(113, 119, 117)

local function fish(parent, base, name, x, z, color, angle)
	local model = Instance.new("Model")
	model.Name, model.Parent = name, parent
	local pose = base * CFrame.new(x, 0.65, z) * CFrame.Angles(0, math.rad(angle), 0)
	part(model, "Body", Vector3.new(0.65, 0.35, 1.5), pose, color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	wedge(model, "Tail", Vector3.new(0.7, 0.3, 0.62), pose * CFrame.new(0, 0, 0.9) * CFrame.Angles(0, math.rad(45), 0), color)
	for _, side in ipairs({-1, 1}) do
		part(model, "Eye" .. side, Vector3.new(0.1, 0.1, 0.1), pose * CFrame.new(side * 0.31, 0.08, -0.45), Color3.fromRGB(25, 42, 47), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
end

local function sign(parent, base, title, accent)
	local board = part(parent, "ZoneSign", Vector3.new(10, 2.5, 0.5), base * CFrame.new(-8, 9.8, 25), darkWood, Enum.Material.Wood)
	part(parent, "SignPost", Vector3.new(0.55, 4.6, 0.55), base * CFrame.new(-8, 7, 25), wood, Enum.Material.Wood)
	for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
		local surface = Instance.new("SurfaceGui")
		surface.Name, surface.Face, surface.SizingMode = "SignText", face, Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud, surface.LightInfluence, surface.Parent = 40, 0.3, board
		local text = Instance.new("TextLabel")
		text.Size, text.BackgroundTransparency, text.Text = UDim2.fromScale(1, 1), 1, title
		text.TextScaled, text.Font, text.TextColor3 = true, Enum.Font.GothamBold, accent
		text.Parent = surface
	end
end

for _, zoneName in ipairs({"Lagoon", "ReedPond", "MysticPool"}) do
	local zone = zones:WaitForChild(zoneName)
	local water = zone:WaitForChild("Water")
	local info = palette[zoneName]
	if not zone:FindFirstChild("DetailProps") then
		local detail = Instance.new("Model")
		detail.Name, detail.Parent = "DetailProps", zone
		local base = water.CFrame

		-- Corner islets put solid ground beneath the existing decorative trees.
		for _, x in ipairs({-27, 27}) do
			for _, z in ipairs({-20, 20}) do
				local key = (x < 0 and "W" or "E") .. (z < 0 and "N" or "S")
				part(detail, "IsletRock" .. key, Vector3.new(19, 3.8, 14), base * CFrame.new(x, 0.2, z), slate, Enum.Material.Rock, Enum.PartType.Ball)
				part(detail, "IsletTop" .. key, Vector3.new(17, 1.5, 12), base * CFrame.new(x, 2.3, z), zoneName == "Lagoon" and sand or Color3.fromRGB(100, 137, 91), zoneName == "Lagoon" and Enum.Material.Sand or Enum.Material.Grass, Enum.PartType.Ball)
			end
		end

		-- Light shelter at the landward end of each fishing pier.
		for _, x in ipairs({-3.3, 3.3}) do
			part(detail, "ShelterPost" .. x, Vector3.new(0.45, 4.8, 0.45), base * CFrame.new(x, 8.6, 20), darkWood, Enum.Material.Wood)
		end
		part(detail, "ShelterRoof", Vector3.new(8, 0.35, 5.5), base * CFrame.new(0, 11.1, 20) * CFrame.Angles(math.rad(5), 0, 0), Color3.fromRGB(194, 176, 136), Enum.Material.Fabric)
		sign(detail, base, info.title, info.accent)

		for i, position in ipairs({{-10, -7, -28}, {3, 4, 42}, {11, -2, -20}}) do
			fish(detail, base, "FishSilhouette" .. i, position[1], position[2], info.fish[i], position[3])
		end

		if zoneName == "Lagoon" then
			for i, z in ipairs({-10, -7, -4}) do
				part(detail, "Driftwood" .. i, Vector3.new(0.8, 0.7, 4.5), base * CFrame.new(-20 + i * 1.6, 2.1, z) * CFrame.Angles(0, math.rad(i * 20), math.rad(12)), wood, Enum.Material.Wood, Enum.PartType.Cylinder)
			end
			for i, x in ipairs({5.3, 7.2}) do
				part(detail, "PierCrate" .. i, Vector3.new(1.5, 1.4, 1.5), base * CFrame.new(x, 6.6, 20), wood, Enum.Material.WoodPlanks)
			end
			part(detail, "PierBenchSeat", Vector3.new(4, 0.3, 1.2), base * CFrame.new(-7.5, 7.2, 20), wood, Enum.Material.WoodPlanks)
			for _, x in ipairs({-9, -6}) do
				part(detail, "PierBenchLeg" .. x, Vector3.new(0.35, 1.2, 0.35), base * CFrame.new(x, 6.5, 20), darkWood, Enum.Material.Wood)
			end
		elseif zoneName == "ReedPond" then
			for i = 1, 10 do
				local x, z = -18 + (i % 5) * 8, (i <= 5 and -14 or 13)
				part(detail, "Reed" .. i, Vector3.new(2.5 + i % 3, 0.28, 0.28), base * CFrame.new(x, 2, z) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(76, 133, 74), Enum.Material.Grass, Enum.PartType.Cylinder)
			end
			for i, x in ipairs({-12, -4, 5, 13}) do
				part(detail, "LilyPad" .. i, Vector3.new(0.15, 2.2, 2.2), base * CFrame.new(x, 1.1, 9 - i * 3) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(70, 150, 92), Enum.Material.Grass, Enum.PartType.Cylinder)
			end
		else
			for i, point in ipairs({{-17, -13}, {16, -9}, {-15, 9}, {15, 13}}) do
				local cf = base * CFrame.new(point[1], 2.7, point[2])
				part(detail, "CrystalBase" .. i, Vector3.new(1.5, 3.2, 1.5), cf * CFrame.Angles(0, math.rad(i * 27), math.rad(10)), Color3.fromRGB(111, 95, 148), Enum.Material.Slate)
				part(detail, "CrystalTip" .. i, Vector3.new(0.8, 1.1, 0.8), cf * CFrame.new(0, 2.1, 0), info.accent, Enum.Material.Neon, Enum.PartType.Ball)
			end
			for i, point in ipairs({{-20, 3}, {19, 5}, {-12, -16}, {12, 17}}) do
				local cf = base * CFrame.new(point[1], 3.5, point[2])
				part(detail, "MushroomStem" .. i, Vector3.new(0.4, 1.4, 0.4), cf, Color3.fromRGB(224, 207, 190), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
				part(detail, "MushroomCap" .. i, Vector3.new(1.4, 0.5, 1.4), cf * CFrame.new(0, 0.85, 0), Color3.fromRGB(157, 112, 193), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			end
		end
	end
end

print("[Fishing] Add-only zone detail pass complete")
