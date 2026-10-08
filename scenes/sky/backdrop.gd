extends Node3D
## Sky backdrop: a sea of clouds under the level plus floating islands scattered
## around it, so the level never floats in an empty void. All procedural and static
## (a handful of MeshInstance3D sharing three meshes), so it costs almost nothing.

@export var seed_value := 7
@export var island_count := 26
@export var min_radius := 55.0
@export var max_radius := 170.0
## Slow vertical bobbing of the islands, in metres.
@export var bob_height := 0.6

var _islands: Array[Node3D] = []
var _phases: Array[float] = []
var _base_y: Array[float] = []
var _time := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var rock := StandardMaterial3D.new()
	rock.albedo_color = Color(0.46, 0.55, 0.68)
	rock.roughness = 0.95
	rock.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	var grass := StandardMaterial3D.new()
	grass.albedo_color = Color(0.55, 0.86, 0.78)
	grass.roughness = 0.9
	grass.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX

	var body := CylinderMesh.new()
	body.top_radius = 1.0
	body.bottom_radius = 0.0
	body.height = 1.0
	body.radial_segments = 7
	body.rings = 1
	body.cap_bottom = false
	body.material = rock
	var cap := CylinderMesh.new()
	cap.top_radius = 1.0
	cap.bottom_radius = 1.04
	cap.height = 0.12
	cap.radial_segments = 7
	cap.rings = 1
	cap.material = grass
	var rubble := PrismMesh.new()
	rubble.material = rock

	for i in island_count:
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(min_radius, max_radius)
		var radius := rng.randf_range(5.0, 17.0)
		var island := Node3D.new()
		island.position = Vector3(cos(angle) * dist, rng.randf_range(-34.0, -6.0), sin(angle) * dist)
		island.rotation.y = rng.randf() * TAU
		var depth := radius * rng.randf_range(0.9, 1.7)
		var body_mesh := MeshInstance3D.new()
		body_mesh.mesh = body
		body_mesh.scale = Vector3(radius, depth, radius)
		body_mesh.position.y = -depth * 0.5
		body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		island.add_child(body_mesh)
		var cap_mesh := MeshInstance3D.new()
		cap_mesh.mesh = cap
		cap_mesh.scale = Vector3(radius, 1.0, radius)
		cap_mesh.position.y = 0.09
		cap_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		island.add_child(cap_mesh)
		for k in rng.randi_range(1, 3):
			var pebble := MeshInstance3D.new()
			pebble.mesh = rubble
			var s := rng.randf_range(1.0, 3.2)
			pebble.scale = Vector3(s, s * rng.randf_range(0.8, 1.8), s)
			var a := rng.randf() * TAU
			pebble.position = Vector3(cos(a), 0.0, sin(a)) * radius * rng.randf_range(0.0, 0.6)
			pebble.rotation.y = rng.randf() * TAU
			pebble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			island.add_child(pebble)
		add_child(island)
		_islands.append(island)
		_phases.append(rng.randf() * TAU)
		_base_y.append(island.position.y)


func _process(delta: float) -> void:
	_time += delta
	for i in _islands.size():
		_islands[i].position.y = _base_y[i] + sin(_time * 0.35 + _phases[i]) * bob_height
