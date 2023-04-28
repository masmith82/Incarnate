extends State

func enter(_args = {}):
	var target = _args["target"]
	var unit = state_machine.unit
	
	# process effects here
	
	await target.resolve_ready
	state_machine.set_unit_state("actor_resolve_ready")
		
func exit(_args = {}):
	pass
