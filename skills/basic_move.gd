extends Skills_Library
class_name Basic_Move

@export var name: String = "Move"
@export var icon: Texture = preload("res://GFX/Generic Icons/walking-boot.png")
@export var cd: int = 0
@export var tt: String = "Move a number of spaces equal to your movement."
@export var target_info =  {"target" : NEEDS_OPEN,
							"color" : MOVE_TARGET,
							"disjointed" :	[]
							}

var type = MOVE
var unit

func execute(unit):
	var origin = unit.origin_tile
	if !move_check(unit): return
	basic_move(unit, origin, unit.movement)
