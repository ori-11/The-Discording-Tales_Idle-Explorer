class_name Game
extends Node

# Preload obstacles
var stump_scene = preload("res://scenes/stump.tscn")
var rock_scene = preload("res://scenes/rock.tscn")
var barrel_scene = preload("res://scenes/barrel.tscn")
var bird_scene = preload("res://scenes/bird.tscn")
var obstacle_types := [stump_scene, rock_scene, barrel_scene]
var obstacles : Array = []
var bird_heights := [200, 90]

# Game variables
const HERD_START_POS := Vector2i(550, 190)
const CAM_START_POS := Vector2i(576, 324)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs

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
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	
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
	# Reset variables
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0
	scroll_speed = 0  # Reset the scroll speed
	target_scroll_speed = 0  # Reset the target scroll speed
	
	# Delete all obstacles
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	# Reset the nodes
	$Dino.position = HERD_START_POS
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)

	# Reset ground generation
	$GroundSegment.reset_ground()

	# Reset HUD and game over screen
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_running:
		# Smoothly interpolate the current scroll speed towards the target scroll speed
		scroll_speed = lerp(scroll_speed, target_scroll_speed, scroll_speed_transition_speed * delta)

		# Update the total travel distance
		total_travel_distance += scroll_speed * delta

		# Update max_position when moving forward
		if scroll_speed > 0 and total_travel_distance > max_position:
			max_position = total_travel_distance

		# Ensure backward movement is within the limit
		if scroll_speed < 0 and total_travel_distance <= (max_position - max_backward_distance):
			_on_rest_button_pressed()  # Simulate pressing the "Rest" button to stop backward movement

		# Move dino and camera based on scroll speed
		$Dino.position.x += scroll_speed * delta
		$Camera2D.position.x += scroll_speed * delta
		
		# Generate obstacles
		generate_obs()
		
		# Update score
		score += scroll_speed * delta
		show_score()
		
		# Update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		# Remove obstacles that have gone off screen
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

# New function to handle input, including "0" key press for console visibility
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		# Check if the "0" key is pressed
		if Input.is_key_pressed(KEY_CTRL):
			# Toggle the visibility of the console node
			console_node.visible = not console_node.visible


# Functions to handle button presses
func _on_rest_button_pressed():
	target_scroll_speed = 0

func _on_graze_button_pressed():
	target_scroll_speed = 100

func _on_haste_button_pressed():
	target_scroll_speed = 300
	
func _on_lookback_button_pressed():
	target_scroll_speed = -100

func generate_obs():
	# Generate ground obstacles
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = 365 - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		# Additionally random chance to spawn a bird
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				# Generate bird obstacles
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

func hit_obs(body):
	if body.name == "Dino":
		game_over()

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(int(score / SCORE_MODIFIER))

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(int(high_score / SCORE_MODIFIER))

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$GameOver.show()
