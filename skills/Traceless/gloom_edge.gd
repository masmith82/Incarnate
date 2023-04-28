extends Skills_Library
class_name Gloom_Edge

@export var fx: PackedScene

@export var name: String = "Gloom Edge"
@export var icon: Texture = preload("res://GFX/Units/Traceless/gloom_edge.png")
@export var cd: int = 2
@export var tt: String = "Strike a foe in melee range for 8 damage. Shadows copying this strike inflict Blind on
	foes they strike."
@export var base_damage = 8
@export var target_info =  {"target" : NEEDS_ENEMY,
							"color" : ATTACK_TARGET,
							"disjointed" :	[]
							}

var type = HEAVY

func execute(unit):
	var origin = unit.origin_tile
	if !action_check(unit, name): return		# sets targeting to special if the action check passes
	target_basic(origin, 1)
	var target = await unit.send_target
	if !target: return
	var t = target.get_unit_on_tile()
	if t: unit.deal_damage(t, base_damage)
	
	if unit is Traceless_Shadow:
		t.add_buff(Buff.debuff_blind.new())
		await unit.finish_action("skill")
		unit.shadow_cleanup()
		return
	
	unit.queue_shadow_strike(HEAVY)
	unit.cooldowns[name] = cd
	unit.finish_action("skill")
	
	# !!! for now we're getting the path but not the shortest path with shift, need to work on the 
	# shift logic so it goes through units when appropriate
