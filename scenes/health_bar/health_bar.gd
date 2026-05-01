extends TextureProgressBar

@export var player: CharacterBody2D
@export var town: Node

func _ready(): 
	if player != null and player.has_signal("healthChanged"):
		player.healthChanged.connect(update)
	if town != null and town.has_signal("town_damaged"):
		town.town_damaged.connect(_on_town_health_changed)
	update()

func update(): 
	if player != null and player.has_method("take_damage") and player.name != "Town":
		value = player.currentHealth * 100 / player.maxHealth
	elif town != null:
		value = (town.current_hp * 100) / town.maxHealth

func _on_town_health_changed(current_hp: int, max_hp: int):
	if max_hp > 0:
		value = (current_hp * 100) / max_hp
