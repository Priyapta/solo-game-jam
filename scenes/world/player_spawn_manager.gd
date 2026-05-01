extends Node

# Script untuk menangani spawn player di door yang tepat
# Pasang di scene world sebagai autoload atau node

func _ready():
	# Tunggu 1 frame agar scene selesai load
	await get_tree().create_timer(0.1).timeout
	
	# Safety check: pastikan NavigationManager ada
	if not NavigationManager:
		return
	
	# Cek apakah ada spawn door tag dari NavigationManager
	if NavigationManager.spawn_door_tag != null and NavigationManager.spawn_door_tag != "":
		_spawn_player_at_door(NavigationManager.spawn_door_tag)
		# Reset tag setelah digunakan
		NavigationManager.spawn_door_tag = ""

func _spawn_player_at_door(door_tag: String):
	# Cari door dengan tag yang sesuai
	var doors = get_tree().get_nodes_in_group("door")
	
	for door in doors:
		if door.name == door_tag or door.get_meta("door_tag", "") == door_tag:
			# Cari player
			var player = get_tree().get_first_node_in_group("player")
			if player:
				# Spawn player di posisi spawn door
				if door.has_node("Spawn"):
					player.global_position = door.get_node("Spawn").global_position
				else:
					player.global_position = door.global_position
				if player.has_method("set_respawn_point"):
					player.set_respawn_point(player.global_position)
			return
