extends CanvasLayer

# Preload scene button
const SHOP_ITEM_BUTTON = preload("res://scenes/sellcard/shop_item_button.tscn")

signal shown
signal hidden

var is_active: bool = false
var current_items: Array[UpgradeData] = []
var current_target: String = "player"  

# Simpan mapping button ke upgrade_id dan nama item untuk refresh
var button_upgrade_map: Dictionary = {}
var button_name_map: Dictionary = {}

@onready var close_button: Button = %CloseButton
@onready var shop_item_container: VBoxContainer = %ShopItemsContainer
@onready var coins_label: Label = %CoinsLabel
@onready var gems_animation_player: AnimationPlayer = $Control/PanelContainer/AnimationPlayer

@onready var item_image: TextureRect = %ItemImage
@onready var item_name: Label = %ItemName
@onready var item_description: Label = %ItemDescription
@onready var item_price: Label = %ItemPrice
@onready var item_status: Label = %ItemStatus

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_menu()
	close_button.pressed.connect(hide_menu)
	
	# Update coins display saat uang berubah
	GameData.uang_changed.connect(_on_uang_changed)
	
	# Refresh display saat stats berubah (dari pembelian di shop lain atau event)
	GameData.stats_updated.connect(_on_stats_updated)

func _on_uang_changed(_new_amount: int) -> void:
	update_coins()
	_refresh_all_button_prices()

func _on_stats_updated() -> void:
	# Refresh semua display saat stats berubah
	_refresh_item_display()
	_refresh_all_button_prices()
	update_coins()

func _unhandled_input(_event: InputEvent) -> void:
	if is_active == false:
		return


func show_menu(items: Array[UpgradeData], target: String = "player") -> void:
	
	current_items = items
	current_target = target
	
	enable_menu(true)
	populate_item_list(items)
	update_coins()
	
	if shop_item_container.get_child_count() > 0:
		var first_button = shop_item_container.get_child(0)
		first_button.grab_focus()
		# Auto-select first item to show details
		if current_items.size() > 0:
			update_item_details(current_items[0])
	
	shown.emit()


func hide_menu() -> void:
	enable_menu(false)
	clear_item_list()
	hidden.emit()

func enable_menu(_enabled: bool = true) -> void:
	get_tree().paused = _enabled
	visible = _enabled
	is_active = _enabled

func update_coins() -> void:
	if coins_label != null:
		coins_label.text = str(GameData.uang)

func clear_item_list() -> void:
	for c in shop_item_container.get_children():
		c.queue_free()
	button_upgrade_map.clear()
	button_name_map.clear()

func populate_item_list(items: Array[UpgradeData]) -> void:
	for item in items:
		var shop_item: ShopItemButton = SHOP_ITEM_BUTTON.instantiate()
		
		# Dapatkan upgrade_id dan data info dari GameData
		var upgrade_id = _get_upgrade_id_from_name(item.name)
		var target = _get_target_for_upgrade(upgrade_id)
		var info = GameData.get_upgrade_info(target, upgrade_id)
		
		# Update item cost dengan harga terkini
		item.cost = info["current_price"]
		
		# Setup button dengan info terbaru
		shop_item.setup_item(item, info["current_level"], info["max_level"])
		if upgrade_id == "tower_hp" and shop_item.has_node("Label"):
			shop_item.get_node("Label").text = _get_tower_hp_label(item.name, info)
		
		# Simpan mapping untuk refresh nanti
		button_upgrade_map[shop_item] = upgrade_id
		button_name_map[shop_item] = item.name
		
		shop_item_container.add_child(shop_item)
		shop_item.focus_entered.connect(update_item_details.bind(item))
		shop_item.pressed.connect(purchase_item.bind(item))

func focused_item_changed(item: UpgradeData) -> void:
	if item:
		update_item_details(item)

func update_item_details(item: UpgradeData) -> void:
	item_image.texture = item.texture
	item_name.text = item.name
	item_description.text = item.description
	
	# Dapatkan harga real-time dari GameData
	var upgrade_id = _get_upgrade_id_from_name(item.name)
	var target = _get_target_for_upgrade(upgrade_id)
	var price = GameData.get_upgrade_price(target, upgrade_id)
	if upgrade_id == "tower_hp":
		var info = GameData.get_upgrade_info(target, upgrade_id)
		item_price.text = str(price)
		item_description.text = "HP Town: %d | " % info.get("current_hp", 0)
	else:
		item_price.text = str(price)
	
	if item_status != null:
		item_status.text = _get_item_status_text(upgrade_id, target)
	
	# Update item.cost untuk referensi
	item.cost = price

