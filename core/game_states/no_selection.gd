extends State
class_name no_selection

func enter(_args = {}):
	Global.deselect()
	
func exit(_args = {}):
	pass
	
func handle_click(tile):
	var unit = tile.get_unit_on_tile()
	if unit and unit.is_in_group("player_units"):
		state_machine.change_selection_state("player_select", {"unit" : unit})
	if unit and unit.is_in_group("NPCs"):
		state_machine.change_selection_state("npc_select", {"unit" : unit})
