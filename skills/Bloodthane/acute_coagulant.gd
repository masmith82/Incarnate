extends Skills_Library
class_name Acute_Coagulant

@export var fx: PackedScene

@export var name: String = "Acute Coagulant"
@export var icon: Texture = preload("res://GFX/Units/Bloodthane/Icons/3AcuteCoagulant.png")
@export var cd: int = 3
@export var tt: String = "Heal yourself for 4 damage. At the beginning of the next two turns, heal for 4 damage."
@export var target_info =  {"target" : NEEDS_ALLY,
							"color" : AID_TARGET,
							"disjointed" : []
							}
var type = DEF

func execute(unit):
	var origin = unit.origin_tile
	if !action_check(unit, name): return
	target_self(origin)
	var target = await unit.send_target
	if !target: return
	unit.heal_damage(unit, 4)
	unit.add_buff(acute_buff.new())
	unit.finish_action("skill")
	unit.cooldowns[name] = cd
	return
	
class acute_buff extends Buff:
	func _init():
		duration = 2
		name = "Acute Coagulant"
		tt = "Heal yourself for 4 damage. At the beginning of the next two turns, heal for 4 damage."
		icon = preload("res://GFX/Units/Bloodthane/Icons/3AcuteCoagulant.png")

	func buff_stuff():
		print("buff stuff")
		print("Acute Coagulant heals ", unit, " for 4 damage.")
		unit.heal_damage(unit, 4)
		
		buff_tick()
