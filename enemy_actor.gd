extends Node

@onready var g = get_node("/root/Global")
@onready var target_pool = g.level.find_child("player_units").get_children()
@onready var buffs = $buff_list

enum {MOVE, SHIFT}
enum {ANY, NO_SKILL, NO_MOVE}

@export var buff_list = Node
@export var skills = Resource

@export var max_health = 9
@export var movement = 4


var health = max_health


var movetype = MOVE

signal end_turn_signal
signal dealt_damage

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
	await get_tree().create_timer(.1).timeout
	get_unit_pos()
	
func _process(delta):
	pass

func set_enemy_actor():
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
	await move(path)
			
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
		self.deal_damage(target, 5)
		print("attack!")
	g.reset_nav()

func face_target(target):
	pass

func deal_damage(target : Node2D, damage : int):
	# insert conditionals here
	target.take_damage(self, damage)

func take_damage(source : Node2D, damage : int):
	health = health - damage
	if health <= 0:
		origin_tile.occupied = false
		queue_free()
	source.i_dealt_damage(self, damage)
	combat_text(damage)
		
func combat_text(damage):
	var tween = create_tween()
	$local_text/combat_text.text = (str(damage))
	tween.tween_property($local_text/combat_text, "position", $local_text/combat_text.position + Vector2(50,-50), 1)
	await tween.finished
	$local_text/combat_text.text = ""

func i_dealt_damage(target: Node2D, damage : int):
	emit_signal("dealt_damage", damage, target)

func heal_damage(source : Node2D, healing : int):
	if health + healing > max_health:
		health = max_health
		var overheal = healing - (max_health - health)		# overhealing will probably do something at some point
		
func add_buff(buffname):
	$buff_list.add_child(buffname)

func remove_buff(buffname):
	$buff_list.remove_child(buffname)

func suppress_collision():
	get_unit_pos()
	g.level.astar.set_point_solid(astar_pos, false)

func unsuppress_collision():
	get_unit_pos()
	g.level.astar.set_point_solid(astar_pos, true)

