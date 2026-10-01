local Catalog = {}

Catalog.Rods = {
	bamboo = {name = "Бамбуковая удочка", price = 0, speed = 1},
	river = {name = "Речная удочка", price = 80, speed = 1.25},
	master = {name = "Удочка мастера", price = 240, speed = 1.6},
}

Catalog.Floats = {
	cork = {name = "Пробковый поплавок", price = 0, window = 2.2, color = Color3.fromRGB(243, 186, 91)},
	feather = {name = "Перьевой поплавок", price = 45, window = 2.8, color = Color3.fromRGB(243, 112, 120)},
	glow = {name = "Светящийся поплавок", price = 120, window = 3.5, color = Color3.fromRGB(117, 243, 209)},
}

Catalog.Baits = {
	bread = {name = "Хлеб", price = 12, amount = 10, boost = 0},
	worm = {name = "Черви", price = 25, amount = 8, boost = 0.15},
	luminous = {name = "Светящаяся приманка", price = 55, amount = 5, boost = 0.4},
}

Catalog.Zones = {
	lagoon = {name = "Лазурная лагуна", color = Color3.fromRGB(47, 180, 213)},
	pond = {name = "Изумрудный пруд", color = Color3.fromRGB(91, 174, 123)},
	mystic = {name = "Лиловый омут", color = Color3.fromRGB(150, 111, 219)},
}

Catalog.Fish = {
	{id = "silver_fry", name = "Серебряный малёк", zone = "lagoon", value = 8, minWeight = 0.2, maxWeight = 0.7, weight = 55, rarity = "Обычная", color = Color3.fromRGB(189, 215, 226)},
	{id = "blue_perch", name = "Голубой окунь", zone = "lagoon", value = 16, minWeight = 0.5, maxWeight = 1.8, weight = 32, rarity = "Необычная", color = Color3.fromRGB(80, 154, 212)},
	{id = "pearl_koi", name = "Жемчужный кои", zone = "lagoon", value = 48, minWeight = 1.2, maxWeight = 3.5, weight = 13, rarity = "Редкая", color = Color3.fromRGB(231, 221, 242)},
	{id = "golden_carp", name = "Золотой карась", zone = "pond", value = 10, minWeight = 0.4, maxWeight = 1.4, weight = 55, rarity = "Обычная", color = Color3.fromRGB(236, 187, 74)},
	{id = "amber_bream", name = "Янтарный лещ", zone = "pond", value = 22, minWeight = 0.9, maxWeight = 2.7, weight = 32, rarity = "Необычная", color = Color3.fromRGB(207, 133, 53)},
	{id = "sunscale", name = "Солнечная рыба", zone = "pond", value = 55, minWeight = 1.5, maxWeight = 4.2, weight = 13, rarity = "Редкая", color = Color3.fromRGB(255, 220, 104)},
	{id = "violet_minnow", name = "Лиловый пескарь", zone = "mystic", value = 14, minWeight = 0.3, maxWeight = 0.9, weight = 55, rarity = "Обычная", color = Color3.fromRGB(166, 131, 213)},
	{id = "moon_perch", name = "Лунный окунь", zone = "mystic", value = 30, minWeight = 0.8, maxWeight = 2.5, weight = 32, rarity = "Необычная", color = Color3.fromRGB(164, 175, 238)},
	{id = "star_koi", name = "Звёздный кои", zone = "mystic", value = 75, minWeight = 1.8, maxWeight = 5, weight = 13, rarity = "Редкая", color = Color3.fromRGB(198, 164, 255)},
}

return Catalog
