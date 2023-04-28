extends Label

#=================#
# FUNCTION: combat_text
# Displays floating combat text when damage is dealt
#=================#

func setup(to_display, color):
	text = str(to_display)
	add_theme_color_override("font_color", color)
	var tween = create_tween()
	var rand = Vector2(self.position.x + randi_range(-75,75), self.position.y + randi_range(-75,-150))
	tween.tween_property(self, "position", rand, 2)
	$AnimationPlayer.play("basic")
	await tween.finished
	queue_free()
