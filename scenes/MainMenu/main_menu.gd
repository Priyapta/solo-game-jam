extends Control

const WORLD_SCENE = preload("res://scenes/world/world.tscn")
const SETTINGS_SCENE = preload("res://global/settings.tscn")

signal new_game_pressed(origin: String)
signal settings_pressed(origin: String)
signal about_pressed(origin: String)
signal exit_pressed(origin: String)

@onready var title_label: Label = $TitleLabel
@onready var new_game_btn: TextureButton = $ButtonContainer/NewGame
@onready var settings_btn: TextureButton = $ButtonContainer/Settings
@onready var exit_btn: TextureButton = $ButtonContainer/Exit

var _title_base_y: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	title_label = $TitleLabel
	new_game_btn = $ButtonContainer/NewGame
	settings_btn = $ButtonContainer/Settings
	exit_btn = $ButtonContainer/Exit
	
	_title_base_y = title_label.offset_top
	
	_setup_particles()
	_setup_button(new_game_btn)
	_setup_button(settings_btn)
	_setup_button(exit_btn)

func _setup_particles() -> void:

	for i in range(15):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(4, 10), randf_range(4, 10))
		particle.position = Vector2(randf_range(0, 1920), randf_range(300, 1080))
		
		var colors = [
			Color(1.0, 0.7, 0.2, randf_range(0.3, 0.7)), 
			Color(1.0, 0.5, 0.1, randf_range(0.3, 0.6)),  
			Color(0.9, 0.3, 0.05, randf_range(0.2, 0.5)),  
		]
		particle.color = colors.pick_random()
		particle.name = "Particle_" + str(i)
		add_child(particle)
		move_child(particle, 1) 

func _process(delta: float) -> void:
	_time += delta
	
	if title_label:
		title_label.offset_top = _title_base_y + sin(_time * 1.5) * 8.0
		title_label.offset_bottom = title_label.offset_top + 110.0
		var pulse = 1.0 + sin(_time * 2.0) * 0.03
		title_label.scale = Vector2(pulse, pulse)
		
	for i in range(15):
		var particle = get_node_or_null("Particle_" + str(i))
		if particle:
			particle.position.y -= (30 + i * 3) * delta
			particle.position.x += sin(_time * 0.5 + i) * 10 * delta
	
			var progress = (1080.0 - particle.position.y) / 1080.0
			var alpha = clampf(0.7 - progress * 0.8, 0.0, 0.7)
			particle.color.a = alpha
		
			if particle.position.y < -20:
				particle.position.y = 1080 + randf_range(0, 100)
				particle.position.x = randf_range(0, 1920)

func _setup_button(btn: TextureButton) -> void:
	btn.mouse_entered.connect(_on_button_hover.bind(btn))
	btn.mouse_exited.connect(_on_button_unhover.bind(btn))

func _on_button_hover(btn: TextureButton) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(btn, "modulate", Color(1.3, 1.3, 1.2, 1.0), 0.15)

func _on_button_unhover(btn: TextureButton) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _on_new_game_pressed() -> void:
	new_game_pressed.emit("main_menu")
	get_tree().change_scene_to_packed(WORLD_SCENE)

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_packed(SETTINGS_SCENE)

func _on_about_pressed() -> void:
	about_pressed.emit("main_menu")

func _on_exit_pressed() -> void:
	exit_pressed.emit("main_menu")
	get_tree().quit()
