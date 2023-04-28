extends Skills_Library
class_name Verve_Magnet

@export var fx: PackedScene

@export var name: String = "Verve Magnet"
@export var icon: Texture = preload("res://GFX/Units/Bloodthane/Icons/4VerveMagnet.png")
@export var cd: int = 4
@export var tt: String = "You and the target unit are each pulled 2 squares toward each other."
@export var target_info =  {"target" : NEEDS_UNIT,
							"color" : SPECIAL_TARGET,
							"disjointed" :	[]
							}
var type = MNVR

var callable = Callable(self, "verve_magnet")

func execute(unit):
	var origin = unit.origin_tile
	if !move_check(unit): return
	target_basic(origin, 4)
	var target = await unit.send_target
	if !target: return
	var t = target.get_unit_on_tile()
	await basic_pull(t, origin, 2)
	await basic_pull(unit, t.origin_tile, 2)
	unit.finish_action("move")
	unit.cooldowns[name] = cd
	return
