extends Control

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
		var name = s["name"]
		if cd[name] > 0:		# s gives us the full skill, s["name"] gives us skill's name, cd[~] should give us cd of skill
			var new_button = base_button.duplicate(0)
			new_button.texture_normal = load(s["icon"])
			$popup_container.add_child(new_button)
			await setup_button(new_button, s, effect_type)
			g.set_select_state(g.POPUP_LOCKED)
			unit.ui_bar.lock_actions()

func setup_button(new_button, skill, effect_type = null):
	var c = Callable(self, "popup_effect")
	new_button.pressed.connect(c.bind(skill, effect_type))

func setup_special_popup(popup_options : Array, target : Node2D):
	base_button.hide()
	for p in popup_options:
		var new_button = base_button.duplicate(0)
		new_button.texture_normal = load(p["icon"])
		$popup_container.add_child(new_button)
		await setup_special_button(new_button, p["pact"], target)
		new_button.show()
	g.set_select_state(g.POPUP_LOCKED)
	unit.ui_bar.lock_actions()
	await unit.special_popup_confirm
	print("pact_finished")

func setup_special_button(new_button : TextureButton, pact : int , target : Node2D):
	var c = Callable(unit.sk.bt_passive.new(), "seal_pact")
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
	print("calling cleanup")
	unit.ui_bar.update_ui()
	unit.ui_bar.unlock_actions()
	g.set_select_state(g.PLAYER_ACTION)
	g.set_target_state(g.NO_TARGET)
	queue_free()

func _on_popup_base_button_pressed():
	emit_signal("popup_confirm", "false")
	popup_cleanup()
