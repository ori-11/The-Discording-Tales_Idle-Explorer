extends Control

# A dictionary to map buttons to resource actions
var button_actions := {}
var input_dialog: LineEdit = null  # Store reference to the input dialog

func _ready() -> void:
	# Find the ButtonStardust and connect it
	var stardust_button = $ButtonStardust
	# Map the button to its action: prompting for stardust amount
	button_actions[stardust_button] = Callable(self, "_toggle_stardust_input")
	
	# Connect the button press signal to the generic handler
	stardust_button.connect("pressed", Callable(self, "_on_button_pressed").bind(stardust_button))


# General button press handler
func _on_button_pressed(button: Button) -> void:
	if button in button_actions:
		button_actions[button].call()

# Function to toggle visibility of the stardust input dialog
func _toggle_stardust_input() -> void:
	# If input_dialog already exists, toggle its visibility and clear text
	if input_dialog:
		input_dialog.visible = not input_dialog.visible
		if input_dialog.visible:
			input_dialog.clear()  # Clear the previous input
			input_dialog.grab_focus()  # Focus on the input if it becomes visible
		return

	# Otherwise, create the input dialog
	input_dialog = LineEdit.new()
	input_dialog.placeholder_text = "Enter amount of stardust (+ to add, - to remove)"
	input_dialog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_dialog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(input_dialog)

	# Connect the 'text_submitted' signal to confirm the input
	input_dialog.connect("text_submitted", Callable(self, "_on_stardust_amount_entered"))

	# Connect the 'text_changed' signal to restrict input to valid characters
	input_dialog.connect("text_changed", Callable(self, "_validate_input"))

	# Auto-focus the input dialog and clear any existing text
	input_dialog.clear()  # Clear any existing input when first shown
	input_dialog.grab_focus()

# Validate the input to ensure only numbers and signs are allowed
func _validate_input() -> void:
	var valid_chars = "+-0123456789"
	var new_text = ""
	for i in range(input_dialog.text.length()):
		if valid_chars.has(input_dialog.text[i]):
			new_text += input_dialog.text[i]
	input_dialog.text = new_text

# Function to handle the amount entered by the user
func _on_stardust_amount_entered(amount_str: String) -> void:
	# Parse the entered text into an integer
	var amount = amount_str.to_int()

	# Update the stardust based on the amount entered
	if amount != 0:
		if amount > 0:
			HandlerStardust.ref.create_stardust(amount)
			print("Added ", amount, " stardust! Current stardust: ", HandlerStardust.ref.stardust())
		else:
			# If the amount is negative, try to remove that much, but clamp at 0
			var current_stardust = HandlerStardust.ref.stardust()
			var remove_amount = abs(amount)
			
			# If remove_amount is greater than current stardust, just set to 0
			if remove_amount > current_stardust:
				remove_amount = current_stardust
			
			HandlerStardust.ref.consume_stardust(remove_amount)
			print("Removed ", remove_amount, " stardust! Current stardust: ", HandlerStardust.ref.stardust())
	else:
		print("No valid amount entered.")

	# Hide the input dialog after the amount is processed
	input_dialog.visible = false
