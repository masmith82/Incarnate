extends Node
class_name State

var state_machine = null

func enter(_args := {}):
	pass
		
func exit(_args := {}):
	pass

func handle_click(_tile):
	print("Something went wrong... ", state_machine.game_state)

func next_state():
	pass
