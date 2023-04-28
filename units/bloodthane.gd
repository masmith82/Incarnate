extends Actor

func _init():
	group_name = "bt_ui"
	skill_data = preload("res://skills/bloodthane_skills.tres")
	sk = skill_data.skill_list
	skill_loadout = [sk[PASS], sk[MOVE], sk[BASIC], sk[HEAVY], sk[AREA], sk[DEF], sk[MNVR], sk[UTIL], sk[ULT]]

func _ready():
	health = max_health
	movement = base_movement
	setup_unit()

func init_passive():
	add_buff(sk[PASS].bt_passive.new())
