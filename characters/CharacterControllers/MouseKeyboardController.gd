extends CharacterController
## WASD + mouse scheme. The camera rig reads the mouse itself, so this controller
## only has to hand the mouse over to it while the scheme is active.


func _ready() -> void:
	super._ready()
	var rig := get_parent().get_node_or_null("CameraPivot") as CameraRig
	if rig:
		rig.acquire_mouse(self)


func _exit_tree() -> void:
	var parent := get_parent()
	var rig := parent.get_node_or_null("CameraPivot") as CameraRig if parent else null
	if rig:
		rig.release_mouse(self)


# The base class turns the camera with the right trigger axes; the mouse does that now.
func _update_player_input() -> void:
	pass
