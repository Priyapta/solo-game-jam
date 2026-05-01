extends Node2D

# Pastikan nama-nama node ini persis dengan yang ada di Scene Anda
@onready var line = $Line2D
@onready var hit_area = $HitboxThunder
@onready var collision_shape = $HitboxThunder/CollisionShape2D
@onready var life_timer = $LifeTime
const SPARK_EFFECT_SCENE = preload("res://scenes/effects/thunder_effect.tscn")
# Variabel yang bisa diatur dari Inspector"res://scenes/effects/thunder_effect.tscn"
@export var damage: int = 10
@export var beam_thickness: float = 20.0
@export var flash_duration: float = 0.2

func _ready():
	z_index = 10 # Pastikan di atas objek lain
	# Hubungkan timer penghancuran diri jika belum ada di TSCN
	if not life_timer.timeout.is_connected(_on_life_timer_timeout):
		life_timer.timeout.connect(_on_life_timer_timeout)

func _process(_delta):
	# Efek visual kedip-kedip (Flicker) agar terlihat seperti aliran listrik
	modulate.a = randf_range(0.6, 1.0)
	line.width = randf_range(beam_thickness * 0.8, beam_thickness * 1.2)

# Fungsi ini akan dipanggil oleh Tower saat menembak
func fire(start_pos: Vector2, end_pos: Vector2):
	# 1. Pindahkan posisi pangkal petir ke posisi Tower
	global_position = start_pos 
	
	# 2. Gambar garis dari Tower (0,0) ke Musuh
	line.clear_points()
	line.add_point(Vector2.ZERO)
	var local_end = to_local(end_pos) # Ubah posisi musuh menjadi relatif terhadap Tower
	line.add_point(local_end)
	
	# 3. Atur ukuran dan posisi Hitbox agar menutupi garis petir
	var distance = start_pos.distance_to(end_pos)
	var rect = RectangleShape2D.new()
	rect.size = Vector2(distance, beam_thickness)
	collision_shape.shape = rect
	
	# Geser Hitbox ke tengah-tengah garis dan putar sesuai arah tembakan
	hit_area.position = local_end / 2.0
	hit_area.rotation = start_pos.direction_to(end_pos).angle()
	
	# 4. Mulai hitung mundur untuk menghapus petir
	life_timer.wait_time = flash_duration
	life_timer.start()

# Fungsi ini terpicu otomatis jika ada benda yang menyentuh Area2D petir

# Fungsi ini terpicu otomatis saat waktu Timer habis (0.2 detik)
func _on_life_timer_timeout():
	queue_free() # Hapus petir dari game


func _on_hitbox_thunder_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") or body.is_in_group("Enemy"):
		# Pastikan musuh memiliki fungsi take_damage di script-nya
		if body.has_method("take_damage"):
			# Kirim damage dan posisi petir (global_position) sebagai argumen kedua
			body.take_damage(damage, global_position)
			
			# Munculkan efek percikan (Spark) di posisi musuh
			if SPARK_EFFECT_SCENE:
				var spark = SPARK_EFFECT_SCENE.instantiate()
				get_tree().current_scene.add_child(spark)
				spark.global_position = body.global_position
