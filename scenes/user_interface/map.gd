extends Control  # or Node2D

# Map size
var map_size = Vector2(58, 45)
var tile_size = Vector2(32, 32)  # Default tile size (will be adjusted dynamically)
var noise = FastNoiseLite.new()

# This will store the map's data (terrain types)
var biome_data = []

# Oasis and outpost tracking
var oasis_data = []  # Stores size and center coordinates of each oasis
var outpost_count = 0
var maximum_outposts = 55
var outpost_symbol = " ⛺ "  # Outpost symbol
var outpost_min_distance = 10  # Minimum distance between outposts (6x6)

# Settings for hot springs and forests
var hot_spring_size_range = Vector2(1, 10)
var hot_spring_probability = 0.05  # Rare, but more common in larger clusters
var forest_growth_chance = 0.1  # Forest growth around hot springs
var steppe_min_size = 5  # Minimum size for steppe oases
var steppe_max_size = 75  # Maximum size for steppe oases
var hill_growth_chance = 0.2  # Hills within large steppes
var forest_growth_in_hills_chance = 0.1  # Forest in hills
var random_walk_steps = 10  # Number of steps for random walk to create organic shapes

# Restricted map size to exclude the border (54x41)
var restricted_map_min = Vector2(3, 3)
var restricted_map_max = Vector2(map_size.x - 4, map_size.y - 4)

# Steppe probabilities for 1st, 2nd, and 3rd tile borders
var steppe_probabilities = {
	1: 0.0,  # No steppes on the 1st tile border
	2: 0.1,  # Rare steppes on the 2nd tile border
	3: 0.5   # More frequent steppes on the 3rd tile border
}

func _ready():
	# Noise configuration
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0

	# Calculate tile size dynamically based on the parent container's size
	var parent_size = get_parent().get_size()
	tile_size = Vector2(parent_size.x / map_size.x, parent_size.y / map_size.y)

	# Set up the GridContainer
	var grid = GridContainer.new()
	grid.columns = int(map_size.x)
	add_child(grid)

	# Generate the map
	generate_base_dunes()
	place_hot_spring_oases()
	place_steppe_oases()

	# Place 20 outposts across the map
	place_outposts()

	# Create the interactive map
	generate_map(grid)

# Step 1: Generate a base map of dunes
func generate_base_dunes() -> void:
	for y in range(map_size.y):
		for x in range(map_size.x):
			var terrain_data
			var distance_to_border = get_tile_border_distance(x, y)

			if distance_to_border == 1:
				# 1st tile border (only dunes)
				terrain_data = {"x": x, "y": y, "symbol": " ✺ ", "biome": "Dunes"}
			elif distance_to_border == 2 and randf() < steppe_probabilities[2]:
				# 2nd tile border (rare steppes)
				terrain_data = {"x": x, "y": y, "symbol": " ◌ ", "biome": "Steppes"}
			elif distance_to_border == 3 and randf() < steppe_probabilities[3]:
				# 3rd tile border (more frequent steppes)
				terrain_data = {"x": x, "y": y, "symbol": " ◌ ", "biome": "Steppes"}
			else:
				# Default to dunes for areas not covered by other rules
				terrain_data = {"x": x, "y": y, "symbol": " ✺ ", "biome": "Dunes"}

			biome_data.append(terrain_data)

# Step 2: Place small hot spring oases
func place_hot_spring_oases() -> void:
	var hot_spring_count = 0

	# Loop through the map and randomly place hot springs within the restricted map area
	for i in range(biome_data.size()):
		var tile_data = biome_data[i]
		var x = tile_data["x"]
		var y = tile_data["y"]
		if randf() < hot_spring_probability and is_within_restricted_area(x, y):
			var size = randi_range(hot_spring_size_range.x, hot_spring_size_range.y)
			create_organic_oasis(x, y, size, "Hot Spring", "  ๑ ")
			hot_spring_count += 1

# Step 3: Place larger steppe oases
func place_steppe_oases() -> void:
	var steppe_count = 0

	# Randomly place larger steppe areas with organic shapes within the restricted map area
	for i in range(biome_data.size()):
		var tile_data = biome_data[i]
		var x = tile_data["x"]
		var y = tile_data["y"]
		if randf() < 0.05 and is_within_restricted_area(x, y):  # Increase steppe probability for oases
			var steppe_size = randi_range(steppe_min_size, steppe_max_size)
			create_organic_oasis(x, y, steppe_size, "Steppes", "  ◌ ")

			# Check if the steppe area is large enough for hills and forests
			if steppe_size >= 10:
				place_hills_and_forest_in_steppe(x, y, steppe_size)
			steppe_count += 1

