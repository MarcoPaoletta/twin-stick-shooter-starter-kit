extends OverlayMenu

@onready var _level_label: Label = %LevelLabel
@onready var _next_button: Button = %NextButton


func set_level(level_name: String, has_next: bool) -> void:
	_level_label.text = level_name
	_next_button.text = "Next level" if has_next else "Back to menu"
