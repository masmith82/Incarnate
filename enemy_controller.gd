extends Node

func start_enemy_turn():
	for enemy in get_children():
		if enemy:
			enemy.set_enemy_actor()
			enemy.get_target()
			await enemy.action_finished
			await get_tree().create_timer(.5).timeout
			
	Global.end_enemy_turn()