func purchase_item(item: UpgradeData) -> void:
	var upgrade_id = _get_upgrade_id_from_name(item.name)
	var target = _get_target_for_upgrade(upgrade_id)
	
	# Coba beli upgrade via GameData
	var success = GameData.beli_upgrade(target, upgrade_id)
	
	if success:
		update_coins()
		update_item_details(item)
		
		# Update display item list untuk menunjukkan level baru
		_refresh_item_display()
		_refresh_all_button_prices()
	else:
		# Not enough money atau max level
		gems_animation_player.play("now_enough_coins")
		gems_animation_player.seek(0)

func _get_upgrade_id_from_name(p_item_name: String) -> String:
	# Mapping nama item ke upgrade_id di GameData
	match p_item_name.to_lower():
		"hp", "health":
			return "hp"
		"attack damage", "attack", "damage":
			return "attack_damage"
		"defense", "defence", "armor":
			return "defense"
		"dash":
			return "dash"
		"money multiplier", "money":
			return "money_multiplier"
		"knockback":
			return "knockback"
		"arrow":
			return "arrow"
		"tower hp", "town hp":
			return "tower_hp"
		"electro attack", "electro", "electric", "town electric":
			return "town_electric"
		_:
			return p_item_name.to_lower().replace(" ", "_")

func _get_target_for_upgrade(upgrade_id: String) -> String:
	if GameData.player_upgrades.has(upgrade_id):
		return "player"
	if GameData.town_upgrades.has(upgrade_id) or upgrade_id == "tower_hp":
		return "town"
	return current_target

func _refresh_item_display() -> void:
	for button in shop_item_container.get_children():
		if not button_upgrade_map.has(button):
			continue
			
		var upgrade_id = button_upgrade_map[button]
		var item_name = button_name_map.get(button, upgrade_id)
		var target = _get_target_for_upgrade(upgrade_id)
		var dict = GameData.player_upgrades if target == "player" else GameData.town_upgrades
		
		if upgrade_id == "tower_hp":
			var tower_info = GameData.get_upgrade_info(target, upgrade_id)
			if button.has_node("Label"):
				button.get_node("Label").text = _get_tower_hp_label(item_name, tower_info)
			continue
		
		if dict.has(upgrade_id):
			var level = dict[upgrade_id]["level"]
			
			# Update label untuk menunjukkan level tanpa batas maksimum.
			if button.has_node("Label"):
				button.get_node("Label").text = item_name + "  Lv." + str(level)

func _refresh_all_button_prices() -> void:
	# Refresh harga pada semua button saat uang berubah atau setelah pembelian
	for button in shop_item_container.get_children():
		if not button_upgrade_map.has(button):
			continue
			
		var upgrade_id = button_upgrade_map[button]
		var target = _get_target_for_upgrade(upgrade_id)
		var current_price = GameData.get_upgrade_price(target, upgrade_id)
		
		if button.has_node("PriceLabel"):
			button.get_node("PriceLabel").text = str(current_price)

func _get_tower_hp_label(p_item_name: String, info: Dictionary) -> String:
	return "%s %d" % [p_item_name, info.get("current_hp", 0)]

func _get_item_status_text(upgrade_id: String, target: String) -> String:
	match upgrade_id:
		"hp":
			return str(GameData.get_player_max_hp())
		"attack_damage":
			return str(GameData.get_player_attack_damage())
		"defense":
			return str(GameData.get_player_defense())
		"dash":
			return "%.1fs\n%d" % [GameData.get_dash_cooldown(), int(GameData.get_dash_speed())]
		"money_multiplier":
			return "x%d" % int(GameData.get_money_multiplier())
		"knockback":
			return str(int(GameData.get_knockback_force()))
		"arrow":
			if not GameData.is_arrow_unlocked():
				return "Locked"
			return "%d | %d" % [GameData.get_arrow_damage(), GameData.get_arrow_projectile_count()]
		"town_electric":
			if not GameData.is_electro_unlocked():
				return "Locked"
			return str(GameData.get_electro_damage())
		"tower_hp":
			var info = GameData.get_upgrade_info(target, upgrade_id)
			return "%d" % info.get("current_hp", 0)
		_:
			return ""
