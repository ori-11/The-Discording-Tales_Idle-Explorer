extends Control  # or Node2D

# Map size
var map_size = Vector2(58, 45)
var tile_size = Vector2(32, 32)  # Default tile size (will be adjusted dynamically)
var noise = FastNoiseLite.new()

# This will store the map's data (terrain types)
var biome_data = []

# Settings for hot springs and forests
var hot_spring_size_range = Vector2(1, 10)
var hot_spring_probability = 0.01  # Rare, but more common in larger clusters
var forest_growth_chance = 0.1  # Forest growth around hot springs
var steppe_min_size = 5  # Minimum size for steppe oases
var steppe_max_size = 75  # Maximum size for steppe oases
var hill_growth_chance = 0.2  # Hills within large steppes
var forest_growth_in_hills_chance = 0.1  # Forest in hills
var random_walk_steps = 10  # Number of steps for random walk to create organic shapes

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

	# Create the interactive map
	generate_map(grid)

# Step 1: Generate a base map of dunes
func generate_base_dunes() -> void:
	for y in range(map_size.y):
		for x in range(map_size.x):
			var terrain_data = {"x": x, "y": y, "symbol": " ✺ ", "biome": "Dunes"}  # Default to dunes 
			biome_data.append(terrain_data)

# Step 2: Place small hot spring oases
func place_hot_spring_oases() -> void:
	var hot_spring_count = 0

	# Loop through the map and randomly place hot springs
	for i in range(biome_data.size()):
		if randf() < hot_spring_probability:
			var tile_data = biome_data[i]
			var size = randi_range(hot_spring_size_range.x, hot_spring_size_range.y)
			create_organic_oasis(tile_data["x"], tile_data["y"], size, "Hot Spring", "  ๑ ")
			hot_spring_count += 1

# Step 3: Place larger steppe oases
func place_steppe_oases() -> void:
	var steppe_count = 0

	# Randomly place larger steppe areas with organic shapes
	for i in range(biome_data.size()):
		if randf() < 0.02:  # A lower probability for steppe oases
			var tile_data = biome_data[i]
			var steppe_size = randi_range(steppe_min_size, steppe_max_size)
			create_organic_oasis(tile_data["x"], tile_data["y"], steppe_size, "Steppes", "  ◌ ")

			# Check if the steppe area is large enough for hills and forests
			if steppe_size >= 10:
				place_hills_and_forest_in_steppe(tile_data["x"], tile_data["y"], steppe_size)
			steppe_count += 1

# Create an organic-shaped oasis using a random walk
func create_organic_oasis(x: int, y: int, size: int, biome: String, symbol: String) -> void:
	var center_x = x
	var center_y = y

	for i in range(size):
		# Perform a random walk to create an organic shape
		var dx = randi_range(-1, 1)
		var dy = randi_range(-1, 1)
		center_x = clamp(center_x + dx, 0, map_size.x - 1)
		center_y = clamp(center_y + dy, 0, map_size.y - 1)

		var tile_data = biome_data[center_y * map_size.x + center_x]
		tile_data.symbol = symbol
		tile_data.biome = biome

		# For hot springs, grow forests around them
		if biome == "Hot Spring" and size >= 5 and randf() < forest_growth_chance:
			grow_forest_around_oasis(center_x, center_y)

# Step 4: Place hills and forest in large steppes
func place_hills_and_forest_in_steppe(x: int, y: int, size: int) -> void:
	for i in range(size / 2):
		# Random walk to create hills inside steppes
		var dx = randi_range(-1, 1)
		var dy = randi_range(-1, 1)
		var hill_x = clamp(x + dx, 0, map_size.x - 1)
		var hill_y = clamp(y + dy, 0, map_size.y - 1)

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
			var nx = clamp(x + dx, 0, map_size.x - 1)
			var ny = clamp(y + dy, 0, map_size.y - 1)
			var tile_data = biome_data[ny * map_size.x + nx]
			
			if tile_data.biome not in ["Hot Spring", "Forest"]:
				tile_data.symbol = "  ⸙ "
				tile_data.biome = "Forest"

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
