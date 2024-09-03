class_name PrototypeClicker
extends Control

## Reference to the label displaying the created stardust
@export var view : UserInterface.Views
@export var user_interface : UserInterface

## Initialize the label at launch
func _ready() -> void:
	visible = true
	
	##use the ui reference, looks for the signal, connect the signal to the navigation request.
	user_interface.navigation_requested.connect(_on_navigation_request)

func create_stardust() -> void:
	HandlerStardust.ref.create_stardust(1)

## Watch the signal and react to it
func _on_navigation_request(requested_view : UserInterface.Views) -> void:
	if requested_view == view:
		visible = true
		return
	visible = false
	
func _on_button_pressed() -> void:
	create_stardust()
