class_name ShopItemButton extends Button

var item: UpgradeData
var upgrade_id: String = ""
# Called when the node enters the scene tree for the first time.

func setup_item(_item: UpgradeData, level: int = 1, _max_level: int = 1) -> void: 
	item = _item
	$Label.text = item.name + "  Lv." + str(level)
	$PriceLabel.text = str(item.cost)
	$TextureRect.texture = item.texture
