extends State
class_name PLAYER_TARGET

func enter(_args := {}):
	if "target_info" in _args:
		state_machine.set_target_state(TARGETING, _args["target_info"])
	else: print("Targeting error.")
	
func exit(_args := {}):
	reset_nav()
	level.emit_signal("send_target", null)
