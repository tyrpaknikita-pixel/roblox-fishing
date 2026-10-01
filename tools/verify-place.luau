-- Background verification of the saved place; no Studio window manipulation.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local game = roblox.deserializePlace(fs.readFile("world/fishing.rbxl"))
local world = assert(game:GetService("Workspace"):FindFirstChild("FishingWorld"), "Missing permanent world")
local sources = {
	{game:GetService("ServerScriptService"):FindFirstChild("FishingServer"), "src/server/FishingServer.server.luau"},
	{game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("FishingClient"), "src/client/FishingClient.client.luau"},
	{game:GetService("ReplicatedStorage").FishingRemotes:FindFirstChild("Catalog"), "src/shared/Catalog.luau"},
}
local clean = function(s) return string.gsub(string.gsub(s, "\r\n", "\n"), "%s+$", "") end
local matched = 0
for _, source in ipairs(sources) do
	local ok = source[1] and clean(source[1].Source) == clean(fs.readFile(source[2]))
	print(source[2], ok and "MATCH" or "MISSING/OUTDATED")
	if ok then matched += 1 end
end
local zones = world:FindFirstChild("Zones")
assert(matched == #sources, "Saved gameplay sources differ from src; redeploy before saving")
assert(zones and #zones:GetChildren() == 3, "Expected three editable fishing zones")
print("Permanent scene instances:", #world:GetDescendants())
print("Zone models:", zones and #zones:GetChildren() or 0)
print("Source matches:", matched, "of", #sources)
for _, zone in ipairs(zones and zones:GetChildren() or {}) do
	assert(zone:IsA("Model") and zone:FindFirstChild("Water"), "Invalid editable zone")
	assert(zone:FindFirstChild("DetailProps"), "Missing permanent environment details")
	print(zone.Name, "ZoneId:", zone.Water:GetAttribute("ZoneId"), "Details:", zone:FindFirstChild("DetailProps") ~= nil)
end
return {matches = matched, zones = zones and #zones:GetChildren() or 0}
