extends Actor

@onready var target_pool = Global.level.find_child("player_units").get_children()
@export var buff_list = Node
@export var skills = Resource

var movetype = MOVE

###################
# STATE VARIABLES #
###################
var target
var queued_action

func _ready():
	await get_tree().create_timer(.1).timeout
	group_name = String(self.name) + "ui"
	setup_unit()

func setup_unit():
	buffs = $buff_list
	health = max_health
	movement = base_movement
	Global.camera.create_ui(self)
	Global.start_turn.connect(Callable(self, "start_turn_upkeep"))

	
func set_enemy_actor():
	Global.s.change_selection_state("enemy_turn")
	queued_action = null
	get_unit_pos()
	Global.current_actor = self
	
	
func get_target():
	await random_target()


func random_target():
	var random = randi_range(1, target_pool.size())
	target = target_pool[random - 1]
	await path_to_target(target)


func path_to_target(target):
	Global.level.astar.set_point_solid(target.origin_tile.astar_index, false)
	var path = Global.level.astar.get_id_path(origin_tile.astar_index, target.astar_pos)		
	Global.level.astar.set_point_solid(target.origin_tile.astar_index, true)
	print(path, movement)
	path.remove_at(0)
	path.resize(movement)
	path = path.filter(func(coords): return coords != target.astar_pos)
	path = path.filter(func(coords): return coords != Vector2i(0,0))
	await move(path)


func move(path):
	print(target.astar_pos, path)
	var waypoint
	if path != []:
		var tween = create_tween()
		for point in path:
			waypoint = Global.level.astar_to_tile[point].position
			tween.tween_property(self, "position", waypoint, .1)
		if tween: await tween.finished
	await get_tree().create_timer(.1).timeout
	get_unit_pos()
	basic_melee()


func end_turn():
	Global.s.change_selection_state("no_selection")
	Global.end_enemy_turn()
	
			
func basic_melee():

	Global.level.target_basic(origin_tile, 1)
	if target.origin_tile.valid_selection == false:
		pass
	if target.origin_tile.valid_selection == true:
		var facing = face_target(target)
		var tween = create_tween()
		self.deal_damage(target, 5)
		tween.tween_property(self, "position", target.origin_tile.position, .1)
		tween.tween_property(self, "position", origin_tile.position, .1)
		if tween: await tween.finished
	Global.reset_nav()


func deal_damage(target : Node2D, damage : int):
	states.set_unit_state("actor_attacking", {"target": target})
	target.states.set_unit_state("actor_under_attack", {"source": self})
	await self.resolve_ready
	target.take_damage(self, damage)
	states.set_unit_state("actor_finished")

func face_target(target):
	pass


func suppress_collision():
	get_unit_pos()
	Global.level.astar.set_point_solid(astar_pos, false)

func unsuppress_collision():
	get_unit_pos()
	Global.level.astar.set_point_solid(astar_pos, true)

