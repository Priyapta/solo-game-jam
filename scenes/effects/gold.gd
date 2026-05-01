extends Node2D

func _ready() -> void:
	$AnimationPlayer.play("gold")

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Hanya player yang bisa mengambil gold
	if body.is_in_group("player"):
		var gold_value = int(ceil(1 * GameData.get_money_multiplier()))
		GameData.uang += gold_value
		queue_free()
