class_name OverlayMenu
extends Control
## Base of the full-screen overlay menus (pause, game over, level complete).
## Fades and pops in, hands the focus to a button, and forwards button presses
## as `action_requested`.

signal action_requested(action: StringName)

## Button that gets the focus when the menu opens (default: the first button).
@export var focus_on_open: Control

var _tween: Tween

@onready var _panel: Control = get_node_or_null("%Panel")


func _ready() -> void:
	visible = false
	modulate.a = 0.0
	if focus_on_open == null:
		var buttons := get_node_or_null("Center/Panel/Box/Buttons")
		if buttons and buttons.get_child_count() > 0:
			focus_on_open = buttons.get_child(0)
	if _panel:
		_panel.resized.connect(func() -> void: _panel.pivot_offset = _panel.size * 0.5)


func open() -> void:
	visible = true
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	if _panel:
		_panel.scale = Vector2(0.92, 0.92)
		_tween.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
	if focus_on_open:
		focus_on_open.grab_focus()


func close() -> void:
	if not visible:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_tween.tween_callback(func() -> void: visible = false)


func _on_action(action: StringName) -> void:
	action_requested.emit(action)
