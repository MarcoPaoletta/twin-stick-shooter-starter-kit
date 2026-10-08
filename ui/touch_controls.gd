class_name TouchOverlay
extends Control
## On-screen controls for phones and tablets: a floating joystick on the left half
## (movement) and buttons on the right (shoot, jump, camera view, zoom, pause).
## Dragging anywhere else on the right half, or dragging while holding Shoot, turns the camera.
## Everything is injected as normal input actions, so the gameplay code is untouched.

const ACCENT := Color(0.27, 0.62, 1.0)
const FILL := Color(0.04, 0.09, 0.2, 0.5)
const FILL_PRESSED := Color(0.27, 0.62, 1.0, 0.75)
const RING := Color(0.62, 0.86, 1.0, 0.8)
const ICON := Color(0.93, 0.97, 1.0, 0.95)
const JOY_RADIUS := 120.0
const DEADZONE := 0.18
const LOOK_BASE_SENSITIVITY := 1.7

class TouchButton:
	var id: StringName
	var action: StringName
	var center := Vector2.ZERO
	var radius := 70.0
	## Held buttons keep the action pressed (shoot); the others send a single press.
	var hold := false
	var look_while_held := false
	var finger := -1

	func hit(p: Vector2) -> bool:
		return p.distance_to(center) <= radius * 1.2

var _buttons: Array[TouchButton] = []
var _active := true
var _joy_finger := -1
var _joy_origin := Vector2.ZERO
var _joy_knob := Vector2.ZERO
var _joy_rest := Vector2.ZERO
var _look_finger := -1
var _scale := 1.0
var _look_sensitivity := 1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scale = Game.settings.touch_ui_scale
	_look_sensitivity = Game.settings.touch_look_sensitivity
	for def: Array in [
		[&"shoot", &"p1_shoot", true, true],
		[&"jump", &"p1_jump", false, false],
		[&"view", &"camera_toggle_view", false, false],
		[&"zoom_in", &"camera_zoom_in", false, false],
		[&"zoom_out", &"camera_zoom_out", false, false],
		[&"pause", &"p1_pause", false, false],
	]:
		var b := TouchButton.new()
		b.id = def[0]
		b.action = def[1]
		b.hold = def[2]
		b.look_while_held = def[3]
		_buttons.append(b)
	resized.connect(_layout)
	_layout()


func set_active(value: bool) -> void:
	if value == _active:
		return
	_active = value
	if not value:
		_release_everything()
	visible = value


func _layout() -> void:
	var m := Game.safe_margins()
	var left := m.x + 56.0 * _scale
	var top := m.y + 40.0 * _scale
	var right := size.x - m.z - 56.0 * _scale
	var bottom := size.y - m.w - 48.0 * _scale
	_joy_rest = Vector2(left + JOY_RADIUS * _scale + 40.0, bottom - JOY_RADIUS * _scale - 50.0)
	if _joy_finger == -1:
		_joy_knob = _joy_rest
		_joy_origin = _joy_rest
	var shoot := Vector2(right - 120.0 * _scale, bottom - 150.0 * _scale)
	_place(&"shoot", shoot, 112.0)
	_place(&"jump", shoot + Vector2(-235.0, 62.0) * _scale, 84.0)
	_place(&"view", shoot + Vector2(-125.0, -215.0) * _scale, 66.0)
	_place(&"zoom_in", Vector2(right - 46.0 * _scale, top + 170.0 * _scale), 42.0)
	_place(&"zoom_out", Vector2(right - 46.0 * _scale, top + 262.0 * _scale), 42.0)
	_place(&"pause", Vector2(right - 46.0 * _scale, top + 46.0 * _scale), 46.0)
	queue_redraw()


func _place(id: StringName, center: Vector2, radius: float) -> void:
	for b in _buttons:
		if b.id == id:
			b.center = center
			b.radius = radius * _scale


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index)
	elif event is InputEventScreenDrag:
		_touch_drag(event.index, event.position, event.relative)


func _touch_down(index: int, pos: Vector2) -> void:
	for b in _buttons:
		if b.finger == -1 and b.hit(pos):
			b.finger = index
			_send(b, true)
			queue_redraw()
			return
	if pos.x < size.x * 0.45:
		if _joy_finger == -1:
			_joy_finger = index
			_joy_origin = pos
			_joy_knob = pos
			queue_redraw()
	elif _look_finger == -1:
		_look_finger = index


func _touch_up(index: int) -> void:
	for b in _buttons:
		if b.finger == index:
			b.finger = -1
			_send(b, false)
			queue_redraw()
	if index == _joy_finger:
		_joy_finger = -1
		_joy_knob = _joy_rest
		_joy_origin = _joy_rest
		_apply_joystick(Vector2.ZERO)
		queue_redraw()
	if index == _look_finger:
		_look_finger = -1


