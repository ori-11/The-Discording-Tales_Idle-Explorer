class_name HandlerResources
extends Node

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
}

## Dictionary to hold situations (booleans)
var situations : Dictionary = {
	"outpost_built": false,
	"colony_prosperous": false
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

## Creates a specific amount of a resource (or increases it)
func create_resource(resource_type: String, quantity: int) -> void:
	if resources.has(resource_type):
		resources[resource_type] += quantity
	else:
		# If the resource type doesn't exist, initialize it
		resources[resource_type] = quantity
	
	resource_created.emit(resource_type, quantity)

	# Trigger event checks after resource update
	get_node("/root/Game/Handlers/Events").check_events()

## Consumes a specific amount of a resource
## Returns "Error" if not enough resource is available
func consume_resource(resource_type: String, quantity: int) -> Error:
	if resources.has(resource_type) and resources[resource_type] >= quantity:
		resources[resource_type] -= quantity
		resource_consumed.emit(resource_type, quantity)

		# Trigger event checks after resource update
		get_node("/root/Game/Handlers/Events").check_events()

		return OK
	else:
		return FAILED  # Not enough of the resource to consume

## NEW FUNCTION: Update (set) a resource directly to a specific value
func update_resource(resource_type: String, new_quantity: int) -> void:
	if resources.has(resource_type):
		resources[resource_type] = new_quantity
	else:
		# If the resource type doesn't exist, initialize it
		resources[resource_type] = new_quantity
	
	resource_created.emit(resource_type, new_quantity)

	# Trigger event checks after resource update
	get_node("/root/Game/Handlers/Events").check_events()

## NEW FUNCTION: Updates a situation
func update_situation(situation_name: String, state: bool) -> void:
	if situations.has(situation_name):
		situations[situation_name] = state

	# Trigger event checks after situation change
	get_node("/root/Game/Handlers/Events").check_events()

## Check if a resource type exists
func resource_exists(resource_type: String) -> bool:
	return resources.has(resource_type)
