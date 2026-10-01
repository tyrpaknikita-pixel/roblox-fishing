-- Run from repository root: .tools/lune/lune.exe run tools/save-place.luau
-- Reads world/.scene-snapshot.json and world/fishing.rbxl; writes only world/fishing-next.rbxl.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local Instance, Vector3, Vector2 = roblox.Instance, roblox.Vector3, roblox.Vector2
local Color3, CFrame = roblox.Color3, roblox.CFrame
local UDim2, UDim, Enum, BrickColor = roblox.UDim2, roblox.UDim, roblox.Enum, roblox.BrickColor

local snapshot = serde.decode("json", fs.readFile("world/.scene-snapshot.json"))
assert(snapshot.format == 1 and type(snapshot.roots) == "table", "Unsupported scene snapshot")
local game = roblox.deserializePlace(fs.readFile("world/fishing.rbxl"))
local terrainBefore = roblox.serializeModel({game:GetService("Workspace"):FindFirstChildOfClass("Terrain")})
local ids, deferred = {}, {}

local function decode(v)
	if type(v) ~= "table" then return v end
	local kind = assert(v.kind, "Missing encoded value kind")
	if kind == "Ref" then return assert(ids[v.id], "Missing instance ref " .. tostring(v.id)) end
	if kind == "Vector3" then return Vector3.new(v.x, v.y, v.z) end
	if kind == "Vector2" then return Vector2.new(v.x, v.y) end
	if kind == "Color3" then return Color3.new(v.r, v.g, v.b) end
	if kind == "CFrame" then return CFrame.new(table.unpack(v.components)) end
	if kind == "UDim2" then return UDim2.new(v.xs, v.xo, v.ys, v.yo) end
	if kind == "UDim" then return UDim.new(v.scale, v.offset) end
	if kind == "EnumItem" then return assert(Enum[v.enum], "Unknown enum " .. v.enum)[v.name] end
	if kind == "BrickColor" then return BrickColor.new(v.number) end
	if kind == "Font" then return roblox.Font.new(v.family, Enum.FontWeight[v.weight], Enum.FontStyle[v.style]) end
	error("Unsupported encoded value " .. kind)
end

local function locate(path)
	local object = game:GetService(path[1])
	for i = 2, #path do object = assert(object:FindFirstChild(path[i]), "Missing parent " .. path[i]) end
	return object
end
local approved = {
	["Workspace/FishingWorld"] = true, ["ReplicatedStorage/FishingRemotes"] = true,
	["ServerScriptService/FishingServer"] = true,
	["StarterPlayer/StarterPlayerScripts/FishingClient"] = true,
	["StarterPack/FishingRod"] = true,
}
local function create(node, parent)
	assert(type(node.id) == "number" and not ids[node.id], "Duplicate or missing node id")
	local object = Instance.new(node.class)
	object.Name = node.name
	object.Parent = parent
	ids[node.id] = object
	table.insert(deferred, {object = object, node = node})
	for _, child in ipairs(node.children) do create(child, object) end
	return object
end
local expected = {}
for _, entry in ipairs(snapshot.roots) do
	local path = table.concat(entry.parentPath, "/") .. "/" .. entry.tree.name
	assert(approved[path] or (path:match("^Lighting/Fishing[%w_]+$") and
		(entry.tree.class == "Atmosphere" or entry.tree.class == "BloomEffect" or entry.tree.class == "ColorCorrectionEffect")),
		"Unapproved replacement root " .. path)
	assert(not expected[path], "Duplicate root " .. path)
	expected[path] = true
	local parent = locate(entry.parentPath)
	local old = parent:FindFirstChild(entry.tree.name)
	if old then old:Destroy() end
	create(entry.tree, parent)
end
for _, item in ipairs(deferred) do
	local object, node = item.object, item.node
	for key, encoded in pairs(node.properties) do
		if type(encoded) == "table" and encoded.kind == "Ref" then
			-- Apply after every instance is created, including cross-root references.
		else
			object[key] = decode(encoded)
		end
	end
	for key, encoded in pairs(node.attributes) do object:SetAttribute(key, decode(encoded)) end
end
for _, item in ipairs(deferred) do
	for key, encoded in pairs(item.node.properties) do
		if type(encoded) == "table" and encoded.kind == "Ref" then item.object[key] = decode(encoded) end
	end
end
local lighting = game:GetService("Lighting")
for key, encoded in pairs(snapshot.lighting) do
	assert(({ClockTime=true, Brightness=true, Ambient=true, OutdoorAmbient=true,
		EnvironmentDiffuseScale=true, EnvironmentSpecularScale=true, GlobalShadows=true})[key], "Unapproved Lighting property " .. key)
	lighting[key] = decode(encoded)
end

local terrainAfter = roblox.serializeModel({game:GetService("Workspace"):FindFirstChildOfClass("Terrain")})
assert(terrainBefore == terrainAfter, "Terrain changed during save")
local function counts(place)
	local scripts, zones = 0, 0
	for _, descendant in ipairs(place:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") then scripts += 1 end
		if descendant:IsA("Model") and descendant.Parent and descendant.Parent.Name == "Zones" then zones += 1 end
	end
	return scripts, zones
end
local scripts, zones = counts(game)
assert(scripts >= 3 and zones >= 3, "Snapshot lacks scripts or fishing zones")
local output = roblox.serializePlace(game)
local check = roblox.deserializePlace(output)
local checkScripts, checkZones = counts(check)
assert(checkScripts == scripts and checkZones == zones, "Round-trip script/zone count mismatch")
for path in pairs(expected) do
	local segments = string.split(path, "/")
	local name = table.remove(segments)
	local parent = check:GetService(segments[1])
	for i = 2, #segments do parent = assert(parent:FindFirstChild(segments[i])) end
	assert(parent:FindFirstChild(name), "Missing saved root " .. path)
end
assert(roblox.serializeModel({check:GetService("Workspace"):FindFirstChildOfClass("Terrain")}) == terrainBefore,
	"Terrain changed after serialization")
fs.writeFile("world/fishing-next.rbxl", output)
print(string.format("Verified fishing-next.rbxl: %d scripts, %d zones, Terrain unchanged", scripts, zones))
