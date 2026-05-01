extends CanvasLayer

# ============================================
# PAUSE MENU SCRIPT
# ============================================
# Fungsi: Menampilkan menu pause saat tekan ESC/P
# Tombol: Resume (lanjut), Restart (ulang), Exit (ke menu)
# ============================================

func _ready():
	# Process mode ALWAYS = tetap jalan saat game di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Sembunyikan pause menu di awal
	visible = false

func _input(event: InputEvent) -> void:
	# Deteksi tombol ESC (ui_cancel) atau P (pause)
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	# Cek scene saat ini - jangan pause di menu utama/game over
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_path = current_scene.scene_file_path.to_lower()
		# Skip jika di main menu atau game over
		if "main_menu" in scene_path or "game_over" in scene_path or "end_game" in scene_path:
			return
	
	# Toggle pause state
	if get_tree().paused:
		# RESUME: Matikan pause, sembunyikan menu
		get_tree().paused = false
		visible = false
	else:
		# PAUSE: Aktifkan pause, tampilkan menu
		get_tree().paused = true
		visible = true

# ============================================
# BUTTON CALLBACKS
# ============================================

func _on_resume_game_pressed():
	# Lanjutkan game dari posisi terakhir
	get_tree().paused = false
	visible = false

func _on_restart_game_pressed():
	# Ulang game dari awal - selalu ke world
	get_tree().paused = false
	visible = false
	
	# Reset semua data
	if GameData:
		GameData.reset_all_data()
	
	# Reset navigation state
	if NavigationManager:
		NavigationManager.current_day = 1
		NavigationManager.current_level = "world"
		NavigationManager.spawn_door_tag = ""
	
	# Selalu pindah ke world
	get_tree().change_scene_to_file("res://scenes/world/world.tscn")

func _on_exit_pressed():
	# Exit = reset semua data lalu ke main menu (no save system)
	get_tree().paused = false
	visible = false
	
	# Reset semua data karena tidak ada save system
	if GameData:
		GameData.reset_all_data()
	
	# Reset navigation state
	if NavigationManager:
		NavigationManager.current_day = 1
		NavigationManager.current_level = "world"
		NavigationManager.spawn_door_tag = ""
	
	get_tree().change_scene_to_file("res://scenes/MainMenu/main_menu.tscn")
