extends Node

var state_machine
var combat_queue

var sender_flags = []
var receiver_flags = []
var effect_queue = []
var queue_paused = false

func _process(delta):
	dequeue()


# What this should do IN THEORY:
# 1. Get an "effects" packet
# 2. Check if packet is an array
# 3. If it ISN'T, check for reactions to that effect and add them before
# 3a. get_reactions() checks the effect against each receiver to see if it has reactions and returns them
#	as an effect to be added to the queu
#	obvious danger of infinite loops here !!!
# 4. If it IS, iterate through array and do the same for each individual effect



func add_effect(effects):
	if effects is Array:
		for e in effects:
			var receiver = get_receiver(e)
			var reaction = get_reactions(receiver, e)
			if reaction and !reaction in effect_queue:		# in theory this shouldn't cause inf loop?
				add_effect(reaction)
			effect_queue.append(e)

	
	#else:
	#	reaction = get_reactions(effects)
	#	if reaction:
	#		add_effect(reaction)
	#	effect_queue.append(effects)


func get_receiver(effect):
	var receiver = effect.get_bound_arguments()
	return receiver[1]


func get_reactions(receiver, effect):
	if receiver.get_reactions(effect) != null:
		return receiver.get_reactions(effect)


func dequeue():
	if effect_queue.size() == 0:
		return
	if queue_paused == true:
		return
	process_effect()
	

func process_effect():
	print(effect_queue)
	effect_queue[0].call()
	effect_queue.pop_front()


func pause_queue():
	queue_paused = true


func resume_queue():
	queue_paused = false
