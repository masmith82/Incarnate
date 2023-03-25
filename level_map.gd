extends Node

######################
# INSTANCE VARIABLES #
######################

@onready var g = get_node("/root/Global")
var new_tile = preload("res://grid_tile.tscn")
var actor = preload("res://actor.tscn")
var astar = AStarGrid2D.new()
var astar_to_tile = {}
var map_size = Vector2i(12,12)

var dir = {	"UP" : Vector2i(0,-1),
			"RIGHT" : Vector2i(1,0),
			"DOWN" : Vector2i(0,1),
			"LEFT" : Vector2i(-1,0),
			}

signal highlight
signal special_select

var debug_f
var debug_a

func _ready():
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	init_astar_map()

func _process(delta):
	debug()

func debug():
	var y = null
	var x = g.current_actor if g.current_actor else null
		
	$debug.text = "selection: %s\n targeting: %s\ncurrent_actor: %s\n queued_action: %s\n" % [g.selection, g.targeting, x, y]
	

#######################
# MAP BUILDER METHODS #
#######################

# sets up astar grid based on map size

func init_astar_map():
	astar.size = Vector2i(map_size)
	astar.cell_size = Vector2(64, 64)
	astar.offset = Vector2i(64, 64)
	astar.update()
	create_grid(astar.size)

# lays out grid tiles at each astar grid position

func create_grid(size: Vector2i):
	var builder = Vector2i(0,0)
	var map_tiles = []
	while builder.y < size.y:
		map_tiles.append_array(astar.get_id_path(builder, Vector2i(astar.size.x - 1, builder.y)))
		builder.y += 1
	map_to_grid(map_tiles)
	
# maps astar grid positions to tile objects

func map_to_grid(map_tiles):
	var astar_pos
	var tile
	for point in map_tiles:
		astar_pos = astar.get_point_position(point)
		tile = new_tile.instantiate()
		$map_grid_tiles.add_child(tile)
		tile.position = astar_pos
		tile.astar_index = point
		astar_to_tile[point] = tile
	map_obstacles()

func map_obstacles():
	var obstacles = $level_map.get_used_cells(1)
	for o in obstacles:
		astar_to_tile[o].obstacle = true
		astar.set_point_solid(o, true)

	for astar in astar_to_tile:
		get_neighbors(astar_to_tile[astar])

	await get_tree().create_timer(.1).timeout
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "units", "get_unit_pos")

# maps neighbors of each tile for better pathfinding, hopefully

func get_neighbors(tile_id: Area2D):
	var start_pos = tile_id.astar_index	
	var dest = Vector2(0,0)
	for d in dir:
		dest = start_pos + dir[d]
		if astar.is_in_boundsv(dest):
			tile_id.neighbors.append(astar_to_tile[dest])


############################
# SELECTION AND NAVIGATION #
############################

# gets a player actor if there's one on the tile that's clicked
# if player is executing an action, calls validate_target to check if target is valid
# hands control over to the actor's script
# called via signal from grid_tile nodes

func tile_select(astar_index: Vector2i):
	var tile_id = astar_to_tile[astar_index]
	var actor
	match g.selection:
		g.NO_SELECTION:
			g.reset_nav()
			if tile_id.get_overlapping_areas():
				actor = tile_id.get_overlapping_areas()[0].get_parent().get_parent()
				if actor.is_in_group("player_units"):
					actor.set_player_actor()
		g.PLAYER_ACTION:
			if tile_id.valid_selection:
				validate_target(tile_id)
			else:
				g.deselect()
		g.LOCKED:
			if tile_id.valid_selection:
				validate_target(tile_id)
		g.NPC_SELECTION:
			pass
		g.ENEMY_TURN:
			pass

func validate_target(tile_id):
	match g.targeting:
		g.PLAYER_MOVE:
			if tile_id.valid_selection == true and tile_id.occupied == false:
				print("Validate movement tile.")
				g.current_actor.sk.c += 1
				g.current_actor.set_target(tile_id)
		g.PLAYER_ATTACK:
			if tile_id.valid_selection == true and tile_id.occupied == true:
				print("Validate target tile.")
				g.current_actor.sk.c += 1
				g.current_actor.set_target(tile_id)
		g.SPECIAL:
			if tile_id.valid_selection:
				print("Validate special tile.")
				g.current_actor.sk.c += 1
				g.current_actor.set_target(tile_id)
				special_select.emit(tile_id)
			
# builds pathfinding from grid tile neighbors
			
func pathfind_basic(tile_id, distance):
	if distance == 0:
		return
	for neighbor in tile_id.neighbors:
		if neighbor.obstacle == false and neighbor.occupied == false: 
			if neighbor.move_cost <= distance:
				neighbor.set_highlight()
				neighbor.valid_selection = true
				pathfind_basic(neighbor, (distance - neighbor.move_cost))
				
func pathfind_shift(tile_id, distance):
	#astar.set_point_solid(tile_id.astar_index, false)
	if distance == 0:
		return
	for neighbor in tile_id.neighbors:
		if neighbor.obstacle == false:
			if neighbor.move_cost <= distance:
				neighbor.set_highlight()
				neighbor.valid_selection = true
				pathfind_basic(neighbor, (distance - neighbor.move_cost))
				
func target_basic(tile_id, distance):
	if distance == 0:
		return
	for neighbor in tile_id.neighbors:
		neighbor.set_highlight()
		neighbor.valid_selection = true
		target_basic(neighbor, (distance - 1))

# clears all pathfinding/rangefinding from tiles

func _on_actor_get_move(unit):
	pass

func special():
	print("main special")
