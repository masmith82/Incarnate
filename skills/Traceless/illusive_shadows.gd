extends Skills_Library
class_name Illusive_Shadows

@export var name = "Illusive Shadows"

class tl_passive extends buff:

	@export var tt = "When you shift out of a square, you may place a shadow on that square. You can't have more than
		3 shadows on the field at one time."

	
	var g = Engine.get_singleton("Global")
	var shadow = preload("res://units/traceless_shadow.tscn")
	var type = PASS
	
	func _init():
		name = "Illusive Shadows"
		icon = preload("res://GFX/Units/Traceless/illusive_shadows.png")		
	
	func _ready():		# override
		unit = get_parent().get_parent()
		callable = Callable(self, "spawn_shadow")
		unit.shifted.connect(callable)

	func spawn_shadow(origin):
		await get_tree().process_frame
		var new_shadow = shadow.instantiate()
		g.level.add_child(new_shadow)
		new_shadow.add_to_group("traceless_shadow")
		new_shadow.origin_tile = origin
		new_shadow.position = origin.position
