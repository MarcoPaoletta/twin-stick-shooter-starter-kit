class_name CameraRig
extends Node3D
## Mouse-driven orbit camera with a smooth swap to a first-person view from the
## player's head. Sits on PlayerEntity/CameraPivot, which carries the yaw.
## The camera is placed here every frame, so the rig owns its whole transform.

signal view_changed(first_person: bool)

# From straight above (-89) down to nearly eye level (-3): the whole vertical range
# the orbit can use without the camera dipping under the floor.
const THIRD_PERSON_PITCH_MIN := deg_to_rad(-89.0)
const THIRD_PERSON_PITCH_MAX := deg_to_rad(-3.0)
const FIRST_PERSON_PITCH_LIMIT := deg_to_rad(89.0)
const ZOOM_STEP := 0.88
const FOV_STEP := 6.0

@export_group("Look")
@export var mouse_sensitivity := 0.0022
## Right-stick look speed in radians per second.
@export var stick_sensitivity := 2.6

@export_group("Third person")
@export var default_distance := 42.5
@export var min_distance := 5.0
@export var max_distance := 80.0
@export_range(-89.0, -5.0, 0.5, "degrees") var default_pitch_deg := -30.0
@export_range(10.0, 90.0, 0.1) var third_person_fov := 30.9

@export_group("First person")
@export_range(30.0, 100.0, 0.5) var first_person_fov := 75.0
@export var min_first_person_fov := 30.0
@export var max_first_person_fov := 100.0
@export var transition_time := 0.7

## True once the player asked for the first-person view (the camera may still be moving).
var first_person := false
## 0 = third person, 1 = first person. Tweened when the view changes.
var view_blend := 0.0
var mouse_enabled := false
var mouse_owner: Node = null

var _yaw := 0.0
var _third_person_pitch := 0.0
var _first_person_pitch := 0.0
var _distance := 0.0
var _distance_target := 0.0
var _fov := 0.0
var _fov_target := 0.0
var _tween: Tween

@onready var camera: Camera3D = $ThirdPersonCamera
@onready var _head: Node3D = get_node_or_null("../HeadAnchor")
@onready var _crosshair: CanvasItem = get_node_or_null("../Crosshair")
@onready var _body: Node3D = get_node_or_null("../IcySkin/Armature/Skeleton3D/body")
@onready var _skin_gun: Node3D = get_node_or_null("../IcySkin/Armature/Skeleton3D/BoneAttachment3D")
var _viewmodel: Viewmodel


func _ready() -> void:
	add_to_group("camera_rig")
	_yaw = rotation.y
	_third_person_pitch = deg_to_rad(default_pitch_deg)
	_distance = default_distance
	_distance_target = default_distance
	_fov = first_person_fov
	_fov_target = first_person_fov
	camera.top_level = true
	camera.current = true
	_viewmodel = Viewmodel.new()
	_viewmodel.name = "Viewmodel"
	camera.add_child(_viewmodel)
	_viewmodel.owner = null
	if mouse_enabled:
		capture_mouse()
	_update_camera(0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not mouse_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(event.screen_relative * mouse_sensitivity)
		if _viewmodel:
			_viewmodel.add_look(event.screen_relative)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Clicking the window gives the mouse back to the camera (after alt-tab, for example).
		capture_mouse()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_toggle_view"):
		toggle_view()
	elif event.is_action_pressed("camera_zoom_in"):
		_zoom(-1)
	elif event.is_action_pressed("camera_zoom_out"):
		_zoom(1)


func _process(delta: float) -> void:
	if mouse_enabled:
		_look(Input.get_vector("p1_aim_left", "p1_aim_right", "p1_aim_up", "p1_aim_down") * stick_sensitivity * delta)
		rotation.y = _yaw
	else:
		_yaw = rotation.y
	_update_camera(delta)


func acquire_mouse(by: Node) -> void:
	mouse_owner = by
	mouse_enabled = true
	if is_node_ready():
		capture_mouse()


func release_mouse(by: Node) -> void:
	if mouse_owner != by:
		return
	mouse_owner = null
	mouse_enabled = false
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func capture_mouse() -> void:
	if mouse_enabled and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func toggle_view() -> void:
	set_first_person(not first_person)


func set_first_person(value: bool) -> void:
	if value == first_person:
		return
	first_person = value
	Audio.play(&"whoosh", -10.0, 0.05)
	if value:
		_first_person_pitch = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "view_blend", 1.0 if value else 0.0, transition_time)
	view_changed.emit(value)


