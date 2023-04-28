extends Node
class_name Buff

#============================#
# BASIC BUFF/DEBUFF HANDLING #
#============================#

var duration
var unit = Actor
var link = null
var stacks = 0
var tt = ""
var ui_icon = load("res://GFX/Generic Icons/blank_square.png")
var effect_info = {}
var skill_lib = load("res://skills/skills_library.tres")

@export var icon = preload("res://GFX/Generic Icons/blank_square.png")	
var callable = Callable(self, "buff_stuff")

func _ready():
	unit = get_parent().get_parent() as Actor
	Global.start_turn.connect(callable)

func buff_tick():
	if duration:
		duration -= 1
		print(name, ": ", duration, "turns remaining.")
		if duration <= 0:
			self.queue_free()

func buff_stuff():
	# to be overridden by each buff's "stuff"
	pass

#============================#
# UNIVERSAL BUFFS/DEBUFFS	 #
#============================#

class debuff_blind extends Buff:
	
	func _init():
		name = "Blind"
	
	func _ready():
		super._ready()
		print(unit.name, " was blinded!")
		
		
#====================#
# TRIGGER MANAGEMENT #
#====================#

# !!! shared with Skills Library

func set_triggers(unit: Actor, target: Actor):
	unit.add_to_group("has_triggers")
	unit.add_to_group("has_triggers")
	await get_tree().create_timer(.1).timeout

func clear_triggers(unit: Actor, target: Actor):
	unit.remove_from_group("has_triggers")
	unit.remove_from_group("has_triggers")
