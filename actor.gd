extends Node2D
class_name Actor

#======================
# CLASS: Actor
# Base class controller for individual units. Player and NPC units inherit from this. Includes logic for
# initializing UI elements, basic stats, start/end of turn upkeep, signals, taking and dealing damage,
# adding and removing buffs.
#======================

#====================#
# INSTANCE VARIABLES
#====================#

# skill info
@export var skill_data = Resource

var skill_loadout = []

# enums for handling skill types and action points
enum {PASS, MOVE, BASIC, HEAVY, AREA, DEF, MNVR, UTIL, ULT}
enum {ANY, NO_SKILL, NO_MOVE, SPENT}

# basic info variables
@export var max_health : int
@export var base_movement : int
var movement : int
var health: int

var cooldowns = {}
const default_action_pool = {
	"move" : 1,
	"skill": 1,
	"flex": 1
}
# !!! should look into why this doesn't work without the read only bit in _ready
var action_pool = default_action_pool.duplicate() 

# pointers and misc setup

var sk
var buffs

var ui_bar = null			# when the unit's UI builds itself, it attaches here
var group_name : String		# stores each individual unit's group name, which is used to refer to that unit's UI elements

var scaled_damage_taken_mods = []
var scaled_damage_dealt_mods = []


#=========#
# SIGNALS #
#=========#
signal action_finished
signal dealt_damage		# tells the game controller and other units that this unit dealt damage
signal took_damage		# tells the game controller and other units that this unit took damage
signal healed_damage	# tells the game controller and other units that this unit healed damage
signal can_react
signal resolve_ready
signal reacted
signal animation_finished

signal shifted
signal moved

signal special_popup_confirm	# confirms a special popup action has been finished
signal queued_action_finished
signal send_target

#=================#
# STATE VARIABLES
# These frequently updated variables that inform where the unit is on the map
# and what actions it can take
#=================#

var actions = ANY
var astar_pos: Vector2i
var origin_tile:  Area2D
var states

#=====================#
# UNIT INITIALIZATION #
#=====================#

#=================#
# FUNCTION: setup_unit
# Called from a unit's _ready()
# Sets up the unit's action pool, initializes cooldowns through init_cooldowns,
# calls create_ui from the camera to create a UI bar for this unit,
# connects the unit to the turn controller for upkeep
#=================#

func setup_unit():
	buffs = $buff_list
	health = max_health
	movement = base_movement

	default_action_pool.make_read_only()
	init_cooldowns()
	Global.camera.create_ui(self)
	Global.start_turn.connect(Callable(self, "start_turn_upkeep"))
	init_passive()

#=================#
# FUNCTION: init_passive
# Placeholder for units to set up their passives if needed
# Called by _ready()
#=================#

func init_passive():
	pass

#=================#
# FUNCTION: init_cooldowns
# Sets up a dictionary to hold the unit's skill cooldowns, with the skill's name as key
# Called by _ready()
# !!! may be changing this to skill types or something
#=================#
func init_cooldowns():
	for skill in skill_loadout:
		if skill != null:
			var n = skill.name
			cooldowns[n] = 0


#=================#
# FUNCTION: action_handler
# Sets the unit's action point availability based on which actions have been spent
# Usually called by finish_action
#=================#

func action_handler():
	actions = ANY
	if action_pool["move"] < 1 and action_pool["flex"] < 1:
		actions = NO_MOVE
	elif action_pool["skill"] < 1 and action_pool["flex"] < 1:
		actions = NO_SKILL
	if action_pool["skill"] < 1 and action_pool["flex"] < 1 and action_pool["move"] < 1:
		actions = SPENT

#=================#
# FUNCTION: finish_action
# Post action cleanup step, called when an action is finished
# Decrements the appropriate action point, calls the action_handler to change state as needed
# Calls global post_action_cleanup
#=================#

func finish_action(act_type):
	await get_tree().create_timer(.1).timeout
	
	get_tree().call_group(group_name, "set_button_state")

	Global.reset_nav()
	deduct_action(act_type)
	
	states.set_unit_state("actor_finished")

	emit_signal("send_target", null)	# failsafe to clear targets. feels like this shouldn't work?




func deduct_action(act_type):
	if act_type == "free":
		return
	if action_pool[act_type] > 0:
		action_pool[act_type] -= 1
	else:
		action_pool["flex"] -= 1
	action_handler()
	get_tree().call_group(group_name, "update_actions_ui")
	get_tree().call_group(group_name, "set_button_state")

#=================#
# FUNCTION: start_turn_upkeep
# Handles start-of-turn upkeep, namely decrementing cooldowns and resetting action points
# Refreshes all action_pool values to their defaults, then calls update_actions_ui to update UI
#=================#

