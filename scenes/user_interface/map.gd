#map.gd script
extends Control  # or Node2D

# Symbols for various map elements
const SYMBOL_DUNE = "𓂃"
const SYMBOL_STEPPE = " "
const SYMBOL_HOT_SPRING = "◌"
const SYMBOL_HILL = "︿"
const SYMBOL_FOREST = "𓍊𓋼"
const SYMBOL_OUTPOST = "✪"
const SYMBOL_COLONY = "⛨"  # Colony symbol

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

var fog_data = []  # Store fog status for each tile (true if covered, false if revealed)
var tooltip: Label

var outpost_positions = []  # To store the positions of all outposts

func _ready():
	# Initialize everything else
	path_line = Line2D.new()
	path_line.width = 2
	path_line.default_color = Color(1.0, 1.0, 1.0)  # white color
	path_line.z_index = 0  # Ensure the path line is below fog

	# Add the Line2D node to the scene
	add_child(path_line)

	# Create and configure the tooltip label
	tooltip = Label.new()
	tooltip.visible = false  # Hide the tooltip initially
	tooltip.add_theme_color_override("font_color", Color(1, 1, 1))  # White text
	tooltip.add_theme_color_override("bg_color", Color(0, 0, 0, 0.8))  # Dark background
	tooltip.custom_minimum_size = Vector2(100, 20)
	tooltip.z_index = 10  # Set a high z_index to ensure it's rendered on top of everything else
	add_child(tooltip)

	# Load the theme and noise
	tile_theme = load("res://theme.tres")
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_gain = 0.5
	noise.fractal_lacunarity = 2.0

	# Initialize fog after generating the map data and placing objects
	generate_map_data()
	place_oases()
	place_outposts()
	place_colony()  # Ensure colony is placed after the outposts
	generate_map()

	setup_astar_grid()

	# Initialize fog of war
	initialize_fog()
	generate_fog_overlay()  # Create visual fog

	# Set up player
	player = preload("res://player.tscn").instantiate()
	add_child(player)
	var center_x = int(map_size.x / 2)
	var center_y = int(map_size.y / 2)
	player.position = Vector2(center_x * tile_size.x + 12, center_y * tile_size.y + 12)
	
	# Reveal fog around the player's initial position
	update_fog_around_player(player.position)
		# Generate paths between outposts
	generate_outpost_paths()
	
	
func generate_outpost_paths():
	# Collect all outpost positions
	for y in range(map_size.y):
		for x in range(map_size.x):
			var index = y * map_size.x + x
			var tile_data = biome_data[index]
			if tile_data.symbol == SYMBOL_OUTPOST:
				outpost_positions.append(Vector2(x, y))  # Store outpost positions

	# For each outpost, generate 1 to 3 random connections to other outposts
	var connected_outposts = {}  # Dictionary to avoid duplicate paths
	for outpost in outpost_positions:
		var num_connections = randi_range(0, 1)  # Choose 1 to 3 random connections
		var available_outposts = outpost_positions.duplicate()  # Copy of outposts
		available_outposts.erase(outpost)  # Remove the current outpost from the available list

		for i in range(num_connections):
			if available_outposts.size() > 0:
				var target_outpost = available_outposts[randi_range(0, available_outposts.size() - 1)]
				available_outposts.erase(target_outpost)  # Avoid connecting to the same outpost again

				# Create a unique key for the path (using string representation of positions)
				var outpost_key = str(outpost.x) + "_" + str(outpost.y)
				var target_key = str(target_outpost.x) + "_" + str(target_outpost.y)
				var path_key = outpost_key + "-" + target_key
				var reverse_key = target_key + "-" + outpost_key

				if not connected_outposts.has(path_key) and not connected_outposts.has(reverse_key):
					connected_outposts[path_key] = true  # Mark the path as created

					# Find the path using AStar2D between the two outposts
					var start_id = get_tile_id(outpost.x, outpost.y)
					var target_id = get_tile_id(target_outpost.x, target_outpost.y)

					if astar.has_point(start_id) and astar.has_point(target_id):
						var astar_path = astar.get_point_path(start_id, target_id)  # Get the path using AStar

						if astar_path.size() > 1:
							# Create and add a new Line2D node for the path
							var outpost_path = Line2D.new()
							outpost_path.width = 10
							outpost_path.default_color = Color(0.125, 0.125, 0.125, 1)  # Gray color for outpost paths
							outpost_path.z_index = -1  # Ensure the path is below other UI elements

							# Add points to the Line2D path for each tile in the AStar path
							for point in astar_path:
								outpost_path.add_point(point * tile_size + tile_size / 2)  # Adjust for tile size

							# Add the Line2D path to the scene
							add_child(outpost_path)

	
	
	
