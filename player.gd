#player.gd script
extends CharacterBody2D

var move_speed = 200  # Base max speed for Steppes
var dynamic_speed = move_speed  # Speed that changes during movement
var base_min_speed = 50  # Base minimum speed for Steppes
var minimum_speed = base_min_speed  # Dynamic minimum speed
var deceleration_rate = 20  # How quickly the player slows down per second
var target_position: Vector2  # Target position to move towards
var is_moving = false  # Whether the player is currently moving
var current_path: Array = []  # List of tiles in the path
var current_path_index = 0  # Index of the current tile in the path
var tile_size: Vector2  # Size of each tile
var tile_type_data: Array = []  # Array to store tile types along the path

var chat_log: VBoxContainer  # Reference to the VBoxContainer (chat log)
var message_sent_tiles = {}  # Dictionary to track tiles where messages have been sent
var map
var log_scene = preload("res://scenes/user_interface/log.tscn")  # Load the log.tscn scene

var sprite  # Reference to the player's Sprite2D
var target_rotation = 0.0  # The target rotation for the sprite

# Speed reduction percentages by tile type
var tile_speed_reduction = {
	"Steppes": 0.0,       # 0% reduction
	"Dunes": 0.15,        # 20% reduction
	"Forest": 0.30,       # 40% reduction
	"Hills": 1.0,         # 60% reduction
	"Hot Spring": 0.60,   # 80% reduction
	"Default": 0.0        # Default reduction for unlisted tile types
}

func _ready():
	# Retrieve the chat log VBoxContainer via the group
	var chat_log_group = get_tree().get_nodes_in_group("chat_log")
	if chat_log_group.size() > 0:
		chat_log = chat_log_group[0] as VBoxContainer  # Assuming there's only one chat log container
	else:
		print("ChatLog VBoxContainer not found in the group")

	# Get the reference to the map
	map = get_parent()

	# Get reference to the Sprite2D child node
	sprite = $Sprite2D  # Make sure the Sprite2D is a direct child of the player

# Function to add a new message to the chat log
func send_to_chatlog(message: String):
	var chat_log = get_tree().get_nodes_in_group("chat_log")[0] if get_tree().has_group("chat_log") else null
	if chat_log:
		var new_message = log_scene.instantiate()  # Instance the log.tscn scene
		if new_message:  # Check if instantiation was successful
			new_message.text = message  # Directly set the message text because new_message is a Label
			chat_log.add_child(new_message)  # Add it to the chat log
			chat_log.move_child(new_message, 0)  # Move it to the top of the chat log
		else:
			print("Failed to instance log.tscn")

# Move the player along the calculated path and pass the tile types for each tile
func move_along_path(path: Array, tile_size_param: Vector2, tile_type_array: Array):
	# Only update the path if it's a new one
	if current_path != path:
		current_path = path
		tile_type_data = tile_type_array
		current_path_index = 0
		tile_size = tile_size_param
		move_to_next_tile()

# Move to the next tile in the path
func move_to_next_tile():
	if current_path_index < current_path.size():
		var tile_type = tile_type_data[current_path_index]
		var reduction = tile_speed_reduction.get(tile_type, tile_speed_reduction["Default"])
		dynamic_speed = move_speed * (1.0 - reduction)
		minimum_speed = base_min_speed * (1.0 - reduction)

		# Get the current tile index as a unique identifier
		var tile_pos = current_path[current_path_index]
		var tile_id = str(tile_pos.x) + "_" + str(tile_pos.y)

		# Only send a message if it hasn't been sent for this tile
		if not message_sent_tiles.has(tile_id):
			send_to_chatlog("Crossing " + tile_type)
			message_sent_tiles[tile_id] = true  # Mark this tile as having sent a message

		target_position = (tile_pos * tile_size) + (tile_size / 2)
		is_moving = true

		# Rotate the sprite gradually by 45 degrees
		target_rotation += deg_to_rad(45)  # Add 45 degrees to the target rotation

var tolerance = 1.0  # You can adjust this value if needed

func _process(delta):
	if is_moving:
		var direction = (target_position - position).normalized()  # Direction towards the next tile
		var distance_to_move = dynamic_speed * delta

		if position.distance_to(target_position) <= distance_to_move + tolerance:
			position = target_position
			current_path_index += 1
			is_moving = false

			# Notify the map to remove the first point from the path
			if map:
				map.remove_point_from_path()

				# Update fog based on the player's new position
				map.update_fog_around_player(position)

			# If there are more tiles in the path, move to the next one
			if current_path_index < current_path.size():
				move_to_next_tile()
		else:
			# Decelerate the player as they move towards the tile
			dynamic_speed = max(dynamic_speed * (1.0 - deceleration_rate * delta), minimum_speed)
			position += direction * distance_to_move

	# Dynamically scale the rotation interpolation speed based on player's movement speed
	var rotation_speed_factor = clamp(dynamic_speed / move_speed, 0.2, 1.0)  # Scale factor based on current speed
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, rotation_speed_factor * delta * 10)
