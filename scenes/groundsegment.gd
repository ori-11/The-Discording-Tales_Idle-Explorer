extends Node2D

var segment_width = 40  # Consistent width throughout
var max_height_diff = 100  # Height variation for hills
var min_y = 200
var max_y = 350
var ground_points = []  # Points for the white line
var red_ground_points = []  # Points for the red line
var last_generated_x = 0

var look_ahead_distance = 300  # Generate this much further ahead of the camera
var retain_distance = 600  # Keep this much distance behind the camera before deleting points
var generate_behind_distance = 600  # Start generating this much behind the camera

var large_hill_frequency = 0.1  # Chance for a large hill to start (10%)
var large_hill_segments = 8  # Number of segments for the large hill
var in_large_hill = false  # Track if currently generating a large hill
var large_hill_remaining_segments = 0  # Remaining segments for the current large hill

func reset_ground():
	ground_points.clear()
	red_ground_points.clear()
	last_generated_x = 0
	in_large_hill = false
	large_hill_remaining_segments = 0
	var camera_bounds = get_camera_bounds()
	last_generated_x = camera_bounds.position.x - generate_behind_distance  # Start generating behind the camera
	generate_ground_until(camera_bounds.position.x + camera_bounds.size.x + look_ahead_distance)
	update_collision_shape()
	update_visual_representation()
	update_filled_area()

func _ready():
	randomize()  # Seed the random number generator
	reset_ground()

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
	var y_white = randi_range(min_y, max_y) if ground_points.size() == 0 else ground_points[-1].y
	var y_red = y_white + randi_range(0, 100)  # Start the red line slightly above the white line
	
	while last_generated_x < end_x:
		var prev_y_white = y_white
		var prev_y_red = y_red
		
		# Determine if we should start or continue a large hill
		var height_diff = max_height_diff
		if in_large_hill:
			height_diff = max_height_diff * 2  # Increase height variation for large hills
			large_hill_remaining_segments -= 1
			if large_hill_remaining_segments <= 0:
				in_large_hill = false
		else:
			if randf() < large_hill_frequency:
				in_large_hill = true
				large_hill_remaining_segments = large_hill_segments
				height_diff = max_height_diff * 10  # Start a large hill with increased height variation
		
		var y_offset_white = randi_range(-height_diff, height_diff) * 0.2  # Moderate multiplier for smoother hills
		y_white = clamp(prev_y_white + y_offset_white, min_y, max_y)
		
		# Generate a smooth red line above the white line
		var y_offset_red = randi_range(-height_diff * 0.05, height_diff * 0.05)  # Smaller variation for smoother hills
		y_red = clamp(prev_y_red + y_offset_red, y_white + 30, max_y)

		# Apply smoothing by averaging with previous points for both white and red lines
		if ground_points.size() > 1:
			var smooth_factor_white = 0.2
			y_white = y_white * smooth_factor_white + ground_points[-1].y * (1.0 - smooth_factor_white)
		
		if red_ground_points.size() > 1:
			var smooth_factor_red = 0.2
			y_red = y_red * smooth_factor_red + red_ground_points[-1].y * (1.0 - smooth_factor_red)
		
		ground_points.append(Vector2(last_generated_x, y_white))
		red_ground_points.append(Vector2(last_generated_x, y_red))
		
		last_generated_x += segment_width  # Move forward by segment width

func remove_old_points(min_x):
	while ground_points.size() > 0 and ground_points[0].x < min_x:
		ground_points.pop_front()
		red_ground_points.pop_front()

func update_collision_shape():
	var shape_points = []
	for point in ground_points:
		shape_points.append(point)
	shape_points.append(Vector2(ground_points[-1].x, 1000))  # Extend to bottom of the screen
	shape_points.append(Vector2(ground_points[0].x, 1000))  # Extend to bottom of the screen
	
	$StaticBody2D/CollisionPolygon2D.polygon = shape_points

func update_visual_representation():
	var line_white = $Line2D
	line_white.clear_points()
	for point in ground_points:
		line_white.add_point(point)

	var line_red = $Line2D_Red  # Assuming you have another Line2D node for the red line
	line_red.clear_points()
	for point in red_ground_points:
		line_red.add_point(point)

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
