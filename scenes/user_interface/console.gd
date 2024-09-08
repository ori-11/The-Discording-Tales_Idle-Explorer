extends Control

# A dictionary to map buttons to resource actions
var button_actions := {}
var input_dialog: LineEdit = null  # Store reference to the input dialog

func _ready() -> void:
	# Find the ButtonKnowledge and connect it
	var knowledge_button = $ButtonKnowledge
	# Map the button to its action: prompting for knowledge amount
	button_actions[knowledge_button] = Callable(self, "_toggle_knowledge_input")
	
	# Connect the button press signal to the generic handler
	knowledge_button.connect("pressed", Callable(self, "_on_button_pressed").bind(knowledge_button))


# General button press handler
func _on_button_pressed(button: Button) -> void:
	if button in button_actions:
		button_actions[button].call()

# Function to toggle visibility of the knowledge input dialog
func _toggle_knowledge_input() -> void:
	# If input_dialog already exists, toggle its visibility and clear text
	if input_dialog:
		input_dialog.visible = not input_dialog.visible
		if input_dialog.visible:
			input_dialog.clear()  # Clear the previous input
			input_dialog.grab_focus()  # Focus on the input if it becomes visible
		return

	# Otherwise, create the input dialog
	input_dialog = LineEdit.new()
	input_dialog.placeholder_text = "Enter amount of knowledge (+ to add, - to remove)"
	input_dialog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_dialog.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(input_dialog)

	# Connect the 'text_submitted' signal to confirm the input
	input_dialog.connect("text_submitted", Callable(self, "_on_knowledge_amount_entered"))

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
func _on_knowledge_amount_entered(amount_str: String) -> void:
	# Parse the entered text into an integer
	var amount = amount_str.to_int()

	# Update the knowledge based on the amount entered
	if amount != 0:
		if amount > 0:
			HandlerResources.ref.create_knowledge(amount)
			print("Added ", amount, " knowledge! Current knowledge: ", HandlerResources.ref.knowledge())
		else:
			# If the amount is negative, try to remove that much, but clamp at 0
			var current_knowledge = HandlerResources.ref.knowledge()
			var remove_amount = abs(amount)
			
			# If remove_amount is greater than current knowledge, just set to 0
			if remove_amount > current_knowledge:
				remove_amount = current_knowledge
			
			HandlerResources.ref.consume_knowledge(remove_amount)
			print("Removed ", remove_amount, " knowledge! Current knowledge: ", HandlerResources.ref.knowledge())
	else:
		print("No valid amount entered.")

	# Hide the input dialog after the amount is processed
	input_dialog.visible = false
