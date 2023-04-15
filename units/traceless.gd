extends "res://actor.gd"

func _init():
	group_name = "tl_ui"
	skill_data = preload("res://skills/traceless_skills.tres")
	sk = skill_data.skill_list
	skill_loadout = [sk[PASS], sk[MOVE], sk[BASIC], sk[HEAVY], sk[AREA], sk[DEF], sk[MNVR], sk[UTIL], sk[ULT]]

func _ready():
	health = max_health
	setup_unit()