# Generate map function
func generate_map() -> void:
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

			# Connect the mouse_entered and mouse_exited signals for the tooltip
			tile.connect("mouse_entered", Callable(self, "_on_tile_mouse_entered").bind(x, y, tile))
			tile.connect("mouse_exited", Callable(self, "_on_tile_mouse_exited"))

			# Connect the tile's press event to move the player
			tile.connect("pressed", Callable(self, "_on_tile_pressed").bind(x, y))

			# Add the tile to the scene tree (no GridContainer, manual layout)
			add_child(tile)
# Initialize fog data
func initialize_fog() -> void:
	fog_data.resize(map_size.x * map_size.y)
	for i in range(fog_data.size()):
		fog_data[i] = true  # Initially, all tiles are covered by fog

# Update fog around the player's position (2 tiles in 4 directions and 1 in diagonals)
func update_fog_around_player(player_pos: Vector2) -> void:
	var px = int(player_pos.x / tile_size.x)
	var py = int(player_pos.y / tile_size.y)

	# Clear a 5x5 area around the player (2 tiles in all directions, 1 tile in diagonals)
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			# Only clear tiles within this range
			if abs(dx) <= 1 or abs(dy) <= 1:
				var nx = px + dx
				var ny = py + dy
				if is_valid_tile(nx, ny):
					fog_data[ny * map_size.x + nx] = false  # Mark the tile as revealed
					var fog_node_name = "TileFog_" + str(nx) + "_" + str(ny)

					# Optionally, remove the fog visually by hiding the corresponding fog tile
					var fog_node = get_node_or_null(fog_node_name)
					if fog_node:
						fog_node.hide()


# Generate fog overlay for each tile
func generate_fog_overlay() -> void:
	for y in range(map_size.y):
		for x in range(map_size.x):
			var fog_rect = ColorRect.new()
			fog_rect.color = Color(0.18, 0.18, 0.18, 1)  # Fully opaque black for fog
			fog_rect.custom_minimum_size = tile_size  # Set the size of the fog tile to match the map tiles
			fog_rect.position = Vector2(x * tile_size.x, y * tile_size.y)  # Set the position based on the tile grid
			fog_rect.name = "TileFog_" + str(x) + "_" + str(y)  # Unique name for each fog tile
			fog_rect.z_index = 1  # Ensure fog is above the path line
			fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow clicking through the fog
			add_child(fog_rect)

			
			
