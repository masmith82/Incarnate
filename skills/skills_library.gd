########################
# CLASS: skill_lib
# Contains basic targeting methods for a variety of attacks and skills
# These skills take a callable from class_skills and set up targeting, while
# logic from the map/level handles target validation and confirms skill execution
# Also includes repeatedly use logic to validate that player has enough actions
# and sets the appropriate states
########################

extends Resource
class_name Skills_Library

enum {NO_SELECTION, PLAYER_ACTION, NPC_SELECTION, ENEMY_TURN, UPKEEP, LOCKED}
enum {NO_TARGET, PLAYER_MOVE, PLAYER_ATTACK, PLAYER_HELP, SPECIAL}

var g	# placeholder for calling Global singleton

############################
# GENERAL HELPERS:
# A few helper functions. call_up gives resource scripts a unified way to call_group up the tree.
# set_targ_state changes the targeting state for the ramshackle state machine
# reset_nav calls the function of the same name from Global, which resets all pathfinding info
############################

func call_up(group : StringName, method : StringName, args = null):
	g = Engine.get_singleton("Global")
	g.get_tree().call_group(group, method, args)

func set_targ_state(state : int):
	call_up("control", "set_target_state", state)
	
func set_select_state(state : int):
	call_up("control", "set_select_state", state)

func reset_nav():
	g = Engine.get_singleton("Global")
	g.reset_nav()

############################
# ACTION POINT CHECKERS:
# Called at the start of most actions to determine if the unit has enough of the appropriate action
# points to use the skill
############################

func action_check(unit, name, targeting):
	if unit.actions == unit.NO_SKILL or unit.actions == unit.SPENT:
		return false
	if unit.cooldowns[name] > 0:
		print("On cooldown!")
		return false
	else:
		set_targ_state(targeting)
		return true
		
func move_check(unit):
	if unit.actions == unit.NO_MOVE or unit.actions == unit.SPENT:
		return false
	else:
		set_targ_state(PLAYER_MOVE)
		return true

############################
# BASIC TARGETING:
# Different methods for finding and highlighting valid tiles for skills and movement
# All the "basic" functions build a standard orthagonal grid out using each tile's neighbors
# Using 1 as an argument for these functions essentially gives melee range targeting
############################

func pathfind_basic(origin : Area2D, distance : int):
	if distance == 0:
		return
	for neighbor in origin.neighbors:
		if neighbor.obstacle == false and neighbor.occupied == false: 
			if neighbor.move_cost <= distance:
				neighbor.set_highlight()
				neighbor.valid_selection = true
				pathfind_basic(neighbor, (distance - neighbor.move_cost))
				
func pathfind_shift(origin : Area2D, distance : int):
	if distance == 0:
		return
	for neighbor in origin.neighbors:
		if neighbor.obstacle == false:
			if neighbor.move_cost <= distance:
				neighbor.set_highlight()
				neighbor.valid_selection = true
				pathfind_basic(neighbor, (distance - neighbor.move_cost))

func manual_path_shift(unit : Node2D, origin: Area2D = unit.origin_tile):
	pathfind_shift(origin, 1)

func target_basic(origin : Area2D, distance : int):
	if distance == 0:
		return
	for neighbor in origin.neighbors:
		neighbor.set_highlight()
		neighbor.valid_selection = true
		if distance > 0:
			target_basic(neighbor, (distance - 1))
			
func target_self(origin: Area2D):
	origin.valid_selection = true
	origin.set_highlight()

############################
# BASIC ACTIONS:
# Basic logic for different types of movement such as regular move, shift, fly, etc.
############################

func basic_move(unit : Node2D, origin : Area2D, movement : int, path : Array = [], is_move : bool = true):
	g = Engine.get_singleton("Global")
	if path.size() <= 0:
		pathfind_basic(origin, movement)
		var target = await g.level.send_target
		if !target: return
		path = g.level.astar.get_id_path(origin.astar_index, target.astar_index)
	var waypoint
	var tween = g.create_tween()
	for point in path:
		waypoint = g.level.astar_to_tile[point].position
		tween.tween_property(unit, "position", waypoint, .1)
	await tween.finished
	if is_move:								# flag if this is a move action, defaults to yes
		unit.finish_action("move")
	path.clear()
	return
	
func basic_shift(unit : Node2D, origin : Area2D, movement : int, path : Array = [], is_move : bool = false):
	g = Engine.get_singleton("Global")
	if path.size() <= 0:					# if a path is passed in (as in Bloody Rush) use that instead
		pathfind_basic(origin, movement)	# otherwise gets path from astar
		var target = await g.level.send_target
		if !target: return
		path = g.level.astar.get_id_path(origin.astar_index, target.astar_index)
	var waypoint
	var tween = g.create_tween()
	for point in path:
		waypoint = g.level.astar_to_tile[point].position
		tween.tween_property(unit, "position", waypoint, .1)
	await tween.finished
	if is_move:							# flag if this is replacing a default move
		unit.finish_action("move")		# otherwise assumes it's attached to a skill
	path.clear()
	return

func basic_pull(unit: Node2D, origin: Area2D, movement : int, path : Array = []):
	g = Engine.get_singleton("Global")
	# why is this happening on moves involving CPU but not player?
	# astar pathfinding has weird issues with obstacles when moving enemies...
	# ok I know why, player is prevented from moving onto enemy tile
	# !!! needs various tweaks to fine tune
	g.level.astar.set_point_solid(origin.astar_index, false)
	path = g.level.astar.get_id_path(unit.origin_tile.astar_index, origin.astar_index)
	g.level.astar.set_point_solid(origin.astar_index, true)
	path = prune_ai_path(origin, movement, path)
	await basic_move(unit, origin, movement, path, false)				# call a regular move, flagged
	await g.get_tree().create_timer(.1).timeout
	unit.get_unit_pos()													# confirm targets new position

func prune_ai_path(origin : Area2D, movement : int, path : Array):
	path.remove_at(0)		# removes the origin tile
	path.resize(movement)
	path = path.filter(func(coords): return coords != origin.astar_index)	# can't pull onto self
	path = path.filter(func(coords): return coords != Vector2i(0,0))		# remove invalid entries so we don't crash
	return path

#============================#
# BASIC BUFF/DEBUFF HANDLING #
#============================#

class buff extends Node:
	var duration
	var unit
	var stacks
	var callable = Callable(self, "buff_stuff")
	
	func _ready():
		unit = get_parent().get_parent()
		var g = Engine.get_singleton("Global")
		g.start_turn.connect(callable)

	func buff_tick():
		if duration:
			duration -= 1
			print(name, ": ", duration, "turns remaining.")
			if duration <= 0:
				self.queue_free()
	
	func buff_stuff():
		pass

#======================#
# SKILLS AS CLASS TEST #
#======================#

class skill:
	var type
	var c = 0
"""


func init_shift(movement : int):
	if !move_check(): return
	g.get_tree().call_group("tiles", "suppress_collision")
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




#func basic_move_target(unit : Node, skill: Callable, movement : int):
#	await unit.get_unit_pos()
#	g.level.pathfind_basic(unit.origin_tile, 1)
#	unit.queued_action = skill



func manual_path_move(unit : Node, skill: Callable, origin: Object = unit.origin_tile):
	await unit.get_unit_pos()
	g.level.pathfind_basic(origin, 1)
	unit.queued_action = skill
	

"""
