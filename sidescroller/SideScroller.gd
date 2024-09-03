extends Node2D

@export var camera_path := NodePath()  # Path to the Camera2D node
@export var scroll_speed : int = 0  # Initial scroll speed
@export var target_scroll_speed : int = 0  # Target scroll speed that we interpolate towards
var scroll_speed_transition_speed : float = 5.0  # How quickly to transition between speeds
var num_pictures : int = 8  # Ensure at least 8 pictures are visible

var total_travel_distance : float = 0.0  # Track the total travel distance
var max_backward_distance : float = 500.0  # The maximum distance the scroller can go backward, set to 500 units
var max_position : float = 0.0  # Track the maximum forward position reached

# Store references to buttons for triggering them programmatically
var rest_button: Button = null

func _ready():
	# Access the UserInterface node
	var user_interface = get_node("/root/Game/HUD/UserInterface")

	# Get the buttons from the UserInterface node
	rest_button = user_interface.get_node("VBoxContainer/Bottom/RightPanel/Actions/Forward/Rest/Button")
	var graze_button = user_interface.get_node("VBoxContainer/Bottom/RightPanel/Actions/Forward/Graze/Button")
	var haste_button = user_interface.get_node("VBoxContainer/Bottom/RightPanel/Actions/Forward/Haste/Button")
	var return_button = user_interface.get_node("VBoxContainer/Bottom/RightPanel/Actions/Return/Button")
	
	# Connect the buttons to their respective functions using Callable
	if rest_button:
		rest_button.connect("pressed", Callable(self, "_on_rest_button_pressed"))
		
	if graze_button:
		graze_button.connect("pressed", Callable(self, "_on_graze_button_pressed"))
		
	if haste_button:
		haste_button.connect("pressed", Callable(self, "_on_haste_button_pressed"))
		
	if return_button:
		return_button.connect("pressed", Callable(self, "_on_return_button_pressed"))

	# Continue with the rest of the initialization
	var camera = get_node(camera_path)
	if camera:
		resize_backgrounds(camera)
	position_backgrounds()

func _process(delta):
	# Smoothly interpolate the current scroll speed towards the target scroll speed
	scroll_speed = lerp(scroll_speed, target_scroll_speed, scroll_speed_transition_speed * delta)

	# Update the total travel distance
	total_travel_distance += scroll_speed * delta

	# Update max_position when moving forward
	if scroll_speed > 0 and total_travel_distance > max_position:
		max_position = total_travel_distance  # Update the max forward position

	# Ensure backward movement is within the limit
	if scroll_speed < 0 and total_travel_distance <= (max_position - max_backward_distance):
		if rest_button:
			rest_button.emit_signal("pressed")  # Simulate pressing the "Rest" button

	# Move backgrounds and handle looping
	move_backgrounds(delta)
	loop_backgrounds()

# Functions to handle button presses
func _on_rest_button_pressed():
	target_scroll_speed = 0

func _on_graze_button_pressed():
	target_scroll_speed = 100

func _on_haste_button_pressed():
	target_scroll_speed = 300
	
func _on_return_button_pressed():
	target_scroll_speed = -100

# Function to resize backgrounds to fit the top fourth of the screen
func resize_backgrounds(camera):
	var screen_size = get_viewport().get_visible_rect().size
	var target_height = screen_size.y / 4  # Resize to fit one-fourth of the screen height
	for child in get_children():
		if child is Sprite2D:
			var texture_size = child.texture.get_size()
			var scale_factor = min(screen_size.x / texture_size.x, target_height / texture_size.y)
			child.scale = Vector2(scale_factor, scale_factor)

# Function to position the backgrounds side by side
func position_backgrounds():
	var screen_size = get_viewport().get_visible_rect().size
	var total_width := 0.0
	var children = get_children()
	var textures_count := children.size()
	
	# Position the original set of images
	for i in range(textures_count):
		var child = children[i]
		if child is Sprite2D:
			child.position.x = total_width
			child.position.y = 0  # Align with the top of the screen
			total_width += child.texture.get_size().x * child.scale.x
	
	# Duplicate and position additional images until they cover +4 images behind
	while total_width < screen_size.x * (num_pictures / 4 + 4):
		for i in range(textures_count):
			var child = children[i].duplicate() as Sprite2D
			add_child(child)
			child.position.x = total_width
			child.position.y = 0
			total_width += child.texture.get_size().x * child.scale.x

# Function to calculate the total width of the side scroller
func calculate_total_width() -> float:
	var total_width := 0.0
	for child in get_children():
		if child is Sprite2D:
			total_width += child.texture.get_size().x * child.scale.x
	return total_width

# Function to move the backgrounds at the current scroll speed
func move_backgrounds(delta):
	for child in get_children():
		if child is Sprite2D:
			child.position.x -= scroll_speed * delta

# Function to loop the backgrounds
func loop_backgrounds():
	var screen_size = get_viewport().get_visible_rect().size  # Declare and assign screen_size here
	var min_x = INF
	var max_x = -INF
	var min_child = null
	var max_child = null
	
	for child in get_children():
		if child is Sprite2D:
			var child_end_x = child.position.x + child.texture.get_size().x * child.scale.x
			
			# Track the furthest back (min) and furthest forward (max) images
			if child.position.x < min_x:
				min_x = child.position.x
				min_child = child
			if child_end_x > max_x:
				max_x = child_end_x
				max_child = child
	
	# If moving forward, loop backgrounds as before
	if scroll_speed > 0:
		for child in get_children():
			if child is Sprite2D:
				if child.position.x + child.texture.get_size().x * child.scale.x < 0:
					if max_child:
						child.position.x = max_child.position.x + max_child.texture.get_size().x * max_child.scale.x
						max_child = child  # Update the last child to the one just repositioned

	# If moving backward, reposition the backgrounds in the opposite direction
	elif scroll_speed < 0:
		for child in get_children():
			if child is Sprite2D:
				if child.position.x > screen_size.x:
					if min_child:
						child.position.x = min_child.position.x - child.texture.get_size().x * child.scale.x
						min_child = child  # Update the first child to the one just repositioned

# Function to update the scroll speed based on some other game logic
func _update_scroll_speed(_amount = 0):
	# Update the scroll speed based on the current amount of stardust
	var stardust_amount = HandlerStardust.ref.stardust()
	# Set a base speed and scale the speed by the stardust amount
	var base_speed = 100  # Adjust this value as needed
	target_scroll_speed = base_speed + stardust_amount * 10