func _touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	if index == _joy_finger:
		var offset := pos - _joy_origin
		var limit := JOY_RADIUS * _scale
		if offset.length() > limit:
			# the base follows the thumb when it is dragged past the edge
			_joy_origin += offset - offset.normalized() * limit
			offset = offset.normalized() * limit
		_joy_knob = _joy_origin + offset
		_apply_joystick(offset / limit)
		queue_redraw()
		return
	if index == _look_finger:
		_look(relative)
		return
	for b in _buttons:
		if b.finger == index and b.look_while_held:
			_look(relative)


func _look(relative: Vector2) -> void:
	var rig := get_tree().get_first_node_in_group("camera_rig") as CameraRig
	if rig:
		rig.look_input(relative * LOOK_BASE_SENSITIVITY * _look_sensitivity)


func _apply_joystick(v: Vector2) -> void:
	var length := v.length()
	var strength := 0.0
	if length > DEADZONE:
		strength = (length - DEADZONE) / (1.0 - DEADZONE)
	var dir := v.normalized() * strength if length > 0.0 else Vector2.ZERO
	_set_axis(&"p1_move_left", &"p1_move_right", dir.x)
	_set_axis(&"p1_move_up", &"p1_move_down", dir.y)


func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	_set_action(negative, maxf(-value, 0.0))
	_set_action(positive, maxf(value, 0.0))


func _set_action(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _send(b: TouchButton, pressed: bool) -> void:
	if b.hold:
		if pressed:
			Input.action_press(b.action)
		else:
			Input.action_release(b.action)
		return
	var ev := InputEventAction.new()
	ev.action = b.action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _release_everything() -> void:
	for b in _buttons:
		if b.finger != -1:
			b.finger = -1
			_send(b, false)
	_joy_finger = -1
	_look_finger = -1
	_joy_knob = _joy_rest
	_joy_origin = _joy_rest
	_apply_joystick(Vector2.ZERO)
	queue_redraw()


func _exit_tree() -> void:
	_release_everything()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var joy_active := _joy_finger != -1
	var base_alpha := 1.0 if joy_active else 0.55
	var r := JOY_RADIUS * _scale
	draw_circle(_joy_origin, r, Color(FILL, FILL.a * base_alpha))
	draw_arc(_joy_origin, r, 0.0, TAU, 64, Color(RING, RING.a * base_alpha), 4.0, true)
	draw_circle(_joy_knob, r * 0.42, Color(ACCENT, 0.85 if joy_active else 0.45))
	draw_arc(_joy_knob, r * 0.42, 0.0, TAU, 40, Color(ICON, 0.9 * base_alpha), 3.0, true)
	for b in _buttons:
		var pressed := b.finger != -1
		draw_circle(b.center, b.radius, FILL_PRESSED if pressed else FILL)
		draw_arc(b.center, b.radius, 0.0, TAU, 64, RING, 4.0, true)
		_draw_icon(b)


func _draw_icon(b: TouchButton) -> void:
	var c := b.center
	var r := b.radius
	match b.id:
		&"shoot":
			draw_arc(c, r * 0.42, 0.0, TAU, 40, ICON, 5.0, true)
			for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				draw_line(c + d * r * 0.3, c + d * r * 0.6, ICON, 5.0, true)
			draw_circle(c, r * 0.07, ICON)
		&"jump":
			for i in 2:
				var y := r * (0.12 - 0.3 * i)
				draw_polyline(PackedVector2Array([c + Vector2(-r * 0.36, y + r * 0.2), c + Vector2(0, y - r * 0.14), c + Vector2(r * 0.36, y + r * 0.2)]), ICON, 6.0, true)
		&"view":
			var pts := PackedVector2Array()
			for i in 33:
				var t := TAU * i / 32.0
				pts.append(c + Vector2(cos(t) * r * 0.56, sin(t) * r * 0.3 * absf(sin(t * 0.5)) * 2.0 * 0.5 + sin(t) * r * 0.12))
			draw_polyline(pts, ICON, 5.0, true)
			draw_circle(c, r * 0.2, ICON)
		&"pause":
			draw_rect(Rect2(c + Vector2(-r * 0.3, -r * 0.34), Vector2(r * 0.2, r * 0.68)), ICON)
			draw_rect(Rect2(c + Vector2(r * 0.1, -r * 0.34), Vector2(r * 0.2, r * 0.68)), ICON)
		&"zoom_in":
			draw_line(c + Vector2(-r * 0.4, 0), c + Vector2(r * 0.4, 0), ICON, 6.0, true)
			draw_line(c + Vector2(0, -r * 0.4), c + Vector2(0, r * 0.4), ICON, 6.0, true)
		&"zoom_out":
			draw_line(c + Vector2(-r * 0.4, 0), c + Vector2(r * 0.4, 0), ICON, 6.0, true)
