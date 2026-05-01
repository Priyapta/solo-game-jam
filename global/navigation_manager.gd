extends Node
const shop_section = preload("res://scenes/shop/shop_section.tscn")
const world = preload("res://scenes/world/world.tscn")
const world_2 = preload("res://scenes/world/world_2.tscn")
const world_3 = preload("res://scenes/world/world_3.tscn")
const end_game = preload("res://scenes/game_over/end_game.tscn")
const wave_ui_scene = preload("res://scenes/world/wave_ui.tscn")

var spawn_door_tag: String = ""
var current_level: String = "world"
var current_day: int = 1
var return_world_level: String = "world"

signal level_changed(new_level: String)
signal game_over_triggered


func go_to_level(level_tag, destination_tag = ""):
	var scene_to_load
	var resolved_level_tag = level_tag
	
	if level_tag == "shop" and current_level != "shop":
		return_world_level = current_level
		current_day += 1
	elif level_tag == "world":
		# Jika pindah ke 'world', ambil acak dari WorldManager
		resolved_level_tag = WorldManager.get_random_world_tag()
	
	match resolved_level_tag:
		"shop":
			scene_to_load = shop_section
		"world":
			scene_to_load = world
		"world_2":
			scene_to_load = world_2
		"world_3":
			scene_to_load = world_3
	
	if scene_to_load != null:
		# Play fade out
		if SceneTransition:
			await SceneTransition.fade_out()
			
		current_level = resolved_level_tag
		spawn_door_tag = destination_tag
		level_changed.emit(resolved_level_tag)
		get_tree().change_scene_to_packed(scene_to_load)
		
		# Play fade in
		if SceneTransition:
			await SceneTransition.fade_in()
			
		# Pastikan WaveUI ada jika ini adalah level world
		if resolved_level_tag.begins_with("world"):
			_ensure_wave_ui()

func _ensure_wave_ui():
	var current_scene = get_tree().current_scene
	if current_scene and not current_scene.has_node("WaveUI"):
		var ui = wave_ui_scene.instantiate()
		ui.name = "WaveUI"
		current_scene.add_child(ui)

func go_to_game_over():
	if SceneTransition:
		await SceneTransition.fade_out()
		
	game_over_triggered.emit()
	get_tree().change_scene_to_packed(end_game)
	
	if SceneTransition:
		await SceneTransition.fade_in()