# Setup the AStar2D grid for pathfinding, avoiding hills
func setup_astar_grid():
	astar.clear()  # Clear any previous points
	for y in range(map_size.y):
		for x in range(map_size.x):
			var id = get_tile_id(x, y)
			var pos = Vector2(x, y)
			var tile_index = y * map_size.x + x
			var tile_data = biome_data[tile_index]

			# If the tile is a hill, don't add it to the pathfinding grid
			if tile_data.symbol != SYMBOL_HILL:
				astar.add_point(id, pos)

	# Connect neighboring tiles in 4 directions (up, down, left, right)
	for y in range(map_size.y):
		for x in range(map_size.x):
			var id = get_tile_id(x, y)
			var tile_index = y * map_size.x + x
			var tile_data = biome_data[tile_index]

			# Skip hills when connecting points
			if tile_data.symbol != SYMBOL_HILL:
				for offset in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
					var neighbor_pos = Vector2(x, y) + offset
					if is_valid_tile(neighbor_pos.x, neighbor_pos.y):
						var neighbor_id = get_tile_id(neighbor_pos.x, neighbor_pos.y)
						var neighbor_tile_index = int(neighbor_pos.y) * map_size.x + int(neighbor_pos.x)
						var neighbor_tile_data = biome_data[neighbor_tile_index]

						# Skip connecting hills
						if neighbor_tile_data.symbol != SYMBOL_HILL:
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
		var truncated_path = []

		for tile_pos in path:
			var tile_index = int(tile_pos.y) * map_size.x + int(tile_pos.x)
			var tile_data = biome_data[tile_index]

			# Append the tile and its type
			truncated_path.append(tile_pos)
			tile_types.append(tile_data.biome)

		# Clear the previous path (if any) before drawing the new one
		path_line.clear_points()  # Use clear_points() instead of clear()

		# Add points to the Line2D for the truncated path
		path_line.add_point(player.position)  # Start at player position
		for point in truncated_path:
			path_line.add_point(point * tile_size + tile_size / 2)  # Adjust for tile size

		# Move the player along the truncated path
		player.move_along_path(truncated_path, tile_size, tile_types)

		var tile_data = biome_data[y * map_size.x + x]
		print("Tile pressed at: ", x, ", ", y)
		print("Biome: ", tile_data.biome)
		print("Symbol: ", tile_data.symbol)

# Utility function to clear the path line
func clear_path_line():
	path_line.clear_points()

# Add a _process function to track the player's movement and clear the line when the destination is reached
func _process(delta):
	# Ensure we can access the player's script
	if player and player.is_moving:
		var direction = (player.target_position - player.position).normalized()  # Direction towards the next tile
		var distance_to_move = player.dynamic_speed * delta

		# Check if the player is close enough to the target tile
		if player.position.distance_to(player.target_position) <= distance_to_move:
			# Snap to the target position
			player.position = player.target_position
			player.current_path_index += 1
			player.is_moving = false


			# If there are more tiles in the path, move to the next one
			if player.current_path_index < player.current_path.size():
				player.move_to_next_tile()

			# Update fog based on the player's new position
			update_fog_around_player(player.position)



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
		ensure_non_hill_adjacent(best_tile["x"], best_tile["y"])  # Ensure adjacent non-hill tile
		outpost_count += 1


# Place the colony at the center of the map and ensure at least one adjacent tile is not a hill
func place_colony() -> void:
	var center_x = int(map_size.x / 2)
	var center_y = int(map_size.y / 2)
	var tile_data = biome_data[center_y * map_size.x + center_x]
	tile_data.symbol = SYMBOL_COLONY
	tile_data.biome = "Colony"

	# Ensure at least one adjacent tile is not a hill
	ensure_non_hill_adjacent(center_x, center_y)

# Ensure one of the adjacent tiles is not a hill
func ensure_non_hill_adjacent(x: int, y: int) -> void:
	var offsets = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
	for offset in offsets:
		var nx = x + offset.x
		var ny = y + offset.y
		if is_valid_tile(nx, ny):
			var neighbor_tile_data = biome_data[ny * map_size.x + nx]
			if neighbor_tile_data.symbol == SYMBOL_HILL:
				# Replace the hill with a steppes or dunes tile
				neighbor_tile_data.symbol = SYMBOL_STEPPE
				neighbor_tile_data.biome = "Steppes"
				return  # Exit after modifying one tile

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
	
	# Remove the first point from the Line2D path (to erase the path behind the player)
func remove_point_from_path():
	if path_line.get_point_count() > 0:
		path_line.remove_point(0)  # This removes the first point from the path

# Show tooltip on mouse enter if the tile is not covered by fog
func _on_tile_mouse_entered(x: int, y: int, tile: Button):
	var index = y * map_size.x + x
	if not fog_data[index]:  # Check if the tile is not covered by fog
		var tile_data = biome_data[index]
		tooltip.text = "... " + tile_data.biome  # Show the biome type

		# Position the tooltip relative to the tile's position
		tooltip.position = tile.position + Vector2(0, tile_size.y + 5)  # Place it below the tile

		tooltip.visible = true
	else:
		tooltip.visible = false  # Hide if the tile is still covered by fog

# Hide tooltip on mouse exit
func _on_tile_mouse_exited():
	tooltip.visible = false
