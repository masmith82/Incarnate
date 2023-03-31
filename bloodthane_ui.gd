extends Control

@onready var g = get_node("/root/Global")
@onready var unit = get_parent()
@onready var camera = g.level.find_child("map_camera")

# !!! hey dummy if you forget what you were doing, it's probably better to move
# all of the button functions to their own scripts so we can have each one handle it's own
# disabled/enabled status and cooldowns, etc.

enum {RECHARGE, RESET}
var old_buffs = []

func _ready():
	await link_to_camera()
	if unit != null:
		unit.link_ui(self)
	else:
		print("Couldn't link UI back to unit!")
	link_buttons()

func link_buttons():
	for child in $ui_icon_container/action_buttons.get_children():
		child.add_to_group(unit.group_name)
		if child.has_method("set_button_detail"):
			child.set_button_detail(unit)
			
	$ui_icon_container/stats_container/actions_ui.add_to_group(unit.group_name)
	$ui_icon_container/stats_container/actions_ui.set_ui_detail(unit)
	$ui_icon_container/stats_container/health_bar.add_to_group(unit.group_name)
	$ui_icon_container/stats_container/health_bar.set_ui_detail(unit)

func link_to_camera():
	await call_deferred("reparent", camera)
	position.x = -455
	position.y = 185
			
func lock_actions():
	get_tree().call_group(unit.group_name, "lock_action")

func unlock_actions():
	get_tree().call_group(unit.group_name, "unlock_check")
	
func update_ui():
	get_tree().call_group(unit.group_name, "update")
	
func update_desc(text):
	$desc_panel/desc_label.text = text
	
func clear_desc():
	# future note: could try using an uneditable text_edit, then can use text_changed signal
	$desc_panel/desc_label.text = ""
		
func hide_ui():
	hide()

func new_action():
	g.reset_nav()
	unit.get_unit_pos()
	g.set_select_state(g.PLAYER_ACTION)

func update_buff_bar():
	for buff in	unit.buffs.get_children():
		if old_buffs.has(buff): continue
		var new_buff = $buff_bar/buff_template.duplicate()
		new_buff.tooltip_text = buff.tt
		$buff_bar.add_child(new_buff)
		new_buff.show()
	old_buffs = unit.buffs.get_children()	

func _on_cancel_button_pressed():
	unlock_actions()
	g.reset_nav()
	g.level.emit_signal("send_target", null)	# feels like this shouldn't work? added null here?

func _on_end_turn_button_pressed():
	await g.deselect(unit)
	unit.end_turn()	

func _on_basic_move_button_pressed():
	new_action()
	unit.sk.move()
	lock_actions()

func _on_basic_atk_button_pressed():
	new_action()
	unit.skill_loadout[0]["func"].call()
	lock_actions()

func _on_heavy_atk_button_pressed():
	new_action()
	if unit.skill_loadout[1]["func"].is_valid() == false:
		print("NYI")
		return
	unit.skill_loadout[1]["func"].call()
	lock_actions()

func _on_area_atk_button_pressed():
	new_action()
	unit.skill_loadout[2]["func"].call()
	lock_actions()

func _on_def_button_pressed():
	new_action()
	unit.skill_loadout[3]["func"].call()
	lock_actions()

func _on_maneuver_button_pressed():
	new_action()
	unit.skill_loadout[4]["func"].call()
	lock_actions()
	
func _on_util_button_pressed():
	new_action()
	unit.skill_loadout[5]["func"].call()
	lock_actions()

func _on_ult_button_pressed():
	new_action()
	unit.skill_loadout[6]["func"].call()
	lock_actions()
