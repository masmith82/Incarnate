extends "res://skills/skills_library.gd"
class_name Bloodthane_Skills

var unit	# at _ready, a unit of this type will link to this variable
var a = []
var c = 0
var t = null
var target = null

func move(origin):
	if !move_check(unit): return
	basic_move(unit, origin, 4)

func blade_fury(origin : Area2D):
	c = 0
	if !action_check(unit, PLAYER_ATTACK): return
	target_basic(origin, 1)
	while c == 0:
		await unit.get_tree().create_timer(.1).timeout
	if c < 0: return
	t = target.get_unit_on_tile()
	if t: t.take_damage(4)
	reset_nav()
	unit.finish_action("skill")

func bloody_rush(origin : Area2D):
	c = 0
	a = []
	if !action_check(unit, SPECIAL): return		# sets targeting to special if the action check passes
	unit.get_tree().call_group("tiles", "suppress_collision")
	manual_path_shift(unit, origin)
	while c >= 0 and c < 3:
		print(c)
		await unit.get_tree().create_timer(.1).timeout
		if c < 0: return
		elif c == 1:
			a.append(target)
			manual_path_shift(unit, target)
		elif c == 2:
			a.append(target)
			manual_path_shift(unit, target)
		elif c == 3:
			a.append(target)
			print("BLOODY RUSH")
			# execute stuff
			# lots of nonsense targeting to fix: disallow repeats, shift logic, resolve shift
			# alternately could be lazy and have BT jump back to origin tile, make it more of an AoE
			# maybe allow him to move only if he has Predation

"""""

func bloody_rush_init():
	if !action_check(g.SPECIAL): return
	var c = Callable(self, "bloody_rush_exec")
	g.level.reset_nav()
	get_tree().call_group("tiles", "suppress_collision")
	unit.get_unit_pos()
	manual_path_shift(unit, c)
	g.selection = g.LOCKED		# overriding
	
	# ok so this is listening for SPECIAL SELECT from LEVEL and activating a method here on SKILLS
	# so if we want to SEND from here we'd do: this_node.connect("special_select in this node", method_in_level_node)
	g.level.connect("special_select", bloody_rush_special)

func bloody_rush_special(last_tile):
	if flex_array == null : flex_array = []
	flex_array.append(last_tile.astar_index)
	count += 1
	manual_path_shift(unit, unit.queued_action, last_tile)
	if count >= 3:
		bloody_rush_exec(flex_array)
		count = 0

func bloody_rush_exec(target_tiles):
	print(target_tiles)
	shift(unit.origin_tile, target_tiles)
	unit.finish_action("skill")
	g.level.disconnect("special_select", bloody_rush_special)
	flex_array.clear()
	"""
