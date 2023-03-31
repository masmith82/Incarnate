extends "res://skills/skills_library.gd"
class_name Bloodthane_Skills


var unit	# at _ready, a unit of this type will link to this variable
var t = null
var popup = load("res://popup_ui.tscn")
var blood_attack = load("res://Effects/blood_attack.tscn")

enum {RECHARGE, RESET}
enum {DOMINANCE, VAMPIRIC, PREDATION}

var bt_basic_1 = {"name" : "Blade Fury",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Blade FurySmall.png",
	"cd" : 0,
	"tt" : "Attack a target in melee range for 4 damage.",
	"func" : Callable(self, "blade_fury")
	}
	
var bt_heavy_1 = {"name" : "Reaving Claws",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Blade FurySmall.png",
	"cd" : 2,
	"tt" : "Big attack",
	"func" : Callable(self, "-----")
	}

var bt_area_1 = {"name" : "Bloody Rush",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/3BloodyRush.png",
	"cd" : 3,
	"tt" : "Shift 3 squares, then deal 2 damage to each enemy in a square you passed through or passed adjacent to.",	
	"func" : Callable(self, "bloody_rush")
	}
	
var bt_def_1 = {"name" : "Acute Coagulant",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Blade FurySmall.png",
	"cd" : 3,
	"tt" : "Heal yourself for 4 damage. At the beginning of the next two turns, heal for 4 damage.",
	"func" : Callable(self, "acute_coagulant")
	}

var bt_man_1 = {"name" : "Verve Magnet",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Blade FurySmall.png",
	"cd" : 3,
	"tt" : "You and the target unit are each pulled 2 squares toward each other.",
	"func" : Callable(self, "verve_magnet")
	}
	
var bt_util_1 = {"name" : "Adrenaline Surge",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Blade FurySmall.png",
	"cd" : 4,
	"tt" : "Refresh a skill.",
	"func" : Callable(self, "adrenaline_surge")
	}

var bt_ult_1 = {"name" : "Bloodlust",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Blade FurySmall.png",
	"cd" : 0,
	"tt" : "Here's a tooltip.",
	"func" : Callable(self, "-----")
	}	

func _ready():
	g.level.send_target.connect()						# connect signals

# placeholder for quick copy/pasting new skills, includes all the necessary checks and cleanups
func skill_template():
	var name = "name from dictionary"
	if !action_check(unit, name, PLAYER_ATTACK): return
	# get target
	var target = await g.level.send_target
	if !target: return
	t = target.get_unit_on_tile() # get whatever target property
	if t: 
		pass # dostuff
	unit.finish_action("skill")
	unit.cooldowns[name]

func move():
	var origin = unit.origin_tile
	if !move_check(unit): return
	basic_move(unit, origin, 4)

func blade_fury():
	var name = bt_basic_1["name"]
	var origin = unit.origin_tile
	if !action_check(unit, name, PLAYER_ATTACK): return
	target_basic(origin, 1)
	var target = await g.level.send_target
	if !target: return
	t = target.get_unit_on_tile()
	if t: t.take_damage(unit, 4)
	# was there a reason I had reset_nav here instead of as part of finish_action?
	t.add_child(blood_attack.instantiate())
	unit.cooldowns[name] = bt_basic_1["cd"]
	await unit.finish_action("skill")

func bloody_rush():
	var name = bt_area_1["name"]
	var origin = unit.origin_tile
	var path = []
	var tiles = []
	var enemies = []
	
	if !action_check(unit, name, SPECIAL): return		# sets targeting to special if the action check passes
	manual_path_shift(unit, origin)				# should be a loop prob
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
	unit.cooldowns[name] = bt_area_1["cd"]	
	path.clear()
	return
		
		# lots of nonsense targeting to fix: disallow repeats, shift logic, resolve shift
		# alternately could be lazy and have BT jump back to origin tile, make it more of an AoE
		# maybe allow him to move only if he has Predation

func acute_coagulant():
	var name = bt_def_1["name"]
	var origin = unit.origin_tile
	if !action_check(unit, name, PLAYER_HELP): return
	target_self(origin)
	var target = await g.level.send_target
	if !target: return
	unit.heal_damage(unit, 4)
	unit.add_buff(acute_buff.new())
	unit.finish_action("skill")
	unit.cooldowns[name] = bt_def_1["cd"]
	return
	
