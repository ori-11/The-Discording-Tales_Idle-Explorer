class_name UserInterface
extends Control
## Main class controling the user interface
var chat_log: VBoxContainer
## List of views in the game
enum Views {
	PROTOTYPE_GENERATOR,
	PROTOTYPE_CLICKER,
}

## Emitted when something requested navigation. Includes the vie target
signal navigation_requested(view : Views)
func _ready():
	# Adjust this path according to your scene structure
	chat_log = get_node("VBoxContainer/Bottom/LeftPanel/ScrollContainer/VBoxContainer")

# Call this function to add a new chat message
func add_chat_message(message: String):
	# Create a new Label for the chat message
	var new_message_label = Label.new()
	new_message_label.text = message

	# If there are already messages in the chat, add the new one above the first one
	if chat_log.get_child_count() > 0:
		var first_message = chat_log.get_child(0)
		chat_log.add_child_below_node(first_message, new_message_label)
	else:
		chat_log.add_child(new_message_label)  # If it's the first message

# Ensure the ScrollContainer scrolls to the top when a new message is added
func scroll_to_top():
	var scroll_container = get_node("VBoxContainer/Bottom/LeftPanel/ScrollContainer")
	scroll_container.scroll_vertical = 0  # Scroll to the top
## Triggered when the generator link is clicked. When the link is clicked, this emits the signal requesting navigation to this view
func _on_prototype_generator_pressed():
	pass # Replace with function body.


## Triggered when the clicker link is clicked. When the link is clicked, this emits the signal requesting navigation to this view
func _on_prototype_generator_link_pressed():
	navigation_requested.emit(Views.PROTOTYPE_GENERATOR)
	
	
func _on_prototype_clicker_link_pressed():
	navigation_requested.emit(Views.PROTOTYPE_CLICKER)
