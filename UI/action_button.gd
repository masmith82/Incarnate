extends TextureButton

#======================
# CLASS: ACTION_BUTTON
# Contoller for creating the skill buttons in the player UI. Called by main ui_bar, it creates
# buttons with the correct names, tooltips, icon and skill logic.
# Also controls locking and unlocking buttons when they are disabled or on cooldown. These functions
# are called often by ui_bar ensure the player can't activate a new skill while resolving another skill.
#======================

var g
var unit
var skill
var cooldown
var index
var action_type

enum {PASS, MOVE, BASIC, HEAVY, AREA, DEF, MNVR, UTIL, ULT}
enum {LOCKED, UNLOCKED}

func set_button_detail(linked_unit):
	g = get_node("/root/Global")
	unit = linked_unit
	index = self.get_index()
	skill = unit.skill_loadout[index + 1]
	if skill == null:
		texture_normal = load("res://GFX/Generic Icons/blank_square.png")
		return
	if skill:
		name = skill.name
		texture_normal = skill.icon
		tooltip_text = skill.tt
		link_verbose_tt()
		pressed.connect(execute_skill)		# connects the skill to it's action

func link_verbose_tt():
	var update_tt = Callable(unit.ui_bar, "update_desc")
	var clear_tt = Callable(unit.ui_bar, "clear_desc")
	mouse_entered.connect(update_tt.bind(tooltip_text))
	mouse_exited.connect(clear_tt)
	
func execute_skill():
	new_action()
	skill.execute(unit)	
	lock_actions()

func new_action():
	g.reset_nav()
	unit.get_unit_pos()
	g.set_select_state(g.PLAYER_ACTION)

func lock_actions():
	get_tree().call_group(unit.group_name, "set_button_state")

func check_button_lock_state():
	if skill == null:
		return
	if g.targeting != g.NO_TARGET:
		print("locked target")
		return LOCKED
	if unit.cooldowns[skill.name] > 0:
		print("locked cd")
		return LOCKED
	if unit.actions == unit.SPENT:
		print("locked spent")
		return LOCKED
	if (unit.actions == unit.NO_MOVE) and (index == 0 or index == 5):
		print("locked no move")
		return LOCKED
	if (unit.actions == unit.NO_SKILL) and (index != 0 and index != 5):
		print(index, " locked no action")
		return LOCKED
	return UNLOCKED

func set_button_state():
	var state = check_button_lock_state()
	update()
	match state:
		LOCKED:
			if disabled: return
			lock_action()
		UNLOCKED:
			if !disabled: return
			unlock_action()

func lock_action():
	disabled = true
	self_modulate = Color(Color.DARK_SLATE_GRAY, .5)

func unlock_action():
	disabled = false
	self_modulate = Color(1,1,1,1)

func update():
	if skill == null:
		return
	if index == 0:
		return
	cooldown = unit.cooldowns[skill.name]
	if cooldown > 0: $cd_label.text = str(cooldown)
	else: $cd_label.text = ""