# Step 4: Create an organic-shaped oasis using a random walk
func create_organic_oasis(x: int, y: int, size: int, biome: String, symbol: String) -> void:
	var center_x = x
	var center_y = y
	var tiles_in_oasis = []

	for i in range(size):
		# Perform a random walk to create an organic shape
		var dx = randi_range(-1, 1)
		var dy = randi_range(-1, 1)
		center_x = clamp(center_x + dx, restricted_map_min.x, restricted_map_max.x)
		center_y = clamp(center_y + dy, restricted_map_min.y, restricted_map_max.y)

		var tile_data = biome_data[center_y * map_size.x + center_x]
		tile_data.symbol = symbol
		tile_data.biome = biome

		tiles_in_oasis.append(tile_data)

		# For hot springs, grow forests around them
		if biome == "Hot Spring" and size >= 5 and randf() < forest_growth_chance:
			grow_forest_around_oasis(center_x, center_y)

	# Store the size and location of the oasis
	oasis_data.append({"center": Vector2(x, y), "size": size, "tiles": tiles_in_oasis})

# Step 5: Place hills and forest in large steppes
func place_hills_and_forest_in_steppe(x: int, y: int, size: int) -> void:
	for i in range(size / 2):
		# Random walk to create hills inside steppes
		var dx = randi_range(-1, 1)
		var dy = randi_range(-1, 1)
		var hill_x = clamp(x + dx, restricted_map_min.x, restricted_map_max.x)
		var hill_y = clamp(y + dy, restricted_map_min.y, restricted_map_max.y)

		var tile_data = biome_data[hill_y * map_size.x + hill_x]
		tile_data.symbol = " ︵ "
		tile_data.biome = "Hills"

		# Grow forests in large hills
		if size >= 10 and randf() < forest_growth_in_hills_chance:
			grow_forest_around_oasis(hill_x, hill_y)

# Grow forest around hot springs or hills
func grow_forest_around_oasis(x: int, y: int) -> void:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var nx = clamp(x + dx, restricted_map_min.x, restricted_map_max.x)
			var ny = clamp(y + dy, restricted_map_min.y, restricted_map_max.y)
			var tile_data = biome_data[ny * map_size.x + nx]
			
			if tile_data.biome not in ["Hot Spring", "Forest"]:
				tile_data.symbol = "  ⸙ "
				tile_data.biome = "Forest"

# Step 6: Place outposts exclusively near hot springs, unless an outpost already exists within 6x6 tiles
func place_outposts() -> void:
	# Iterate over oasis_data and only consider hot springs for outpost placement
	for oasis in oasis_data:
		# Check the biome type of the first tile in the oasis
		var first_tile = oasis["tiles"][0]  # Assuming tiles exist in the oasis dictionary
		if first_tile.biome == "Hot Spring":
			place_outpost_near_oasis(oasis)

# Place an outpost near a hot spring but only if no outpost exists within a 6x6 tile range
func place_outpost_near_oasis(oasis: Dictionary) -> void:
	# Find a tile near the oasis center but at least 6 tiles away from other outposts
	var best_tile = null
	var max_distance = -INF

	# Check tiles around the oasis (within its organic shape)
	for tile in oasis["tiles"]:
		if can_place_outpost(tile["x"], tile["y"]):
			var distance = get_min_distance_to_other_outposts(Vector2(tile["x"], tile["y"]))
			if distance > max_distance:
				max_distance = distance
				best_tile = tile

	# Place the outpost on the selected tile if one was found
	if best_tile != null:
		best_tile.symbol = outpost_symbol
		best_tile.biome = "Outpost"
		outpost_count += 1

# Check if an outpost can be placed at the given coordinates, ensuring it is outside the 6x6 range of any other outpost
func can_place_outpost(x: int, y: int) -> bool:
	# Ensure the tile is within the restricted map and not overlapping with other outposts
	if not is_within_restricted_area(x, y):
		return false

	# Check the 6x6 area around the target tile for existing outposts
	for dx in range(-outpost_min_distance / 2, outpost_min_distance / 2 + 1):
		for dy in range(-outpost_min_distance / 2, outpost_min_distance / 2 + 1):
			var nx = clamp(x + dx, 0, map_size.x - 1)
			var ny = clamp(y + dy, 0, map_size.y - 1)
			var tile_data = biome_data[ny * map_size.x + nx]
			if tile_data.biome == "Outpost":
				return false
	return true

