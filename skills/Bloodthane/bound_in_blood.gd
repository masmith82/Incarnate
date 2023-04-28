extends Skills_Library
class_name Bound_In_Blood

enum {DOMINANCE, VAMPIRIC, PREDATION}
var name = "Bound in Blood"

class bt_passive extends Buff:

	var type = PASS
	
	var popup = load("res://UI/popup_ui.tscn")
	var target
	var p
		
	var pacts = [{"name" : "Dominance Pact",
	"icon" : preload("res://GFX/Units/Bloodthane/Icons/bt_dominance_pact.png"),
	"tt" : "Enemies affected by dominance pact are more likely to attack the Bloodthane,
	and the Bloodthane takes less damage from them.",
	"ID" : DOMINANCE
	},
	{"name" : "Vampiric Pact",
	"icon" : preload("res://GFX/Units/Bloodthane/Icons/bt_vampiric_pact.png"),
	"tt" : "Enemies affected by Vampiric Pact lose health each turn, and the Bloodthane heals that much damage.",
	"ID" : VAMPIRIC
	},
	{"name" : "Predation Pact",
	"icon" : preload("res://GFX/Units/Bloodthane/Icons/bt_predation_pact.PNG"),
	"tt" : "Foes affected by Predation Pact have their movement reduced by 1 and the Bloodthan gains 1 movement.",
	"ID" : PREDATION
	}]
	
		
	func _init():
		name = "Bound in Blood"
		icon = preload("res://GFX/Units/Bloodthane/Icons/1 Bound in Blood.png")
		tt = "Whenever you strike a foe for the second time in a turn, you may bind a Pact. Bound
		Pacts buff you and debuff your enemies. Pacts are permanent."
	
	func _ready():		# override
		callable = Callable(self, "on_hit")
		unit = get_parent().get_parent() as Actor
		unit.dealt_damage.connect(callable)

		
	func on_hit(target : Node2D, damage: int):
		var blood = target.buffs.get_node_or_null("Blood-bound")
		
		if !blood: target.add_buff(blood_bind_stack.new())
		elif target.buffs.find_child("pact"): print("has a pact")
		else:
			blood.stacks += 1
			if blood.stacks >= 2:
				bind_pact.call_deferred(target)
	
	class blood_bind_stack extends Buff:
		func _init():
			name = "Blood-bound"
			stacks = 1
	
	func bind_pact(target):
#		set_triggers(unit, target)
		var effect_info = {"trigger": String("The Bloodthane can bind a pact to " + target.name + "."),
						"icon": icon,
						"effect": "Pacts buff the Bloodthane debuff his enemies. Pacts are permanent.",
						}

		var confirm = skill_lib.confirmation_popup(unit, effect_info, true)
		confirm.caller = unit
		confirm.add_buttons(pacts)
		var pact_selection = await confirm.resolved
#		clear_triggers(unit, target)

		if target == null:
			return
		else:
			print("Sealing pact: ", pact_selection)
			seal_pact(target, pact_selection)

	
	# !!! need to resolve what happens if a killing blow triggers a pact
	# currently still calls the popup menu (which probably needs to be reworked anyway)
	
	func seal_pact(target, pact):
		if target != null:
			var blood = target.buffs.find_child("Blood-bound", false, false)
			target.remove_buff(blood)

			var debuff
			var buff

			match pact:
				"Dominance Pact":
					debuff = dominance_debuff.new(0)
					buff = dominance_buff.new(0)
					debuff.link = unit
					buff.link = target	
					target.add_buff(debuff)
					unit.add_buff(buff)
				"Vampiric Pact":
					debuff = vampiric_debuff.new(1)
					buff = vampiric_buff.new(1)
					debuff.link = unit
					buff.link = target
					target.add_buff(debuff)
					unit.add_buff(buff)
				"Predation Pact":
					debuff = predation_debuff.new(2)
					buff = predation_buff.new(2)
					debuff.link = unit
					buff.link = target
					unit.add_buff(buff)
					target.add_buff(debuff)	


#=======#
# PACTS #
#=======#

	class Pact extends Buff:
		var index

		func _init(index):
			name = bt_passive.new().pacts[index].name
			icon = bt_passive.new().pacts[index].icon
			tt = bt_passive.new().pacts[index].tt		# !!! is this going to cause memory issues?
		
		func _ready():
			super._ready()
			buff_stuff()

#================#
# DOMINANCE PACT #
#================#


	class dominance_debuff extends Pact:
		func buff_stuff():
			print("Dominance Pact afflicts ", unit)

	class dominance_buff extends Pact:
		func buff_stuff():
			print("Dominance Pact boosts ", unit)

#===============#
# VAMPIRIC PACT #
#===============#


	class vampiric_debuff extends Pact:
		func buff_stuff():
			print(link)
			unit.take_damage(unit, 1)
			link.heal_damage(unit, 1)
			
	class vampiric_buff extends Pact:
		pass

#================#
# PREDATION PACT #
#================#

		
	class predation_debuff extends Pact:
		func buff_stuff():
			print("Predation pact afflicts ", unit.name)
			unit.movement = unit.base_movement -1

	class predation_buff extends Pact:
		func buff_stuff():
			print("Predation pact boosts ", unit.name)
			unit.movement = unit.base_movement + 1
			print(unit.movement)
