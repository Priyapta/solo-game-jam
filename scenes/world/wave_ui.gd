extends CanvasLayer

@onready var label = $Control/WaveLabel
@onready var anim_player = $AnimationPlayer

# HUD Elements
@onready var persistent_day_label = $Control/HUD/MarginContainer/VBoxContainer/DayLabel



func _ready():
	
	label.modulate.a = 0
	label.scale = Vector2(0.5, 0.5)
	
	# Inisialisasi HUD
	_update_persistent_day()
	
	# Cari spawner di scene world
	var spawner = get_tree().get_first_node_in_group("spawner")
	if spawner:
		spawner.day_started.connect(_on_day_started)
		if spawner.current_day > 0:
			_on_day_started(spawner.current_day, spawner.current_day % 10 == 0)
	


func _update_persistent_day():
	if NavigationManager:
		persistent_day_label.text = "DAY " + str(NavigationManager.current_day)



func _on_day_started(number: int, is_horde: bool):
	_update_persistent_day()
	if is_horde:
		label.text = "!!! HORDE DAY " + str(number) + " !!!"
		label.add_theme_color_override("font_color", Color.RED)
	else:
		label.text = "DAY " + str(number)
		label.add_theme_color_override("font_color", Color.WHITE)
	
	# Jalankan animasi
	if anim_player.has_animation("show_wave"):
		anim_player.play("show_wave")
	else:
		_fallback_animation()

func _fallback_animation():
	var tween = create_tween()
	label.modulate.a = 0
	label.scale = Vector2(0.5, 0.5)
	
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
