extends Actor
class_name Traceless_Shadow

func _ready():
	skill_data = load("res://skills/traceless_skills.tres")
	sk = skill_data.skill_list
	skill_loadout = [sk[PASS], sk[MOVE], sk[BASIC], sk[HEAVY], sk[AREA], sk[DEF], sk[MNVR], sk[UTIL], sk[ULT]]


func shadow_copy(skill_type):
	await get_tree().process_frame
	var skill_path = sk[skill_type]
	var callable = Callable(skill_path, "execute")
	Global.add_to_queue(self, sk[skill_type], callable.bind(self))		# sends the unit, skill icon and a callable to queue


func shadow_cleanup():
	await states.set_unit_state("actor_finished")
	emit_signal("queued_action_finished")
	Global.reset_nav()

# !!! this works but is flimsy

func shadow_swap_highlight():
	origin_tile.valid_selection = true
	origin_tile.set_highlight()


func kill_shadow_at_tile(tile):
	if origin_tile == tile:
		queue_free()
