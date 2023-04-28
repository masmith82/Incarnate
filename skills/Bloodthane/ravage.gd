extends Skills_Library
class_name Ravage


@export var fx: PackedScene

@export var name: String = "Ravage"
@export var icon: Texture
@export var cd: int = 2
@export var tt: String = "Strike twice for 4 damage. Each strike can target a different foe."
@export var base_damage = 4

var target_info =  {"target" : NEEDS_ENEMY,
							"color" : ATTACK_TARGET,
							"disjointed" :	[{"target" : NEEDS_ENEMY,
											"disjointed" : [],
											"color" : SPECIAL_TARGET},]
							}

var type = HEAVY

func execute(unit):
	var enemies = []
	var origin = unit.origin_tile
	if !action_check(unit, name): return

	target_basic(origin, 1)
	var target = await unit.send_target
	if !target: return
	var t = target.get_unit_on_tile()
	enemies.append(t)
	await Global.get_tree().create_timer(.1).timeout

	target_basic(origin, 1)
	target = await unit.send_target
	if !target: return
	t = target.get_unit_on_tile()
	enemies.append(t)

	for e in enemies:
		if e:
			await unit.deal_damage(e, base_damage)
		else:
			continue
	
	await animate(unit, origin, enemies)

	unit.cooldowns[name] = cd
	unit.finish_action("skill")

func animate(unit, origin, target):
	unit.states.set_unit_state("actor_animating")
	await melee_attack_anim(unit, origin, target[0].origin_tile, fx)
	await melee_attack_anim(unit, origin, target[1].origin_tile, fx)
