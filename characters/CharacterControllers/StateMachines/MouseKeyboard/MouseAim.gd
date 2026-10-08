extends PlayerState
## Mouse and keyboard aiming. The character always faces where the camera looks,
## the weapon stays drawn and the shoot action (left click) fires continuously.

const ARROW := preload("res://objects/Arrow.tscn")
## world (2) + objects (8) + enemies (16)
const AIM_RAY_MASK := 2 | 8 | 16
const AIM_RANGE := 150.0
const ARROW_SPEED := 90.0

@export var fire_interval := 0.16

var _cooldown := 0.0


func enter(msg := {}) -> void:
	super(msg) # emits enter_state, which the movement states listen to
	player.model.play_aiming(true)


func process(delta: float) -> void:
	var rig := player.camera_rig
	_cooldown = maxf(_cooldown - delta, 0.0)

	# Turn faster in first person so the weapon never trails behind the view.
	var turn_speed := 4.0 if rig.is_first_person_active() else 1.0
	player.model.orient_model_to_direction(rig.get_flat_aim_direction(), minf(delta * turn_speed, 0.08))

	if _cooldown <= 0.0 and rig.can_shoot() and Input.is_action_pressed("p1_shoot"):
		_cooldown = fire_interval
		_shoot(rig)


func _shoot(rig: CameraRig) -> void:
	var origin: Vector3
	var direction: Vector3
	if rig.is_first_person_active():
		# Start next to the eye and converge on whatever the crosshair points at.
		var eye := rig.get_eye_position()
		var look := rig.get_aim_direction()
		origin = rig.get_muzzle_position()
		direction = (_find_aim_point(eye, look) - origin).normalized()
	else:
		origin = player.shoot_anchor.global_position
		direction = rig.get_flat_aim_direction()

	var arrow: Arrow = ARROW.instantiate()
	arrow.initial_velocity = ARROW_SPEED
	get_tree().current_scene.add_child(arrow)
	arrow.add_collision_exception_with(player)
	arrow.global_transform = Transform3D(Basis.looking_at(-direction, Vector3.UP), origin)
	arrow.apply_central_impulse(direction * arrow.initial_velocity)
	# The third-person muzzle flash sits on the character model, so it only plays there;
	# in first person the viewmodel shows its own flash at the barrel.
	if not rig.is_first_person_active():
		player.model.play_shooting(true)
	get_tree().call_group("crosshair", "kick")
	Audio.play(&"shot", -5.0)
	get_tree().call_group("viewmodel", "kick")


func _find_aim_point(from: Vector3, direction: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * AIM_RANGE, AIM_RAY_MASK)
	query.exclude = [player.get_rid()]
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return from + direction * AIM_RANGE
	return hit.position
