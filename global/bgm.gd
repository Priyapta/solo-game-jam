extends AudioStreamPlayer

var normal_bgm = preload("res://assets/audio/alexander-nakarada-superepic(chosic.com).mp3")
var boss_bgm = preload("res://assets/audio/BoxCat-Games-Battle-Boss(chosic.com).mp3")

func _ready() -> void:

	play_normal()

func play_normal() -> void:
	if stream != normal_bgm:
		stream = normal_bgm
		play()

func play_boss() -> void:
	if stream != boss_bgm:
		stream = boss_bgm
		play()

# Fungsi ini otomatis terpanggil setiap kali lagu habis
func _on_finished() -> void:
	play()
