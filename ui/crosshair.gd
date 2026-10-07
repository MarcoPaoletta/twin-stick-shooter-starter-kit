extends Control
## Dynamic crosshair for the first person view: the gap widens while moving and
## kicks when firing. The camera rig fades it in and out.

@export var color := Color(1, 1, 1, 0.95)
@export var outline_color := Color(0, 0, 0, 0.6)
@export var base_gap := 10.0
@export var arm_length := 16.0

var _gap := 10.0
var _kick := 0.0

@onready var _player := get_parent() as CharacterBody3D


func _ready() -> void:
	add_to_group("crosshair")
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func kick() -> void:
	_kick = 12.0


func _process(delta: float) -> void:
	if not visible:
		return
	var speed := _player.velocity.length() if _player else 0.0
	var target := base_gap + clampf(speed * 0.6, 0.0, 10.0) + _kick
	_gap = lerpf(_gap, target, 1.0 - exp(-16.0 * delta))
	_kick = lerpf(_kick, 0.0, 1.0 - exp(-14.0 * delta))
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var dirs: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for dir in dirs:
		draw_line(center + dir * (_gap - 1.0), center + dir * (_gap + arm_length + 1.0), outline_color, 8.0, true)
	draw_circle(center, 5.0, outline_color)
	for dir in dirs:
		draw_line(center + dir * _gap, center + dir * (_gap + arm_length), color, 4.0, true)
	draw_circle(center, 3.0, color)
