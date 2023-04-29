extends State

func enter(_args = {}):
	var unit = state_machine.unit
	
	if not unit.is_in_group("temporary"):
		unit.ui_bar.hide()
		unit.call_deferred("get_unit_pos")
	
	
func exit(_args = {}):
	pass
