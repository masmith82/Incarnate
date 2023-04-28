extends PopupPanel
class_name Trigger_Confirm

var caller
var button
var selection

@onready var base_button = $main_container/button_container/base_button

#======================
# CLASS: Trigger_Confirm
# Controls the trigger_confirm popup window scene. Pulls the text and icons it needs from the calling
# skill. Pauses the game and awaits player response.
#======================

signal resolved

func _init():
	pass

func setup(trigger : String = "", icon : Texture = Global.blank_icon, effect : String = ""):
	$main_container/trigger_label.text = trigger
	$main_container/mid_container/effect_icon.texture = icon
	$main_container/mid_container/effect_label.text = effect

func add_buttons(effects):
	for e in effects:
		var new_button = base_button.duplicate() as TextureButton
		new_button.name = e.name
		new_button.texture_normal = e.icon
		new_button.tooltip_text = e.tt
		new_button.pressed.connect(select.bind(e.name))
		new_button.show()
		$main_container/button_container.add_child(new_button)

func select(selection):
	emit_signal("resolved", selection)
	get_tree().paused = false
	queue_free()

func _on_ok_button_pressed():
	emit_signal("resolved")
	get_tree().paused = false
	queue_free()
