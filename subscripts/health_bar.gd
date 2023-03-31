extends TextureProgressBar

var unit

func set_ui_detail(linked_unit):
	unit = linked_unit
	min_value = 0
	max_value = unit.max_health
	value = max_value
	update_health_bar()
	
func update_health_bar():
	value = unit.health
	$health_label.text = str(value) + " / " + str(max_value)
