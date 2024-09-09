extends Control  # or Node2D

# Symbols for various map elements
const SYMBOL_DUNE = "𓂃"
const SYMBOL_STEPPE = "𓇢"
const SYMBOL_HOT_SPRING = "◌"
const SYMBOL_HILL = "︿"
const SYMBOL_FOREST = "𓍊𓋼"
const SYMBOL_OUTPOST = "✪"

# Map size and tile settings
var map_size = Vector2(45, 23)
var tile_size = Vector2(12, 12)  # Set the size for each tile
var noise = FastNoiseLite.new()

# Map data
var biome_data = []
var oasis_data = []  # Stores size and center coordinates of each oasis
var outpost_count = 0
var maximum_outposts = 55
var outpost_min_distance = 10

# Settings for hot springs, forests, and other biome generation
var hot_spring_size_range = Vector2(1, 10)
var hot_spring_probability = 0.05
var forest_growth_chance = 0.001
var steppe_min_size = 5
var steppe_max_size = 50
var steppe_probabilities = {1: 0.0, 2: 0.1, 3: 0.5}

# Restricted map size to exclude the border (54x41)
var restricted_map_min = Vector2(3, 3)
var restricted_map_max = Vector2(map_size.x - 4, map_size.y - 4)

# Theme resource variable
var tile_theme: Theme

func _ready():
	# Load the theme from the specified path
	tile_theme = load("res://theme.tres")

	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0

	var grid = GridContainer.new()
	grid.columns = int(map_size.x)  # Set the number of columns

	# Enable theme overrides for hseparation and vseparation and set them to 0
	grid.add_theme_constant_override("h_separation", -3)
	grid.add_theme_constant_override("v_separation", -3)

	add_child(grid)

	generate_map_data()
	place_oases()
	place_outposts()
	generate_map(grid)

# Function to generate the base terrain (dunes/steppes)
func generate_map_data() -> void:
	for y in range(map_size.y):
		for x in range(map_size.x):
			var distance_to_border = get_tile_border_distance(x, y)
			var terrain_data = {
				"x": x,
				"y": y,
				"symbol": SYMBOL_DUNE,
				"biome": "Dunes"
			}
			
			if distance_to_border == 2 and randf() < steppe_probabilities[2]:
				terrain_data.symbol = SYMBOL_STEPPE
				terrain_data.biome = "Steppes"
			elif distance_to_border == 3 and randf() < steppe_probabilities[3]:
				terrain_data.symbol = SYMBOL_STEPPE
				terrain_data.biome = "Steppes"

			biome_data.append(terrain_data)

# Place hot spring and steppe oases
func place_oases() -> void:
	for i in range(biome_data.size()):
		var tile_data = biome_data[i]
		var x = tile_data["x"]
		var y = tile_data["y"]

		if randf() < hot_spring_probability and is_within_restricted_area(x, y):
			create_organic_oasis(x, y, randi_range(hot_spring_size_range.x, hot_spring_size_range.y), "Hot Spring", SYMBOL_HOT_SPRING)
		elif randf() < 0.05 and is_within_restricted_area(x, y):
			var steppe_size = randi_range(steppe_min_size, steppe_max_size)
			create_organic_oasis(x, y, steppe_size, "Steppes", SYMBOL_STEPPE)
			if steppe_size >= 25:
				place_hills_and_forest(x, y, steppe_size)

# Create an organic oasis using random walk
func create_organic_oasis(x: int, y: int, size: int, biome: String, symbol: String) -> void:
	var center_x = x
	var center_y = y
	var tiles_in_oasis = []

	for i in range(size):
		center_x = clamp(center_x + randi_range(-1, 1), restricted_map_min.x, restricted_map_max.x)
		center_y = clamp(center_y + randi_range(-1, 1), restricted_map_min.y, restricted_map_max.y)
		
		var tile_data = biome_data[center_y * map_size.x + center_x]
		tile_data.symbol = symbol
		tile_data.biome = biome
		tiles_in_oasis.append(tile_data)

		if biome == "Hot Spring" and size >= 3 and randf() < forest_growth_chance:
			grow_forest_around_oasis(center_x, center_y)

	oasis_data.append({"center": Vector2(x, y), "size": size, "tiles": tiles_in_oasis})

