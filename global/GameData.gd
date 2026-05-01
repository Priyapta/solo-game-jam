extends Node

signal stats_updated
signal uang_changed(new_amount: int)
signal town_healed(heal_amount: int) 

var town_heal_price_flat: int = 10  
var town_current_hp: int = 1000
var town_max_hp: int = 1000
var uang: int = 10:
	set(value):
		uang = value
		uang_changed.emit(uang)

# 1. DATA PLAYER
var player_upgrades: Dictionary = {
	"hp": {"level": 1, "base_price": 5},
	"attack_damage": {"level": 1, "base_price": 5},
	"defense": {"level": 1, "base_price": 5},
	"dash": {"level": 1, "base_price": 5},
	"money_multiplier": {"level": 1, "base_price": 10},
	"knockback": {"level": 1, "base_price": 5},
	
	# Skill Khusus Player
	"arrow": {"level": 0, "is_unlocked": false, "base_price": 20, "unlock_price": 20}
}

# 2. DATA TOWN
var town_upgrades: Dictionary = {
	"town_electric": {"level": 0, "is_unlocked": false, "base_price": 20, "unlock_price": 20}
}

var enemy_stats: Dictionary = {
	"base_hp": 50,
	"base_attack": 10,
	"base_knockback_resist": 0
}

func get_enemy_attack_damage() -> int:
	return enemy_stats["base_attack"]



func get_upgrade_price(target: String, upgrade_id: String) -> int:
	if upgrade_id == "tower_hp":
	
		if get_town_missing_hp() > 0:
			return town_heal_price_flat
		return 0
	
	var dict = player_upgrades if target == "player" else town_upgrades
	if not dict.has(upgrade_id):
		push_warning("Upgrade '%s' tidak ditemukan untuk target '%s'" % [upgrade_id, target])
		return 0
	var data = dict[upgrade_id]
	
	# Jika belum di-unlock, return harga unlock
	if data.has("is_unlocked") and not data["is_unlocked"]:
		return data.get("unlock_price", data["base_price"])
	
	var level = data["level"]
	var base = data["base_price"]
	return int(base * pow(1.5, level - 1))

func get_upgrade_info(target: String, upgrade_id: String) -> Dictionary:
	if upgrade_id == "tower_hp":
		var current_hp = get_current_town_hp()
		var max_hp = get_town_max_hp()
		var missing_hp = max(max_hp - current_hp, 0)
		var heal_price = town_heal_price_flat if missing_hp > 0 else 0
		return {
			"current_level": current_hp,
			"max_level": -1,
			"is_unlocked": true,
			"current_price": heal_price,
			"can_upgrade": missing_hp > 0 and uang >= heal_price,
			"current_hp": current_hp,
			"max_hp": max_hp,
			"missing_hp": missing_hp
		}
		
	var dict = player_upgrades if target == "player" else town_upgrades
	if not dict.has(upgrade_id):
		push_warning("Upgrade '%s' tidak ditemukan untuk target '%s'" % [upgrade_id, target])
		return {
			"current_level": 0,
			"max_level": 0,
			"is_unlocked": false,
			"current_price": 0,
			"can_upgrade": false
		}
	var data = dict[upgrade_id]
		
	return {
		"current_level": data["level"],
		"max_level": data.get("max_level", -1),
		"is_unlocked": data.get("is_unlocked", true),
		"current_price": get_upgrade_price(target, upgrade_id),
		"can_upgrade": uang >= get_upgrade_price(target, upgrade_id)
	}


func can_afford_repair() -> bool:
	var repair_cost = get_upgrade_price("town", "tower_hp")
	return repair_cost > 0 and uang >= repair_cost

func repair_town_action():
	var missing_hp = get_town_missing_hp()
	var repair_cost = town_heal_price_flat
	if missing_hp <= 0:
		return false
	if uang >= repair_cost:
		uang -= repair_cost
		town_healed.emit(missing_hp)
		return true
	return false

func get_current_town_hp() -> int:
	return get_saved_town_hp()

func get_town_missing_hp() -> int:
	return max(get_town_max_hp() - get_current_town_hp(), 0)


