extends Node2D

@export var enemy_scene: PackedScene


signal day_started(number: int, is_horde: bool)


var current_day: int = 1
var enemies_remaining_to_spawn: int = 0
var enemies_alive: int = 0
var is_horde_day: bool = false
var spawn_loop_id: int = 0
var elite_spawned_this_horde: bool = false  


@export var base_enemy_count: int = 5
@export var count_increase_per_day: float = 0.5 
@export var spawn_delay: float = 1.0

func _ready():
	add_to_group("spawner")
	current_day = NavigationManager.current_day

	await get_tree().create_timer(0.2).timeout

	start_day()

func _exit_tree() -> void:
	spawn_loop_id += 1

func start_day():
	is_horde_day = (current_day % 10 == 0)
	spawn_loop_id += 1
	elite_spawned_this_horde = false  
	
	# Hitung jumlah musuh berdasarkan day
	var count = base_enemy_count + int(current_day * count_increase_per_day)
	if is_horde_day:
		count *= 2
	
	day_started.emit(current_day, is_horde_day)
	
	# Pindahkan/Ganti Musik Otomatis
	if is_horde_day:
		if Bgm.has_method("play_boss"): Bgm.play_boss()
	else:
		if Bgm.has_method("play_normal"): Bgm.play_normal()
		

	enemies_remaining_to_spawn = count
	enemies_alive = 0
	
	spawn_loop(spawn_loop_id)

func spawn_loop(loop_id: int):
	while is_inside_tree() and loop_id == spawn_loop_id and enemies_remaining_to_spawn > 0:
		spawn_enemy()
		enemies_remaining_to_spawn -= 1
		
		# Jeda antar spawn
		var delay = spawn_delay
		if is_horde_day:
			delay *= 0.3

		var tree := get_tree()
		if tree == null:
			return

		var timer := tree.create_timer(delay)
		if timer == null:
			return

		await timer.timeout

		if not is_inside_tree() or loop_id != spawn_loop_id:
			return

func spawn_enemy():
	if enemy_scene == null:
		push_error("Enemy scene belum dimasukkan ke spawner!")
		return
		
	var spawn_points = get_children()
	if spawn_points.is_empty():
		return
		
	var random_marker = spawn_points.pick_random()
	var enemy_instance = enemy_scene.instantiate()
	
	# Elite hanya spawn saat horde day dan hanya 1 per horde day
	var is_elite = false
	if is_horde_day and not elite_spawned_this_horde:
		is_elite = true
		elite_spawned_this_horde = true
	

	var scaling_factor = 1.0 + (current_day * 0.1)
	

	if enemy_instance.has_method("setup_stats"):
		enemy_instance.setup_stats(scaling_factor, is_elite)
	
	enemy_instance.global_position = random_marker.global_position
	

	enemy_instance.add_to_group("enemy")
	
	# Pantau kapan musuh ini mati
	enemy_instance.tree_exited.connect(_on_enemy_death)
	enemies_alive += 1
	
	var world = get_parent()
	if world == null:
		return

	world.add_child.call_deferred(enemy_instance)

func _on_enemy_death():
	enemies_alive -= 1
	
