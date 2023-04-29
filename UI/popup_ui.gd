extends Control
class_name Popup_UI

#======================
# CLASS: Popup_UI
# Creates popup buttons dynamically for triggered effects. This version just creates buttons and does not
# pause the game. Some of this functionality will be moved to the Trigger_Confirm popup window class, but
# this version still may be needed.
#======================

@onready var g = get_node("/root/Global")

var unit
var skills
var cd
var base_button

enum {RECHARGE, RESET}

signal popup_confirm

func _ready():
	base_button = $popup_container/popup_base_button
	unit = get_parent()
	skills = get_parent().skill_loadout
	cd = get_parent().cooldowns
	set_global_position(unit.position + Vector2(64, -64))
	
func setup_skill_popup(effect_type):
	for s in skills:
		if s == null: continue
		name = s["name"]
		if cd[name] > 0:		# s gives us the full skill, s["name"] gives us skill's name, cd[~] should give us cd of skill
			var new_button = base_button.duplicate(0)
			new_button.texture_normal = s["icon"]
			$popup_container.add_child(new_button)
			setup_button(new_button, s, effect_type)
			Global.s.change_selection_state("handle_popup")
			get_tree().call_group(Global.current_actor.group_name, "set_button_state")

func setup_button(new_button, skill, effect_type = null):
	var c = Callable(self, "popup_effect")
	new_button.pressed.connect(c.bind(skill, effect_type))

func setup_special_popup(popup_options : Array, target : Node2D):
	base_button.hide()
	for p in popup_options:
		var new_button = base_button.duplicate(0)
		new_button.texture_normal = load(p["icon"])
		$popup_container.add_child(new_button)
		setup_special_button(new_button, p["pact"], target)
		new_button.show()
	Global.s.change_selection_state("handle_popup")
	get_tree().call_group(unit.group_name, "set_button_state")
	await unit.special_popup_confirm
	print("popup_finished")

func setup_special_button(new_button : TextureButton, pact : int , target : Node2D):
	var c = Callable(unit.sk[0].bt_passive.new(), "seal_pact")	# sk[0] here is the passive slot
	new_button.pressed.connect(c.bind(target, pact, self))

func popup_effect(skill, effect_type):
	var name = skill["name"]
	match effect_type:
		RECHARGE:
			unit.cooldowns[name] -= 1
		RESET:
			unit.cooldowns[name] = 0
	emit_signal("popup_confirm", "true")
	popup_cleanup()
	
func popup_cleanup():
	get_tree().call_group(unit.group_name, "set_button_state")
	Global.s.change_selection_state("player_select")
	queue_free()

func _on_popup_base_button_pressed():
	emit_signal("popup_confirm", "false")
	popup_cleanup()