func start_turn_upkeep():
	print(name, " turn start upkeep")
	for k in action_pool:
		action_pool[k] = default_action_pool[k]
	for cd in cooldowns:
		if cooldowns[cd] > 0: cooldowns[cd] -= 1
	action_handler()
	get_tree().call_group(group_name, "update_actions_ui")
	get_tree().call_group(group_name, "set_button_state")

#=================#
# FUNCTION: end_turn
# Clears any targetting data, confirms the unit's position and state, informs game controller than
# player turn has ended
# !!! this could probably move to global too
#=================#

func end_turn():
	Global.reset_nav()
	get_unit_pos()
	Global.end_player_turn()

#=================#
# FUNCTION: get_unit_pos
# Get's the units current tile and astar_position.
# Also sets the unit's tile as occupied for pathfinding purposes
#=================#

func get_unit_pos():
	if $actor_core/actor_area.get_overlapping_areas():
		var a = $actor_core/actor_area.get_overlapping_areas()
		astar_pos = a[0].astar_index
		origin_tile = a[0]
		origin_tile.occupied = true		# this might be a problem with shifting?
		print(name, " getting unit position...")

func deal_damage(target : Node2D, damage : int):
	states.set_unit_state("actor_attacking", {"target": target})
	target.states.set_unit_state("actor_under_attack", {"source": self})
	await self.resolve_ready
	target.take_damage(self, damage)

#=================#
# FUNCTION: scaled_damage_taken_reduction:
# Helper function that averages all % based damage reduction in damage_taken_mods 
#=================#

func scaled_damage_taken_reduction(damage):
	print("Reducing damage ", scaled_damage_taken_mods)
	var total = 0
	if scaled_damage_taken_mods.size() > 0:
		for n in scaled_damage_taken_mods:
			total += n
		print("Damage reduced by : ", total, " on ", self.name)
		var modified_damage = (damage * (total / scaled_damage_taken_mods.size()))
		return floor(modified_damage)
	return damage

#=================#
# FUNCTION: take_damage
# Decrements health when attacked, sends a signal to the damaging actor that damage was successful,
# calls combat_text and updates the health bar
#=================#

func take_damage(source : Node2D, damage : int):
	var damage_modified = scaled_damage_taken_reduction(damage)
	health = health - damage_modified
	combat_text(damage_modified)
	get_tree().call_group(group_name, "update_health_bar")
	emit_signal("took_damage")
	source.i_dealt_damage(self, damage_modified)
	incoming_resolved()

func incoming_resolved():
	if !states.actor_state:
		print("Actor may be in an invalid state?")
	if Global.current_actor == self:
		return
	if states.actor_state == states.get_node("actor_idle"):
		return
	states.set_unit_state("actor_finished")


#=================#
# FUNCTION: heal_damage
# Increments health when healed, stores overhealing info
# !!! NYI fully
#=================#
func heal_damage(source : Node2D, healing : int):
	if health + healing > max_health:
		health = max_health
		var overheal = healing - (max_health - health)		# overhealing will probably do something at some point
	else:
		health += healing
		combat_text(healing, Color.GREEN)

	get_tree().call_group(group_name, "update_health_bar")
	incoming_resolved()
	
# when a unit takes damage, it calls this method to confirm with it's attacker if the attack was successful
# and thus trigger on hits and that sort of thing

#=================#
# FUNCTION: i_dealt_damage
# Tells listeners that this unit successfully dealt damage
# !!! For now this connects to the Bloodthane's passive, will need expansion/tweaking
#=================#

func i_dealt_damage(target: Node2D, damage : int):
	await self.action_finished
	emit_signal("dealt_damage", target, damage)

#=================#
# FUNCTION: combat_text
# Displays floating combat text when damage is dealt
#=================#

func combat_text(to_display, color: Color = Color.WHITE_SMOKE):
	var t = preload("res://UI/combat_text.tscn")
	var combat_text = t.instantiate()
	$local_text.add_child(combat_text)
	combat_text.setup(to_display, color)


#=================#
# FUNCTION: add_buff
# Adds a new buff to this unit's buff_list node and updates the buff bar
#=================#

func add_buff(buffname):
	$buff_list.add_child(buffname)
	ui_bar.update_buff_bar()

#=================#
# FUNCTION: remove_buff
# Removes a buff from this unit's buff_list node and updates the buff bar
#=================#

func remove_buff(buffname):
	$buff_list.remove_child(buffname)
	buffname.ui_icon.queue_free()
	ui_bar.update_buff_bar()
	buffname.queue_free()
