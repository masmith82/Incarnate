extends Node

@onready var g = get_node("/root/Global")
@onready var target_pool = g.level.find_child("player_units").get_children()
enum {MOVE, SHIFT}
enum {ANY, NO_SKILL, NO_MOVE}

@export var health = 12
@export var movement = 4

var movetype = MOVE

signal end_turn_signal

###################
# STATE VARIABLES #
###################

var actions = ANY
var astar_pos = Vector2i(0,0)
var origin_tile = Area2D
var target = null
var moving = false
var queued_action

func _ready():
	get_unit_pos()
	
func _process(delta):
	pass

func set_enemy_actor():
	print("Setting actor")
	g.selection = g.ENEMY_TURN
	queued_action = null
	get_unit_pos()
	g.current_actor = self
	
func get_target():
	await random_target()

func random_target():
	var random = randi_range(1, target_pool.size())
	target = target_pool[random - 1]
	await path_to_target(target)

func path_to_target(target):
	g.level.astar.set_point_solid(target.origin_tile.astar_index, false)
	var path = g.level.astar.get_id_path(origin_tile.astar_index, target.astar_pos)		
	g.level.astar.set_point_solid(target.origin_tile.astar_index, true)
	path.remove_at(0)
	path.resize(movement)
	path = path.filter(func(coords): return coords != target.astar_pos)
	path = path.filter(func(coords): return coords != Vector2i(0,0))
	print(path)
	await move(path)

func prune_path(coords):
		return coords != target.astar_pos
			
func move(path):
	print(target.astar_pos, path)
	var waypoint
	if path != []:
		var tween = create_tween()
		for point in path:
			waypoint = g.level.astar_to_tile[point].position
			tween.tween_property(self, "position", waypoint, .1)
		if tween: await tween.finished
	await get_tree().create_timer(.1).timeout
	await get_unit_pos()
	await basic_melee()
	
func end_turn():
	g.selection = g.NO_SELECTION
	g.end_enemy_turn()
	
func get_unit_pos():
	if $actor_core/actor_area.get_overlapping_areas():
		var a = $actor_core/actor_area.get_overlapping_areas()
		astar_pos = a[0].astar_index
		origin_tile = a[0]
		
func basic_melee():
	g.level.target_basic(origin_tile, 1)
	if target.origin_tile.valid_selection == true:
		var facing = face_target(target)
		var tween = create_tween()
		tween.tween_property(self, "position", target.origin_tile.position, .1)
		tween.tween_property(self, "position", origin_tile.position, .1)
		target.take_damage(5)
		print("attack!")
	g.reset_nav()
	await end_turn()

func take_damage(damage):
	health = health - damage
	if health <= 0:
		queue_free()

func face_target(target):
		pass
