extends Control

@onready var master_slider: HSlider = %MasterSlider
@onready var master_value: Label = %MasterValue
@onready var master_mute: CheckBox = %MasterMute

var _master_bus: int

func _ready() -> void:
	_master_bus = AudioServer.get_bus_index("Master")
	_load_settings()
	_update_label(master_value, master_slider.value)

func _load_settings() -> void:
	master_slider.value = _bus_volume_to_slider(_master_bus)
	master_mute.button_pressed = AudioServer.is_bus_mute(_master_bus)

func _bus_volume_to_slider(bus_idx: int) -> float:
	var db = AudioServer.get_bus_volume_db(bus_idx)
	return clampf(db_to_linear(db) * 100.0, 0.0, 100.0)

func _slider_to_db(value: float) -> float:
	if value <= 0.0:
		return -60.0
	return linear_to_db(value / 100.0)

func _update_label(label: Label, value: float) -> void:
	label.text = str(int(value)) + "%"

func _apply_volume(bus_idx: int, value: float) -> void:
	AudioServer.set_bus_volume_db(bus_idx, _slider_to_db(value))
	if value <= 0.0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)

func _on_master_changed(value: float) -> void:
	_apply_volume(_master_bus, value)
	_update_label(master_value, value)

func _on_master_mute_toggled(pressed: bool) -> void:
	AudioServer.set_bus_mute(_master_bus, pressed)
	if pressed:
		master_slider.value = 0
		_update_label(master_value, 0)
	else:
		master_slider.value = 100
		_update_label(master_value, 100)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu/main_menu.tscn")
