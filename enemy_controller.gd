extends Node

@onready var g = get_node("/root/Global")

func _ready():
	pass # Replace with function body.

func _process(delta):
	pass

func start_enemy_turn():
	for enemy in get_children():
		if enemy:
			await enemy.set_enemy_actor()
			await enemy.get_target()
	g.end_enemy_turn()
