extends Node2D

var sk = load("res://skills/bloodthane_skills.tres")

@onready var g = get_node("/root/Global")
@onready var buffs = $buff_list

enum {ANY, NO_SKILL, NO_MOVE, SPENT}

@export var max_health = 12
@export var movement = 4
@export var skills = Resource

var health = max_health

const default_action_pool = {
	"move" : 1,
	"skill": 1,
	"flex": 1
}

var ui_bar
var group_name = "bt_ui"
var cooldowns = {}

# currently skills are stored in this array and we use these indexes in other places
# 0 = basic attack, 1 = heavy attack, 2 = area attack, and so on

var skill_loadout = [sk.bt_basic_1,
					sk.bt_heavy_1,
					sk.bt_area_1,
					sk.bt_def_1,
					sk.bt_man_1,
					sk.bt_util_1,
					sk.bt_ult_1
					]
					
var action_pool = default_action_pool.duplicate()

signal dealt_damage
signal took_damage
signal healed_damage
signal special_popup_confirm

###################
# STATE VARIABLES #
###################

var actions = ANY
var astar_pos = Vector2i(0,0)
var origin_tile = Area2D

func _process(delta):
	pass

func _ready():
	default_action_pool.make_read_only()
	link_skills()
	init_cooldowns()
	g.start_turn.connect(Callable(self, "start_turn_upkeep"))
	await add_buff(sk.bt_passive.new())

func link_skills():
	sk.unit = self

func init_cooldowns():
	for skill in skill_loadout:
		var n = skill["name"]
		cooldowns[n] = 0

func link_ui(ui):
	ui_bar = ui

func set_player_actor():
	get_unit_pos()
	g.set_select_state(g.PLAYER_ACTION)
	g.current_actor = self
	ui_bar.show()
	
func hide_menu():
	ui_bar.hide()

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
	await get_tree().create_timer(.1).timeout
	g.post_action_cleanup(self)
	
func start_turn_upkeep():
	for cd in cooldowns:
		if cooldowns[cd] > 0: cooldowns[cd] -= 1
		ui_bar.unlock_actions()
		ui_bar.update_ui()

func end_turn():
	for k in action_pool:
		action_pool[k] = default_action_pool[k]
	await get_tree().create_timer(.1).timeout
	g.reset_nav()
	get_unit_pos()
	action_handler()
	g.selection = g.NO_SELECTION
	g.end_player_turn()
	
func get_unit_pos():
	if $actor_core/actor_area.get_overlapping_areas():
		var a = $actor_core/actor_area.get_overlapping_areas()
		astar_pos = a[0].astar_index
		origin_tile = a[0]
		origin_tile.occupied = true		# this might be a problem with shifting?
		
func take_damage(source : Node2D, damage : int):
	health = health - damage
	source.i_dealt_damage(self, damage)
	combat_text(damage)
	get_tree().call_group(group_name, "update_health_bar")
	
func heal_damage(source : Node2D, healing : int):
	if health + healing > max_health:
		health = max_health
		var overheal = healing - (max_health - health)		# overhealing will probably do something at some point
	else:
		health += healing
	get_tree().call_group(group_name, "update_health_bar")

# when a unit takes damage, it calls this method to confirm with it's attacker if the attack was successful
# and thus trigger on hits and that sort of thing


func i_dealt_damage(target: Node2D, damage : int):
	emit_signal("dealt_damage", target, damage)

func combat_text(damage):
	var tween = create_tween()
	$local_text/combat_text.text = (str(damage))
	tween.tween_property($local_text/combat_text, "position", $local_text/combat_text.position + Vector2(50,-50), 1)
	await tween.finished
	$local_text/combat_text.text = ""
	$local_text/combat_text.position = Vector2(0,0)







# had some problems on initializing, so we wait here to make sure the buff_list node is loaded before
# we add the initial passive buffs
# actually just kidding it's still not working :(
# probably just make it a subscript of buff_list I guess

func add_buff(buffname):
	$buff_list.add_child(buffname)
	ui_bar.update_buff_bar()
	
func remove_buff(buffname):
	$buff_list.remove_child(buffname)
	ui_bar.update_buff_bar()
