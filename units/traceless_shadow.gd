extends "res://actor.gd"
class_name Traceless_Shadow

func _ready():
	skill_data = load("res://skills/traceless_skills.tres")
	sk = skill_data.skill_list
	skill_loadout = [sk[PASS], sk[MOVE], sk[BASIC], sk[HEAVY], sk[AREA], sk[DEF], sk[MNVR], sk[UTIL], sk[ULT]]

func shadow_copy(skill_type):
	await get_tree().process_frame
	#set_process_mode(Node.PROCESS_MODE_ALWAYS)
	#get_tree().paused = true
	var skill_path = sk[skill_type]
	var callable = Callable(skill_path, "execute")
	g.add_to_queue(self, sk[skill_type].icon, callable.bind(self))		# sends the unit, skill icon and a callable to queue

# modified version of standard cleanup routine
# called by traceless skills if the executing unit is a shadow

func shadow_cleanup():
	#set_process_mode(Node.PROCESS_MODE_INHERIT)
	g.post_action_cleanup(self)
	g.set_select_state(g.NO_SELECTION)
	g.set_target_state(g.NO_TARGET)
	emit_signal("queued_action_finished")
	self.queue_free()

func shadow_swap_highlight():
	origin_tile.valid_selection = true
	origin_tile.set_highlight()

func kill_shadow_at_tile(tile):
	if origin_tile == tile:
		queue_free()

func get_unit_pos():	# override
	pass
