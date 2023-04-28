extends TextureRect

#======================
# SCRIPT: ACTION_POINT_UI
# Controller for the action point display. After each action, checks if the player unit still has
# actions of that type and grays out the icon if they don't.
#======================

var unit

# called during ui initialization, links this UI element to it's unit
func set_ui_detail(linked_unit):
	unit = linked_unit

func update_actions_ui():
	if unit.action_pool["move"] < 1: $move_action.self_modulate = Color(Color.DARK_SLATE_GRAY, .5)
	else: $move_action.self_modulate = Color(1,1,1,1)

	if unit.action_pool["skill"] < 1: $skill_action.self_modulate = Color(Color.DARK_SLATE_GRAY, .5)
	else: $skill_action.self_modulate = Color(1,1,1,1)
	
	if unit.action_pool["flex"] < 1: $flex_action.self_modulate = Color(Color.DARK_SLATE_GRAY, .5)
	else: $flex_action.self_modulate = Color(1,1,1,1)
	
	print(unit.action_pool)
