extends State
class_name TARGETING

var enemies = true
var occupied = true
var obstacles = false
var disjointed = false

func enter(_args := {}):
	if "target_info" in _args:
		get_tree().call_group("tiles", "set_highlight")
	else:
		print("No targeting info!?")
	
func exit(_args := {}):
	reset_nav() # redundant?
