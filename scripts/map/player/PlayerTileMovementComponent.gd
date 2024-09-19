extends Node2D

@onready var playerTile: Node2D = $".."

var path: PackedVector2Array = []
var pathIdx: int = 0
var traveling: bool = false
var targetPos: Vector2
var moveSpeed: float = 250

var tilemap: TileMapLayer
var mapNavigationController: Node

func _ready() -> void:
	mapNavigationController = get_tree().get_first_node_in_group("MapNavigationController")

func setTargetCoord(coord: Vector2i) -> void:
	getPathToCoord(coord)

func getPathToCoord(coord: Vector2i) -> void:
	var playerMapCoord: Vector2i = tilemap.local_to_map(playerTile.position)
	var foundPath: PackedVector2Array = mapNavigationController.getPath(playerMapCoord, coord)
	if !foundPath.is_empty():
		setPath(foundPath)

func setPath(newPath: PackedVector2Array) -> void:
	path = newPath
	if !traveling:
		targetPos = tilemap.to_global(tilemap.map_to_local(path[1]))
	pathIdx = 1
	traveling = true

func goToNextTile() -> void:
	pathIdx += 1
	
	if pathIdx < path.size():
		targetPos = tilemap.to_global(tilemap.map_to_local(path[pathIdx]))
	else:
		doneTraveling()
		
func doneTraveling() -> void:
	traveling = false
	path.clear()
	pathIdx = 0

func _process(delta: float) -> void:
	if traveling:
		playerTile.global_position = playerTile.global_position.move_toward(targetPos, delta * moveSpeed)
		if playerTile.global_position == targetPos:
			goToNextTile()
