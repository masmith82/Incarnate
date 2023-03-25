extends Node
class_name skill_lib

@onready var g = get_node("/root/Global")
@onready var unit = get_parent()

########################
# CLASS: skill_lib
# Contains basic targeting methods for a variety of attacks and skills
# These skills take a callable from class_skills and set up targeting, while
# logic from the map/level handles target validation and confirms skill execution
# Also includes repeatedly use logic to validate that player has enough actions
# and sets the appropriate states
########################

func action_check(targeting):
	g.level.reset_nav()
	if unit.actions == unit.NO_SKILL or unit.actions == unit.SPENT:
		return false
	else:
		g.selection = g.PLAYER_ACTION
		g.targeting = targeting
		return true
		
func move_check(targeting = g.PLAYER_MOVE):
	g.level.reset_nav()
	if unit.actions == unit.NO_MOVE or unit.actions == unit.SPENT:
		return false
	else:
		g.selection = g.PLAYER_ACTION
		g.targeting = targeting
		return true

func init_move():
	if !move_check(): return
	unit.get_unit_pos()
	print("Origin tile: ", unit, unit.origin_tile)
	g.level.pathfind_basic(unit.origin_tile, unit.movement)

	unit.queued_action = Callable(self, "move")

func init_shift(movement : int):
	if !move_check(): return
	get_tree().call_group("tiles", "suppress_collision")
	unit.get_unit_pos()
	g.level.pathfind_basic(unit.origin_tile, movement)
	unit.queued_action = Callable(self, "shift")
	
func shift(target_tile : Area2D, target_tiles : Array = []):
	var path
	if target_tiles.size() > 0:
		path = target_tiles
	else: 
		path = g.level.astar.get_id_path(unit.origin_tile.astar_index, target_tile.astar_index)
	var waypoint
	var tween = create_tween()
	print("animate? ", path)
	for point in path:
		waypoint = g.level.astar_to_tile[point].position
		tween.tween_property(unit, "position", waypoint, .1)
	await tween.finished
	await get_tree().create_timer(.1).timeout
	unit.get_unit_pos()
	if unit.origin_tile.occupied == true:
		resolve_shift()
	else:
		unit.finish_action("move")

func resolve_shift():
	pass
#	get_tree().call_group("tiles", "unsuppress_collision")	


func move(target_tile : Area2D):
	if unit.moving == false:
		var path = g.level.astar.get_id_path(unit.origin_tile.astar_index, target_tile.astar_index)
		var waypoint
		var tween = create_tween()
		unit.moving = true
		print(path)
		for coords in path:
			print(g.level.astar_to_tile[coords].position)
		for point in path:
			waypoint = g.level.astar_to_tile[point].position
			tween.tween_property(unit, "position", waypoint, .1)
		unit.moving = false
		await get_tree().create_timer(.1).timeout
		unit.get_unit_pos()
		unit.finish_action("move")

#func basic_move_target(unit : Node, skill: Callable, movement : int):
#	await unit.get_unit_pos()
#	g.level.pathfind_basic(unit.origin_tile, 1)
#	unit.queued_action = skill

# basic_melee_target
# Provides targetting for targets units adjacent to the calling unit
# Args: unit: the calling unit's base Node
#		skill: the primed skilled as a Callable
#		origin: optionally set the origin tile for disjoint attacks

func basic_melee_target(unit : Node, skill: Callable, origin: Object = unit.origin_tile):
	await unit.get_unit_pos()
	g.level.target_basic(origin, 1)
	unit.queued_action = skill

func manual_path_move(unit : Node, skill: Callable, origin: Object = unit.origin_tile):
	await unit.get_unit_pos()
	g.level.pathfind_basic(origin, 1)
	unit.queued_action = skill
	
func manual_path_shift(unit : Node, skill: Callable, origin: Object = unit.origin_tile):
	await unit.get_unit_pos()
	g.level.pathfind_shift(origin, 1)
	unit.queued_action = skill


func basic_ranged_target():
	pass
	
func basic_ranged_exec():
	pass
