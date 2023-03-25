extends Node2D

@onready var g = get_node("/root/Global")
var sk = load("res://skills/bloodthane_skills.tres")

enum {ANY, NO_SKILL, NO_MOVE, SPENT}

@export var health = 12
@export var movement = 4
@export var skills = Resource

const default_action_pool = {
	"move" : 1,
	"skill": 1,
	"flex": 1
}

var action_pool = default_action_pool.duplicate()

###################
# STATE VARIABLES #
###################

var actions = ANY
var astar_pos = Vector2i(0,0)
var origin_tile = Area2D

func _ready():
	default_action_pool.make_read_only()
	link_skills()
	
func _process(delta):
	pass

func link_skills():
	sk.unit = self

func set_player_actor():
	get_unit_pos()
	g.set_select_state(g.PLAYER_ACTION)
	g.current_actor = self
	$battle_menu.show_menu()
	
func hide_menu():
	$battle_menu.hide_menu()	

func action_handler():
	actions = ANY
	if action_pool["move"] < 1 and action_pool["flex"] < 1:
		actions = NO_MOVE
	elif action_pool["skill"] < 1 and action_pool["flex"] < 1:
		actions = NO_SKILL
	if action_pool["skill"] < 1 and action_pool["flex"] < 1 and action_pool["move"] < 1:
		actions = SPENT

func finish_action(act_type):
	if action_pool[act_type] > 0:
		action_pool[act_type] -= 1
	else:
		action_pool["flex"] -= 1
	action_handler()
	$battle_menu.update()
	await get_tree().create_timer(.1).timeout
	g.post_action_cleanup(self)
	get_tree().call_group("menu", "reset_menu")
	
# move some of this to start turn?

func set_target(target):
	sk.target = target

func end_turn():
	for k in action_pool:
		action_pool[k] = default_action_pool[k]
	await get_tree().create_timer(.1).timeout
	get_unit_pos()
	action_handler()
	g.selection = g.NO_SELECTION
	g.end_player_turn()
	get_tree().call_group("menu", "reset_menu")
	
func get_unit_pos():
	if $actor_core/actor_area.get_overlapping_areas():
		var a = $actor_core/actor_area.get_overlapping_areas()
		astar_pos = a[0].astar_index
		origin_tile = a[0]

func take_damage(damage):
	health = health - damage
	$battle_menu.update()



#func init_move1():
#	g.level.reset_nav()
#	if actions != NO_MOVE or actions != SPENT:
#		get_unit_pos()
#		g.selection = g.PLAYER_ACTION
#		g.targeting = g.PLAYER_MOVE
#		g.level.pathfind_basic(origin_tile, movement)
#		queued_action = Callable(self, "move")

#func move1(target_tile):
#	if moving == false:
#		print(origin_tile)
#		var path = g.level.astar.get_id_path(origin_tile.astar_index, target_tile)
#		var waypoint
#		var tween = create_tween()
#		moving = true
#		for point in path:
#			waypoint = g.level.astar_to_tile[point].position
#			tween.tween_property($actor_core, "position", waypoint, .1)
#		await tween.finished
#		moving = false
#		await get_tree().create_timer(.1).timeout
#		get_unit_pos()
#		finish_action("move")



