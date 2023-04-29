extends Node
class_name Global_Controller

#======================#
# SINGLETON: Global
# A collection of global variables that will be referenced by multiple scripts in each map
#======================#

#============#
# QUICK REFS #
#============#

@onready var level = get_node("/root/level")
@onready var camera = get_node("/root/level/map_camera")
@onready var enemy = level.find_child("enemy_controller")
@onready var popup = preload("res://UI/popup_ui.tscn")
@onready var skill_lib = load("res://skills/skills_library.tres")
@onready var blank_icon = load("res://GFX/Generic Icons/blank_square.png")
var s	# will hold state machine


var dir = {	"UP" : Vector2i(0,-1),
			"RIGHT" : Vector2i(1,0),
			"DOWN" : Vector2i(0,1),
			"LEFT" : Vector2i(-1,0),
			}
			
var dir_to_vec = {	Vector2(0,-1) : "up",
					Vector2(1,0) : "right",
					Vector2(0,1) : "down",
					Vector2(-1,0) : "left",
				}

#======================#
# KEY GROUPS AND SIGNALS
# GROUPS:
#	control - calls to this singleton
#	map - calls to the level_map
#	xx_ui - calls to a specific unit's ui_bar (xx = bt for bloodthane, tl for traceless, etc.)
#	tiles - calls to all map tiles
#	units - calls to all units
#	player_units - calls to all player units
#	bloodthane - calls to a specific unit... !!! not used?
#
# SIGNALS:
#	start_turn
#	end_turn
#
#======================#

#====================#
# INSTANCE VARIABLES #
#====================#

@onready var current_actor = null			# the current actor selected by the player or AI
var action_queue = []

#=========#
# SIGNALS #
#=========#

signal start_turn
signal end_turn

func _ready():
	self.add_to_group("control")				# adds itself to "control" group for signal calls
	Engine.register_singleton("Global", self)	# registers itself as a singleton.
												# seems to be needed for reference-based scripts to find it.
	var state_machine = load("res://core/game_states/state_machine.tscn")
	s = state_machine.instantiate()
	add_child(s)

#===============#
# TURN HANDLING #
#===============#

func end_player_turn():
	deselect()
	s.change_selection_state("no_selection")
	get_tree().call_group("queued_action_buttons", "queue_free")
	emit_signal("end_turn")
	enemy.start_enemy_turn()

func end_enemy_turn():
	deselect()
	s.change_selection_state("no_selection")
	print("Player turn start!")
	emit_signal("start_turn")		# !!! temporary for testing buffs, will need to expand and modify
	select_unit(get_tree().get_first_node_in_group("player_units"))

#=====================#
# GLOBAL NAV HANDLING #
#=====================#

#######################
# FUNCTION: reset_nav
# Calls all tiles to reset their states to default, clearing all pathfinding highlight and flags.
# If any tiles are suppressed, unsuppresses them
#######################

func reset_nav():
	get_tree().call_group("tiles", "clear_tiles")

#######################
# FUNCTION: deselect
# Called when a unit is deselected, either manually or after finishing an action.
#######################

func deselect():
	reset_nav()
	get_tree().call_group("units", "hide_ui")
	if is_instance_valid(current_actor):
		current_actor.states.set_unit_state("actor_idle")
	current_actor = null


func select_unit(unit):
	deselect()					# deselect current selection
	current_actor = unit			# set global actor to this unit
	unit.states.set_unit_state("actor_selected")

	
func suppress_collision():
	get_tree().call_group("units", "suppress_collision")
	
func unsuppress_collision():
	get_tree().call_group("units", "unsuppress_collision")


#=================#
# ACTION QUEUEING #
#=================#

#==============================#
# FUNCTION: add_to_queue
# Actions are added to the queue as callables with all skill data available:
# the skill resource, the execute method and the unit executing the skill
# Here we link that callable to the resolve_queued_action method and link
# that with a (hopefully) unique button
# TODO: Set up proper button positioning box
# - May need to change the queuing system so we can add the icon and tooltip too
# - Probably need a way to cancel the queued action
#==============================#

func add_to_queue(unit, skill, callable):
	var flex_button = load("res://UI/flex_button.tscn")
	var new_button = flex_button.instantiate()				# create a new button for a queued action
	new_button.add_to_group("queued_action_buttons")
	new_button.texture_normal = skill.icon
	add_child(new_button)
	action_queue.append(new_button)
	new_button.set_global_position(unit.position)			# set position
	new_button.z_index = 5
	
	var c = Callable(self, "resolve_queued_action")			# link callable to button
	var call_queued = c.bind(callable, unit, skill)
	var q = Callable(self, "queued_cleanup")				# link cleanup callable
	var queued_cleanup = q.bind(new_button)

	new_button.pressed.connect(call_queued)					# connect signals, button pressed activates skill
	unit.queued_action_finished.connect(queued_cleanup)		# queued_action_finished is emitted from unit

# !!! if we're going to pause the game, we need to lock out ALL other options including other flex buttons
# !!! related? : when we click again on the button it causes issues... button needs a way to cancel

func resolve_queued_action(callable, unit, skill):
	deselect()
	s.change_selection_state("player_target", skill.target_info.duplicate(true))
	current_actor = unit
	callable.call()

func queued_cleanup(button):
	button.queue_free()
	#get_tree().paused = false
	if button in action_queue:
		action_queue.erase(button)
