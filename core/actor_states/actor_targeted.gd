extends State

#=============================
# ACTOR CONTROLLER STATE
# when a unit is affected by something, this state processes if they can react before the effect
# resolves
#=============================


func enter(_args = {}):
	var source = _args["source"]
	var unit = state_machine.unit

	for buff in unit.buffs.get_children():		# check buffs for reaction effects
		if buff.effect_info.has("reaction"):
			unit.emit_signal("can_react")
			await unit.reacted
	
	state_machine.set_unit_state("actor_resolve_ready")
	print("defender resolve ready")
	
func exit(_args = {}):
	pass
