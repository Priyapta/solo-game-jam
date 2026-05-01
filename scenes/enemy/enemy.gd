extends CharacterBody2D
enum State{
	IDLE,
	CHASE,
	CHASE_TOWN,
	RETURN,
	ATTACK,
	ATTACK_TOWN,
	DEAD
}

enum TargetType {
	NONE,
	PLAYER,
	TOWN
}
@export_category("Stats")
@export var speed: int = 120 
@export var attack_speed: float = 1.0 
@export var attack_damage: int = 8
@export var aggro_range: float = 800.0 
@export var attack_range: float = 60.0
@export var hitpoints: int = 100
@export var separation_radius: float = 52.0
@export var separation_force: float = 220.0
@export_category("Related Scenes")
@export var death_packed: PackedScene
@export var knockback_force: float = 400

var state : State = State.IDLE
var is_attacking: bool = false
var is_hurt: bool = false
var current_animation: String = ""
var knockback_velocity: Vector2 = Vector2.ZERO
var can_deal_damage: bool = true

@onready var spawn_point: Vector2 = global_position
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_playback: AnimationNodeStateMachinePlayback = $AnimationTree["parameters/playback"]
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var town: Node2D = _find_town()
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_box_collision: CollisionShape2D = $HitBox/CollisionShape2D
@onready var death_sound: AudioStreamPlayer2D = $SoundDeath
@onready var got_damage_sound: AudioStreamPlayer2D = $SoundGotDamage
@export var gold_scene: PackedScene


var current_target: TargetType = TargetType.NONE
var current_target_position: Vector2 = Vector2.ZERO
var target_switch_cooldown: float = 0.0


var aggro_timer: float = 0.0
var max_aggro_time: float = 3.0 
var is_aggro_to_player: bool = false

func _ready() -> void:
	animation_tree.active = true
	hit_box_collision.set_deferred("disabled", true)
	
	if not $AnimationPlayer.animation_finished.is_connected(_on_animation_player_animation_finished):
		$AnimationPlayer.animation_finished.connect(_on_animation_player_animation_finished)
	
	# Setup navigation agent
	nav_agent.avoidance_enabled = true
	nav_agent.path_desired_distance = 20.0
	nav_agent.target_desired_distance = 40.0
	nav_agent.max_speed = speed
	
	# Connect velocity computed signal untuk avoidance
	if not nav_agent.velocity_computed.is_connected(_on_navigation_agent_2d_velocity_computed):
		nav_agent.velocity_computed.connect(_on_navigation_agent_2d_velocity_computed)
	
	# Setup avoidance groups
	nav_agent.set_avoidance_layer_value(1, true)
	nav_agent.set_avoidance_mask_value(1, true)
	
	# Set avoidance priority 
	nav_agent.avoidance_priority = randf_range(0.8, 1.0)
	
	await _wait_for_navigation_map()
	
	# Set titik spawn
	spawn_point = global_position
	
	# Set target awal ke town 
	if town != null:
		current_target = TargetType.TOWN
		current_target_position = town.global_position

func _wait_for_navigation_map() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

func _find_town() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null

	var town_node := tree.get_first_node_in_group("town")
	if town_node == null:
		town_node = tree.get_first_node_in_group("Town")
	return town_node as Node2D

func _physics_process(delta: float) -> void:
	# Update references
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	if town == null:
		town = _find_town()
	
	if state == State.DEAD:
		return
	
	# Update cooldown
	if target_switch_cooldown > 0:
		target_switch_cooldown -= delta
	
	# Update aggro timer
	if aggro_timer > 0:
		aggro_timer -= delta
		if aggro_timer <= 0:
	
			is_aggro_to_player = false
	
	# decay knockback
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
	var separation_velocity := _get_separation_velocity()
	

	if is_hurt:
		velocity = knockback_velocity + separation_velocity
		move_and_slide()
		return
	

	if is_attacking:
		update_animation()
		velocity = knockback_velocity + (separation_velocity * 0.5)
		move_and_slide()
		return
	

	_update_target_selection()
	

	match current_target:
		TargetType.PLAYER:
			_handle_player_target()
		TargetType.TOWN:
			_handle_town_target()
		TargetType.NONE:
			_handle_no_target()
	
	
	if velocity.length() < 10.0 and (state == State.CHASE or state == State.CHASE_TOWN or state == State.RETURN):
		var dir_to_target = (current_target_position - global_position).normalized()
		velocity = dir_to_target * speed
	
	update_animation()
	
	var final_velocity = velocity + knockback_velocity + separation_velocity
	velocity = final_velocity
	move_and_slide()


