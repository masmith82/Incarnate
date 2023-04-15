extends Control

@onready var g = get_node("/root/Global")
@onready var camera = g.camera

enum {PASS, MOVE, BASIC, HEAVY, AREA, DEF, MNVR, UTIL, ULT}

var unit

enum {RECHARGE, RESET}		# currently called in relation to the skill select popup, might be unecessary
var old_buffs = []			# might need to separate this and other buff functions out to the buff_list node

func setup_ui(linked_unit):
	unit = linked_unit
	linked_unit.ui_bar = self
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
			
func update_ui():
	get_tree().call_group(unit.group_name, "update")
	
func update_desc(text):
	$desc_panel/desc_label.text = text
	
func clear_desc():
	# future note: could try using an uneditable text_edit, then can use text_changed signal
	$desc_panel/desc_label.text = ""
		
func hide_ui():
	hide()

func update_buff_bar():
	for buff in	unit.buffs.get_children():
		if old_buffs.has(buff): continue
		var new_buff = $buff_bar/buff_template.duplicate()
		new_buff.tooltip_text = buff.tt
		$buff_bar.add_child(new_buff)
		new_buff.show()
	old_buffs = unit.buffs.get_children()

func _on_cancel_button_pressed():
	g.post_action_cleanup(unit)

func _on_end_turn_button_pressed():
	await g.deselect(unit)
	unit.end_turn()	
