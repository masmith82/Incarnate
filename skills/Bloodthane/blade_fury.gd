extends Skills_Library
class_name Blade_Fury

@export var fx: PackedScene

@export var name: String = "Blade Fury"
@export var icon: Texture = preload("res://GFX/Units/Bloodthane/Icons/1 Blade FurySmall.png")
@export var cd: int = 0
@export var tt: String = "Attack a target in melee range for 4 damage."
var type = BASIC

func execute(unit):
	var origin = unit.origin_tile
	if !action_check(unit, name, PLAYER_ATTACK): return
	target_basic(origin, 1)
	var target = await g.level.send_target
	if !target: return
	var t = target.get_unit_on_tile()
	if t: t.take_damage(unit, 4)
	t.add_child(fx.instantiate())
	unit.cooldowns[name] = cd
	unit.finish_action("skill")
	

# placeholder for quick copy/pasting new skills, includes all the necessary checks and cleanups
func _execute(unit):
	var origin = unit.origin_tile
	if !action_check(unit, name, PLAYER_ATTACK): return
	# get target i.e. target_basic(origin, 1)
	var target = await g.level.send_target
	if !target: return
	var t = target.get_unit_on_tile() # get target unit or tile
	if t: 
		pass # dostuff
	unit.cooldowns[name]
	unit.finish_action("skill")
