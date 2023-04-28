extends Skills_Library
class_name Mirage_Shift

@export var fx: PackedScene

@export var name: String = "Mirage Shift"
@export var icon: Texture = preload("res://GFX/Units/Traceless/mirage_shift.png")
@export var cd: int = 3
@export var tt: String = "Create a Shadow in target square. This turn you may swap squares with a Shadow as a free action."
@export var target_info =  {"target" : NEEDS_OPEN,
							"color" : MOVE_TARGET,
							"disjointed" :	[]
							}

@export var special_info =  {"target" : NEEDS_ENEMY,
							"color" : MOVE_TARGET,
							"disjointed" :	[]
							}

var type = MNVR
var button = preload("res://UI/flex_button.tscn")

func execute(unit):
	var origin = unit.origin_tile
	if !move_check(unit): return
	target_basic(origin, 6, false)
	var target = await unit.send_target
	if !target: return

	unit.spawn_shadow(target)
	unit.cooldowns[name] = cd
	unit.finish_action("move")
	
	enable_shadow_swap(unit)

func enable_shadow_swap(unit):
	var new_button = button.instantiate()	# create a new temporary button for free shadow swap
	unit.ui_bar.add_child(new_button)
	new_button.position += Vector2(800, -64)
	new_button.z_index = 5
	new_button.texture_normal = icon
	var shadow_swap_call = Callable(self, "shadow_swap").bind(unit)
	new_button.pressed.connect(shadow_swap_call)
	
func shadow_swap(unit):
	reset_nav()							# makeshift version of new_action/lock_actions
	unit.get_unit_pos()
	Global.s.change_selection_state("player_target", special_info)
	Global.get_tree().call_group(unit.group_name, "set_button_state")
	var origin = unit.origin_tile
	
	# call each shadow to highlight and validate it's own tile
	Global.get_tree().call_group("traceless_shadow", "shadow_swap_highlight")
	var target = await unit.send_target
	if !target: return

	unit.position = target.position
	Global.get_tree().call_group("traceless_shadow", "kill_shadow_at_tile", target)
	unit.spawn_shadow(unit.origin_tile)
	unit.get_unit_pos()
	
	# makeshift cleanup
	Global.s.change_selection_state("player_select")
	reset_nav()
	Global.get_tree().call_group(unit.group_name, "set_button_state")
	Global.get_tree().call_group(unit.group_name, "update_actions_ui")

# !!! error message is coming from shadow being deleted and respawned
