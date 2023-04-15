extends Skills_Library
class_name Bound_In_Blood

enum {DOMINANCE, VAMPIRIC, PREDATION}
var name = "Bound in Blood"

class bt_passive extends buff:
	
	@export var tt = "Whenever you strike a foe for the second time in a turn, you may bind a Pact. Bound
		Pacts buff you and debuff your enemies. Pacts are permanent."
	@export var icon = preload("res://GFX/Units/Bloodthane/Icons/1 Bound in Blood.png")	
	var type = PASS
	
	var popup = load("res://UI/popup_ui.tscn")
	var p
		
	var pacts = [{"name" : "Dominance Pact",
	"icon" : "res://GFX/Units/Bloodthane/Icons/1 Bound in Blood.png",
	"tt" : "Do some pact stuff.",
	"pact" : DOMINANCE
	},
	{"name" : "Vampiric Pact",
	"icon" : "res://GFX/Units/Bloodthane/Icons/1 Bound in Blood.png",
	"tt" : "Do some pact stuff.",
	"pact" : VAMPIRIC
	},
	{"name" : "Predation Pact",
	"icon" : "res://GFX/Units/Bloodthane/Icons/1 Bound in Blood.png",
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
