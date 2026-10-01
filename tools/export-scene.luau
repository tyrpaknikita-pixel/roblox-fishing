-- Execute in Studio Edit mode through MCP. Return value is JSON; save it as world/.scene-snapshot.json.
assert(not game:GetService("RunService"):IsRunning(), "Export only in Edit mode")
local HttpService = game:GetService("HttpService")
local allowed = {
	Model = {}, Folder = {}, Part = {}, SpawnLocation = {}, Tool = {}, Attachment = {},
	WeldConstraint = {}, SurfaceGui = {}, TextLabel = {}, ProximityPrompt = {}, PointLight = {},
	Atmosphere = {}, BloomEffect = {}, ColorCorrectionEffect = {}, RemoteEvent = {},
	Script = {}, LocalScript = {}, ModuleScript = {}, WedgePart = {},
}
local common = {"Archivable"}
local properties = {
	Model = {"PrimaryPart", "WorldPivot"},
	Part = {"Anchored", "CanCollide", "CanTouch", "CanQuery", "Massless", "Size", "CFrame", "Color", "Material", "Transparency", "Reflectance", "Shape", "TopSurface", "BottomSurface", "CastShadow"},
	SpawnLocation = {"Anchored", "CanCollide", "CanTouch", "CanQuery", "Massless", "Size", "CFrame", "Color", "Material", "Transparency", "Reflectance", "Shape", "TopSurface", "BottomSurface", "Neutral", "Enabled", "Duration", "TeamColor", "AllowTeamChangeOnTouch"},
	Tool = {"Grip", "ToolTip", "CanBeDropped", "RequiresHandle", "Enabled", "ManualActivationOnly"},
	Attachment = {"Position", "CFrame", "Visible", "Axis", "SecondaryAxis"},
	WeldConstraint = {"Part0", "Part1", "Enabled"},
	SurfaceGui = {"Face", "AlwaysOnTop", "Enabled", "LightInfluence", "Brightness", "PixelsPerStud", "SizingMode", "ZIndexBehavior", "ClipsDescendants"},
	TextLabel = {"Size", "Position", "AnchorPoint", "BackgroundTransparency", "BackgroundColor3", "Text", "TextColor3", "TextScaled", "TextSize", "TextTransparency", "FontFace", "TextXAlignment", "TextYAlignment", "Visible", "ZIndex", "RichText", "TextWrapped", "Rotation"},
	ProximityPrompt = {"ActionText", "ObjectText", "HoldDuration", "MaxActivationDistance", "RequiresLineOfSight", "Enabled", "KeyboardKeyCode", "Exclusivity", "Style"},
	PointLight = {"Brightness", "Range", "Color", "Shadows", "Enabled"},
	Atmosphere = {"Density", "Offset", "Color", "Decay", "Glare", "Haze"},
	BloomEffect = {"Intensity", "Size", "Threshold", "Enabled"},
	ColorCorrectionEffect = {"Brightness", "Contrast", "Saturation", "TintColor", "Enabled"},
	Script = {"Source", "Disabled", "RunContext"},
	LocalScript = {"Source", "Disabled"},
	ModuleScript = {"Source"},
}
properties.WedgePart = {"Anchored", "CanCollide", "CanTouch", "CanQuery", "Massless", "Size", "CFrame", "Color", "Material", "Transparency", "Reflectance", "TopSurface", "BottomSurface", "CastShadow"}
local roots = {
	{game:GetService("Workspace"), "FishingWorld"},
	{game:GetService("ReplicatedStorage"), "FishingRemotes"},
	{game:GetService("ServerScriptService"), "FishingServer"},
	{game:GetService("StarterPlayer").StarterPlayerScripts, "FishingClient"},
	{game:GetService("StarterPack"), "FishingRod"},
}
for _, child in ipairs(game:GetService("Lighting"):GetChildren()) do
	if child.Name:match("^Fishing") then table.insert(roots, {game:GetService("Lighting"), child.Name}) end
end
local ids, nextId = {}, 0
local function assign(object)
	nextId += 1
	ids[object] = nextId
	for _, child in ipairs(object:GetChildren()) do assign(child) end
end
for _, root in ipairs(roots) do
	local object = root[1]:FindFirstChild(root[2])
	if object then assign(object) end
end
local function value(v)
	local t = typeof(v)
	if t == "string" or t == "number" or t == "boolean" then return v end
	if t == "Instance" then
		assert(ids[v], "Reference outside exported roots: " .. v:GetFullName())
		return {kind = "Ref", id = ids[v]}
	end
	if t == "Vector3" then return {kind = t, x = v.X, y = v.Y, z = v.Z} end
	if t == "Vector2" then return {kind = t, x = v.X, y = v.Y} end
	if t == "Color3" then return {kind = t, r = v.R, g = v.G, b = v.B} end
	if t == "CFrame" then return {kind = t, components = {v:GetComponents()}} end
	if t == "UDim2" then return {kind = t, xs = v.X.Scale, xo = v.X.Offset, ys = v.Y.Scale, yo = v.Y.Offset} end
	if t == "UDim" then return {kind = t, scale = v.Scale, offset = v.Offset} end
	if t == "EnumItem" then return {kind = t, enum = tostring(v.EnumType):gsub("^Enum%.", ""), name = v.Name} end
	if t == "BrickColor" then return {kind = t, number = v.Number} end
	if t == "Font" then return {kind = t, family = v.Family, weight = v.Weight.Name, style = v.Style.Name} end
	error("Unsupported value type " .. t)
end
local function encode(object)
	assert(allowed[object.ClassName], "Unsupported class: " .. object:GetFullName() .. " (" .. object.ClassName .. ")")
	local node = {id = ids[object], class = object.ClassName, name = object.Name, properties = {}, attributes = {}, children = {}}
	for _, key in ipairs(common) do node.properties[key] = value(object[key]) end
	for _, key in ipairs(properties[object.ClassName] or {}) do
		local ok, result = pcall(function() return object[key] end)
		assert(ok, "Cannot read " .. object:GetFullName() .. "." .. key .. ": " .. tostring(result))
		if result ~= nil then node.properties[key] = value(result) end
	end
	for key, attribute in pairs(object:GetAttributes()) do node.attributes[key] = value(attribute) end
	for _, child in ipairs(object:GetChildren()) do table.insert(node.children, encode(child)) end
	return node
end
local snapshot = {format = 1, roots = {}, lighting = {}}
for _, entry in ipairs(roots) do
	local object = entry[1]:FindFirstChild(entry[2])
	if object then
		local path = entry[1] == game:GetService("StarterPlayer").StarterPlayerScripts and {"StarterPlayer", "StarterPlayerScripts"} or {entry[1].Name}
		table.insert(snapshot.roots, {parentPath = path, tree = encode(object)})
	end
end
for _, key in ipairs({"ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows"}) do
	snapshot.lighting[key] = value(game:GetService("Lighting")[key])
end
return HttpService:JSONEncode(snapshot)
