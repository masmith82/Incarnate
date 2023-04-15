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

enum {NO_SELECTION, PLAYER_SELECT, PLAYER_ACTION, NPC_SELECTION, ENEMY_TURN, UPKEEP, LOCKED}
enum {NO_TARGET, PLAYER_MOVE, PLAYER_ATTACK, PLAYER_HELP, SPECIAL}
enum {PASS, MOVE, BASIC, HEAVY, AREA, DEF, MNVR, UTIL, ULT}
enum {RECHARGE, RESET}

var g	# placeholder for calling Global singleton
var popup = load("res://UI/popup_ui.tscn")

############################
# SKILL TEMPLATE:
# The basic format of each skill.
# fx: a packed scene containing VFX and SFX to be instantiated
# name: the name of the skill as a string
# icon: the icon for the skill, a texture to preload
# cd: the cooldown of the skill
# tt: the skill's tooltip
# type: the skills type, from the skill type enum
# All skills use the "execute" method to contain their main logic
# Steps: 1) establish origin tile. 2) call action_check to see if unit can perform the action and
#	set targeting type. 3) Initializing targeting method. 4) await target signal from map.
#	5) when target signal received, get targetted unit(s). 6) instantiate FX. 7) set cooldown.
#	8) invoke finish_action() for cleanup
############################

class skill_template extends Skills_Library:
	
	@export var fx: PackedScene
	@export var name: String
	@export var icon: Texture
	@export var cd: int
	@export var tt: String
	var type = BASIC
	
	func execute(unit):
		var origin = unit.origin_tile
		if !action_check(unit, name, PLAYER_ATTACK): return
		target_basic(origin, 1)
		var target = await g.level.send_target
		if !target: return
		var t = target.get_unit_on_tile()
		if t: pass # do stuff here
		t.add_child(fx.instantiate())
		unit.cooldowns[name] = cd
		await unit.finish_action("skill")

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
	g.suppress_collision()
	if path.size() <= 0:					# if a path is passed in (as in Bloody Rush) use that instead
		pathfind_shift(origin, movement)	# otherwise gets path from astar
		var target = await g.level.send_target
		if !target: return
		path = g.level.astar.get_id_path(origin.astar_index, target.astar_index)
	var waypoint
	var tween = g.create_tween()
	for point in path:
		waypoint = g.level.astar_to_tile[point].position
		tween.tween_property(unit, "position", waypoint, .1)
	await tween.finished
	await resolve_shift(path.back(), path)
	g.unsuppress_collision()
	if is_move:							# flag if this is replacing a default move
		unit.finish_action("move")		# otherwise assumes it's attached to a skill
	path.clear()

func resolve_shift(target : Vector2i, path : Array):
	# !!! currently the shift logic allows units to shift through but not into other unit's spaces
	# !!! that may be good enough honestly!
	var tile = g.level.astar_to_tile[target]
	if tile.get_overlapping_areas().size() > 1:
		print("conflict")
		pass

func basic_pull(unit: Node2D, origin: Area2D, movement : int, path : Array = []):
	g = Engine.get_singleton("Global")
	# why is this happening on moves involving CPU but not player?
	# astar pathfinding has weird issues with obstacles when moving enemies...
	# ok I know why, player is prevented from moving onto enemy tile... whoops did I fix this or not? lol
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
		# to be overridden by each buff's "stuff"
		pass
