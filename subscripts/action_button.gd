extends TextureButton

@onready var index = self.get_index()

var unit
var skill
var cooldown

func set_button_detail(linked_unit):
	unit = linked_unit
	skill = unit.skill_loadout[index - 1]
	if index == 0:
		tooltip_text = "Move up to " + str(unit.movement) + " squares."
		return
	if skill["tt"]:
		tooltip_text = skill["tt"]
		name = skill["name"]
		var update_tt = Callable(unit.ui_bar, "update_desc")
		var clear_tt = Callable(unit.ui_bar, "clear_desc")
		mouse_entered.connect(update_tt.bind(tooltip_text))
		mouse_exited.connect(clear_tt)

func lock_action():
	disabled = true
	self_modulate = Color(Color.DARK_SLATE_GRAY, .5)

func unlock_check():
	if disabled == true and unit.actions != unit.SPENT:
		if index == 0:
			if unit.actions != unit.NO_MOVE:
				unlock_action()
			return
		if index == 5:
			if unit.actions != unit.NO_MOVE and unit.cooldowns[name] <= 0:
				unlock_action()
			return
		if unit.cooldowns[name] <= 0 and unit.actions != unit.NO_SKILL:
			unlock_action()
			return
	update()

func unlock_action():
	disabled = false
	self_modulate = Color(1,1,1,1)
	await get_tree().create_timer(.1).timeout
	update()

func update():
	if index == 0:
		return
	cooldown = unit.cooldowns[name]
	if cooldown > 0: $cd_label.text = str(cooldown)
	else: $cd_label.text = ""
