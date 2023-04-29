extends Skills_Library
class_name Displacer_Strike

@export var fx: PackedScene

@export var name: String = "Displacer Strike"
@export var icon: Texture = preload("res://GFX/Units/Traceless/displacer_strike.png")
@export var cd: int = 0
@export var tt: String = "Shift 2 squares, then strike an enemy for 3 damage."
@export var base_damage = 4
var target_info =  {"target" : NEEDS_OPEN,
					"color" : MOVE_TARGET,
					"disjointed" :	[{"target" : NEEDS_ENEMY,
									"disjointed" : [],
									"color" : ATTACK_TARGET}]
					}
var type = BASIC


func execute(unit):
	var origin = unit.origin_tile
	var path = []
	if !action_check(unit, name): return
	pathfind_shift(origin, 2)
	var target = await unit.send_target
	if !target: return
	var shift_target = target
	
	target_basic(target,1)
	target = await unit.send_target
	if !target: return
	var t = target.get_unit_on_tile()
	Global.suppress_collision()
	path = Global.level.astar.get_id_path(origin.astar_index, shift_target.astar_index)

	var effects = {"effects":
					[damage_effect.bind(unit, t, base_damage)]}
	await animate(unit, target, origin, path, effects)

	if unit is Traceless_Shadow:
		unit.shadow_cleanup()
		return
	
	unit.queue_shadow_strike(BASIC)
	unit.finish_action("skill")

func animate(unit, target, origin, path, effects):
	basic_shift(unit, origin, 2, path)
	await Global.get_tree().create_timer(.15).timeout
	unit.emit_signal("change_state", "actor_attacking", effects)
	
	target.add_child(fx.instantiate())
	await unit.animation_finished

	# !!! need to find a way to make it wait for animation to finish
