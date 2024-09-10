extends CharacterBody2D

var move_speed = 150  # Base max speed for Steppes
var dynamic_speed = move_speed  # Speed that changes during movement
var base_min_speed = 50  # Base minimum speed for Steppes
var minimum_speed = base_min_speed  # Dynamic minimum speed
var deceleration_rate = 10  # How quickly the player slows down per second
var target_position: Vector2  # Target position to move towards
var is_moving = false  # Whether the player is currently moving
var current_path: Array = []  # List of tiles in the path
var current_path_index = 0  # Index of the current tile in the path
var tile_size: Vector2  # Size of each tile
var tile_type_data: Array = []  # Array to store tile types along the path

var chat_log: VBoxContainer  # Reference to the VBoxContainer (chat log)
var message_sent = false  # Flag to check if message has already been sent for the current tile

# Speed reduction percentages by tile type
var tile_speed_reduction = {
	"Steppes": 0.0,       # 0% reduction
	"Dunes": 0.15,        # 20% reduction
	"Forest": 0.30,       # 40% reduction
	"Hills": 1.0,        # 60% reduction
	"Hot Spring": 0.60,   # 80% reduction
	"Default": 0.0        # Default reduction for unlisted tile types
}

# Called when the node enters the scene tree for the first time
func _ready():
	# Retrieve the chat log VBoxContainer via the group
	var chat_log_group = get_tree().get_nodes_in_group("chat_log")
	
	if chat_log_group.size() > 0:
		chat_log = chat_log_group[0] as VBoxContainer  # Assuming there's only one chat log container
	else:
		print("ChatLog VBoxContainer not found in the group")

# Function to add a new message to the chat log
func add_chat_message(message: String):
	if chat_log:
		# Create a new Label node for the message
		var new_message_label = Label.new()
		new_message_label.text = message

		# Add the message label to the VBoxContainer
		chat_log.add_child(new_message_label)

		# Move the newly added label to the top of the VBoxContainer
		chat_log.move_child(new_message_label, 0)
	else:
		print("ChatLog container not set")

# Move the player along the calculated path and pass the tile types for each tile
func move_along_path(path: Array, tile_size_param: Vector2, tile_type_array: Array):
	current_path = path
	tile_type_data = tile_type_array  # Store the tile types along the path
	current_path_index = 0
	tile_size = tile_size_param  # Set the tile_size member variable
	move_to_next_tile()

# Move to the next tile in the path
func move_to_next_tile():
	if current_path_index < current_path.size():
		# Get the current tile type
		var tile_type = tile_type_data[current_path_index]

		# Get speed reduction for the current tile
		var reduction = tile_speed_reduction.get(tile_type, tile_speed_reduction["Default"])

		# Apply speed reduction to both max and min speed
		dynamic_speed = move_speed * (1.0 - reduction)  # Max speed after reduction
		minimum_speed = base_min_speed * (1.0 - reduction)  # Min speed after reduction
		
		# Only add the message if it hasn't already been sent for this tile
		if not message_sent:
			add_chat_message("Crossing " + tile_type)
			message_sent = true  # Mark the message as sent

		# Calculate the target position by converting tile coordinates to world coordinates
		target_position = (current_path[current_path_index] * tile_size) + (tile_size / 2)
		is_moving = true  # Enable movement

func _process(delta):
	if is_moving:
		var direction = (target_position - position).normalized()  # Direction towards the next tile
		var distance_to_move = dynamic_speed * delta

		# Check if the player is close enough to the target tile
		if position.distance_to(target_position) <= distance_to_move:
			# Snap to the target position
			position = target_position
			current_path_index += 1
			is_moving = false
			message_sent = false  # Reset the message flag for the next tile

			# If there are more tiles in the path, move to the next one
			if current_path_index < current_path.size():
				move_to_next_tile()
		else:
			# Decelerate the player as they move towards the tile
			dynamic_speed = max(dynamic_speed * (1.0 - deceleration_rate * delta), minimum_speed)
			position += direction * distance_to_move
