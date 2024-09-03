class_name Game2
extends Node
## Main node of the game.

##All instances of statics will share the same variable - "Singleton reference".
static var ref : Game2

## assigns itself if there is no ref, and otherwise, destroy it. "Singleton check".
func _singleton_check() -> void:
	if not ref:
		ref = self
		return
		
	queue_free()

## Contains the data to save and load.
var data : Data

## Singleton check & Data initialization.
func _enter_tree() -> void:
	_singleton_check()
	data = Data.new()