class acute_buff extends buff:
	func _init():
		duration = 2
		name = "Acute Coagulant"

	func buff_stuff():
		print("Acute Coagulant heals ", unit, " for 4 damage.")
		unit.heal_damage(unit, 4)
		buff_tick()
		
func verve_magnet():
	var name = bt_man_1["name"]
	var origin = unit.origin_tile
	if !action_check(unit, name, PLAYER_ATTACK): return
	target_basic(origin, 4)
	var target = await g.level.send_target
	if !target: return
	t = target.get_unit_on_tile()
	await basic_pull(t, origin, 2)
	await basic_pull(unit, t.origin_tile, 2)
	unit.finish_action("move")
	unit.cooldowns[name] = bt_man_1["cd"]	
	return

func adrenaline_surge():
	var name = bt_util_1["name"]
	var origin = unit.origin_tile
	if !action_check(unit, name, PLAYER_HELP): return
	target_basic(origin, 4)
	var target = await g.level.send_target
	if !target: return

	t = target.get_unit_on_tile()
	var p = popup.instantiate()
	unit.add_child(p)
	p.setup_skill_popup(RECHARGE)
	var confirm = await p.popup_confirm
	if confirm == "false":
		unit.g.reset_nav()
		return
	t.action_pool["skill"] += 1
	unit.combat_text("+1 skill action")
	unit.cooldowns[name] = bt_util_1["cd"]
	unit.finish_action("skill")
	
	# need to build a system to select a skill
	# and add the refresh effect obv

class bt_passive extends buff:
	var popup = load("res://popup_ui.tscn")
	var p
	
	var tt = "Whenever you strike a foe for the second time in a turn, you may bind a Pact. Bound
		Pacts buff you and debuff your enemies. Pacts are permanent."
	
	var pacts = [{"name" : "Dominance Pact",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Bound in Blood.png",
	"tt" : "Do some pact stuff.",
	"pact" : DOMINANCE
	},
	{"name" : "Vampiric Pact",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Bound in Blood.png",
	"tt" : "Do some pact stuff.",
	"pact" : VAMPIRIC
	},
	{"name" : "Predation Pact",
	"icon" : "res://GFX/Characters/Bloodthane/Icons/1 Bound in Blood.png",
	"tt" : "Do some pact stuff.",
	"pact" : PREDATION
	}]
	
	func _init():
		name = "Bound in Blood"
	
	func _ready():		# override
		callable = Callable(self, "on_hit")
		unit = get_parent().get_parent()
		unit.dealt_damage.connect(callable)
		
	func on_hit(target : Node2D, damage: int):
		var buffs = target.find_child("buff_list")
		var blood = buffs.get_node_or_null("Blood-bound")
		
		if !blood: target.add_buff(blood_bind_stack.new())
		elif buffs.find_child("pact"): print("has a pact")
		else:
			blood.stacks += 1
			if blood.stacks >= 2:
				await get_tree().create_timer(.1).timeout
				bind_pact.call_deferred(target)
	
	class blood_bind_stack extends buff:
		func _init():
			name = "Blood-bound"
			stacks = 1
	
	func bind_pact(target):
		var p = popup.instantiate()
		unit.add_child(p)
		p.setup_special_popup(pacts, target)
	
	func seal_pact(target, pact, popup):
		unit = popup.get_parent()
		var blood = target.buffs.find_child("Blood-bound", false, false)
		target.remove_buff(blood)
		unit.special_popup_confirm.emit()
		popup.popup_cleanup()	
		match pact:
			DOMINANCE:
				target.add_buff(dominance_debuff.new())
				unit.add_buff(dominance_buff.new())
			VAMPIRIC:
				target.add_buff(vampiric_debuff.new())
			PREDATION:
				target.add_buff(predation_debuff.new())

	class dominance_debuff extends buff:
		func _init():
			name = "Dominated"
			
		func buff_stuff():
			print("Dominance Pact afflicts ", unit)

	class dominance_buff extends buff:
		var tt = "Dominance buff"
		func _init():
			name = "Dominant"
			
		func buff_stuff():
			print("Dominance Pact boosts ", unit)
			
	class vampiric_debuff extends buff:
		func _init():
			name = "Dominance Pact"
		
	class predation_debuff extends buff:
		func _init():
			name = "Dominance Pact"

	func vampiric_pact(target, popup):
		print("Vampiric Pact on", target)
		unit.special_popup_confirm.emit()
		popup.popup_cleanup()

	func predation_pact(target, popup):
		print("Predation Pact on ", target)
		unit.special_popup_confirm.emit()
		popup.popup_cleanup()
