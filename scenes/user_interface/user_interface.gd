class_name UserInterface
extends Control
## Main class controling the user interface

## List of views in the game
enum Views {
	PROTOTYPE_GENERATOR,
	PROTOTYPE_CLICKER,
}

## Emitted when something requested navigation. Includes the vie target
signal navigation_requested(view : Views)

## Triggered when the generator link is clicked. When the link is clicked, this emits the signal requesting navigation to this view
func _on_prototype_generator_pressed():
	pass # Replace with function body.


## Triggered when the clicker link is clicked. When the link is clicked, this emits the signal requesting navigation to this view
func _on_prototype_generator_link_pressed():
	navigation_requested.emit(Views.PROTOTYPE_GENERATOR)
	
	
func _on_prototype_clicker_link_pressed():
	navigation_requested.emit(Views.PROTOTYPE_CLICKER)
