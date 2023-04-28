extends State

# !!! transition state, automatically calls actor_idle or actor_selected if current actor

func enter(_args = {}):
	# !!! in theory, prevents finalizing turn until all (tween) animations are finished
	if not get_tree().get_processed_tweens().is_empty():
		await get_tree().create_timer(.1)
	else:
		pass

	if state_machine.unit.is_in_group("temporary"):		# special logic for removing temporary units like shadows
		if state_machine.unit == Global.current_actor:
			Global.current_actor == null
		state_machine.unit.queue_free()
		return
	
	finalize()


func finalize():
	if Global.current_actor == state_machine.unit and state_machine.unit.is_in_group("player_units"):
		state_machine.set_unit_state("actor_selected")
	else:
		state_machine.set_unit_state("actor_idle")


func exit(_args = {}):
	print("emitting action finished")
	state_machine.unit.emit_signal("action_finished")
