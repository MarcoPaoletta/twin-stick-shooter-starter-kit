extends Node
## Global game flow: level order, fade transitions and menu navigation.
## Registered as the `Game` autoload.

const MAIN_MENU := "res://ui/MainMenu.tscn"
const LEVELS: Array[String] = [
	"res://scenes/level1/level1.tscn",
	"res://scenes/level2/level2.tscn",
	"res://scenes/level3/level3.tscn",
	"res://scenes/level4/level4.tscn",
	"res://scenes/level5/level5.tscn",
]
const LEVEL_TITLES: Array[String] = ["Shooting Range", "Warehouse", "Barracks", "Foundry", "Citadel"]
## [keys, action] pairs shown in the main menu and the pause menu.
const CONTROLS: Array = [
	["W A S D", "Move"],
	["Mouse", "Look around"],
	["Left click", "Shoot"],
	["Space", "Jump"],
	["E", "First person / third person"],
	["Mouse wheel", "Zoom in / out"],
	["Esc", "Pause"],
]
const FADE_TIME := 0.3

var _fade_rect: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.03, 0.04, 0.07, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade_rect)


func start_game() -> void:
	go_to_level(0)


func go_to_level(index: int) -> void:
	_change_scene(LEVELS[clampi(index, 0, LEVELS.size() - 1)])


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU)


func restart_level() -> void:
	_change_scene("")


func next_level() -> void:
	if has_next_level():
		go_to_level(current_level_index() + 1)
	else:
		go_to_main_menu()


func has_next_level() -> bool:
	var index := current_level_index()
	return index >= 0 and index + 1 < LEVELS.size()


## Index of the running level in LEVELS, or -1 outside of a level.
func current_level_index() -> int:
	var scene := get_tree().current_scene
	if scene == null:
		return -1
	return LEVELS.find(scene.scene_file_path)


func quit() -> void:
	get_tree().quit()


## An empty path reloads the current scene.
func _change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await _fade_to(1.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if path.is_empty():
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", alpha, FADE_TIME)
	await tween.finished
