class_name PrototypeClicker
extends Control

@export var view: UserInterface.Views
@export var user_interface: UserInterface
@export var log_label: Label  # Label node for displaying the chat log
@export var button: Button  # Reference to the Button
@export var timer: Timer  # Timer for controlling click delay
@export var progress_bar: ProgressBar  # Reference to the ProgressBar
@export var tooltip: LineEdit  # Reference to the LineEdit node for the tooltip

var button_disabled_time = 1.0  # Time in seconds for the button cooldown
var elapsed_time = 0.0  # To track the time progression
var tooltip_description = "This button creates stardust and has a 1s cooldown."  # Tooltip text

## Initialize the label at launch
func _ready() -> void:
	visible = true
	user_interface.navigation_requested.connect(Callable(self, "_on_navigation_request"))
	button.pressed.connect(Callable(self, "_on_button_pressed"))
	
	# Connect the mouse enter and exit signals to the button
	button.connect("mouse_entered", Callable(self, "_on_button_mouse_entered"))
	button.connect("mouse_exited", Callable(self, "_on_button_mouse_exited"))

	# Set initial properties for the LineEdit tooltip
	if tooltip:
		tooltip.editable = false  # Disable editing for the tooltip
		tooltip.visible = false  # Start hidden

	timer.wait_time = button_disabled_time
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	
	progress_bar.min_value = 0  # Set the progress bar minimum value
	progress_bar.max_value = 100  # Set the progress bar max value to 100
	progress_bar.value = 0  # Start with the bar at 0

## Create stardust and add a message to the log
func create_stardust() -> void:
	HandlerStardust.ref.create_stardust(1)
	add_to_chat_log("Created stardust!")

## Function to add a message to the chat log
func add_to_chat_log(message: String) -> void:
	log_label.text = message + "\n" + log_label.text

## Watch the signal and react to it
func _on_navigation_request(requested_view: UserInterface.Views) -> void:
	if requested_view == view:
		visible = true
		return
	visible = false

## Triggered when the button is pressed
func _on_button_pressed() -> void:
	if button.disabled:  # If the button is disabled, ignore the press
		return
	
	create_stardust()
	button.disabled = true  # Disable the button after pressing
	elapsed_time = 0.0  # Reset the elapsed time
	progress_bar.value = 0  # Reset the progress bar value to 0
	
	# Hide tooltip when clicked, but only if the button has a cooldown
	if button_disabled_time > 0:
		tooltip.visible = false
	
	timer.start()  # Start the timer

## Called when the timer times out
func _on_timer_timeout() -> void:
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
		tooltip.global_position = global_position + Vector2(0, button_size.y)

## Handle mouse exit: hide the tooltip
func _on_button_mouse_exited() -> void:
	if button.disabled == false and tooltip:
		tooltip.visible = false  # Hide the tooltip when the mouse leaves

## Update the progress bar while the button is disabled
func _process(delta: float) -> void:
	if button.disabled:
		elapsed_time += delta
		var progress = int((elapsed_time / button_disabled_time) * 100)  # Calculate progress in percentage
		progress_bar.value = progress  # Update the progress bar value
		if elapsed_time >= button_disabled_time:  # If the time is complete
			progress_bar.value = 100  # Ensure the bar is fully filled when the time is complete
