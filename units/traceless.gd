extends "res://actor.gd"

func _init():
	group_name = "tl_ui"
	skill_data = preload("res://skills/traceless_skills.tres")
	sk = skill_data.skill_list
	skill_loadout = [sk[PASS], sk[MOVE], sk[BASIC], sk[HEAVY], sk[AREA], sk[DEF], sk[MNVR], sk[UTIL], sk[ULT]]

func _ready():
	health = max_health
	setup_unit()

func init_passive():
	add_buff(sk[PASS].tl_passive.new())

func queue_shadow_strike(skill_type):
	get_tree().call_group("traceless_shadow", "shadow_copy", skill_type)
	
func spawn_shadow(target):
	var shadow = load("res://units/traceless_shadow.tscn")
	var new_shadow = shadow.instantiate()
	new_shadow.position = target.position
	g.level.add_child(new_shadow)
	new_shadow.add_to_group("traceless_shadow")
	new_shadow.origin_tile = target
