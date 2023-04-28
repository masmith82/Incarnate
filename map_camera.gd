extends Camera2D

#====================#
# INSTANCE VARIABLES #
#====================#

var camera_speed = 1.0
var camera_movement = Vector2.ZERO
var ui_bar = preload("res://UI/ui_bar.tscn")

#====================#
# FUNCTION: _process:
# Moves camera if gets input, and forces update to keep any UI elements looking correct 
#====================#
	
func _process(delta):
	move_camera(delta)
	force_update_scroll()
	
#====================#
# FUNCTION: create_ui
# Called by each player unit when that unit is initialized
# Instantiates the ui_bar scene, adds it to the tree, and calls setup_ui to populate buttons and data
#====================#

func create_ui(unit):
	var new_ui = ui_bar.instantiate()
	new_ui.unit = unit
	add_child(new_ui)
	if unit.is_in_group("player_units"):
		new_ui.setup_ui(unit)
	else:
		new_ui.setup_NPC_ui(unit)
	print("Created UI for ", unit)

#====================#
# FUNCTION: move_camera
# Simple camera movement logic
#====================#

func move_camera(delta):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			camera_movement = -Input.get_last_mouse_velocity() * delta * camera_speed
		else:
			camera_movement = Vector2.ZERO
	
		position += camera_movement
