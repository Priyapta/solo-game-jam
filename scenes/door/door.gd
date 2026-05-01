extends Area2D

class_name Door
@export var detstination_level_tag: String
@export var destination_door_tag: String = ""
@export var spawn_direction = "up"
@onready var spawn: Marker2D
var door_origin_level: String = ""
var is_disabled: bool = false
var player_in_door: bool = false
var town_in_door: bool = false
var current_player: Node2D = null
var current_town: Node2D = null
var is_transitioning: bool = false

func _ready() -> void:

	if has_node("Spawn"):
		spawn = $Spawn
	
	# Simpan level asal door ini
	if NavigationManager:
		door_origin_level = NavigationManager.current_level

		NavigationManager.level_changed.connect(_on_level_changed)


func _on_level_changed(new_level: String) -> void:
	# Jika player sudah pindah dari level asal
	if new_level != door_origin_level:
		is_disabled = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("test")
		player_in_door = true
		current_player = body
	elif body.is_in_group("town"):
		town_in_door = true
		current_town = body
	else:
		return
	
	_try_enter_door()

func _on_body_exited(body: Node2D) -> void:
	if body == current_player:
		player_in_door = false
		current_player = null
	elif body == current_town:
		town_in_door = false
		current_town = null

func _try_enter_door() -> void:
	if is_transitioning:
		return
	if not player_in_door or not town_in_door:
		return
	
	
	if is_disabled:
		return
	

	if NavigationManager == null:
		return
	
	is_transitioning = true
	NavigationManager.go_to_level(detstination_level_tag, destination_door_tag)
