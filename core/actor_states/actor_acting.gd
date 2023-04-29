extends State

func enter(_args = {}):
	if "effects" in _args:
		combat_queue.add_effect(_args["effects"])
	
func exit(_args = {}):
	pass
