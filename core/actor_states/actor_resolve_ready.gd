extends State

func enter(_args = {}):
	pass
	
func _process(_delta):
	if state_machine.actor_state == self:
		state_machine.unit.emit_signal("resolve_ready")		# keep broadcasting resolve ready


func exit(_args = {}):
	pass
