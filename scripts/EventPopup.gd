extends Window

var event_data = null  # Store current event data
var chat_log  # Reference to the chat log
var log_scene = preload("res://scenes/user_interface/log.tscn")  # Load the log scene

# Called when the node enters the scene tree for the first time
func _ready():
	hide()  # Make sure the popup is hidden initially
	# Retrieve the chat log VBoxContainer via the group
	var chat_log_group = get_tree().get_nodes_in_group("chat_log")
	if chat_log_group.size() > 0:
		chat_log = chat_log_group[0] as VBoxContainer  # Assuming there's only one chat log container

# Function to show the event
func show_event(event):
	event_data = event
	get_node("VBoxContainer/Label").text = event.description

	# Send the event description to the chat log
	send_to_chatlog("Event: " + event.description)

	var button_container = get_node("VBoxContainer/GridContainer")  # Reference the GridContainer
	
	# Clear previous buttons
	for child in button_container.get_children():
		child.queue_free()

	# Create buttons for each option
	for option in event.options:
		var btn = Button.new()
		btn.text = option["text"]
		
		# Set size flags to expand horizontally
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Use Callable to connect the button press to the event handler
		btn.connect("pressed", Callable(self, "_on_option_selected").bind(option))
		button_container.add_child(btn)

	# Show the popup when the event is triggered and center it
	show()
	popup_centered()

# Handle option selection
func _on_option_selected(option):
	# Send the decision made to the chat log
	send_to_chatlog("Decision made: " + option["text"])

	# Apply consequences
	for consequence in option["consequences"]:
		if consequence["type"] == "resource":
			get_node("/root/Game/Handlers/Resources").update_resource(consequence["name"], consequence["amount"])
			send_to_chatlog("Consequence: " + str(consequence["amount"]) + " " + consequence["name"])  # Send resource change to chat log
		elif consequence["type"] == "situation":
			get_node("/root/Game/Handlers/Resources").update_situation(consequence["name"], consequence["state"])
			send_to_chatlog("Consequence: Situation " + consequence["name"] + " changed.")  # Send situation change to chat log

	# Hide the popup after choosing an option
	hide()

# Function to send messages to the chat log using log.tscn
func send_to_chatlog(message: String):
	var chat_log = get_tree().get_nodes_in_group("chat_log")[0] if get_tree().has_group("chat_log") else null
	if chat_log:
		var new_message = log_scene.instantiate()  # Instance the log.tscn scene
		if new_message:  # Check if instantiation was successful
			new_message.text = message  # Directly set the message text because new_message is a Label
			chat_log.add_child(new_message)  # Add it to the chat log
			chat_log.move_child(new_message, 0)  # Move it to the top of the chat log
		else:
			print("Failed to instance log.tscn")
