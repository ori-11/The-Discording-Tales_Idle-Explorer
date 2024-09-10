extends Control  # or Node2D

# Symbols for various map elements
const SYMBOL_DUNE = "𓂃"
const SYMBOL_STEPPE = " "
const SYMBOL_HOT_SPRING = "◌"
const SYMBOL_HILL = "︿"
const SYMBOL_FOREST = "𓍊𓋼"
const SYMBOL_OUTPOST = "✪"

# Map size and tile settings
var map_size = Vector2(40, 40)
var tile_size = Vector2(22, 22)  # Set the size for each tile
var noise = FastNoiseLite.new()

# Pathfinding using AStar2D
var astar = AStar2D.new()
# Path line
var path_line: Line2D


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
var player

func _ready():
		# Create the Line2D node for the path
	path_line = Line2D.new()
	path_line.width = 2
	path_line.default_color = Color(1.0, 1.0, 1.0)  # white color
	

	path_line.set_material(material)

	# Add the Line2D node to the scene
	add_child(path_line)
	# Load the theme from the specified path
	tile_theme = load("res://theme.tres")

	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0

	# Remove GridContainer and manually layout tiles
	generate_map_data()
	place_oases()
	place_outposts()
	generate_map()

	# Set up AStar for pathfinding
	setup_astar_grid()

	# Instance the player and place it on the center tile (Colony)
	player = preload("res://player.tscn").instantiate()
	add_child(player)
	var center_x = int(map_size.x / 2)
	var center_y = int(map_size.y / 2)
	player.position = Vector2(center_x * tile_size.x, center_y * tile_size.y)

# Function to generate the interactive map manually
func generate_map() -> void:
	var center_x = int(map_size.x / 2)
	var center_y = int(map_size.y / 2)

	for y in range(map_size.y):
		for x in range(map_size.x):
			var index = y * map_size.x + x
			var tile_data = biome_data[index]

			# Create a button to represent each tile
			var tile = Button.new()
			tile.custom_minimum_size = tile_size
			tile.text = tile_data.symbol
			tile.flat = false
			tile.theme = tile_theme
			tile.focus_mode = Control.FOCUS_NONE

			# Set the position manually (convert grid coordinates to world coordinates)
			tile.position = Vector2(x * tile_size.x, y * tile_size.y)

			# Set the Colony tile in the center
			if x == center_x and y == center_y:
				tile.text = "⛨"  # Colony symbol

			# Connect the tile's press event to move the player
			tile.connect("pressed", Callable(self, "_on_tile_pressed").bind(x, y))

			# Add the tile to the scene tree (no GridContainer, manual layout)
			add_child(tile)

# Setup the AStar2D grid for pathfinding
func setup_astar_grid():
	for y in range(map_size.y):
		for x in range(map_size.x):
			var id = get_tile_id(x, y)
			var pos = Vector2(x, y)
			astar.add_point(id, pos)
	
	# Connect neighboring tiles in 4 directions (up, down, left, right)
	for y in range(map_size.y):
		for x in range(map_size.x):
			var id = get_tile_id(x, y)
			for offset in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				var neighbor_pos = Vector2(x, y) + offset
				if is_valid_tile(neighbor_pos.x, neighbor_pos.y):
					var neighbor_id = get_tile_id(neighbor_pos.x, neighbor_pos.y)
					astar.connect_points(id, neighbor_id)

# Utility function to get a unique ID for each tile
func get_tile_id(x: int, y: int) -> int:
	return y * map_size.x + x

# Utility function to check if a tile is valid for movement
func is_valid_tile(x: int, y: int) -> bool:
	# Example: Check if the tile is within bounds and not an obstacle
	return x >= 0 and x < map_size.x and y >= 0 and y < map_size.y

# Function to handle tile clicks and move the player along the path
func _on_tile_pressed(x: int, y: int) -> void:
	var start_tile_id = get_tile_id(int(player.position.x / tile_size.x), int(player.position.y / tile_size.y))
	var target_tile_id = get_tile_id(x, y)
	
	if astar.has_point(start_tile_id) and astar.has_point(target_tile_id):
		var path = astar.get_point_path(start_tile_id, target_tile_id)

		# Create an array of tile types along the path
		var tile_types = []
		for tile_pos in path:
			var tile_index = int(tile_pos.y) * map_size.x + int(tile_pos.x)
			tile_types.append(biome_data[tile_index]["biome"])  # Append the biome (tile type) of each tile
		
		# Clear the previous path (if any) before drawing the new one
		path_line.clear_points()

		# Add points to the Line2D for the path
		for point in path:
			path_line.add_point(point * tile_size + tile_size / 2)  # Adjust for tile size
		
		# Move the player along the path
		player.move_along_path(path, tile_size, tile_types)

		var tile_data = biome_data[y * map_size.x + x]
		print("Tile pressed at: ", x, ", ", y)
		print("Biome: ", tile_data.biome)
		print("Symbol: ", tile_data.symbol)

# Utility function to clear the path line
func clear_path_line():
	path_line.clear_points()

# Add a _process function to track the player's movement and clear the line when the destination is reached
func _process(delta):
	if not player.is_moving:
		# When the player has reached the destination, clear the path line
		clear_path_line()
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
	
# Utility: Get tile distance from map borders
func get_tile_border_distance(x: int, y: int) -> int:
	return min(min(x, map_size.x - 1 - x), min(y, map_size.y - 1 - y)) + 1

# Utility: Check if a tile is within restricted area (excluding borders)
func is_within_restricted_area(x: int, y: int) -> bool:
	return x >= restricted_map_min.x and x <= restricted_map_max.x and y >= restricted_map_min.y and y <= restricted_map_max.y
