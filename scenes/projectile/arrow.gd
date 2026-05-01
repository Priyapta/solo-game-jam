extends Area2D

@export var speed: float = 600.0
@export var damage: int = 25
@export var max_distance: float = 1000.0

var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0

func _ready() -> void:
	# Rotasi arrow sesuai arah
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	# Gerakkan arrow ke arah yang ditentukan
	var movement = direction * speed * delta
	position += movement
	traveled_distance += movement.length()
	
	# Hancurkan arrow jika sudah terlalu jauh
	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Jika kena enemy, beri damage
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Jika kena hurtbox enemy, beri damage
	if area.has_method("take_damage"):
		area.take_damage(damage, global_position)
	queue_free()
