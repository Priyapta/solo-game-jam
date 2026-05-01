extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var animation_player = $AnimationPlayer

func _ready():
	color_rect.modulate.a = 0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func fade_out() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	await tween.tween_property(color_rect, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).finished

func fade_in() -> void:
	var tween = create_tween()
	await tween.tween_property(color_rect, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
