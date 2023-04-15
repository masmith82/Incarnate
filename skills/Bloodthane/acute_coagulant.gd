extends Skills_Library
class_name Acute_Coagulant

@export var fx: PackedScene

@export var name: String = "Acute Coagulant"
@export var icon: Texture = preload("res://GFX/Units/Bloodthane/Icons/3AcuteCoagulant.png")
@export var cd: int = 3
@export var tt: String = "Heal yourself for 4 damage. At the beginning of the next two turns, heal for 4 damage."
var type = DEF

var callable = Callable(self, "acute_coagulant")

func execute(unit):
	var origin = unit.origin_tile
	if !action_check(unit, name, PLAYER_HELP): return
	target_self(origin)
	var target = await g.level.send_target
	if !target: return
	unit.heal_damage(unit, 4)
	unit.add_buff(acute_buff.new())
	unit.finish_action("skill")
	unit.cooldowns[name] = cd
	return
	
class acute_buff extends buff:
	func _init():
		duration = 2
		name = "Acute Coagulant"

	func buff_stuff():
		print("Acute Coagulant heals ", unit, " for 4 damage.")
		unit.heal_damage(unit, 4)
		buff_tick()