# Get the minimum distance from a given position to any other outpost
func get_min_distance_to_other_outposts(position: Vector2) -> float:
	var min_distance = INF
	for tile in biome_data:
		if tile.biome == "Outpost":
			var distance = position.distance_to(Vector2(tile["x"], tile["y"]))
			min_distance = min(min_distance, distance)
	return min_distance

# Compare oasis sizes for sorting
func _compare_oasis_size(a, b) -> int:
	return b["size"] - a["size"]

# Place an outpost in the most remote location
func add_outpost_in_remote_location() -> void:
	var best_tile = null
	var max_distance = -INF

	# Look for the tile that is furthest from all existing outposts
	for tile in biome_data:
		if tile.biome != "Outpost" and can_place_outpost(tile["x"], tile["y"]):
			var distance = get_min_distance_to_other_outposts(Vector2(tile["x"], tile["y"]))
			if distance > max_distance:
				max_distance = distance
				best_tile = tile

	# Place the outpost on the best tile found
	if best_tile != null:
		best_tile.symbol = outpost_symbol
		best_tile.biome = "Outpost"
		outpost_count += 1


# Find the tile furthest from any existing outpost
func get_furthest_tile_from_outposts() -> Dictionary:
	var furthest_tile = null
	var max_distance = 0

	for tile in biome_data:
		var tile_position = Vector2(tile["x"], tile["y"])
		var distance = get_min_distance_to_outposts(tile_position)

		if distance > max_distance and tile.biome != "Outpost":
			max_distance = distance
			furthest_tile = tile

	return furthest_tile

# Calculate the minimum distance from a tile to any existing outpost
func get_min_distance_to_outposts(tile_position: Vector2) -> float:
	var min_distance = INF
	for existing_tile in biome_data:
		if existing_tile.biome == "Outpost":
			var outpost_position = Vector2(existing_tile["x"], existing_tile["y"])
			var distance = tile_position.distance_to(outpost_position)
			min_distance = min(min_distance, distance)
	return min_distance

# Step 7: Calculate the distance to the nearest border of the map (for terrain generation)
func get_tile_border_distance(x: int, y: int) -> int:
	var dist_x = min(x, map_size.x - 1 - x)
	var dist_y = min(y, map_size.y - 1 - y)
	return min(dist_x, dist_y) + 1  # +1 to make it 1-indexed

# Function to check if coordinates are within the restricted area (3-tile border excluded)
func is_within_restricted_area(x: int, y: int) -> bool:
	return x >= restricted_map_min.x and x <= restricted_map_max.x and y >= restricted_map_min.y and y <= restricted_map_max.y


# Generate the interactive map based on biome data
func generate_map(grid: GridContainer) -> void:
	for y in range(map_size.y):
		for x in range(map_size.x):
			var index = y * map_size.x + x
			var tile_data = biome_data[index]
			
			# Create a tile as a Button
			var tile = Button.new()
			tile.custom_minimum_size = tile_size
			
			# Make the button flat and non-focusable
			tile.flat = true  # No decoration for the button
			tile.focus_mode = Control.FOCUS_NONE  # Disable focus
			
			# Create a CenterContainer for centering the Label inside the Button
			var center_container = CenterContainer.new()

			# Create a Label for the ASCII symbol
			var label = Label.new()
			label.text = tile_data.symbol  # Set the ASCII symbol for the terrain

			# Add the Label to the CenterContainer
			center_container.add_child(label)
			tile.add_child(center_container)  # Add the CenterContainer to the Button

			# Connect the button's press event
			tile.connect("pressed", Callable(self, "_on_tile_pressed").bind(x, y))
			
			# Add the tile to the grid
			grid.add_child(tile)

# Handle tile interactions
func _on_tile_pressed(x: int, y: int) -> void:
	var tile_data = biome_data[y * map_size.x + x]
	print("Tile pressed at: ", x, ", ", y)
	print("Biome: ", tile_data.biome)
	print("Symbol: ", tile_data.symbol)
