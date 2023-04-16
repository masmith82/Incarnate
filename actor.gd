extends Node2D

#====================#
# INSTANCE VARIABLES
#====================#

# skill info
@export var skill_data = Resource
var sk
var skill_loadout = []

# enums for handling skill types and action points
enum {PASS, MOVE, BASIC, HEAVY, AREA, DEF, MNVR, UTIL, ULT}
enum {ANY, NO_SKILL, NO_MOVE, SPENT}

# basic info variables
@export var max_health : int = 0
@export var movement : int = 0
var health

var cooldowns = {}
const default_action_pool = {
	"move" : 1,
	"skill": 1,
	"flex": 1
}
# !!! should look into why this doesn't work without the read only bit in _ready
var action_pool = default_action_pool.duplicate() 

# pointers and misc setup
@onready var g = get_node("/root/Global")
var buffs

var ui_bar					# when the unit's UI builds itself, it attaches here
var group_name : String		# stores each individual unit's group name, which is used to refer to that unit's UI elements


#=========#
# SIGNALS #
#=========#
signal dealt_damage		# tells the game controller and other units that this unit dealt damage
signal took_damage		# tells the game controller and other units that this unit took damage
signal healed_damage	# tells the game controller and other units that this unit healed damage
signal shifted
signal moved
signal special_popup_confirm	# confirms a special popup action has been finished
signal queued_action_finished
#=================#
# STATE VARIABLES
# These frequently updated variables that inform where the unit is on the map
# and what actions it can take
#=================#

var actions = ANY
var astar_pos = Vector2i(0,0)
var origin_tile = Area2D

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
	default_action_pool.make_read_only()
	init_cooldowns()
	g.camera.create_ui(self)
	g.start_turn.connect(Callable(self, "start_turn_upkeep"))
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
# FUNCTION: set_player_actor
# In forms the game controller singleton that this unit is the current actor,
# gets it's position and changes the selection state and displays the unit's UI
# !!! this could probably just be handled from global?
#=================#

func set_player_actor():
	if g.current_actor:
		g.deselect()		# if we have an actor selected, deselect it
	get_unit_pos()
	g.set_select_state(g.PLAYER_SELECT)
	g.current_actor = self
	ui_bar.update_ui()
	ui_bar.show()

#=================#
# FUNCTION: hide_ui
# Hide's the unit's UI bar
#=================#

func hide_ui():
	ui_bar.hide()

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
	if act_type == "free":
		g.post_action_cleanup(self)
		return
	if action_pool[act_type] > 0:
		action_pool[act_type] -= 1
	else:
		action_pool["flex"] -= 1
	action_handler()
	await get_tree().create_timer(.1).timeout
	g.post_action_cleanup(self)

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
		get_tree().call_group(group_name, "set_button_state")
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
	g.reset_nav()
	get_unit_pos()
	g.selection = g.NO_SELECTION
	g.end_player_turn()

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

func deal_damage(target : Node2D, damage : int):
	# insert conditionals here
	target.take_damage(self, damage)

#=================#
# FUNCTION: take_damage
# Decrements health when attacked, sends a signal to the damaging actor that damage was successful,
# calls combat_text and updates the health bar
#=================#

func take_damage(source : Node2D, damage : int):
	health = health - damage
	source.i_dealt_damage(self, damage)
	combat_text(damage)
	get_tree().call_group(group_name, "update_health_bar")

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
	get_tree().call_group(group_name, "update_health_bar")

# when a unit takes damage, it calls this method to confirm with it's attacker if the attack was successful
# and thus trigger on hits and that sort of thing

#=================#
# FUNCTION: i_dealt_damage
# Tells listeners that this unit successfully dealt damage
# !!! For now this connects to the Bloodthane's passive, will need expansion/tweaking
#=================#

func i_dealt_damage(target: Node2D, damage : int):
	emit_signal("dealt_damage", target, damage)

#=================#
# FUNCTION: combat_text
# Displays floating combat text when damage is dealt
#=================#

func combat_text(damage):
	var tween = create_tween()
	$local_text/combat_text.text = (str(damage))
	tween.tween_property($local_text/combat_text, "position", $local_text/combat_text.position + Vector2(50,-50), 1)
	await tween.finished
	$local_text/combat_text.text = ""
	$local_text/combat_text.position = Vector2(0,0)

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
	ui_bar.update_buff_bar()

func suppress_collision():
	await get_tree().create_timer(.1).timeout
	get_unit_pos()
	g.level.astar.set_point_solid(astar_pos, false)

func unsuppress_collision():
	await get_tree().create_timer(.1).timeout
	get_unit_pos()
	g.level.astar.set_point_solid(astar_pos, true)
