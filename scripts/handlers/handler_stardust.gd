class_name HandlerStardust
extends Node
## Manages stardust and related signals

##All instances of statics will share the same variable - "Singleton reference".
static var ref : HandlerStardust

## assigns itself if there is no ref, and otherwise, destroy it. "Singleton check".
func _enter_tree() -> void:
	if not ref:
		ref = self
		return
		
	queue_free()
	
## Returns the current amount of available stardust
func stardust() -> int:
	return Game.ref.data.stardust
	
## Emitted when stardust has been created	
signal stardust_created(quantity : int)
## Emitted when stardust has been consumed
signal stardust_consumed(quantity : int)


## Creates a specific amount of stardust
func create_stardust(quantity : int) -> void:
	Game.ref.data.stardust += quantity
	stardust_created.emit(quantity)

## Returns "Error" when we don't have enough stardust, otherwise, consumes the specific amount of stardust
func consume_stardust(quantity : int) -> Error:
	if quantity > Game.ref.data.stardust:
		return Error.FAILED
		
	Game.ref.data.stardust -= quantity
	stardust_consumed.emit(quantity)
	
	return Error.OK
	


	
	
