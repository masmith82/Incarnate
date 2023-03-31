extends Camera2D

var camera_speed = 1.0
var camera_movement = Vector2.ZERO

func _ready():
	pass
	
func _process(delta):
	move_camera(delta)
	force_update_scroll()

func move_camera(delta):
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			camera_movement = -Input.get_last_mouse_velocity() * delta * camera_speed
		else:
			camera_movement = Vector2.ZERO
	
		position += camera_movement
