extends Node
## Audio autoload: crossfaded looping music, pooled one-shot SFX, and automatic
## click/hover sounds for every button in the game.

const SFX := {
	&"shot": preload("res://audio/sfx/shot.wav"),
	&"impact": preload("res://audio/sfx/impact.wav"),
	&"enemy_hit": preload("res://audio/sfx/enemy_hit.wav"),
	&"enemy_die": preload("res://audio/sfx/enemy_die.wav"),
	&"player_hurt": preload("res://audio/sfx/player_hurt.wav"),
	&"jump": preload("res://audio/sfx/jump.wav"),
	&"land": preload("res://audio/sfx/land.wav"),
	&"click": preload("res://audio/sfx/click.wav"),
	&"hover": preload("res://audio/sfx/hover.wav"),
	&"win": preload("res://audio/sfx/win.wav"),
	&"lose": preload("res://audio/sfx/lose.wav"),
	&"whoosh": preload("res://audio/sfx/whoosh.wav"),
}
const MUSIC := {
	&"menu": preload("res://audio/music/music_menu.mp3"),
	&"level": preload("res://audio/music/music_level.mp3"),
	&"hard": preload("res://audio/music/music_level_hard.mp3"),
}
const POOL_SIZE := 16
const MUSIC_VOLUME_DB := -9.0

var _pool: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _music: Array[AudioStreamPlayer] = []
var _active_music := 0
var _current_track := &""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("sfx")
	for track: AudioStreamMP3 in MUSIC.values():
		track.loop = true
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_pool.append(p)
		var p3 := AudioStreamPlayer3D.new()
		p3.max_distance = 80.0
		p3.unit_size = 12.0
		add_child(p3)
		_pool_3d.append(p3)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.volume_db = -80.0
		add_child(m)
		_music.append(m)
	get_tree().node_added.connect(_on_node_added)


func play(sfx_name: StringName, volume_db := 0.0, pitch_variation := 0.06) -> void:
	var p := _free_player(_pool)
	if p == null or not SFX.has(sfx_name):
		return
	p.stream = SFX[sfx_name]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()


func play_at(sfx_name: StringName, position: Vector3, volume_db := 0.0, pitch_variation := 0.08) -> void:
	var p := _free_player(_pool_3d)
	if p == null or not SFX.has(sfx_name):
		return
	p.stream = SFX[sfx_name]
	p.global_position = position
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()


## Called by bullets through the "sfx" group.
func play_impact(position: Vector3) -> void:
	play_at(&"impact", position, -6.0)


func play_music(track: StringName, fade := 1.2) -> void:
	if track == _current_track or not MUSIC.has(track):
		return
	_current_track = track
	var old := _music[_active_music]
	_active_music = 1 - _active_music
	var new_player := _music[_active_music]
	new_player.stream = MUSIC[track]
	new_player.volume_db = -80.0
	new_player.play()
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel()
	_music_tween.tween_property(new_player, "volume_db", MUSIC_VOLUME_DB, fade)
	_music_tween.tween_property(old, "volume_db", -80.0, fade)
	_music_tween.chain().tween_callback(old.stop)


## Music ducks while a menu is open so the UI sounds stay clear.
func set_music_ducked(ducked: bool) -> void:
	var target := MUSIC_VOLUME_DB - 8.0 if ducked else MUSIC_VOLUME_DB
	create_tween().tween_property(_music[_active_music], "volume_db", target, 0.3)


func _free_player(pool: Array) -> Node:
	for p in pool:
		if not p.playing:
			return p
	return null


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind(&"click", -4.0, 0.03))
		node.mouse_entered.connect(play.bind(&"hover", -12.0, 0.03))
		node.focus_entered.connect(_on_button_focus.bind(node))


func _on_button_focus(button: BaseButton) -> void:
	# focus_entered also fires when a menu opens; only play it for keyboard/gamepad navigation
	if button.is_hovered():
		return
	play(&"hover", -14.0, 0.03)
