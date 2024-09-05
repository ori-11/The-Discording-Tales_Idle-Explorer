class_name PrototypeGenerator
extends Control

@export var button: Button
@export var timer: Timer
@export var view: UserInterface.Views
@export var user_interface: UserInterface
@export var log_label: Label  # Reference to the Label node that will display the chat log

## Initialize the label at launch
func _ready() -> void:
	visible = false
	user_interface.navigation_requested.connect(_on_navigation_request)
	button.pressed.connect(_on_button_pressed)  # Connect the button signal to the function

func create_stardust() -> void:
	HandlerStardust.ref.create_stardust(1)
	
## Start the timer AND disable the button
func begin_generating_stardust() -> void:
	timer.start()
	button.disabled = true

## Triggered when the button is pressed
func _on_button_pressed() -> void:
	add_to_chat_log("Starting to collect...")
	begin_generating_stardust()

## Function to add a message to the chat log
func add_to_chat_log(message: String) -> void:
	log_label.text = message + "\n" + log_label.text

## Triggered when the Timer is out - every .1s
func _on_timer_timeout() -> void:
	create_stardust()

## Watch for navigation requests and react accordingly
func _on_navigation_request(requested_view: UserInterface.Views) -> void:
	if requested_view == view:
		visible = true
		return
	visible = false
