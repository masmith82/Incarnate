extends Skills_Library
class_name Mirage_Shift

@export var fx: PackedScene

@export var name: String = "Mirage Shift"
@export var icon: Texture = preload("res://GFX/Units/Traceless/mirage_shift.png")
@export var cd: int = 3
@export var tt: String = "Create a Shadow in target square. This turn you may swap squares with a Shadow as a free action."

var type = HEAVY
var button = preload("res://UI/flex_button.tscn")

func execute(unit):
	var origin = unit.origin_tile
	if !move_check(unit): return
	target_basic(origin, 6)
	var target = await g.level.send_target
	if !target: return

	unit.spawn_shadow(target)
	unit.cooldowns[name] = cd
	unit.finish_action("move")
	
	var new_button = button.instantiate()	# create a new temporary button for free shadow swap
	unit.ui_bar.add_child(new_button)
	new_button.position += Vector2(800, -64)
	new_button.z_index = 5
	var c = Callable(self, "shadow_swap")
	var shadow_swap_call = c.bind(unit)
	new_button.pressed.connect(shadow_swap_call)
	
func shadow_swap(unit):
	reset_nav()							# makeshift version of new_action/lock_actions
	unit.get_unit_pos()
	g.set_select_state(PLAYER_ACTION)
	g.set_target_state(PLAYER_MOVE)
	g.get_tree().call_group(unit.group_name, "set_button_state")
	var origin = unit.origin_tile
	
	# call each shadow to highlight and validate it's own tile
	g.get_tree().call_group("traceless_shadow", "shadow_swap_highlight")	
	var target = await g.level.send_target
	if !target: return
	
	unit.position = target.position
	g.get_tree().call_group("traceless_shadow", "kill_shadow_at_tile", target)
	unit.spawn_shadow(unit.origin_tile)
	unit.get_unit_pos()
	
	# makeshift cleanup
	g.set_select_state(PLAYER_SELECT)
	g.set_target_state(NO_TARGET)
	reset_nav()
	g.get_tree().call_group(unit.group_name, "set_button_state")
	g.get_tree().call_group(unit.group_name, "update_actions_ui")
