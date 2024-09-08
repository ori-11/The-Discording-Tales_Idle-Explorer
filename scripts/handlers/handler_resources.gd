class_name HandlerResources
extends Node
## Manages multiple resources and related signals

## Singleton reference
static var ref : HandlerResources

## Assigns itself if there is no ref, and otherwise, destroy it (singleton check)
func _enter_tree() -> void:
	if not ref:
		ref = self
		return
		
	queue_free()

## Dictionary to hold different resource types and their quantities
var resources : Dictionary = {
	"Knowledge": 0,
	"Wood": 0,
	"Gold": 0
	# Add other resources as needed
}

## Signals for resource creation and consumption
signal resource_created(resource_type : String, quantity : int)
signal resource_consumed(resource_type : String, quantity : int)

## Returns the current amount of a specific resource
func get_resource(resource_type: String) -> int:
	if resources.has(resource_type):
		return resources[resource_type]
	else:
		return 0  # Return 0 if the resource type doesn't exist

## Creates a specific amount of a resource
func create_resource(resource_type: String, quantity: int) -> void:
	if resources.has(resource_type):
		resources[resource_type] += quantity
	else:
		# If the resource type doesn't exist, initialize it
		resources[resource_type] = quantity
	
	resource_created.emit(resource_type, quantity)

## Consumes a specific amount of a resource
## Returns "Error" if not enough resource is available
func consume_resource(resource_type: String, quantity: int) -> Error:
	if resources.has(resource_type) and resources[resource_type] >= quantity:
		resources[resource_type] -= quantity
		resource_consumed.emit(resource_type, quantity)
		return OK
	else:
		return FAILED  # Not enough of the resource to consume

## Check if a resource type exists
func resource_exists(resource_type: String) -> bool:
	return resources.has(resource_type)
