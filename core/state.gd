extends Node
class_name State

var state_machine = null
var combat_queue = null

func enter(_args := {}):
	pass
		
func exit(_args := {}):
	pass

func handle_click(_tile):
	print("Something went wrong... ", state_machine.game_state)
