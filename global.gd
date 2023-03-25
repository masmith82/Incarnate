extends Node

@onready var level = get_node("/root/level")
@onready var enemy = level.find_child("enemy_controller")

enum {NO_SELECTION, PLAYER_ACTION, NPC_SELECTION, ENEMY_TURN, UPKEEP, LOCKED}
enum {NO_TARGET, PLAYER_MOVE, PLAYER_ATTACK, PLAYER_HELP, SPECIAL}

@onready var selection = NO_SELECTION
@onready var targeting = NO_TARGET

var current_actor = null
var collision_tiles = []
var collision_suppressed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	self.add_to_group("control")
	Engine.register_singleton("Global", self)

func set_select_state(state):
	selection = state
	
func set_target_state(state):
	targeting = state

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func end_player_turn():
	selection = ENEMY_TURN
	enemy.start_enemy_turn()

func end_enemy_turn():
	selection = NO_SELECTION

func reset_nav():
	get_tree().call_group("tiles", "clear_tiles")
	get_tree().call_group("tiles", "clear_valid")
	if collision_tiles.is_empty() == false:
		get_tree().call_group("tiles", "unsuppress_collision")	

func post_action_cleanup(unit):
	current_actor.sk.c = 0		# failsafe
	unit.get_unit_pos()
	reset_nav()
	targeting = NO_TARGET

func deselect():
	reset_nav()
	current_actor = null
	get_tree().call_group("player_units", "hide_menu")
	selection = NO_SELECTION

#	get_tree().call_group("menu", "clear_menu_holds")
