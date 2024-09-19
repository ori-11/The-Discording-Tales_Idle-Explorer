extends Node2D

@onready var playerSprite: Sprite2D = $Sprite2D
@onready var movementComponent: Node2D = $PlayerTileMovementComponent

var mapInputController: Node2D 
var tilemap: TileMapLayer

func _ready() -> void:
	mapInputController = get_tree().get_first_node_in_group("MapInputController")
	mapInputController.ValidTileClicked.connect(setTargetCoord)
	tilemap = $".."
	movementComponent.tilemap = tilemap

func setTargetCoord(coord: Vector2) -> void:
	movementComponent.setTargetCoord(coord)