func _update_target_selection() -> void:
	# Jika sedang aggro ke player, prioritas player
	if is_aggro_to_player and aggro_timer > 0:
		if player != null and player.state != 3:  # 3 = DEAD state
			var aggro_dist = global_position.distance_to(player.global_position)
			if aggro_dist <= aggro_range * 1.5: 
				if current_target != TargetType.PLAYER:
					current_target = TargetType.PLAYER
				return
		# Player terlalu jauh atau mati, reset aggro
		is_aggro_to_player = false
	
	var dist_to_player: float = INF
	var dist_to_town: float = INF
	
	if player != null and player.state != 3:  # 3 = DEAD state
		dist_to_player = global_position.distance_to(player.global_position)
	
	# Hitung jarak ke town
	if town != null:
		dist_to_town = global_position.distance_to(town.global_position)
	
	# Pilih target berdasarkan jarak terdekat
	var new_target: TargetType = TargetType.NONE
	
	if dist_to_player <= dist_to_town:

		if dist_to_player <= aggro_range:
			new_target = TargetType.PLAYER
		elif dist_to_town <= aggro_range * 1.5:  # Town punya range lebih besar
			new_target = TargetType.TOWN
	else:
	
		if dist_to_town <= aggro_range * 1.5:
			new_target = TargetType.TOWN
		elif dist_to_player <= aggro_range:
			new_target = TargetType.PLAYER
	
	# Switch target hanya jika cooldown selesai atau target berbeda jauh
	if new_target != current_target and target_switch_cooldown <= 0:
		current_target = new_target
		target_switch_cooldown = 0.5  

func _handle_player_target() -> void:
	var dist_to_player = global_position.distance_to(player.global_position)
	
	if dist_to_player <= attack_range:
		state = State.ATTACK
		current_target_position = player.global_position
		attack_target(player)
	else:
		state = State.CHASE
		current_target_position = player.global_position
		move_to_target()

func _handle_town_target() -> void:
	if town == null:
		current_target = TargetType.NONE
		return
	

	var dist_to_town = global_position.distance_to(town.global_position)
	var town_attack_range = attack_range * 2.0  
	
	if dist_to_town <= town_attack_range:
		state = State.ATTACK_TOWN
		current_target_position = town.global_position
		attack_town()
	else:
		state = State.CHASE_TOWN
		current_target_position = town.global_position
		move_to_target()

func _handle_no_target() -> void:
	# Kembali ke spawn point jika terlalu jauh
	if global_position.distance_to(spawn_point) > 100:
		state = State.RETURN
		current_target_position = spawn_point
		move_to_target()
	else:
		state = State.IDLE
		velocity = Vector2.ZERO
		
func distance_to_player() -> float:
	if player == null:
		return INF
	return global_position.distance_to(player.global_position)
	
func attack_target(target_node: Node2D) -> void:
	if is_attacking:
		return
	
	is_attacking = true
	can_deal_damage = true
	

	hit_box_collision.set_deferred("disabled", false)
	
	var target_pos: Vector2 = target_node.global_position
	var attack_dir: Vector2 = (target_pos - global_position).normalized()
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	
	animation_playback.start("attack")
	

	get_tree().create_timer(attack_speed).timeout.connect(func():
		if is_attacking:
			_on_attack_animation_finished()
	)

func attack_town() -> void:
	if is_attacking:
		return
	
	if town == null:
		return
	
	is_attacking = true
	can_deal_damage = true
	

	hit_box_collision.set_deferred("disabled", false)
	
	
	var attack_dir: Vector2 = (town.global_position - global_position).normalized()
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_dir)
	
	animation_playback.start("attack")
	
	# Timer untuk town damage
	get_tree().create_timer(attack_speed * 0.5).timeout.connect(func():
		# Damage ke town di tengah animasi
		if town != null and state == State.ATTACK_TOWN:
			town.take_damage(attack_damage)
	)
	
	# Fallback timer
	get_tree().create_timer(attack_speed).timeout.connect(func():
		if is_attacking:
			_on_attack_animation_finished()
	)
	
func _on_attack_animation_finished() -> void:

	if state != State.ATTACK and state != State.ATTACK_TOWN:
		return
	
	is_attacking = false
	

	hit_box_collision.set_deferred("disabled", true)
	
	# Reset target selection untuk re-evaluate
	target_switch_cooldown = 0
	

	current_animation = ""

func move_to_target() -> void:
	nav_agent.target_position = current_target_position
	
	# Cek apakah path tersedia dan masih dalam perjalanan
	if nav_agent.is_target_reachable() and not nav_agent.is_navigation_finished():
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		velocity = global_position.direction_to(next_path_position) * speed
	else:

		var target_pos = current_target_position
		if global_position.distance_to(target_pos) > attack_range:
			velocity = global_position.direction_to(target_pos) * speed
		else:
			velocity = Vector2.ZERO
	
	# avoidance velocity
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(velocity)
	
func update_animation() -> void:
	var target_anim: String = ""
	
	match state:
		State.IDLE:
			target_anim = "idle"
		State.CHASE, State.CHASE_TOWN, State.RETURN:
			target_anim = "run"
		State.ATTACK, State.ATTACK_TOWN:
			target_anim = "attack"
	
	if target_anim != current_animation:
		current_animation = target_anim
		animation_playback.travel(current_animation)
	
