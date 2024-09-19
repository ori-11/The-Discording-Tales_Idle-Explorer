extends Node2D

signal ValidTileClicked(coord: Vector2i)

@onready var tileMap: TileMapLayer = $"../TileMapLayer"

func _ready() -> void:
	add_to_group("MapInputController")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("LeftMouseButton"):
		var tilePos: Vector2i = tileMap.local_to_map(get_local_mouse_position())
		var tileCellData: TileData = tileMap.get_cell_tile_data(tilePos)
		if tileCellData != null:
			if tileCellData.get_custom_data("Traversable"):
				ValidTileClicked.emit(tilePos)
				
