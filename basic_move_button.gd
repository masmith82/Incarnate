extends TextureButton

@onready var index = self.get_index()

func set_button_detail(unit):
	tooltip_text = "Move up to " + str(unit.movement) + " squares."
