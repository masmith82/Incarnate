@tool
extends Skills_Library
class_name Chimeric_Cloak

@export var fx: PackedScene

@export var name: String = "Chimeric Cloak"
@export var icon: Texture = preload("res://GFX/Units/Traceless/chimeric_cloak.png")
@export var cd: int = 3
@export var tt: String = "The next strike against you this turn deals half damage.
	If less than 3 damage is prevented, prepare Chimeric Cloak."

var unit

var target_info =  {"target" : NEEDS_ALLY,
					"color" : AID_TARGET,
					"disjointed" :	[]
					}

var type = DEF

func execute(unit):
	var origin = unit.origin_tile
	if !action_check(unit, name): return
	target_self(origin)
	var target = await unit.send_target
	if !target: return
	
	unit.add_buff(chimeric_buff.new())
	unit.finish_action("skill")
	unit.cooldowns[name] = cd
	return
	
class chimeric_buff extends Buff:

	func _init():
		duration = 1
		name = "Chimeric CLoak"
		tt = "The next strike against you this turn deals half damage. If less than 3 damage is prevented,
		prepare Chimeric Cloak."
		icon = preload("res://GFX/Units/Traceless/chimeric_cloak.png")
		
	func _ready():
		unit = get_parent().get_parent()
		var callable = Callable(self, "chimeric_cloak")
		unit.can_react.connect(callable)
		effect_info = {"trigger": String("An enemy is attacking " + unit.name + ". Use " + name + "?"),
						"effect": "You take half damage from this strike. If less than 3 damage is prevented, this buff refreshes. Otherwise it is consumed.",
						"icon": icon, "reaction": true
						}
		
	func chimeric_cloak():
		var confirm = skill_lib.confirmation_popup(unit, effect_info)
		await confirm.resolved
		unit.emit_signal("reacted")
		unit.scaled_damage_taken_mods.append(.50)
		await unit.took_damage
		unit.scaled_damage_taken_mods.erase(.50)
		unit.remove_buff(self)


# best approach may be to move the popup to somewhere that can be active while paused
# or figure out another way to reference the popup so we can easily get a singal from it
# as it is stands, it's not even getting to the pause because it's awaiting the confirmation popup...
# figure out how to make it wait for  init
