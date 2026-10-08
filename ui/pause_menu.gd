extends OverlayMenu
## Pause menu. Also lets the player switch the control scheme.

const SCHEME_NAMES: Array[String] = [
	"Mouse + keyboard",
	"Gamepad: one stick",
	"Gamepad: two sticks",
	"Gamepad: auto-shoot",
]

@export var game_data: GameDataStore

@onready var _scheme_option: OptionButton = %SchemeOption


func _ready() -> void:
	super._ready()
	for scheme_name in SCHEME_NAMES:
		_scheme_option.add_item(scheme_name)
	_scheme_option.select(game_data.controller_scheme)
	_scheme_option.item_selected.connect(_on_scheme_selected)
	# Touch devices use the on-screen controls, there is no scheme to pick.
	%SchemeRow.visible = not Game.touch_enabled()


func open() -> void:
	_scheme_option.select(game_data.controller_scheme)
	super.open()


func _on_scheme_selected(index: int) -> void:
	game_data.controller_scheme = index
