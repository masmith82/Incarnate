extends Skills_Library
class_name Blade_Fury

@export var fx: PackedScene

@export var name: String = "Blade Fury"
@export var icon: Texture = preload("res://GFX/Units/Bloodthane/Icons/1 Blade FurySmall.png")
@export var cd: int = 0
@export var tt: String = "Attack a target in melee range for 4 damage."
@export var base_damage = 4

@export var target_info =  {"target" : NEEDS_ENEMY,
							"color" : ATTACK_TARGET,
							"disjointed" :	[]
							}

var type = BASIC

func execute(unit):
	var origin = unit.origin_tile
	if !action_check(unit, name): return
	target_basic(origin, 1)
	var target = await unit.send_target
	if !target: return
	var t = target.get_unit_on_tile()

	if t:
		await unit.deal_damage(t, base_damage)

	await animate(unit, origin, target)

	unit.cooldowns[name] = cd
	unit.finish_action("skill")
	

func animate(unit, origin, target):
	unit.states.set_unit_state("actor_animating")
	await melee_attack_anim(unit, origin, target, fx)
