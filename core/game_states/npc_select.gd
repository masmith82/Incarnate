extends State
class_name NPC_Select

func enter(_args := {}):
	#if Global.current_actor != null:	# if there's an actor selected, reset it's buttons (!!! is this needed?)
	#	get_tree().call_group(Global.current_actor.group_name, "set_button_state")
	
	if "unit" in _args:				# if a unit was passed in (which it should be)
		if Global.current_actor == _args["unit"]: return	# if it's the already-selected unit, do nothing
		var unit = _args["unit"]
		Global.deselect()					# deselect current selection
		Global.current_actor = unit			# set global actor to this unit
		unit.states.set_unit_state("actor_selected")


func exit(_args := {}):
	pass

func handle_click(tile):
	var unit = tile.get_unit_on_tile()
	if !unit:
		state_machine.change_selection_state("no_selection")
	else:
		if unit.is_in_group("player_units"):
			state_machine.change_selection_state("player_select", {"unit" : unit})
		if unit.is_in_group("NPCs"):
			state_machine.change_selection_state("npc_select", {"unit" : unit})
