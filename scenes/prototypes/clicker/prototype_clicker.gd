class_name PrototypeClicker
extends Control

# Exported variables to configure different resource types, amount, tooltip, and chat log messages
@export var resource_type: String = "Knowledge"  # Define the type of resource (e.g., "Knowledge", "Wood", "Gold")
@export var min_amount: int = 1  # Minimum amount of resource to generate
@export var max_amount: int = 3  # Maximum amount of resource to generate
@export var tooltip_description: String = "This button creates a resource and has a cooldown."  # Tooltip text
@export var chat_log_message: String = "Created {amount} {resource}!"  # Custom message for the chat log

# Exported timer configuration
@export var timer_length: float = 5.0  # Time delay for cooldown in seconds

# References to UI elements
@export var chat_log_container: VBoxContainer  # VBoxContainer for displaying chat log messages
@export var button: Button  # Reference to the Button
@export var timer: Timer  # Timer for controlling click delay
@export var progress_bar: ProgressBar  # Reference to the ProgressBar
@export var tooltip: LineEdit  # Reference to the LineEdit node for the tooltip

var elapsed_time = 0.0  # To track the time progression

## Initialize the button, signals, and UI at launch
func _ready() -> void:
	visible = true
	button.pressed.connect(Callable(self, "_on_button_pressed"))
	
	# Connect the mouse enter and exit signals to the button
	button.connect("mouse_entered", Callable(self, "_on_button_mouse_entered"))
	button.connect("mouse_exited", Callable(self, "_on_button_mouse_exited"))

	# Set initial properties for the LineEdit tooltip
	if tooltip:
		tooltip.editable = false  # Disable editing for the tooltip
		tooltip.visible = false  # Start hidden

	# Set the timer's wait time from the exported variable
	timer.wait_time = timer_length
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))

	# Initialize progress bar values
	progress_bar.min_value = 0  # Set the progress bar minimum value
	progress_bar.max_value = 100  # Set the progress bar max value to 100
	progress_bar.value = 0  # Start with the bar at 0

## Function to create the resource
func create_resource() -> void:
	var amount = randi_range(min_amount, max_amount)  # Generate a random amount of the resource between min_amount and max_amount
	
	# Create resources based on the specified resource type
	HandlerResources.ref.create_resource(resource_type, amount)

	# Add the appropriate message to the chat log
	var message = chat_log_message.replace("{amount}", str(amount)).replace("{resource}", resource_type)
	add_to_chat_log(message)

## Function to add a message to the chat log (now using VBoxContainer)
func add_to_chat_log(message: String) -> void:
	if chat_log_container:
		# Create a new Label node for the message
		var new_message_label = Label.new()
		new_message_label.text = message

		# Add the new message at the top of the VBoxContainer
		chat_log_container.add_child(new_message_label)
		chat_log_container.move_child(new_message_label, 0)  # Move it to the top
	else:
		print("ChatLog container not set")

## Triggered when the button is pressed
func _on_button_pressed() -> void:
	if button.disabled:  # If the button is disabled, ignore the press
		return
	
	button.disabled = true  # Disable the button after pressing
	elapsed_time = 0.0  # Reset the elapsed time
	progress_bar.value = 0  # Reset the progress bar value to 0
	
	# Hide tooltip when clicked, but only if the timer has a cooldown
	if timer.wait_time > 0:
		tooltip.visible = false
	
	timer.start()  # Start the timer

## Called when the timer times out (resource is created after the timer ends)
func _on_timer_timeout() -> void:
	create_resource()  # Resource is created only after the timer finishes
	button.disabled = false  # Re-enable the button when the timer finishes
	progress_bar.value = 0  # Reset the bar when cooldown is over

## Handle button hover: show the tooltip
func _on_button_mouse_entered() -> void:
	if button.disabled == false and tooltip:  # Only show the tooltip if the button is not disabled
		tooltip.visible = true  # Show the tooltip
		tooltip.text = tooltip_description  # Set tooltip text

		# Position tooltip below the button
		var global_position = button.get_global_transform().origin
		var button_size = button.get_size()  # Get the button size
		tooltip.global_position = global_position + Vector2(5, button_size.y)

## Handle mouse exit: hide the tooltip
func _on_button_mouse_exited() -> void:
	if button.disabled == false and tooltip:
		tooltip.visible = false  # Hide the tooltip when the mouse leaves

## Update the progress bar while the button is disabled
func _process(delta: float) -> void:
	if button.disabled:
		elapsed_time += delta
		var progress = int((elapsed_time / timer.wait_time) * 100)  # Calculate progress in percentage based on timer's wait_time
		progress_bar.value = progress  # Update the progress bar value
		if elapsed_time >= timer.wait_time:  # If the time is complete
			progress_bar.value = 100  # Ensure the bar is fully filled when the time is complete
