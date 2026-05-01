extends CharacterBody2D

@export var speed: float = 200.0
@export var attack_cooldown: float = 0.6
@export var arrow_cooldown: float = 0.9

var attack_damage: int = 10
var defense: int = 5
var currentHealth: int = 100
var maxHealth: int = 100

@onready var arrow_scene = preload("res://scenes/projectile/arrow.tscn")
var dash_speed: float = 400.0
@export var dash_duration: float = 0.10
var dash_cooldown: float = 0.8
@onready var hit_sound: AudioStreamPlayer2D = $SoundAttack
@onready var Death_sound: AudioStreamPlayer2D = $DeathSound
@onready var walk_sound: AudioStreamPlayer2D = $WalkSound
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hit_box_collision: CollisionShape2D = $HitBox/CollisionShape2D
@onready var hurt_box_collision: CollisionShape2D = $HurtBox/CollisionShape2D
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_force: float = 200.0

signal healthChanged
signal player_died  


enum State {
	IDLE,
	RUN,
	ATTACK,
	DEAD
}

var state: State = State.IDLE
var input_direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN
var attack_direction: Vector2 = Vector2.DOWN
var can_attack: bool = true
var can_deal_damage: bool = true  # Cooldown untuk damage
var damaged_enemies: Array = []  # Track enemy yang sudah kena damage dalam attack ini
var can_shoot_arrow: bool = true
var respawn_position: Vector2
var walk_sound_cooldown: float = 0.0

# Dash State
var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	animation_tree.active = true
	hit_box_collision.set_deferred("disabled", true)
	

	GameData.stats_updated.connect(_on_stats_updated)
	

	_apply_upgrades()
	
	currentHealth = maxHealth
	respawn_position = global_position
func _on_stats_updated() -> void:
	var old_max = maxHealth
	_apply_upgrades()
	
	var hp_increase = maxHealth - old_max
	if hp_increase > 0:
		currentHealth += int(hp_increase * 0.5)
		currentHealth = min(currentHealth, maxHealth)
	
	healthChanged.emit()

func _apply_upgrades() -> void:

	maxHealth = GameData.get_player_max_hp()
	attack_damage = GameData.get_player_attack_damage()
	defense = GameData.get_player_defense()
	dash_speed = GameData.get_dash_speed()
	dash_cooldown = GameData.get_dash_cooldown()
	knockback_force = GameData.get_knockback_force()
	


func take_damage(amount: int, from_position: Vector2, _attacker: Node = null) -> void:
	if hit_sound != null:
		hit_sound.pitch_scale = randf_range(0.95, 1.05)
		hit_sound.play()
	
	var damage_multiplier = 100.0 / (100.0 + defense)
	var reduced_damage = int(amount * damage_multiplier)
	reduced_damage = max(reduced_damage, 1)  # Minimum 1 damage
	
	# 1. Kurangi darah
	currentHealth -= reduced_damage
	currentHealth = max(currentHealth, 0)
	
	# 2. Update UI Health Bar
	healthChanged.emit()
	
	# 3. Hitung arah pantulan (Knockback)
	var direction = (global_position - from_position).normalized()
	knockback_velocity = direction * knockback_force
	
	# 4. Cek apakah mati
	if currentHealth <= 0:
		_die()

func _die() -> void:
	state = State.DEAD
	var death_position = global_position
	if Death_sound != null:
		Death_sound.pitch_scale = randf_range(0.98, 1.02)
		Death_sound.play()
	_disable_player_for_respawn()
	player_died.emit()

	await get_tree().create_timer(2.0).timeout
	global_position = death_position
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	currentDirection_reset()
	currentHealth = maxHealth
	state = State.IDLE
	_enable_player_after_respawn()
	healthChanged.emit()

func set_respawn_point(new_respawn_position: Vector2) -> void:
	respawn_position = new_respawn_position

func _disable_player_for_respawn() -> void:
	visible = false
	can_attack = false
	can_dash = false
	can_shoot_arrow = false
	is_dashing = false
	if walk_sound != null:
		walk_sound.stop()
	hit_box_collision.set_deferred("disabled", true)
	body_collision.set_deferred("disabled", true)
	hurt_box_collision.set_deferred("disabled", true)

func _enable_player_after_respawn() -> void:
	visible = true
	can_attack = true
	can_dash = true
	can_shoot_arrow = true
	body_collision.set_deferred("disabled", false)
	hurt_box_collision.set_deferred("disabled", false)

func currentDirection_reset() -> void:
	input_direction = Vector2.ZERO
	last_direction = Vector2.DOWN
	attack_direction = Vector2.DOWN
	update_sprite_flip(last_direction)
	update_animation()

func _update_walk_sound() -> void:
	if walk_sound == null:
		return
	var is_walking = state == State.RUN and input_direction != Vector2.ZERO and velocity.length() > 10.0 and not is_dashing
	if not is_walking:
		if walk_sound.playing:
			walk_sound.stop()
		return
	if walk_sound.playing or walk_sound_cooldown > 0:
		return
	walk_sound.pitch_scale = randf_range(0.98, 1.02)
	walk_sound.play()
	walk_sound_cooldown = 0.35

func heal(amount: int) -> void:
	currentHealth += amount
	currentHealth = min(currentHealth, maxHealth)
	healthChanged.emit()

