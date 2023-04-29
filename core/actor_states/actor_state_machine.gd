extends Node
class_name State_Machine

#=============================
# ACTOR STATE MACHINE
# Controls what states units are in
#=============================

@onready var actor_state = get_node("actor_idle")
@onready var unit = get_parent()

func _ready() -> void:
	for child in get_children():
		child.state_machine = self
		child.combat_queue = $combat_queue
	unit.states = self
	unit.change_state.connect(set_unit_state)


func set_unit_state(state, _args = {}):
	print(unit.name, "transitioning from ", actor_state.name, " to ", state)
	actor_state.exit()
	var new_state := get_node(state)
	actor_state = new_state
	new_state.enter(_args)
