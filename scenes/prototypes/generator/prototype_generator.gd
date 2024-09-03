class_name PrototypeGenerator
extends Control
## Creates Stardust every .1s

## Various references to the three needed nodes
@export var button : Button
@export var timer : Timer
@export var view : UserInterface.Views

@export var user_interface : UserInterface



## Initialize the label at launch
func _ready() -> void:
	visible = false
	
	##use the ui reference, looks for the signal, connect the signal to the navigation request.
	user_interface.navigation_requested.connect(_on_navigation_request)

func create_stardust() -> void:
	HandlerStardust.ref.create_stardust(1)

## Start the timer AND disable the button
func begin_generating_stardust() -> void:
	timer.start()
	button.disabled = true

## Triggered when the button is pressed
func _on_button_pressed():
	begin_generating_stardust()

## Triggered when the Timer is out - every .1s
func _on_timer_timeout():
	create_stardust()

## Watch for navigation requests and react accordingly
func _on_navigation_request(requested_view : UserInterface.Views) -> void:
	if requested_view == view:
		visible = true
		return
	visible = false
