# This script displays the current amount of a chosen resource
class_name LabelResource
extends Label

# Export a string to set the resource type (like "Knowledge", "Stardust", etc.)
@export var resource_type: String = "Knowledge"

## Connects the signals for resource creation/consumption
func _ready() -> void:
	update_text()
	# Connect to the resource handler's signals
	HandlerResources.ref.resource_created.connect(_on_resource_updated)
	HandlerResources.ref.resource_consumed.connect(_on_resource_updated)

## Updates the label with the current amount of the chosen resource
func update_text(_quantity: int = -1) -> void:
	text = "%s: %s" % [resource_type, HandlerResources.ref.get_resource(resource_type)]

## Called when a resource is created or consumed, updates the label only if it's the relevant resource
func _on_resource_updated(resource_name: String, _quantity: int) -> void:
	if resource_name == resource_type:
		update_text()
