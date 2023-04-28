extends Node
class_name Turn_State_Machine

#=============================
# TURN CONTROLLER STATE MACHINE
# Controls when and how the player can interact with the game world based on whose turn it is, if
# an action is mid-execution, etc.
#=============================

var target_color

@onready var game_state = get_node("no_selection")
@onready var execute_state = preload("res://core/game_states/action_execute.tscn")

func _ready() -> void:
	for child in get_children():
		child.state_machine = self

func change_selection_state(state, _args = {}):
	print("Transitioning from ", game_state.name, " to ", state)
	await game_state.exit()
	var new_state := get_node(state)
	game_state = new_state
	new_state.enter(_args)
