extends Node2D

signal ValidTileClicked(coord: Vector2i)

@onready var tileMap: TileMapLayer = $"../TileMapLayer"
# link to where you want to display the hovered tile's name
@export var hoveredTileLabel: RichTextLabel

func _ready() -> void:
	add_to_group("MapInputController")

func _input(event: InputEvent) -> void:
	var mouseTilePos: Vector2i = tileMap.local_to_map(get_local_mouse_position())
	var tileCellData: TileData = tileMap.get_cell_tile_data(mouseTilePos)
	if tileCellData != null:
		if Input.is_action_just_pressed("LeftMouseButton"):
			if tileCellData != null:
				if tileCellData.get_custom_data("Traversable"):
					ValidTileClicked.emit(mouseTilePos)
		else:
			hoveredTileLabel.text = tileCellData.get_custom_data("TileName")
