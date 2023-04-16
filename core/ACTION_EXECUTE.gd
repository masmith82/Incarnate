extends State
class_name ACTION_EXECUTE

func enter(_args := {}):
	pass
	
func exit(_args := {}):
	post_action_cleanup(null)
	current_actor.get_unit_pos()
	get_tree().call_group(current_actor.group_name, "set_button_state")
	get_tree().call_group(current_actor.group_name, "update_actions_ui")
	state_machine.set_select_state(PLAYER_UNIT_SELECT)
	state_machine.set_target_state(NOT_TARGETING)
