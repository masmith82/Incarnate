########################
# SCENE: grid_tile
# Creates the graphics and stores values for each tile in the map grid.
# Each tile individually knows whether or not it is:
# pathfindable, a valid target, and occupied by a unit.
# Each tile also stores an array of it's neighbors to aid with pathfinding.
########################

extends Area2D

@onready var g = get_node("/root/Global")
@export var astar_index = Vector2i(0,0)
@export var move_cost = 1

var neighbors = []
var valid_selection = false
var occupied = false
var obstacle = false
var locked = false

signal tile_clicked

func _ready():
	await get_tree().create_timer(.1).timeout		# slight delay to generate the map fully

func _process(delta):
	pass
	$coords.text = str(astar_index, "t" if occupied == true else "f")		# debug

# gets clicks and notifies the map of the astar index of the clicked tile
# tile_select also handles selecting units and issuing orders

func _on_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("left_click"):
		g.level.tile_select(astar_index)

func clear_tiles():
	set_modulate(Color(255,255,255,255))

func clear_valid():
	valid_selection = false
	
func get_unit_on_tile():
	var occupants = get_overlapping_areas()
	for unit in occupants:
		if unit is Node2D:
			return unit.get_parent().get_parent()
	
func set_highlight():
	match g.targeting:
		g.PLAYER_MOVE:
			set_modulate(Color(0,0,255))
		g.PLAYER_ATTACK:
			set_modulate(Color(255,0,0))
		g.PLAYER_HELP:
			set_modulate(Color(0,255,0))
		g.SPECIAL:
			set_modulate(Color(0,255,255))
			
func suppress_collision():
	if occupied == true and obstacle == false:
		g.level.astar.set_point_solid(astar_index, false)
		g.collision_tiles.append(self)
		print(astar_index, "suppressed")
	
func unsuppress_collision():
	for tile in g.collision_tiles:
		if occupied:
			g.level.astar.set_point_solid(tile.astar_index, true)
	g.collision_tiles.clear()
	g.collision_suppressed = false

func _on_area_entered(area):
	if g.collision_suppressed == false:
		occupied = true
		g.level.astar.set_point_solid(astar_index, true)
	
func _on_area_exited(area):
	occupied = false
	g.level.astar.set_point_solid(astar_index, false)


func _on_mouse_entered():
	pass
	#print(astar_index, " ", position, " ", valid_selection, occupied)
