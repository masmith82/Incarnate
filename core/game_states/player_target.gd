extends State
class_name Player_Target

enum {ATTACK_TARGET, MOVE_TARGET, AID_TARGET, SPECIAL_TARGET}
enum {NEEDS_ENEMY, NEEDS_ALLY, NEEDS_OPEN, NEEDS_ANY, NEEDS_UNIT}

var target_info
var target_count

func enter(_args := {}):
	print("Player target args: ", _args)
	if "target" in _args:
		target_info = _args
		state_machine.target_color = _args["color"]
	else: print("Targeting error.")
	
func exit(_args := {}):
	Global.reset_nav()
	target_info = null
	state_machine.target_color = null


func handle_click(tile):
	if tile.valid_selection == false:		# if the tile isn't valid, don't need to check anything else
		return
	var unit = tile.get_unit_on_tile()
	var valid = false
	target_count = target_info["disjointed"].size()
	
	match target_info["target"]:
		NEEDS_ANY:
			valid = true
		NEEDS_OPEN:
			if !unit: valid = true
		NEEDS_UNIT:
			if unit: valid = true
		NEEDS_ENEMY:
			if unit and unit.is_in_group("enemy_units"): valid = true
		NEEDS_ALLY:
			if unit and unit.is_in_group("player_units"): valid = true
		_: return
	
#	if target_info["target"] == NEEDS_ANY:
#		valid = true
#	elif !unit and target_info["target"] == NEEDS_OPEN:
#		valid = true
#	elif unit and target_info["target"] == NEEDS_ANY:
#		valid = true
#	elif unit and unit.is_in_group("enemy_units") and target_info["target"] == NEEDS_ENEMY:
#		valid = true
#	elif unit and unit.is_in_group("player_units") and target_info["target"] == NEEDS_ALLY:
#		valid = true


	if valid == true:
		if target_count <= 0:
			Global.current_actor.emit_signal("send_target", tile)
			var execute_state = state_machine.execute_state.instantiate()
			state_machine.add_child(execute_state)
			execute_state.state_machine = state_machine
			state_machine.change_selection_state("action_execute")

		else:
			Global.current_actor.emit_signal("send_target", tile)
			tile.grid_text.text = "1"
			target_info["target"] = target_info["disjointed"].front()["target"]
			state_machine.target_color = target_info["disjointed"].pop_front()["color"]
			target_count -= 1
			
	
	# working for displacer strike but not ravage?
	
	
	# Might work better if all disjoints are stored as an array to be easily iterated, as the dictionary ->
	# array fiddling makes things a little messy
	# !!! This could certainly probably be cleaned up...
