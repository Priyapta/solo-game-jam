extends Node

@export var main_menu_scene: PackedScene
@export var world_scene: PackedScene

var current_menu: Control = null

func _ready() -> void:
	load_main_menu()


func load_main_menu() -> void:
	# Hapus menu lama jika ada
	if current_menu != null:
		current_menu.queue_free()
	
	# Load menu baru
	current_menu = main_menu_scene.instantiate()
	add_child(current_menu)
	
	# Connect signals
	current_menu.new_game_pressed.connect(_on_new_game_pressed)
	current_menu.settings_pressed.connect(_on_settings_pressed)
	current_menu.about_pressed.connect(_on_about_pressed)
	current_menu.exit_pressed.connect(_on_exit_pressed)


func _on_new_game_pressed(_origin: String) -> void:
	# Reset game data
	GameData.reset_all_data()
	
	# Reset navigation state
	if NavigationManager:
		NavigationManager.current_day = 1
		NavigationManager.current_level = "world"
		NavigationManager.spawn_door_tag = ""
	
	# Load world
	get_tree().change_scene_to_packed(world_scene)


func _on_settings_pressed(_origin: String) -> void:
	get_tree().change_scene_to_file("res://global/settings.tscn")


func _on_about_pressed(_origin: String) -> void:
	# TODO: Implement about menu
	pass


func _on_exit_pressed(_origin: String) -> void:
	get_tree().quit()
