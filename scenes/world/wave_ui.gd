extends CanvasLayer

@onready var label = $Control/WaveLabel
@onready var anim_player = $AnimationPlayer

# HUD Elements
@onready var persistent_day_label = $Control/HUD/MarginContainer/VBoxContainer/DayLabel

# Town Indicator
var _arrow: Polygon2D
var _arrow_bg: Polygon2D
var _dist_label: Label
var _town: Node2D = null
var _player: Node2D = null

const _EDGE_MARGIN := 55.0
var _ARROW_SHAPE := PackedVector2Array([
	Vector2(20, 0),
	Vector2(-8, -13),
	Vector2(-3, -6),
	Vector2(-12, -6),
	Vector2(-12, 6),
	Vector2(-3, 6),
	Vector2(-8, 13),
])

func _ready():

	label.modulate.a = 0
	label.scale = Vector2(0.5, 0.5)

	_create_town_indicator()

	# Inisialisasi HUD
	_update_persistent_day()

	# Cari spawner di scene world
	var spawner = get_tree().get_first_node_in_group("spawner")
	if spawner:
		spawner.day_started.connect(_on_day_started)
		if spawner.current_day > 0:
			_on_day_started(spawner.current_day, spawner.current_day % 10 == 0)

func _create_town_indicator() -> void:
	_arrow_bg = Polygon2D.new()
	_arrow_bg.color = Color(0, 0, 0, 0.6)
	_arrow_bg.polygon = _ARROW_SHAPE
	_arrow_bg.scale = Vector2(1.3, 1.3)
	add_child(_arrow_bg)

	_arrow = Polygon2D.new()
	_arrow.color = Color(1.0, 0.85, 0.1, 1.0)
	_arrow.polygon = _ARROW_SHAPE
	add_child(_arrow)

	_dist_label = Label.new()
	_dist_label.add_theme_font_size_override("font_size", 14)
	_dist_label.add_theme_color_override("font_color", Color.WHITE)
	_dist_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_dist_label.add_theme_constant_override("outline_size", 5)
	add_child(_dist_label)

func _process(_delta: float) -> void:
	_update_town_indicator()

func _update_town_indicator() -> void:
	if not is_instance_valid(_town):
		_town = get_tree().get_first_node_in_group("town") as Node2D
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D

	if _town == null or _player == null:
		_arrow.visible = false
		_arrow_bg.visible = false
		_dist_label.visible = false
		return

	var camera := get_viewport().get_camera_2d()
	if camera == null:
		_arrow.visible = false
		_arrow_bg.visible = false
		_dist_label.visible = false
		return

	var vp_size := get_viewport().get_visible_rect().size
	var center := vp_size * 0.5
	var zoom := camera.zoom
	var town_screen := (_town.global_position - camera.global_position) * zoom + center

	var m := _EDGE_MARGIN
	if town_screen.x >= m and town_screen.x <= vp_size.x - m \
	and town_screen.y >= m and town_screen.y <= vp_size.y - m:
		_arrow.visible = false
		_arrow_bg.visible = false
		_dist_label.visible = false
		return

	var diff := town_screen - center
	if diff.length_squared() < 1.0:
		_arrow.visible = false
		_arrow_bg.visible = false
		_dist_label.visible = false
		return

	var dir := diff.normalized()

	var half_w := center.x - m
	var half_h := center.y - m
	var t := INF
	if abs(dir.x) > 0.0001:
		t = min(t, abs(half_w / dir.x))
	if abs(dir.y) > 0.0001:
		t = min(t, abs(half_h / dir.y))

	var pos := center + dir * t
	var rot := dir.angle()
	var alpha := 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.004)

	_arrow.visible = true
	_arrow.position = pos
	_arrow.rotation = rot
	_arrow.modulate.a = alpha

	_arrow_bg.visible = true
	_arrow_bg.position = pos
	_arrow_bg.rotation = rot
	_arrow_bg.modulate.a = alpha * 0.7

	var dist := int(_player.global_position.distance_to(_town.global_position))
	_dist_label.visible = true
	_dist_label.text = str(dist) + "m"
	var lpos := pos + dir * 30.0
	_dist_label.position = lpos - Vector2(_dist_label.size.x * 0.5, _dist_label.size.y * 0.5)
	


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
