extends Window

var event_data = null  # Store current event data

# Function to show the event
func show_event(event):
	event_data = event
	get_node("VBoxContainer/Label").text = event.description
	var button_container = get_node("VBoxContainer/ButtonContainer")
	
	# Clear previous buttons
	for child in button_container.get_children():
		child.queue_free()

	# Create buttons for each option
	for option in event.options:
		var btn = Button.new()
		btn.text = option["text"]

		# Use Callable to connect the button press to the event handler
		btn.connect("pressed", Callable(self, "_on_option_selected").bind(option))
		button_container.add_child(btn)

	popup_centered()

# Handle option selection
func _on_option_selected(option):
	# Apply consequences
	for consequence in option["consequences"]:
		if consequence["type"] == "resource":
			get_node("/root/Game/Handlers/Resources").update_resource(consequence["name"], consequence["amount"])
		elif consequence["type"] == "situation":
			get_node("/root/Game/Handlers/Resources").update_situation(consequence["name"], consequence["state"])

	# Hide the popup after choosing an option
	hide()
