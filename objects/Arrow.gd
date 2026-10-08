extends RigidBody3D
class_name Arrow
## Fast, almost straight bullet. It leaves a bright tracer, vanishes with a spark
## when it hits the level or an enemy, and is gone after a short flight.

signal exploded

@export var initial_velocity := 90.0
## Real bullets drop a little over distance; this keeps it subtle but visible.
@export var gravity_factor := 0.12
@export var max_lifetime := 2.5

const TRACER_COLOR := Color(0.55, 0.9, 1.0)

var _spent := false
var _age := 0.0

@onready var _body_mesh: MeshInstance3D = $ArrowBody
@onready var _head_mesh: MeshInstance3D = $ArrowHead
@onready var _impact_mesh: MeshInstance3D = $ImpactMesh


func _ready() -> void:
	gravity_scale = gravity_factor
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 2
	linear_damp = 0.0
	angular_damp = 10.0
	_impact_mesh.visible = false
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = TRACER_COLOR
	mat.emission_enabled = true
	mat.emission = TRACER_COLOR
	mat.emission_energy_multiplier = 2.0
	_body_mesh.material_override = mat
	_head_mesh.material_override = mat
	# thin tracer instead of a fat arrow
	_body_mesh.scale = Vector3(0.28, 0.5, 0.28)
	_body_mesh.position.z = 0.0
	_head_mesh.visible = false
	_body_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body_entered.connect(_on_body_hit)


func _physics_process(delta: float) -> void:
	_age += delta
	if _spent:
		return
	# The enemy's hit area removes the bullet from the group when it lands a hit.
	if not is_in_group("bullet") or _age > max_lifetime:
		_impact()
		return
	if linear_velocity.length_squared() > 1.0:
		look_at(global_position + linear_velocity.normalized(), Vector3.UP)


func _on_body_hit(_body: Node) -> void:
	_impact()


func _impact() -> void:
	if _spent:
		return
	_spent = true
	exploded.emit()
	get_tree().call_group("sfx", "play_impact", global_position)
	_spawn_spark()
	queue_free()


func _spawn_spark() -> void:
	var sparks := CPUParticles3D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.amount = 10
	sparks.lifetime = 0.35
	sparks.explosiveness = 1.0
	sparks.direction = -linear_velocity.normalized()
	sparks.spread = 70.0
	sparks.initial_velocity_min = 3.0
	sparks.initial_velocity_max = 8.0
	sparks.gravity = Vector3(0, -14, 0)
	sparks.scale_amount_min = 0.5
	sparks.scale_amount_max = 1.0
	var quad := BoxMesh.new()
	quad.size = Vector3(0.06, 0.06, 0.18)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.85, 0.5)
	quad.material = m
	sparks.mesh = quad
	get_tree().current_scene.add_child(sparks)
	sparks.global_position = global_position
	sparks.emitting = true
	get_tree().create_timer(0.8).timeout.connect(sparks.queue_free)
