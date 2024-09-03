extends Node2D

var segment_width = 50
var max_height_diff = 30
var min_y = 200
var max_y = 400
var ground_points = []

func _ready():
	generate_ground()
	update_collision_shape()
	#update_visual_representation()

func generate_ground():
	var x = 0
	var y = randi_range(min_y, max_y)
	while x < 2000:  # Adjust based on how long you want the ground to be
		ground_points.append(Vector2(x, y))
		x += segment_width
		y += randi_range(max(y - max_height_diff, min_y), min(y + max_height_diff, max_y))

func update_collision_shape():
	var shape_points = []
	for point in ground_points:
		shape_points.append(point)
	shape_points.append(Vector2(ground_points[-1].x, 1000))  # Extend to bottom of the screen
	shape_points.append(Vector2(ground_points[0].x, 1000))  # Extend to bottom of the screen
	
	$StaticBody2D/CollisionPolygon2D.polygon = shape_points
#
#func update_visual_representation():
	#var line = $Line2D
	#line.clear_points()
	#for point in ground_points:
		#line.add_point(point)
	#$Sprite2D.texture = generate_texture()
