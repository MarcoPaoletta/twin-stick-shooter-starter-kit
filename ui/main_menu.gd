extends Control
## Title screen: play, level select and quit.

@onready var _play_button: Button = %PlayButton
@onready var _levels_button: Button = %LevelsButton
@onready var _quit_button: Button = %QuitButton
@onready var _levels_panel: Control = %LevelsList
@onready var _level_rows: VBoxContainer = %LevelRows
@onready var _left_column: Control = %LeftColumn
@onready var _right_column: Control = %RightColumn


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play_music(&"menu")
	var world := Node3D.new()
	world.set_script(load("res://ui/menu/menu_world.gd"))
	add_child(world)
	move_child(world, 0)
	_build_levels()
	_play_button.pressed.connect(Game.start_game)
	_levels_button.pressed.connect(_show_panel.bind(_levels_panel))
	_quit_button.pressed.connect(Game.quit)
	_quit_button.visible = not OS.has_feature("web")
	_levels_panel.visible = true
	_right_column.visible = false
	_play_button.grab_focus()
	_animate_in()


func _build_levels() -> void:
	for i in Game.LEVELS.size():
		var button := Button.new()
		button.text = "%d   %s" % [i + 1, Game.LEVEL_TITLES[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 58
		button.pressed.connect(Game.go_to_level.bind(i))
		_level_rows.add_child(button)


func _show_panel(_panel: Control) -> void:
	_right_column.visible = not _right_column.visible


func _animate_in() -> void:
	_left_column.modulate.a = 0.0
	_right_column.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_left_column, "modulate:a", 1.0, 0.6)
	tween.tween_property(_right_column, "modulate:a", 1.0, 0.6).set_delay(0.2)
	_left_column.position.x = -40.0
	tween.tween_property(_left_column, "position:x", 0.0, 0.6)
