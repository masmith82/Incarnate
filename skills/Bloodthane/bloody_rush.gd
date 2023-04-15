
extends Skills_Library
class_name Bloody_Rush

@export var fx: PackedScene

@export var name: String = "Bloody Rush"
@export var icon: Texture = preload("res://GFX/Units/Bloodthane/Icons/3BloodyRush.png")
@export var cd: int = 3
@export var tt: String = "Shift 3 squares, then deal 2 damage to each enemy in a square you passed through or passed adjacent to."
var type = AREA

func execute(unit):
	var origin = unit.origin_tile
	var path = []
	var tiles = []
	var enemies = []
	if !action_check(unit, name, SPECIAL): return		# sets targeting to special if the action check passes

	manual_path_shift(unit, origin)	
	var target = await g.level.send_target
	if !target: return
	path.append(target.astar_index)
	tiles.append(target)
	manual_path_shift(unit, target)
	target = await g.level.send_target
	if !target: return
	path.append(target.astar_index)
	tiles.append(target)
	manual_path_shift(unit, target)
	target = await g.level.send_target
	if !target: return
	path.append(target.astar_index)
	tiles.append(target)
	
	if path.size() >= 3:
		await basic_shift(unit, origin, 3, path)
	
	# check each tile on the path, and if enemies in that tile or adjacent tile is not already added,
	# add them to enemies list
	# we add the origin tile here so it also catches units adjcent to start position

	tiles.append(origin)
	for tile in tiles:
		if !enemies.has(tile.get_unit_on_tile()): enemies.append(tile.get_unit_on_tile())
		for neighbor in tile.neighbors:
			if !enemies.has(neighbor.get_unit_on_tile()): enemies.append(neighbor.get_unit_on_tile())

	# filter null entries
	enemies = enemies.filter(func(e): return e != null)

	for e in enemies:
		if e.is_in_group("enemy_units"): e.take_damage(unit, 2)
		
	unit.finish_action("skill")
	unit.cooldowns[name] = cd
	path.clear()

	# lots of nonsense targeting to fix: disallow repeats, shift logic, resolve shift
	# alternately could be lazy and have BT jump back to origin tile, make it more of an AoE
	# maybe allow him to move only if he has Predation
