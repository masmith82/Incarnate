extends Skills_Library
class_name Displacer_Strike

@export var fx: PackedScene

@export var name: String = "Displacer Strike"
@export var icon: Texture = preload("res://GFX/Units/Traceless/displacer_strike.png")
@export var cd: int = 0
@export var tt: String = "Shift 2 squares, then strike an enemy for 3 damage."
@export var base_damage = 4
var type = BASIC


func execute(unit):
	var origin = unit.origin_tile
	var path = []
	if !action_check(unit, name, MOVE): return		# sets targeting to special if the action check passes
	pathfind_shift(origin, 2)
	var target = await g.level.send_target
	if !target: return
	var shift_target = target
	
	g.set_target_state(PLAYER_ATTACK)
	target_basic(target,1)
	target = await g.level.send_target
	if !target: return
	var t = target.get_unit_on_tile()
	g.suppress_collision()
	path = g.level.astar.get_id_path(origin.astar_index, shift_target.astar_index)
	await basic_shift(unit, origin, 2, path)
	if t: unit.deal_damage(t, base_damage)
	

	
	if unit is Traceless_Shadow:
		await unit.finish_action("skill")
		unit.shadow_cleanup()
		return
	unit.queue_shadow_strike(BASIC)
	unit.finish_action("skill")
	
	# !!! for now we're getting the path but not the shortest path with shift, need to work on the 
	# shift logic so it goes through units when appropriate
