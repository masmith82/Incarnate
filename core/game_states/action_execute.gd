extends State
class_name Action_Execute

#=============================
# TURN CONTROLLER STATE
# for when a unit has confirmed an action and is executing any effects and animations.
#=============================

func _ready():
	if Global.current_actor.is_in_group("temporary"):		# failsafe against self-destroying units
		Global.s.change_selection_state("no_selection")
		return
		
	await Global.current_actor.action_finished
	
	state_machine.change_selection_state("player_select")

func enter(_args := {}):
	pass
	
func exit(_args := {}):
	queue_free()

# !!! For now this is just a placeholder/transition state. Unit's call their own cleanup which is
#	probably safer than calling from g.current_unit
# 	Not also this node is temporary, created and destroyed when needed... I guess so it's not constantly
#	in process if that matters?
# 	IIRC the reason I did this is I couldn't think of another way to implement without keeping this
#	in process constnatly, but that probably doesn't matter and may be unneeded with actor_states