func _unhandled_input(event: InputEvent) -> void:
	if state == State.DEAD:
		return
		
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed \
	and can_attack \
	and state != State.ATTACK \
	and not is_dashing:
		attack()
	
	# Shoot arrow with right click (only if unlocked)
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed \
	and not is_dashing:
		if GameData.is_arrow_unlocked():
			shoot_arrow()
	
	
	# Dash input
	if event is InputEventKey \
	and event.keycode == KEY_SHIFT \
	and event.pressed \
	and can_dash \
	and not is_dashing \
	and state != State.ATTACK:
		dash()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	
	# Apply knockback 
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 200 * delta)
	if walk_sound_cooldown > 0:
		walk_sound_cooldown -= delta
	
	if is_dashing:
		
		velocity = dash_direction * dash_speed
	elif state != State.ATTACK:
		movement_loop()
	else:
		
		velocity = Vector2.ZERO
	

	velocity += knockback_velocity
	move_and_slide()
	_update_walk_sound()


func movement_loop() -> void:
	input_direction = Input.get_vector("left", "right", "up", "down")
	
	velocity = input_direction * speed
	
	if input_direction != Vector2.ZERO:
		last_direction = input_direction.normalized()
		if not is_dashing:
			state = State.RUN
	elif not is_dashing:
		state = State.IDLE
	
	update_animation()
	update_sprite_flip(last_direction)


func dash() -> void:
	is_dashing = true
	can_dash = false
	
	# Tentukan arah dash
	if input_direction != Vector2.ZERO:
		dash_direction = input_direction.normalized()
	else:
		dash_direction = last_direction
	

	await get_tree().create_timer(dash_duration).timeout
	

	is_dashing = false
	
	
	if input_direction != Vector2.ZERO:
		state = State.RUN
	else:
		state = State.IDLE
	update_animation()
	

	await get_tree().create_timer(dash_cooldown - dash_duration).timeout
	can_dash = true

func shoot_arrow() -> void:
	if not GameData.is_arrow_unlocked() or not can_shoot_arrow:
		return
	
	can_shoot_arrow = false
	
	# Hitung arah ke mouse
	var mouse_pos = get_global_mouse_position()
	var shoot_direction = (mouse_pos - global_position).normalized()
	var projectile_count = GameData.get_arrow_projectile_count()
	var spacing_degrees = 14.0
	
	for i in range(projectile_count):
		var arrow_instance = arrow_scene.instantiate()
		arrow_instance.global_position = global_position
		
		var angle_offset = deg_to_rad((i - (projectile_count - 1) / 2.0) * spacing_degrees)
		arrow_instance.direction = shoot_direction.rotated(angle_offset)
		arrow_instance.damage = GameData.get_arrow_damage()
		
		get_tree().current_scene.add_child(arrow_instance)
	
	await get_tree().create_timer(arrow_cooldown).timeout
	can_shoot_arrow = true

func attack() -> void:
	can_attack = false
	can_deal_damage = true 
	damaged_enemies.clear()  
	state = State.ATTACK
	velocity = Vector2.ZERO
	

	hit_box_collision.set_deferred("disabled", false)
	

	await get_tree().physics_frame
	

	if state == State.ATTACK:
		_deal_damage_to_all_in_range()
	
	
	var mouse_pos := get_global_mouse_position()
	var dir := (mouse_pos - global_position).normalized()
	
	# lock 4 arah
	if abs(dir.x) > abs(dir.y):
		attack_direction = Vector2(sign(dir.x), 0)
	else:
		attack_direction = Vector2(0, sign(dir.y))
	
	last_direction = attack_direction
	$AnimatedSprite2D.flip_h = attack_direction.x < 0 and abs(attack_direction.x) >= abs(attack_direction.y)
	
	# kirim ke blendspace
	animation_tree.set("parameters/attack/BlendSpace2D/blend_position", attack_direction)
	update_sprite_flip(attack_direction)
	
	update_animation()
	
	await get_tree().create_timer(attack_cooldown).timeout
	

	hit_box_collision.set_deferred("disabled", true)
	
	can_attack = true
	state = State.IDLE
	update_animation()


func update_animation() -> void:
	if is_dashing:
		playback.travel("run")
		animation_tree.set("parameters/run/blend_position", dash_direction)
		return
	
	match state:
		State.IDLE:
			playback.travel("idle")
			animation_tree.set("parameters/idle/blend_position", last_direction)

		State.RUN:
			playback.travel("run")
			animation_tree.set("parameters/run/blend_position", last_direction)

		State.ATTACK:
			playback.travel("attack")



func update_sprite_flip(direction: Vector2) -> void:
	var flip_dir = direction
	if is_dashing:
		flip_dir = dash_direction
	
	if flip_dir.x < 0:
		sprite.flip_h = true
	elif flip_dir.x > 0:
		sprite.flip_h = false


func _deal_damage_to_all_in_range():
	if state != State.ATTACK:
		return
	
	var hit_box = $HitBox
	var overlapping_areas = hit_box.get_overlapping_areas()
	
	var damage_count = 0
	for area in overlapping_areas:
		if area.owner == self:
			continue
		
		# Skip jika bukan hurtbox enemy
		if not area.has_method("take_damage"):
			continue
		
		# Skip jika enemy ini sudah kena damage dalam attack ini
		if area.owner in damaged_enemies:
			continue
		
	
		damaged_enemies.append(area.owner)
		area.take_damage(attack_damage, global_position, self)
		damage_count += 1

func _on_hit_box_area_entered(area):
	# Hanya proses saat sedang attacking
	if state != State.ATTACK:
		return
	

	if area.owner == self:
		return
	

	if not area.has_method("take_damage"):
		return
	

	if area.owner in damaged_enemies:
		return
	

	damaged_enemies.append(area.owner)
	area.take_damage(attack_damage, global_position, self)
