extends Node

#======================#
# SCENE: level_map
# Setup for battle maps that builds out astar pathfinding, obstacles and sets up the grid and tiles
#======================#

#====================#
# INSTANCE VARIABLES #
#====================#

@onready var g = get_node("/root/Global")
var new_tile = preload("res://grid_tile.tscn")
var actor = preload("res://actor.tscn")

var astar = AStarGrid2D.new()	# initializing the astar pathfinder
var astar_to_tile = {}			# a dictionary that contains astar coordinates to tile_ids as key:value pairs
var map_size = Vector2i(12,12)	# size of the map, x tiles * y tiles
								# a dictionary of directions as vectors
								
var dir = {	"UP" : Vector2i(0,-1),
			"RIGHT" : Vector2i(1,0),
			"DOWN" : Vector2i(0,1),
			"LEFT" : Vector2i(-1,0),
			}

#=========#
# SIGNALS #
#=========#

signal highlight
signal send_target
signal special_select		# !!! might be deprecated?

func _ready():
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER	# set astar to only use orthagonal movement
	init_astar_map()	# load the map on ready

func _process(delta):
	debug()

func debug():
	var y = null
	var x = g.current_actor if g.current_actor else null
		
	$map_camera/debug.text = "selection: %s\n targeting: %s\ncurrent_actor: %s\n queued_action: %s\n" % [g.selection, g.targeting, x, y]
	

#=====================#
# MAP BUILDER METHODS #
#=====================#

#######################
# FUNCTION: init_astar_map
# Sets up grid and tile size, calls astar.update and then creates an astar grid based on map size
#######################

func init_astar_map():
	astar.size = Vector2i(map_size)
	astar.cell_size = Vector2(64, 64)
	astar.offset = Vector2i(64, 64)
	astar.update()
	create_grid(astar.size)

#######################
# FUNCTION: create_grid
# Creates an array of x,y positions that will have tiles mapped to them, then calls map_to_grid
# to assign grid_tile instances to each
# @params: size, a Vector2i representing number of horitzontal tiles * vertical tiles
#######################

func create_grid(size: Vector2i):
	var builder = Vector2i(0,0)
	var map_tiles = [] 				# could maybe use a 2D array here
	while builder.y < size.y:
		map_tiles.append_array(astar.get_id_path(builder, Vector2i(astar.size.x - 1, builder.y)))
		builder.y += 1
	map_to_grid(map_tiles)
	
#######################
# FUNCTION: map_to_grid
# Instantiates a grid_tile scene for each position on the grid
# Each grid tile scene contains info about it's own astar coordinates, it's occupation status,
# if it's pathfindable, etc. Calls map_obstacles() to set up obstacle pathfinding
# @params: map_tiles, an array of Vector2i grid positions from create_grid()
#######################

func map_to_grid(map_tiles):
	var astar_pos
	var tile
	for point in map_tiles:
		astar_pos = astar.get_point_position(point)
		tile = new_tile.instantiate()
		$map_grid_tiles.add_child(tile)		# adds new tile as a child of the map_grid_tiles container node
		tile.position = astar_pos			# sets the tile's actual position to the astar actual position
		tile.astar_index = point			# sets the tile's astar_index to the astar position
		astar_to_tile[point] = tile			# adds the tile to the astar_to_tile dictionary as a astar:tile k:v pair
	map_obstacles()

#######################
# FUNCTION: map_obstacles
# Unpassable tiles are on layer 1 of the tilemap. This function collects all tilemap cells on layer 1
# and sets each as an obstacle and disables pathfinding to it. Then calls build_pathfinding() to
# initialize the neighbor pathfinding system
#######################

func map_obstacles():
	var obstacles = $level_map.get_used_cells(1)
	for o in obstacles:
		astar_to_tile[o].obstacle = true
		astar.set_point_solid(o, true)
	build_pathfinding()

#######################
# FUNCTION: build_pathfinding
# Gets each tile's neighbors which will be used for pathfinding
# This is basically the last step of map set up, so then calls confirm_units to get all unit's starting positions
#######################

func build_pathfinding():
	for astar in astar_to_tile:
		get_neighbors(astar_to_tile[astar])
	await get_tree().create_timer(.1).timeout
	confirm_units()

#######################
# FUNCTION: get_neighbors
# Called on each tile individually. For each tile, checks in each cardinal direction and if there is a valid
# astar tile in range, it adds it to it's own neighbors array. Pathfinding will be built out from this.
# @params: tile_id, the Node for each tile
#######################

