extends Node

@onready var tilemap: TileMapLayer = $"../TileMapLayer"
var aStar := AStarGrid2D.new()

func _ready() -> void:
	setupNavigaton()
	add_to_group("MapNavigationController")

func setupNavigaton() -> void:
	aStar.region = tilemap.get_used_rect()
	aStar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	aStar.update()
	solidifyNonTraversableTiles()
	

# tiles with custom data "Traversable" set to true will be made solid (non-traversable) in the aStarGrid2D
func solidifyNonTraversableTiles() -> void:
	for coord in tilemap.get_used_cells():
		if !tilemap.get_cell_tile_data(coord).get_custom_data("Traversable"):
			aStar.set_point_solid(coord, true)

func getPath(from: Vector2i, to: Vector2i) -> PackedVector2Array:
	return aStar.get_point_path(from, to)
