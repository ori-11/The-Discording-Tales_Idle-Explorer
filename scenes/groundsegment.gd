extends Node2D

var segment_width = 30  # Consistent width throughout
var max_height_diff = 100  # Height variation for hills
var min_y = 200
var max_y = 350
var ground_points = []
var last_generated_x = 0

var look_ahead_distance = 300  # Generate this much further ahead of the camera
var retain_distance = 300  # Keep this much distance behind the camera before deleting points

func _ready():
	randomize()  # Seed the random number generator
	var camera_bounds = get_camera_bounds()
	last_generated_x = camera_bounds.position.x  # Start from the camera's initial position
	generate_ground_until(camera_bounds.position.x + camera_bounds.size.x + look_ahead_distance)
	update_collision_shape()
	update_visual_representation()
	update_filled_area()

func _process(delta):
	var camera_bounds = get_camera_bounds()
	var camera_right_edge = camera_bounds.position.x + camera_bounds.size.x
	
	# Generate new ground if the camera has moved past the last generated point
	generate_ground_until(camera_right_edge + look_ahead_distance)
	
	# Remove points that are off-screen to the left, but keep a bit more
	remove_old_points(camera_bounds.position.x - retain_distance)
	
	update_collision_shape()
	update_visual_representation()
	update_filled_area()

func get_camera_bounds():
	var camera = get_node("/root/Game/Camera2D")
	if camera == null:
		return Rect2()

	var screen_size = get_viewport().size
	var top_left = camera.global_position - screen_size * 0.5
	return Rect2(top_left, screen_size)

func generate_ground_until(end_x):
	var y = randi_range(min_y, max_y) if ground_points.size() == 0 else ground_points[-1].y
	
	while last_generated_x < end_x:
		var prev_y = y
		var y_offset = randi_range(-max_height_diff, max_height_diff) * 0.2  # Moderate multiplier for smoother hills

		y = clamp(prev_y + y_offset, min_y, max_y)

		# Smoothing: If the difference between consecutive points is too steep, smooth it
		if abs(y - prev_y) > max_height_diff * 0.1:
			var step = (y - prev_y) / 5.0  # Smooth over 3 segments
			for i in range(5):
				prev_y += step
				ground_points.append(Vector2(last_generated_x, clamp(prev_y, min_y, max_y)))
				last_generated_x += segment_width
		else:
			ground_points.append(Vector2(last_generated_x, y))
			last_generated_x += segment_width  # Move forward by segment width

func remove_old_points(min_x):
	while ground_points.size() > 0 and ground_points[0].x < min_x:
		ground_points.pop_front()

func update_collision_shape():
	var shape_points = []
	for point in ground_points:
		shape_points.append(point)
	shape_points.append(Vector2(ground_points[-1].x, 1000))  # Extend to bottom of the screen
	shape_points.append(Vector2(ground_points[0].x, 1000))  # Extend to bottom of the screen
	
	$StaticBody2D/CollisionPolygon2D.polygon = shape_points

func update_visual_representation():
	var line = $Line2D
	line.clear_points()
	for point in ground_points:
		line.add_point(point)

func update_filled_area():
	var poly_points = []
	
	# Add the ground points to the polygon
	for point in ground_points:
		poly_points.append(point)
	
	# Extend the polygon to the bottom of the screen
	var last_x = ground_points[-1].x
	var first_x = ground_points[0].x
	poly_points.append(Vector2(last_x, 1000))  # Bottom right corner
	poly_points.append(Vector2(first_x, 1000))  # Bottom left corner
	
	$Polygon2D.polygon = poly_points
	$Polygon2D.color = Color(1, 1, 1)  # Set to white