# Place hills and forests in large steppes
func place_hills_and_forest(x: int, y: int, size: int) -> void:
	for i in range(size / 2):
		var hill_x = clamp(x + randi_range(-1, 1), restricted_map_min.x, restricted_map_max.x)
		var hill_y = clamp(y + randi_range(-1, 1), restricted_map_min.y, restricted_map_max.y)

		var tile_data = biome_data[hill_y * map_size.x + hill_x]
		tile_data.symbol = SYMBOL_HILL
		tile_data.biome = "Hills"
		if size >= 10 and randf() < 0.1:
			grow_forest_around_oasis(hill_x, hill_y)

# Grow forest around an oasis or hills
func grow_forest_around_oasis(x: int, y: int) -> void:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var nx = clamp(x + dx, restricted_map_min.x, restricted_map_max.x)
			var ny = clamp(y + dy, restricted_map_min.y, restricted_map_max.y)
			var tile_data = biome_data[ny * map_size.x + nx]
			if tile_data.biome not in ["Hot Spring", "Forest"]:
				tile_data.symbol = SYMBOL_FOREST
				tile_data.biome = "Forest"

# Place outposts
func place_outposts() -> void:
	for oasis in oasis_data:
		if oasis["tiles"][0].biome == "Hot Spring":
			place_outpost_near_oasis(oasis)

# Place outpost near a hot spring
func place_outpost_near_oasis(oasis: Dictionary) -> void:
	var best_tile = null
	var max_distance = -INF
	for tile in oasis["tiles"]:
		if can_place_outpost(tile["x"], tile["y"]):
			var distance = get_min_distance_to_other_outposts(Vector2(tile["x"], tile["y"]))
			if distance > max_distance:
				max_distance = distance
				best_tile = tile

	if best_tile != null:
		best_tile.symbol = SYMBOL_OUTPOST
		best_tile.biome = "Outpost"
		outpost_count += 1

# Check if an outpost can be placed at coordinates
func can_place_outpost(x: int, y: int) -> bool:
	if not is_within_restricted_area(x, y):
		return false
	for dx in range(-outpost_min_distance / 2, outpost_min_distance / 2 + 1):
		for dy in range(-outpost_min_distance / 2, outpost_min_distance / 2 + 1):
			var nx = clamp(x + dx, 0, map_size.x - 1)
			var ny = clamp(y + dy, 0, map_size.y - 1)
			if biome_data[ny * map_size.x + nx].biome == "Outpost":
				return false
	return true

# Get minimum distance to other outposts
func get_min_distance_to_other_outposts(position: Vector2) -> float:
	var min_distance = INF
	for tile in biome_data:
		if tile.biome == "Outpost":
			min_distance = min(min_distance, position.distance_to(Vector2(tile["x"], tile["y"])))
	return min_distance

# Generate the interactive map (Updated)
func generate_map(grid: GridContainer) -> void:
	for y in range(map_size.y):
		for x in range(map_size.x):
			var index = y * map_size.x + x
			var tile_data = biome_data[index]

			# Create a button to represent a tile
			var tile = Button.new()
			tile.custom_minimum_size = tile_size  # Set uniform button size
			tile.text = tile_data.symbol  # Set the symbol as the button's text
			tile.flat = false  # Remove any border or decoration
			tile.theme = tile_theme  # Apply the loaded theme to the tile
			tile.focus_mode = Control.FOCUS_NONE  # Disable focus
			tile.connect("pressed", Callable(self, "_on_tile_pressed").bind(x, y))
			
			# Add the tile to the grid
			grid.add_child(tile)

# Handle tile interactions
func _on_tile_pressed(x: int, y: int) -> void:
	var tile_data = biome_data[y * map_size.x + x]
	print("Tile pressed at: ", x, ", ", y)
	print("Biome: ", tile_data.biome)
	print("Symbol: ", tile_data.symbol)

# Utility: Get tile distance from map borders
func get_tile_border_distance(x: int, y: int) -> int:
	return min(min(x, map_size.x - 1 - x), min(y, map_size.y - 1 - y)) + 1

# Utility: Check if a tile is within restricted area (excluding borders)
func is_within_restricted_area(x: int, y: int) -> bool:
	return x >= restricted_map_min.x and x <= restricted_map_max.x and y >= restricted_map_min.y and y <= restricted_map_max.y