func take_damage(damage_taken:int, from_position: Vector2, attacker: Node = null) -> void:
	hitpoints -= damage_taken
	_play_got_damage_sound()

	
	var direction = (global_position - from_position).normalized()
	knockback_velocity = direction * knockback_force
	
	# --- AGGRO SYSTEM: Kalau diserang Player, marah dan kejar Player! ---
	if attacker != null and attacker.is_in_group("player"):
		is_aggro_to_player = true
		aggro_timer = max_aggro_time
	
	_play_hit_flash()
	
	# --- BIKIN MUSUH STUN/KAGET ---
	is_hurt = true 
	is_attacking = false
	hit_box_collision.set_deferred("disabled", true) 
	state = State.IDLE
	current_animation = "idle" 
	
	animation_playback.start("idle")
	
	
	get_tree().create_timer(0.4).timeout.connect(func():
		is_hurt = false
	)
	 
	if hitpoints <= 0:
		call_deferred("death")



func _play_got_damage_sound() -> void:
	if got_damage_sound == null:
		return
	if got_damage_sound.playing:
		got_damage_sound.stop()
	got_damage_sound.pitch_scale = randf_range(0.95, 1.05)
	got_damage_sound.play()

func _play_death_sond() -> void:
	if death_sound == null:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null or death_sound.stream == null:
		return
	
	var temp_player := AudioStreamPlayer2D.new()
	temp_player.stream = death_sound.stream
	temp_player.global_position = global_position
	temp_player.pitch_scale = randf_range(0.95, 1.05)
	tree.current_scene.add_child(temp_player)
	temp_player.play()
	temp_player.finished.connect(temp_player.queue_free)

func setup_stats(scaling_factor: float, is_elite: bool = false) -> void:
	# Ambil base attack dari GameData
	var base_attack = GameData.get_enemy_attack_damage()
	
	hitpoints = int(hitpoints * scaling_factor)
	attack_damage = int(base_attack * scaling_factor)
	
	if is_elite:
		hitpoints *= 3
		attack_damage *= 2
		speed *= 0.8
		
		# Visual elite - lebih besar dan glow merah
		if animated_sprite:
			animated_sprite.modulate = Color(2.5, 0.5, 0.5)
			animated_sprite.scale *= 2.5  
			
		# Tambah label "ELITE" di atas kepala
		_add_elite_label()

func _add_elite_label() -> void:
	# Buat Label3D atau Label untuk menandai elite
	var label = Label.new()
	label.text = " ELITE "
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 1))
	label.add_theme_font_size_override("font_size", 24)
	label.position = Vector2(-50, -80)  # Di atas kepala enemy
	add_child(label)

func _play_hit_flash() -> void:

	

	var normal_color = Color(1, 1, 1, 1)
	var flash_color = Color(2, 2, 2, 1)  
	
	# Buat tween untuk animasi flash
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	

	animated_sprite.modulate = flash_color
	
	
	tween.tween_property(animated_sprite, "modulate", normal_color, 0.15)
	
	
	var original_scale = animated_sprite.scale
	animated_sprite.scale = original_scale * 1.1  # Besar sedikit
	
	var scale_tween = create_tween()
	scale_tween.tween_property(animated_sprite, "scale", original_scale, 0.15)
func death() -> void: 

	var death_pos = global_position
	var map_utama = get_tree().current_scene
	_play_death_sond()
	# Munculkan scene mati
	var death_scene: Node2D = death_packed.instantiate()
	death_scene.global_position = death_pos + Vector2(0.0, -32.0)
	
	
	map_utama.call_deferred("add_child", death_scene)
	
	# Munculkan Koin Emas 
	if gold_scene != null:
		var gold_drop = gold_scene.instantiate()
		gold_drop.global_position = death_pos
		
		# Titip tugas ke timer menggunakan map_utama
		get_tree().create_timer(1.25).timeout.connect(func():
			if is_instance_valid(map_utama):
				map_utama.add_child(gold_drop)
		)
	

	queue_free()

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:

	velocity = safe_velocity

func _get_separation_velocity() -> Vector2:
	var push_vector: Vector2 = Vector2.ZERO
	var nearby_enemies: int = 0
	

	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self or not is_instance_valid(other):
			continue
		if not (other is CharacterBody2D) or not other.has_method("get"):
			continue
		if other.get("state") == State.DEAD:
			continue
		
		var distance = global_position.distance_to(other.global_position)
		if distance < separation_radius and distance > 0:
			# Hitung arah dorong (menjauhi enemy lain)
			var push_dir = (global_position - other.global_position).normalized()
			# Semakin dekat, semakin kuat dorongannya
			var force = (separation_radius - distance) / separation_radius
			push_vector += push_dir * force
			nearby_enemies += 1
	
	# Terapkan dorongan jika ada enemy di dekatnya
	if nearby_enemies > 0:
		return push_vector.normalized() * separation_force

	return Vector2.ZERO


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	# Handle attack animation finished
	if anim_name in ["attack", "attack_right", "attack_left", "attack_up", "attack_down"]:
		_on_attack_animation_finished()


func _on_hit_box_area_entered(area: Area2D) -> void:
	# Hanya bisa damage saat sedang attacking dan cooldown siap
	if not is_attacking or not can_deal_damage:
		return
	

	if area.owner == self:
		return
	
	if area.has_method("take_damage"):

		can_deal_damage = false
		area.take_damage(attack_damage, global_position)
		
