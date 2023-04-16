extends State
class_name PLAYER_UNIT_SELECT

func enter(_args := {}):
	if "unit" in _args:
		if current_actor == _args["unit"]: return
		deselect()
		current_actor = _args["unit"]
		current_actor.ui_bar.show()
		current_actor.get_unit_pos()

func exit(_args := {}):
	pass
