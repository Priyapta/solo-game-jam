extends AnimatedSprite2D

@onready var thunder_sound: AudioStreamPlayer2D = $thunderSound
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Pastikan animasi diputar dari awal
	sprite_frames.set_animation_loop("strike", false) # Matikan loop agar memicu signal finished
	play("strike")
	thunder_sound.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_animation_finished() -> void:
	
	queue_free()