# PLAYER STATS
func get_player_max_hp() -> int:
	var level = player_upgrades["hp"]["level"]
	return 100 + (level - 1) * 20

func get_player_attack_damage() -> int:
	var level = player_upgrades["attack_damage"]["level"]
	return 10 + (level - 1) * 5 

func get_player_defense() -> int:
	var level = player_upgrades["defense"]["level"]
	return 5 + (level - 1) * 3   # Base 5, +3 per level

func get_dash_cooldown() -> float:
	var level = player_upgrades["dash"]["level"]
	return 0.8 - (level - 1) * 0.1  

func get_dash_speed() -> float:
	var level = player_upgrades["dash"]["level"]
	return 1000.0 + (level - 1) * 100.0 

func get_money_multiplier() -> float:
	var level = player_upgrades["money_multiplier"]["level"]
	return float(level)  # Level 1 = x1, Level 2 = x2, Level 3 = x3

func get_knockback_force() -> float:
	var level = player_upgrades["knockback"]["level"]
	return 200.0 + (level - 1) * 50.0  

func is_arrow_unlocked() -> bool:
	return player_upgrades["arrow"]["is_unlocked"]

func get_arrow_damage() -> int:
	if not is_arrow_unlocked():
		return 0
	var level = player_upgrades["arrow"]["level"]
	return 15 + (level - 1) * 10  

func get_arrow_projectile_count() -> int:
	if not is_arrow_unlocked():
		return 0
	var level = player_upgrades["arrow"]["level"]
	return max(level, 1)


# TOWN STATS
func get_town_max_hp() -> int:
	return town_max_hp

func set_town_max_hp(value: int) -> void:
	town_max_hp = max(value, 1)
	town_current_hp = min(town_current_hp, town_max_hp)

func get_saved_town_hp() -> int:
	return clamp(town_current_hp, 0, town_max_hp)

func set_saved_town_hp(value: int) -> void:
	town_current_hp = clamp(value, 0, town_max_hp)

func is_electro_unlocked() -> bool:
	return town_upgrades["town_electric"]["is_unlocked"]

func get_electro_damage() -> int:
	if not is_electro_unlocked():
		return 0
	var level = town_upgrades["town_electric"]["level"]
	return 30 + (level - 1) * 15


# PEMBELIAN UPGRADE
func beli_upgrade(target: String, upgrade_id: String) -> bool:
	if upgrade_id == "tower_hp":
		return repair_town_action()
		
	var dict = player_upgrades if target == "player" else town_upgrades
	if not dict.has(upgrade_id):
		push_warning("Upgrade '%s' tidak ditemukan untuk target '%s'" % [upgrade_id, target])
		return false
	var data = dict[upgrade_id]
	
	var harga = get_upgrade_price(target, upgrade_id)
	
	if uang < harga:
		return false
		

	uang -= harga
	

	if data.has("is_unlocked") and not data["is_unlocked"]:
		data["is_unlocked"] = true
		data["level"] = 1
	else:
		
		data["level"] += 1
		
	stats_updated.emit()
	return true


# RESET (PERMADEATH)
func reset_all_data() -> void:
	
	uang = 10
	town_max_hp = 1000
	town_current_hp = town_max_hp
	
	# Reset player upgrades
	player_upgrades = {
		"hp": {"level": 1, "base_price": 5},
		"attack_damage": {"level": 1, "base_price": 5},
		"defense": {"level": 1, "base_price": 5},
		"dash": {"level": 1, "base_price": 5},
		"money_multiplier": {"level": 1, "base_price": 10},
		"knockback": {"level": 1, "base_price": 5},
		"arrow": {"level": 0, "is_unlocked": false, "base_price": 20, "unlock_price": 20}
	}
	
	# Reset town upgrades
	town_upgrades = {
		"town_electric": {"level": 0, "is_unlocked": false, "base_price": 20, "unlock_price": 20}
	}
	
	stats_updated.emit()


## SAVE / LOAD 
#func save_data() -> void:KLA
	#var save_dict = {
		#"uang": uang,
		#"player_upgrades": player_upgrades,
		#"town_upgrades": town_upgrades
	#}
	#
#
#func load_data() -> void:
#
	#pass
