extends State

func enter(_args = {}):
	state_machine.unit.ui_bar.show()
	state_machine.unit.get_unit_pos()
	
func exit(_args = {}):
	pass
