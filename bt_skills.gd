extends skill_lib

var count = 0
var flex_array = null

func _ready():
	pass

func blade_fury_init():
	if !action_check(g.PLAYER_ATTACK): return
	var c = Callable(self, "blade_fury_exec")
	g.level.reset_nav()
	unit.get_unit_pos()
	basic_melee_target(unit, c)

func blade_fury_exec(tile):
	var t = tile.get_unit_on_tile()
	t.take_damage(4)
	print("Attacks for 4 damage." )
	unit.finish_action("skill")

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
	
### we can probably use a "locked" state on tiles to control double-backing during this kind of move




#	basic_melee_target()
#	var tween = hero.find_node("Tween")
#	var sprite = hero.find_node("AnimatedSprite")
#	hero.unoccupy_tile()
#	for tile in target_tile:
#		tween.interpolate_property(hero, "position", hero.position, tile.position, .25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
#		tween.interpolate_property(sprite, "scale", 3, 5, .25, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0)
#		tween.start()
#		yield(hero.find_node("Tween"), "tween_completed")
#		yield(get_tree(), "idle_frame")
#	hero.occupy_tile()
#	hero.shift_end_check()
#	hero.targstate = STANDARD
#	hero.skill_origin.target_tiles.clear() #####
#	hero.skill_origin.deselect()
#

		
#		set up a basic loop to wait for 3 results
#		add_tile_to_array
#		highlight
#		get_another
#		add_tile_to_array
#		get_another
#		once we have three break loop and move on
