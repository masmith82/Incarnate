extends Control

@onready var g = get_node("/root/Global")
@onready var unit = get_parent()
@onready var basics = unit.find_child("skill_lib")
@onready var skills = unit.find_child("class_skills")

const X = 850
const Y = 450

signal unit_move
signal unit_action
signal unit_deselect

func _ready():
	position.x = X
	position.y = Y
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func show_menu():
	$menu_cont/actions_val.text = str("Actions: ", g.current_actor.action_pool)
	$menu_cont/health_val.text = str("Health: ", g.current_actor.health)
	$menu_cont/unit_menu.deselect_all()
	$menu_cont.show()

func hide_menu():
	$menu_cont.hide()
	$menu_cont/action_menu.hide()
	$menu_cont/unit_menu.deselect_all()
	
func update():
	if g.selection != g.ENEMY_TURN:
		$menu_cont/actions_val.text = str("Actions: ", g.current_actor.action_pool)
		$menu_cont/health_val.text = str("Health: ", g.current_actor.health)

func _on_action_menu_item_clicked(index, at_position, mouse_button_index):
	match g.selection:
		g.NO_SELECTION, g.PLAYER_ACTION:
			g.reset_nav()
			unit.get_unit_pos()
			$menu_cont/unit_menu.hide()
					
			if index == 0:
				unit.sk.move(unit.origin_tile)

			if index == 1:
				unit.sk.blade_fury(unit.origin_tile)
				
			if index == 2:
				unit.sk.bloody_rush(unit.origin_tile)
				
			if index == 3:
				hide_menu()
				unit.end_turn()	


func _on_button_pressed():
	unit.sk.c = -1
	g.reset_nav()
	$menu_cont/unit_menu.show()

func reset_menu():
	unit.sk.c = -1
	g.reset_nav()
	$menu_cont/unit_menu.show()
