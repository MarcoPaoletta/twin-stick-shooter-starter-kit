extends Control
## Title screen: play, level select, controls overview and quit.

@onready var _play_button: Button = %PlayButton
@onready var _levels_button: Button = %LevelsButton
@onready var _controls_button: Button = %ControlsButton
@onready var _quit_button: Button = %QuitButton
@onready var _controls_panel: Control = %ControlsList
@onready var _levels_panel: Control = %LevelsList
@onready var _control_rows: VBoxContainer = %ControlRows
@onready var _level_rows: VBoxContainer = %LevelRows
@onready var _left_column: Control = %LeftColumn
@onready var _right_column: Control = %RightColumn


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_controls()
	_build_levels()
	_play_button.pressed.connect(Game.start_game)
	_levels_button.pressed.connect(_show_panel.bind(_levels_panel))
	_controls_button.pressed.connect(_show_panel.bind(_controls_panel))
	_quit_button.pressed.connect(Game.quit)
	_quit_button.visible = not OS.has_feature("web")
	_show_panel(_controls_panel)
	_play_button.grab_focus()
	_animate_in()


func _build_controls() -> void:
	for entry: Array in Game.CONTROLS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		var keys := Label.new()
		keys.theme_type_variation = &"KeyLabel"
		keys.text = entry[0]
		keys.custom_minimum_size.x = 210
		var action := Label.new()
		action.text = entry[1]
		row.add_child(keys)
		row.add_child(action)
		_control_rows.add_child(row)


func _build_levels() -> void:
	for i in Game.LEVELS.size():
		var button := Button.new()
		button.text = "%d   %s" % [i + 1, Game.LEVEL_TITLES[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 58
		button.pressed.connect(Game.go_to_level.bind(i))
		_level_rows.add_child(button)


func _show_panel(panel: Control) -> void:
	_controls_panel.visible = panel == _controls_panel
	_levels_panel.visible = panel == _levels_panel


func _animate_in() -> void:
	_left_column.modulate.a = 0.0
	_right_column.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_left_column, "modulate:a", 1.0, 0.6)
	tween.tween_property(_right_column, "modulate:a", 1.0, 0.6).set_delay(0.2)
	_left_column.position.x = -40.0
	tween.tween_property(_left_column, "position:x", 0.0, 0.6)
