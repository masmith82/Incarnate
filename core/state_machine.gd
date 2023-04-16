extends Global_Controller
class_name State_Machine
#enum {NO_SELECTION, PLAYER_SELECT, PLAYER_ACTION, NPC_SELECTION, ENEMY_TURN, UPKEEP, POPUP_LOCKED}
#enum {NO_TARGET, PLAYER_MOVE, PLAYER_ATTACK, PLAYER_HELP, SPECIAL}

var TARGETING
var NOT_TARGETING

@onready var game_state = get_node("NO_SELECTION")
@onready var target_state = get_node("NO_TARGET")

func _ready() -> void:
	for child in get_children():
		child.state_machine = self
	game_state.enter()

func change_selection_state(state, _args):
	await game_state.exit()
	var new_state := get_node(state)
	game_state = new_state
	new_state.enter(_args)
