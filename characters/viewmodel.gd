class_name Viewmodel
extends Node3D
## First person weapon. Child of the camera, held low on the right. It never plays the
## character's animations, so it stays steady while the character runs; the only
## motion is a soft sway when looking around, a gentle bob and the shot recoil.

const GUN_SCENE := preload("res://objects/laser-gun-design1.glb")

@export var rest_position := Vector3(0.26, -0.24, -0.5)
@export var gun_scale := 0.11
@export var sway_amount := 0.0009
@export var bob_amount := 0.004

var muzzle: Marker3D
var _flash: MeshInstance3D
var _flash_tween: Tween
var _gun: Node3D
var _look_delta := Vector2.ZERO
var _recoil := 0.0
var _bob_time := 0.0
var _offset := Vector3.ZERO
var _tilt := Vector3.ZERO

@onready var _player := owner as CharacterBody3D


func _ready() -> void:
	add_to_group("viewmodel")
	_gun = GUN_SCENE.instantiate()
	_gun.scale = Vector3.ONE * gun_scale
	# The model's barrel points along -Z; tilt the grip slightly inwards.
	_gun.rotation_degrees = Vector3(0.0, 0.0, 0.0)
	add_child(_gun)
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0, 0.0, -0.38)
	add_child(muzzle)
	for mesh in _gun.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash = MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.035
	ball.height = 0.07
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.7, 0.95, 1.0)
	ball.material = mat
	_flash.mesh = ball
	_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash.visible = false
	muzzle.add_child(_flash)
	position = rest_position
	visible = false


func add_look(delta: Vector2) -> void:
	_look_delta += delta


func kick() -> void:
	_recoil = 1.0
	if _flash_tween:
		_flash_tween.kill()
	_flash.visible = true
	_flash.scale = Vector3.ONE * randf_range(0.8, 1.2)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "scale", Vector3.ZERO, 0.07)
	_flash_tween.tween_callback(func() -> void: _flash.visible = false)


func _process(delta: float) -> void:
	if not visible:
		return
	var speed := 0.0
	if _player and _player.is_on_floor():
		speed = Vector2(_player.velocity.x, _player.velocity.z).length()
	var move_factor := clampf(speed / 15.0, 0.0, 1.0)
	_bob_time += delta * (6.0 + move_factor * 4.0)
	var bob := Vector3(cos(_bob_time * 0.5) * bob_amount, absf(sin(_bob_time * 0.5)) * bob_amount, 0.0) * move_factor

	var target_offset := Vector3(-_look_delta.x, _look_delta.y, 0.0) * sway_amount + bob
	_look_delta = _look_delta.lerp(Vector2.ZERO, 1.0 - exp(-20.0 * delta))
	_offset = _offset.lerp(target_offset, 1.0 - exp(-10.0 * delta))
	_recoil = lerpf(_recoil, 0.0, 1.0 - exp(-16.0 * delta))

	position = rest_position + _offset + Vector3(0.0, 0.0, _recoil * 0.07)
	var target_tilt := Vector3(_recoil * 0.12 + _offset.y * 2.0, -_offset.x * 3.0, 0.0)
	_tilt = _tilt.lerp(target_tilt, 1.0 - exp(-18.0 * delta))
	rotation = _tilt
