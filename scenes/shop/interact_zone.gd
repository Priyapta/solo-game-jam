extends StaticBody2D


var is_player_near: bool = false


var shop_menu_instance: CanvasLayer = null


@onready var interact_prompt: Label = $InteractPrompt

var shop_items: Array[UpgradeData] = [
	preload("res://assets/resources/ability/attack.tres"),
	preload("res://assets/resources/ability/defense.tres"),
	preload("res://assets/resources/skill/arrow.tres"),
	preload("res://assets/resources/skill/lightning.tres"),
	#preload("res://assets/resources/ability/movement_speed.tres"),
	preload("res://assets/resources/ability/dash.tres"),
	preload("res://assets/resources/ability/tower_health.tres"),
	preload("res://assets/resources/ability/money.tres")
	
]

func _ready() -> void:

	if interact_prompt:
		interact_prompt.visible = false



func _on_interactzone_area_exited(area: Area2D) -> void:
	if area.owner and area.owner.is_in_group("player"):
		is_player_near = false
		tutup_menu_upgrade()

# 4. Deteksi tombol 'E' di sini
func _unhandled_input(_event: InputEvent) -> void:
	
	if _event.is_action_pressed("interact") and is_player_near:
		buka_menu_upgrade()

func buka_menu_upgrade() -> void:
	
	# Jika shop sudah ada, tidak perlu buat lagi
	if shop_menu_instance != null:
		return
	

	if interact_prompt:
		interact_prompt.visible = false
	

	var shop_scene_resource = load("res://scenes/sellcard/shop_scene.tscn")
	if shop_scene_resource == null:
		# Tampilkan kembali prompt jika gagal
		if interact_prompt and is_player_near:
			interact_prompt.visible = true
		return
	
	shop_menu_instance = shop_scene_resource.instantiate()
	if shop_menu_instance == null:
		# Tampilkan kembali prompt jika gagal
		if interact_prompt and is_player_near:
			interact_prompt.visible = true
		return
	

	shop_menu_instance.layer = 10
	get_tree().root.add_child(shop_menu_instance)
	
	await get_tree().process_frame
	

	var menu = shop_menu_instance
	if menu and menu.has_method("show_menu"):
		
		menu.show_menu(shop_items, "player")
		
		if not menu.hidden.is_connected(tutup_menu_upgrade):
			menu.hidden.connect(tutup_menu_upgrade)
	else:
		
		# Tampilkan kembali prompt jika gagal
		if interact_prompt and is_player_near:
			interact_prompt.visible = true
	

func tutup_menu_upgrade() -> void:
	if shop_menu_instance != null:
		shop_menu_instance.queue_free()
		shop_menu_instance = null
	
	# Tampilkan kembali prompt jika player masih di area
	if interact_prompt and is_player_near:
		interact_prompt.visible = true


func _on_interactzone_body_entered(body: Node2D) -> void:
	# Cek apakah body yang masuk adalah player
	if body.is_in_group("player"):
		is_player_near = true
		
		
		if interact_prompt:
			interact_prompt.visible = true

func _on_interactzone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_near = false
		# Sembunyikan prompt
		if interact_prompt:
			interact_prompt.visible = false
		tutup_menu_upgrade()
