extends Area2D

@export var target: Node

func take_damage(damage: int, from_position: Vector2, attacker: Node = null):
	if owner and owner.has_method("take_damage"):
		owner.take_damage(damage, from_position, attacker)
