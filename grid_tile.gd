#======================#
# SCENE: grid_tile
# Creates the graphics and stores values for each tile in the map grid. Each tile individually knows
#w hether or not it is: pathfindable, a valid target, and occupied by a unit.
# Each tile also stores an array of it's neighbors to aid with pathfinding.
#======================#

extends Area2D

@onready var g = get_node("/root/Global")		# quick reference to Global singleton
@export var move_cost = 1						# move cost multiplier for rough terrain

var astar_index = Vector2i(0,0)					# astar position of the tile
var neighbors = []								# array of neighbor tiles
var valid_selection = false						# flagged if a tile is determined to be valid during rangefinding
var occupied = false							# set if tile is currently occupied by a unit
var obstacle = false							# set if tile is currently occupied by an obstacle

func _ready():
	await get_tree().create_timer(.1).timeout		# slight delay to generate the map fully
	$coords.text = str(astar_index, "t" if occupied == true else "f")		# debug: displays tile astar pos
	
func _process(delta):
	pass

#######################
# SIGNALLED FUNCTION: on_input_event
# Gets clicks and notifies the map of the ID of the tile that was selected
# Results of click are handled by level_map script and Global singleton states
# @event: the mouse click
#######################
	
func _on_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("left_click"):
		get_tree().call_group("map", "tile_select", self)
#		g.level.tile_select(astar_index)	# in case something breaks?

#######################
# FUNCTION: clear_tiles
# Calls a tile to reset it's display to default (unselected, no pathfinding). Usually called
# as a group call to all tiles.
#######################

func clear_tiles():
	valid_selection = false
	g.collision_tiles.clear()
	$grid_outline.frame = 0
	$grid_outline.modulate.a = 1

#######################
# FUNCTION: get_unit_on_tile
# Checks for units on the tile.
# !!! will need expansion if we implement multiple units on a tile for some reason
#######################

func get_unit_on_tile() -> Node2D:
	var occupants = get_overlapping_areas()
	for unit in occupants:
		if unit is Node2D and unit != null:
			return unit.get_parent().get_parent()
	return 

#######################
# FUNCTION: set_highlight
# Sets the color of valid selectable tiles depending on the current action state.
# Movement: Cyan. Attacks: Red. Support: Green.
#######################
	
func set_highlight():
	match g.targeting:
		g.PLAYER_MOVE:
			$grid_outline.frame = 1
			$grid_outline.modulate.a = .5
		g.PLAYER_ATTACK:
			$grid_outline.frame = 2
		g.PLAYER_HELP:
			$grid_outline.frame = 3
		g.SPECIAL:
			$grid_outline.frame = 2	

#######################
# FUNCTION: suppress_collision
# Calls tiles to suppress unit collision. Currently, the astar grid seems to require units to be
# marked "solid" like obstacles to prevent pathfinding. !!! (Can we rewrite to just block "occupied?"
# For each tile that is occupied and not an obstacle, we temporary remove "solid" so it is pathfindable.
# Adds the suppressed tiles to an array in the Global singleton to be unsuppressed later.
#######################

func suppress_collision():
	print("Suppression called")
	if occupied == true and obstacle == false:
		g.level.astar.set_point_solid(astar_index, false)
		g.collision_tiles.append(self)
		print(astar_index, "suppressed")

#######################
# FUNCTION: unsuppress_collision
# Undoes suppressing collision on each tile in the array in the Global singleton.
#######################
	
func unsuppress_collision():
	print("Unsuppression called")
	if get_unit_on_tile():
		print(occupied, astar_index, "unsuppressed")
		g.level.astar.set_point_solid(self.astar_index, true)
		occupied = true
		print(astar_index, " ", occupied)
	g.collision_tiles.clear()


#######################
# SIGNALLED FUNCTION: on_area_entered
# When a unit enters a tile, the tile is marked occupied and pathfinding is disabled.
# @params: area, the tile entered
#######################

func _on_area_entered(area):
	occupied = true
	g.level.astar.set_point_solid(astar_index, true)

#######################
# SIGNALLED FUNCTION: on_area_exited
# When a unit enters a tile, the tile is marked unoccupied and pathfinding is reenabled.
# @params: area, the tile entered
#######################
	
func _on_area_exited(area):
	if !get_unit_on_tile():
		occupied = false
		g.level.astar.set_point_solid(astar_index, false)

# for debug

func _on_mouse_entered():
	pass
	#print(astar_index, " ", position, " ", valid_selection, occupied)
