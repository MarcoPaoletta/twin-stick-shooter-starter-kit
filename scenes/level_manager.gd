extends Node3D
## Root script shared by every level scene. Instances the level UI, shows the
## intro banner, reacts to the player's death and ends the level when every
## enemy is down.

const LEVEL_UI := preload("res://ui/LevelUI.tscn")

@export var level_title := ""

var _title := ""
var _ui: Node
var _player: PlayerEntity
var _enemies_total := 0
var _enemies_alive := 0


func _ready() -> void:
	_ui = LEVEL_UI.instantiate()
	add_child(_ui)

	var index := Game.current_level_index()
	_title = level_title
	if _title.is_empty():
		_title = Game.LEVEL_TITLES[index] if index >= 0 else str(name)
	var subtitle := ""
	if index >= 0:
		subtitle = "Level %d" % (index + 1)
	_ui.show_banner(_title, subtitle)

	var players := find_children("*", "PlayerEntity", true, false)
	if not players.is_empty():
		_player = players[0]
		_player.is_dead.connect(_on_player_death)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_ancestor_of(enemy):
			_enemies_total += 1
			_enemies_alive += 1
			enemy.died.connect(_on_enemy_died, CONNECT_ONE_SHOT)


func _on_player_death() -> void:
	_ui.show_game_over()


func _on_enemy_died() -> void:
	_enemies_alive -= 1
	if _enemies_total > 0 and _enemies_alive <= 0:
		await get_tree().create_timer(1.8).timeout
		_ui.show_complete(_title, Game.has_next_level())