## Called by the player when it dies: pull back to the third person view and free the mouse.
func on_player_died() -> void:
	set_first_person(false)
	if mouse_owner:
		release_mouse(mouse_owner)


## True once the camera has (almost) reached the head.
func is_first_person_active() -> bool:
	return first_person and view_blend > 0.85


func can_shoot() -> bool:
	return mouse_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


func get_eye_position() -> Vector3:
	if _head:
		return _head.global_position
	return global_position + Vector3.UP * 0.7


## Yaw and pitch of the first person view as a basis.
func get_aim_basis() -> Basis:
	return Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, _first_person_pitch)


## Where the crosshair points (first person view).
func get_aim_direction() -> Vector3:
	return get_aim_basis() * Vector3.FORWARD


## Horizontal direction the camera looks at; the character faces it.
func get_flat_aim_direction() -> Vector3:
	return Basis(Vector3.UP, _yaw) * Vector3.FORWARD


func _look(delta: Vector2) -> void:
	_yaw -= delta.x
	if first_person:
		_first_person_pitch = clampf(_first_person_pitch - delta.y, -FIRST_PERSON_PITCH_LIMIT, FIRST_PERSON_PITCH_LIMIT)
	else:
		_third_person_pitch = clampf(_third_person_pitch - delta.y, THIRD_PERSON_PITCH_MIN, THIRD_PERSON_PITCH_MAX)


func _zoom(direction: int) -> void:
	if first_person:
		_fov_target = clampf(_fov_target + direction * FOV_STEP, min_first_person_fov, max_first_person_fov)
	else:
		_distance_target = clampf(_distance_target * pow(1.0 / ZOOM_STEP, direction), min_distance, max_distance)


## Tells the level material which walls stand between the camera and the player.
func _update_wall_fade() -> void:
	RenderingServer.global_shader_parameter_set("fade_cam_pos", camera.global_position)
	RenderingServer.global_shader_parameter_set("fade_target_pos", global_position + Vector3.UP * 1.1)
	RenderingServer.global_shader_parameter_set("fade_enabled", 1.0 - smoothstep(0.0, 0.5, view_blend))


func get_muzzle_position() -> Vector3:
	if _viewmodel and _viewmodel.muzzle:
		return _viewmodel.muzzle.global_position
	return get_eye_position()


func _exit_tree() -> void:
	RenderingServer.global_shader_parameter_set("fade_enabled", 0.0)


func _update_camera(delta: float) -> void:
	var smoothing := 1.0 - exp(-12.0 * delta)
	_distance = lerpf(_distance, _distance_target, smoothing)
	_fov = lerpf(_fov, _fov_target, smoothing)

	var yaw_basis := Basis(Vector3.UP, _yaw)
	var orbit_basis := yaw_basis * Basis(Vector3.RIGHT, _third_person_pitch)
	var pivot_point := global_position + Vector3.UP * 1.0
	var third_person := Transform3D(orbit_basis, pivot_point + orbit_basis * Vector3(0.0, 0.0, _distance))
	var first_person_basis := yaw_basis * Basis(Vector3.RIGHT, _first_person_pitch)
	var first_person_transform := Transform3D(first_person_basis, get_eye_position())

	camera.global_transform = third_person.interpolate_with(first_person_transform, view_blend)
	camera.fov = lerpf(third_person_fov, _fov, view_blend)

	if _body:
		_body.visible = view_blend < 0.96
	if _skin_gun:
		_skin_gun.visible = view_blend < 0.96
	if _viewmodel:
		_viewmodel.visible = view_blend > 0.96
	# A tight near/far range keeps depth precision high, which avoids z-fighting.
	camera.near = lerpf(0.5, 0.05, view_blend)
	camera.far = 700.0
	_update_wall_fade()
	if _crosshair:
		var alpha := clampf((view_blend - 0.6) / 0.4, 0.0, 1.0)
		_crosshair.modulate.a = alpha
		_crosshair.visible = alpha > 0.0
