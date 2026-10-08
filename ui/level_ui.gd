extends CanvasLayer
## In-level UI: level banner, control hints, pause, game over and level complete.
## Instanced by the level manager.

enum State { PLAYING, PAUSED, GAME_OVER, COMPLETE }

var state := State.PLAYING

@onready var _pause_menu: OverlayMenu = $PauseMenu
@onready var _game_over_menu: OverlayMenu = $GameOverMenu
@onready var _complete_menu: OverlayMenu = $LevelCompleteMenu
@onready var _banner: Control = %Banner
@onready var _banner_title: Label = %BannerTitle
@onready var _banner_subtitle: Label = %BannerSubtitle
@onready var _hint: Control = %Hint


var _touch: TouchOverlay


func _ready() -> void:
	if Game.touch_enabled():
		_touch = TouchOverlay.new()
		_touch.name = "TouchControls"
		$Hud.add_child(_touch)
		_hint.hide()
	for menu: OverlayMenu in [_pause_menu, _game_over_menu, _complete_menu]:
		menu.action_requested.connect(_on_action)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("p1_pause"):
		return
	match state:
		State.PLAYING:
			pause()
		State.PAUSED:
			resume()
		_:
			return
	get_viewport().set_input_as_handled()


func show_banner(title: String, subtitle: String) -> void:
	_banner_title.text = title
	_banner_subtitle.text = subtitle
	_banner.modulate.a = 0.0
	_banner.position.y = -20.0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_interval(0.5)
	tween.set_parallel()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.5)
	tween.tween_property(_banner, "position:y", 0.0, 0.5)
	tween.chain().tween_interval(2.6)
	tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.8)


func pause() -> void:
	state = State.PAUSED
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hint.hide()
	if _touch:
		_touch.set_active(false)
	Audio.set_music_ducked(true)
	_pause_menu.open()


func resume() -> void:
	state = State.PLAYING
	get_tree().paused = false
	_hint.visible = _touch == null
	if _touch:
		_touch.set_active(true)
	Audio.set_music_ducked(false)
	_pause_menu.close()
	get_tree().call_group("camera_rig", "capture_mouse")


func show_game_over(delay := 1.4) -> void:
	if state == State.GAME_OVER or state == State.COMPLETE:
		return
	state = State.GAME_OVER
	_hint.hide()
	if _touch:
		_touch.set_active(false)
	Audio.play(&"lose", -4.0, 0.0)
	await get_tree().create_timer(delay).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.set_music_ducked(true)
	_game_over_menu.open()


func show_complete(level_name: String, has_next: bool) -> void:
	if state == State.GAME_OVER or state == State.COMPLETE:
		return
	state = State.COMPLETE
	_hint.hide()
	if _touch:
		_touch.set_active(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play(&"win", -4.0, 0.0)
	Audio.set_music_ducked(true)
	_complete_menu.set_level(level_name, has_next)
	_complete_menu.open()


func _on_action(action: StringName) -> void:
	match action:
		&"resume":
			resume()
		&"restart":
			Game.restart_level()
		&"next":
			Game.next_level()
		&"menu":
			Game.go_to_main_menu()
		&"quit":
			Game.quit()
