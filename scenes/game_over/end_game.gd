extends Control

const WORLD_SCENE = preload("res://scenes/world/world.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/MainMenu/main_menu.tscn")

@onready var restart_button: TextureButton = $ColorRect/VBoxContainer/HBoxContainer/NewGame
@onready var quit_button: TextureButton = $ColorRect/VBoxContainer/HBoxContainer/NewGame2

func _ready() -> void:
	# Connect buttons
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_restart_pressed():
	# Reset GameData
	if GameData:
		GameData.reset_all_data()

	if NavigationManager:
		NavigationManager.current_day = 1
		NavigationManager.current_level = "world"
		NavigationManager.spawn_door_tag = ""
	# Pindah ke world
	get_tree().change_scene_to_packed(WORLD_SCENE)

func _on_quit_pressed():
	get_tree().quit()
