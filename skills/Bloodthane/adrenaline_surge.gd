extends Skills_Library
class_name Adrenaline_Surge

@export var fx: PackedScene

@export var name: String = "Adrenaline Surge"
@export var icon: Texture = preload("res://GFX/Units/Bloodthane/Icons/5AdrenalineSurge.png")
@export var cd: int = 4
@export var tt: String = "Refresh a skill."
@export var target_info =  {"target" : NEEDS_ALLY,
							"color" : AID_TARGET,
							"disjointed" :	[]
							}
var type = UTIL

func execute(unit):
	var origin = unit.origin_tile
	if !action_check(unit, name): return
	target_basic(origin, 4)
	var target = await unit.send_target
	if !target: return

	var t = target.get_unit_on_tile()
	var p = popup.instantiate()
	unit.add_child(p)
	p.setup_skill_popup(RECHARGE)
	var confirm = await p.popup_confirm
	if confirm == "false":
		Global.reset_nav()
		return
	t.action_pool["skill"] += 1
	unit.combat_text("+1 skill action")
	unit.cooldowns[name] = cd
	unit.finish_action("skill")