func get_neighbors(tile_id: Area2D):
	var start_pos = tile_id.astar_index	
	var dest = Vector2(0,0)
	for d in dir:
		dest = start_pos + dir[d]
		if astar.is_in_boundsv(dest):
			tile_id.neighbors.append(astar_to_tile[dest])

#######################
# FUNCTION: confirm_units
# Calls each unit on the map to get it's own tile position and set it's tile to occupied
#######################

func confirm_units():
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, "units", "get_unit_pos")

#=================================#
# UNIT SELECTION and CONFIRMATION #
#=================================#

#######################
# FUNCTION: tile_select
# Called from each tile when clicked. Depending on the current gamestate (see Global), this executes
# different actions.
# - If no units are selected, it will select a player unit and set that unit as the Global "current actor"
# -NYI- If no units selected an enemy clicked, shows enemy info
# - If a player unit has initialized an action, confirms that action if the tile is a valid target
# - Does nothing if during an enemy or NPC turn
# - Will likely need to be expanded/modified for different states
# @params: tile_id, the grid_tile node that was clicked
#######################

func tile_select(tile_id : Node2D):
	var actor = tile_id.get_unit_on_tile()
	print("valid: ", tile_id.valid_selection, " --- occupied: ", tile_id.occupied)
	
	match g.selection:
		g.NO_SELECTION:
			g.reset_nav()
			if actor and actor.is_in_group("player_units"):
				actor.set_player_actor()
		g.PLAYER_ACTION:
			if tile_id.valid_selection:
				validate_target(tile_id)
			else:
				g.reset_nav()
				emit_signal("send_target", null)
				g.post_action_cleanup(g.current_actor)
				if actor:	# if there's a unit on the clicked tile...
					if actor == g.current_actor: return		# if it's our current unit, do nothing
					elif actor.is_in_group("player_units"): actor.set_player_actor()	# if it's another player unit, switch to that unit
					elif actor.is_in_group("enemy_units"):
						g.deselect(g.current_actor) # NYI, will show enemy details
					
		g.POPUP_LOCKED: pass
		g.NPC_SELECTION:
			pass
		g.ENEMY_TURN:
			pass

#######################
# FUNCTION: validate_target
# Called by tile_select if a player unit is in an active targeting state. While in this state, waits
# for user input, and signals the skill to execute when it receives target data.
# Currently "special" state doesn't do anything
#######################

func validate_target(tile_id):
	var target = tile_id.get_unit_on_tile()
#	var c = 0
#	while c == 0:
#		await get_tree().create_timer(.1).timeout

	match g.targeting:
		g.PLAYER_MOVE:
			if tile_id.valid_selection == true and tile_id.occupied == false:
				print("Validate movement tile.")					
				emit_signal("send_target", tile_id)
				return tile_id
		g.PLAYER_ATTACK:
			if tile_id.valid_selection == true and tile_id.occupied == true:
				print("Validate target tile.")
				emit_signal("send_target", tile_id)
				return tile_id
		g.PLAYER_HELP:
			if tile_id.valid_selection == true and tile_id.occupied == true:
				if target.is_in_group("player_units"):
					print("validing player help")
					print("Validate support tile.")
					emit_signal("send_target", tile_id)
					return tile_id
		g.SPECIAL:			# This currently doesn't really do anything
			if tile_id.valid_selection:
				print("Validate special tile.")
				emit_signal("send_target", tile_id)
				return tile_id
	return
			
#============================#
# PATHFINDING / RANGEFINDING #
# !!! these have been moved to skills_library for player units at least #
#============================#

#######################
# FUNCTION: pathfind_basic
# Basic rangefinding method. Checks each adjacent tile, deducts movement, and if there's still movement left,
# repeats the process for the next tile
# !!! Will likely need expansion when building "difficult terrain" and so on
# @params:  tile_id, the grid_tile node that was clicked
#			distance, an int representing the distance to pathfind
#######################
			
func pathfind_basic(tile_id, distance):
	if distance == 0:
		return
	for neighbor in tile_id.neighbors:
		if neighbor.obstacle == false and neighbor.occupied == false: 
			if neighbor.move_cost <= distance:
				neighbor.set_highlight()
				neighbor.valid_selection = true
				pathfind_basic(neighbor, (distance - neighbor.move_cost))

#######################
# FUNCTION: pathfind_shift
# Rangefinding for shift-type movements and open targeting. Ignores unit collision when finding path.
# @params:  tile_id, the grid_tile node that was clicked
#			distance, an int representing the distance to pathfind
#######################
				
func pathfind_shift(tile_id, distance):
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
