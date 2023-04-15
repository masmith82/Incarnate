extends Node

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

#======================#
# MATCH STATES
# Used for controlling what actions the player can take depending on if they have a unit selected,
# an ability/movement queued, and so on.
#======================#

enum {NO_SELECTION, PLAYER_SELECT, PLAYER_ACTION, NPC_SELECTION, ENEMY_TURN, UPKEEP, POPUP_LOCKED}
enum {NO_TARGET, PLAYER_MOVE, PLAYER_ATTACK, PLAYER_HELP, SPECIAL}

@onready var selection = NO_SELECTION
@onready var targeting = NO_TARGET

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

var current_actor = null			# the current actor selected by the player or AI
var collision_tiles = []			# an array of tiles collected by suppress_collision, marks tiles
									# to be unsuppressed later
									# !!! (could be moved to the map_tiles container on level?)
var collision_suppressed = false	# flag if tile is suppressed or not. !!! Redundant?

#=========#
# SIGNALS #
#=========#

signal start_turn
signal end_turn

func _ready():
	self.add_to_group("control")				# adds itself to "control" group for signal calls
	Engine.register_singleton("Global", self)	# registers itself as a singleton.
												# seems to be needed for reference-based scripts to find it.

#=========#
# SETTERS #
#=========#

func set_select_state(state):
	selection = state
	
func set_target_state(state):
	targeting = state
	
func get_select_state() -> int:
	return selection
	
func get_target_state() -> int:
	return targeting

#===============#
# TURN HANDLING #
#===============#

func end_player_turn():
	selection = ENEMY_TURN
	emit_signal("start_turn")		# !!! temporary for testing buffs, will need to expand and modify
	enemy.start_enemy_turn()

func end_enemy_turn():
	selection = NO_SELECTION

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
	if !collision_tiles.is_empty():
		unsuppress_collision()
		collision_tiles.clear()

#######################
# FUNCTION: post_action_cleanup
# After a unit complets an action, resets selection/targeting and pathfinding and confirms unit's map pos
#######################

func post_action_cleanup(unit):
	set_select_state(PLAYER_SELECT)
	set_target_state(NO_TARGET)
	level.emit_signal("send_target", null)	# feels like this shouldn't work? added null here?

	unit.get_unit_pos()
	reset_nav()

	get_tree().call_group(unit.group_name, "set_button_state")
	get_tree().call_group(unit.group_name, "update_actions_ui")


#######################
# FUNCTION: deselect
# Called when a unit is deselected, either manually or after finishing an action.
#######################

func deselect(unit):
	reset_nav()
	if unit:
		unit.ui_bar.hide()
	current_actor = null
	get_tree().call_group("menu", "hide_ui")
	selection = NO_SELECTION
	targeting = NO_TARGET

func suppress_collision():
	get_tree().call_group("units", "suppress_collision")
	
func unsuppress_collision():
	get_tree().call_group("units", "unsuppress_collision")
#	for tile in collision_tiles:
#		tile.unsuppress_collision()
