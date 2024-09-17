class_name Game
extends Node

const CAM_START_POS := Vector2i(576, 324)



var screen_size : Vector2i
var game_running : bool

# Scroll speed variables
@export var scroll_speed : int = 0  # Initial scroll speed
@export var target_scroll_speed : int = 0  # Target scroll speed that we interpolate towards
var scroll_speed_transition_speed : float = 5.0  # How quickly to transition between speeds
var max_backward_distance : float = 500.0  # The maximum distance the scroller can go backward
var total_travel_distance : float = 0.0  # Track the total travel distance
var max_position : float = 0.0  # Track the maximum forward position reached

const SPEED_MODIFIER : int = 5000  # Adjust this value as needed

## Singleton reference
static var ref : Game

## Contains the data to save and load
var data : Data

# Console node reference
var console_node

## Singleton check & Data initialization
func _enter_tree() -> void:
	_singleton_check()
	data = Data.new()

## Singleton check
func _singleton_check() -> void:
	if not ref:
		ref = self
		return
	queue_free()

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	
	# Get the buttons from the UserInterface node
	var user_interface = get_node("/root/Game/HUD/UserInterface")
	user_interface.get_node("VBoxContainer/Bottom/RightPanel/Actions/Forward/Rest/Button").connect("pressed", Callable(self, "_on_rest_button_pressed"))
	user_interface.get_node("VBoxContainer/Bottom/RightPanel/Actions/Forward/Graze/Button").connect("pressed", Callable(self, "_on_graze_button_pressed"))
	user_interface.get_node("VBoxContainer/Bottom/RightPanel/Actions/Forward/Haste/Button").connect("pressed", Callable(self, "_on_haste_button_pressed"))
	user_interface.get_node("VBoxContainer/Bottom/RightPanel/Actions/LookBack/Button").connect("pressed", Callable(self, "_on_lookback_button_pressed"))
	
	# Access the Console node from the UserInterface scene
	console_node = user_interface.get_node("VBoxContainer/Bottom/LeftPanel/Console")
	console_node.visible = false  # Start with the console hidden
	
	new_game()

func new_game():

	

	$Camera2D.position = CAM_START_POS

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):


		$Camera2D.position.x += scroll_speed * delta


# New function to handle input, including "0" key press for console visibility
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		# Check if the "0" key is pressed
		if Input.is_key_pressed(KEY_CTRL):
			# Toggle the visibility of the console node
			console_node.visible = not console_node.visible
