extends CharacterBody2D

@export var move_speed: float = 70


var maxHealth: int = 1000
var current_hp: int = 1000

# Signal untuk ke UI dan Sistem Game
signal town_damaged(current_hp: int, maxHealth: int)
signal town_destroyed	
# signal town_arrived_at_destination  # Belum digunakan

# Thunder Attack System
@onready var thunder_range_area = $ThunderRange
@onready var thunder_point = $ThunderPoint
const THUNDER_BEAM_SCENE = preload("res://scenes/effects/thunder_beam.tscn")

var thunder_cooldown: float = 1.0 # Kecepatan tembak
var time_since_last_thunder: float = 0.0
var thunder_damage: int = 30
var has_reached_destination: bool = false

func _ready() -> void:
	# Add town ke group untuk deteksi
	add_to_group("Town")
	add_to_group("town")
	

	GameData.stats_updated.connect(_on_stats_updated)
	GameData.town_healed.connect(heal)

	_update_hp_stats()
	current_hp = clamp(GameData.get_saved_town_hp(), 0, maxHealth)
	GameData.set_saved_town_hp(current_hp)
	town_damaged.emit(current_hp, maxHealth)
	


func _on_stats_updated() -> void:
	_update_hp_stats()
	current_hp = min(current_hp, maxHealth)
	GameData.set_saved_town_hp(current_hp)
	town_damaged.emit(current_hp, maxHealth)


func _update_hp_stats() -> void:

	maxHealth = GameData.get_town_max_hp()

func take_damage(amount: int, _from_position: Vector2 = Vector2.ZERO) -> void:
	if current_hp <= 0: return 
	
	current_hp -= amount
	current_hp = max(current_hp, 0)
	GameData.set_saved_town_hp(current_hp)
	
	town_damaged.emit(current_hp, maxHealth)
	
	_flash_damage()
	
	if current_hp <= 0:
		_destroyed()

	town_damaged.emit(current_hp, maxHealth) 

func _flash_damage() -> void:

	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		

		var tween = create_tween()
		
	
		sprite.modulate = Color(1, 0.3, 0.3, 1)
		
		# Pudar kembali ke warna normal (Putih) dalam 0.2 detik
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)

func _destroyed() -> void:
	town_destroyed.emit()
	
	# Stop pergerakan Town
	set_physics_process(false) 
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.stop()
	

	get_tree().create_timer(1.5).timeout.connect(func():
		if NavigationManager:
			NavigationManager.go_to_game_over()
		else:

			get_tree().change_scene_to_file("res://scenes/game_over/end_game.tscn")
	)

func heal(amount: int = -1) -> void:
	if current_hp <= 0: return
	
	if amount < 0:
		current_hp = maxHealth 
	else:
		current_hp += amount
		current_hp = min(current_hp, maxHealth)
		
	GameData.set_saved_town_hp(current_hp)
	town_damaged.emit(current_hp, maxHealth)

func _physics_process(delta: float) -> void:
	# Update cooldown petir
	if GameData.is_electro_unlocked():
		_process_thunder_attack(delta)
		
	var path_follow = get_parent()
	
	if path_follow is PathFollow2D and not has_reached_destination:

		path_follow.progress += move_speed * delta
		
	
		if path_follow.progress_ratio >= 1.0:
			has_reached_destination = true
			path_follow.progress_ratio = 1.0
			if has_node("AnimationPlayer"):
				$AnimationPlayer.play("idle") # Ganti animasi ke diam
			return 
			
	if has_node("AnimationPlayer") and is_physics_processing() and not has_reached_destination:
		$AnimationPlayer.play("move")

func _process_thunder_attack(delta: float) -> void:
	time_since_last_thunder += delta
	
	if time_since_last_thunder >= thunder_cooldown:

		var enemies = thunder_range_area.get_overlapping_bodies()
		var target_enemy = null
		var closest_dist = INF
		
		for body in enemies:
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				var dist = global_position.distance_to(body.global_position)
				if dist < closest_dist:
					closest_dist = dist
					target_enemy = body
		

		if target_enemy:
			_shoot_thunder(target_enemy)
			time_since_last_thunder = 0.0

func _shoot_thunder(target: Node2D) -> void:
	var beam = THUNDER_BEAM_SCENE.instantiate()
	
	# Ambil damage dari GameData agar progresif
	beam.damage = GameData.get_electro_damage()
	
	get_tree().current_scene.add_child(beam)
	
	# Tembakkan!
	var start_pos = thunder_point.global_position
	var end_pos = target.global_position
	beam.fire(start_pos, end_pos)
