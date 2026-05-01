extends CharacterBody2D

@onready var path: Path2D = $Path2D
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D

var last_position: Vector2

@export var move_speed: float = 60.0

func _ready() -> void:
	# Set posisi dan rotasi awal saat game dimulai
	position = path_follow.global_position
	rotation = path_follow.rotation
	
	last_position = position

func _physics_process(delta: float) -> void:
	# 1. Majukan titik PathFollow di jalurnya
	path_follow.progress += move_speed * delta
	
	# 2. Pindahkan posisi kotak ke titik PathFollow yang baru
	position = path_follow.global_position
	
	# 3. [BARU] Samakan rotasi kotak agar ikut berbelok sesuai kurva jalur
	rotation = path_follow.rotation
	
	# 4. Kalkulasi vektor pergerakan (bisa kamu pakai untuk logika partikel asap dsb)
	var movement := position - last_position
	
	# 5. Simpan posisi saat ini untuk dihitung di frame berikutnya
	last_position = position
