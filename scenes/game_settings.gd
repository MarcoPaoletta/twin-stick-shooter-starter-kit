class_name GameSettings
extends Resource
## Project-wide switches you can tweak in the inspector (res://scenes/game_settings.tres).

enum TouchMode {
	## On for mobile exports (iOS / Android, and Xogot on a phone or tablet), off on desktop.
	AUTO,
	## Always show the on-screen joystick and buttons (handy to preview them on desktop).
	ALWAYS_ON,
	## Never show them.
	ALWAYS_OFF,
}

@export var touch_controls: TouchMode = TouchMode.AUTO
## Size of the on-screen buttons and joystick.
@export_range(0.6, 1.6, 0.05) var touch_ui_scale := 1.0
## Camera turning speed when dragging on the right side of the screen.
@export_range(0.4, 3.0, 0.05) var touch_look_sensitivity := 1.0
