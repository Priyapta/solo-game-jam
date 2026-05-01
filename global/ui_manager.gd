extends CanvasLayer



var player_health_bar: ProgressBar
var player_health_label: Label
var town_health_bar: ProgressBar
var town_health_label: Label
var gold_label: Label
var gold_icon: TextureRect

var player: Node = null
var town: Node = null
var ui_initialized: bool = false

func _ready():
	
	layer = 100
	
	# Connect ke signals
	GameData.uang_changed.connect(_on_gold_changed)
	GameData.stats_updated.connect(_on_stats_updated)
	

	_call_deferred_setup()

func _call_deferred_setup():
	await get_tree().process_frame
	

	if has_node("Control/PlayerHealthContainer/PlayerHealthBar"):
		player_health_bar = $Control/PlayerHealthContainer/PlayerHealthBar
	if has_node("Control/PlayerHealthContainer/PlayerHealthLabel"):
		player_health_label = $Control/PlayerHealthContainer/PlayerHealthLabel
	if has_node("Control/TownHealthContainer/TownHealthBar"):
		town_health_bar = $Control/TownHealthContainer/TownHealthBar
	if has_node("Control/TownHealthContainer/TownHealthLabel"):
		town_health_label = $Control/TownHealthContainer/TownHealthLabel
	if has_node("Control/GoldContainer/GoldLabel"):
		gold_label = $Control/GoldContainer/GoldLabel
	if has_node("Control/GoldContainer/GoldIcon"):
		gold_icon = $Control/GoldContainer/GoldIcon
	
	ui_initialized = (player_health_bar != null and player_health_label != null and 
					town_health_bar != null and town_health_label != null and gold_label != null)
	
	# Cari player
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.healthChanged.connect(_on_player_health_changed)
		_update_player_health()
	
	# Cari town
	town = get_tree().get_first_node_in_group("town")
	if town:
		town.town_damaged.connect(_on_town_damaged)
		_update_town_health()
	
	# Update gold
	_update_gold_display()

func _on_player_health_changed():
	_update_player_health()

func _on_town_damaged(_current_hp: int, _max_hp: int):
	_update_town_health()

func _on_gold_changed(_new_amount: int):
	_update_gold_display()

func _on_stats_updated():
	_update_player_health()
	_update_town_health()

func _update_player_health():
	if not ui_initialized:
		return
	
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		if player:
			player.healthChanged.connect(_on_player_health_changed)
	
	if player and player_health_bar and player_health_label:
		var current = player.currentHealth
		var max_hp = player.maxHealth
		
		player_health_bar.max_value = max_hp
		player_health_bar.value = current
		player_health_label.text = str(current) + " / " + str(max_hp)
		
		# Ganti warna berdasarkan HP
		if current > max_hp * 0.6:
			player_health_bar.modulate = Color(0.2, 0.8, 0.2)  # Hijau
		elif current > max_hp * 0.3:
			player_health_bar.modulate = Color(1, 0.8, 0)     # Kuning
		else:
			player_health_bar.modulate = Color(1, 0.2, 0.2)   # Merah

func _update_town_health():
	if not ui_initialized:
		return
	
	if town == null:
		town = get_tree().get_first_node_in_group("town")
		if town:
			town.town_damaged.connect(_on_town_damaged)
	
	if town and town_health_bar and town_health_label:
		var current = town.current_hp
		var max_hp = town.maxHealth
		
		town_health_bar.max_value = max_hp
		town_health_bar.value = current
		town_health_label.text = str(current) + " / " + str(max_hp)
		
		
		if current > max_hp * 0.6:
			town_health_bar.modulate = Color(0.2, 0.5, 0.9)  
		elif current > max_hp * 0.3:
			town_health_bar.modulate = Color(1, 0.8, 0)     
		else:
			town_health_bar.modulate = Color(1, 0.2, 0.2)   

func _update_gold_display():
	if not ui_initialized or gold_label == null:
		return
	
	gold_label.text = str(GameData.uang)
	
	# Animasi pop saat gold berubah
	var tween = create_tween()
	tween.tween_property(gold_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(gold_label, "scale", Vector2(1.0, 1.0), 0.1)

func _process(_delta):
	# Refresh reference jika scene berubah
	if not ui_initialized:
		return
	
	if player == null or !is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if player and !player.healthChanged.is_connected(_on_player_health_changed):
			player.healthChanged.connect(_on_player_health_changed)
			_update_player_health()
	
	if town == null or !is_instance_valid(town):
		town = get_tree().get_first_node_in_group("town")
		if town and town.has_signal("town_damaged"):
			town.town_damaged.connect(_on_town_damaged)
			_update_town_health()
