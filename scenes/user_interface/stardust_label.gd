class_name LabelStardust
extends Label
## Displays the current amount of available stardust

## Connects the signals of Stardust creation/consumption handlers
func _ready() -> void:
	update_text()
	HandlerStardust.ref.stardust_created.connect(update_text)
	HandlerStardust.ref.stardust_consumed.connect(update_text)

## Updates the text with the current stardust. We used "_"quantity as we don't need to know how much quantity, yet need to use it as an argument in the signals. Giving -1 emphasize that we don't want to use it
func update_text(_quantity : int =-1) -> void:
	text = "Stardust : %s" %HandlerStardust.ref.stardust()
