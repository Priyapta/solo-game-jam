extends Node


var worlds: Array[String] = [
	"world",
	"world_2",
	"world_3"
]

var last_world: String = ""

func _ready():
	randomize()

func get_random_world_tag() -> String:
	var available_worlds = worlds.duplicate()
	
	if available_worlds.size() > 1 and last_world != "":
		available_worlds.erase(last_world)
	
	var random_index = randi() % available_worlds.size()
	var selected_world = available_worlds[random_index]
	
	last_world = selected_world
	return selected_world

func transition_to_next_random_world():
	var next_world = get_random_world_tag()
	if NavigationManager:
		NavigationManager.go_to_level(next_world)
