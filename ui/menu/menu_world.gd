extends Node3D
## Living background of the main menu: the real Level 3 without player, enemies or
## gameplay script, filmed by a camera director that hard-cuts between shots.

const WORLD := preload("res://scenes/level3/level3.tscn")

var director: MenuCameraDirector


func _ready() -> void:
	var world := WORLD.instantiate()
	world.set_script(null)
	for node in world.get_children():
		if node is PlayerEntity or node.is_in_group("enemy") or node is NavigationRegion3D:
			world.remove_child(node)
			node.free()
	add_child(world)

	director = MenuCameraDirector.new()
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	director.add_child(camera)

	# [start position, look target, end offset, duration, fov]
	var shots := [
		[Vector3(-8, 26, 70), Vector3(30, 0, 26), Vector3(30, -4, -6), 5.0, 48.0],
		[Vector3(14, 4.5, 44), Vector3(26, 1.5, 28), Vector3(8, 0.5, -4), 4.0, 70.0],
		[Vector3(64, 20, 4), Vector3(44, 0, 22), Vector3(-6, -3, 8), 4.5, 40.0],
		[Vector3(34, 9, 14), Vector3(40, 3, 6), Vector3(-10, 1, 6), 4.0, 62.0],
		[Vector3(4, 34, 28), Vector3(28, 0, 28), Vector3(0, -8, 0), 5.0, 55.0],
	]
	for s in shots:
		var shot := MenuCameraShot.new()
		shot.movement = MenuCameraShot.Movement.MOVE
		shot.end_offset = s[2]
		shot.duration = s[3]
		shot.fov = s[4]
		shot.look_at_target = true
		shot.look_target = s[1]
		director.add_child(shot)
		shot.position = s[0]
	add_child(director)
	camera.current = true
	director.active = true
