extends CanvasLayer

const UI_FONT := preload("res://assets/fonts/Gothikka.ttf")

var kills: int = 0
var gold: int = 0

@onready var player          = get_parent()
@onready var leveling        = get_parent().get_node("LevelManager")
@onready var weapon_manager  = get_parent().get_node("WeaponManager")

@onready var gold_label:       Label       = %GoldLabel
@onready var kills_label:      Label       = %KillsLabel
@onready var exp_progress_bar: ProgressBar = %ExpBar
@onready var time_label:       Label       = %TimeLabel
@onready var level_label:      Label = %LevelLabel

@onready var weapon_slots: Array[Panel] = [
	%WeaponSlot0, %WeaponSlot1, %WeaponSlot2, %WeaponSlot3
]
@onready var item_slots: Array[Panel] = [
	%ItemSlot0, %ItemSlot1, %ItemSlot2,
	%ItemSlot3, %ItemSlot4, %ItemSlot5
]
@onready var item_labels: Array[Label] = [
	%ItemSlotLabel0, %ItemSlotLabel1, %ItemSlotLabel2, 
	%ItemSlotLabel3, %ItemSlotLabel4, %ItemSlotLabel5
]

func _ready():
	player.exp_gained.connect(_on_player_exp_gained)
	leveling.upgrade_applied.connect(_on_upgrade_applied)
	weapon_manager.weapon_added.connect(_on_weapon_added)
	weapon_manager.item_added.connect(_on_item_added)
	_refresh_exp_bar()

func _process(_delta):
	var minutes := int(GameTimer.seconds()) / 60
	var secs    := int(GameTimer.seconds()) % 60
	time_label.text = "%d:%02d" % [minutes, secs]

func add_kill():
	kills += 1
	kills_label.text = str(kills)
	SaveManager.current_kills = kills

func _on_weapon_added(weapon_data: WeaponData):
	var index = weapon_manager.active_weapons.size() - 1
	update_weapon_slot(index, weapon_data.icon)

func update_weapon_slot(index: int, icon: Texture2D) -> void:
	if index >= weapon_slots.size():
		return
	var tex := TextureRect.new()
	tex.texture = icon
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	weapon_slots[index].add_child(tex)

func _on_item_added(item_data: ItemData):
	var index = weapon_manager.active_items.size() - 1
	update_item_slot(index, item_data.icon)
	var level: int = leveling.item_levels.get(item_data, 1)
	_refresh_item_label(index, item_data, level)

func update_item_slot(index: int, icon: Texture2D) -> void:
	if index >= item_slots.size():
		return
	for child in item_slots[index].get_children():
		if child is TextureRect:
			child.queue_free()
	var tex := TextureRect.new()
	tex.texture = icon
	tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_slots[index].add_child(tex)
	item_slots[index].move_child(tex, 0)

func _refresh_item_label(index: int, item_data: ItemData, level: int) -> void:
	if index >= item_labels.size():
		return
	var label := item_labels[index]
	if not is_instance_valid(label):
		return
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))

	label.text = _to_roman(level)
	if level >= item_data.max_level:
		label.add_theme_color_override("font_color", Color("#f5cf1d"))
	else:
		label.remove_theme_color_override("font_color")
		
func _on_player_exp_gained(_amount: int):
	_refresh_exp_bar()

func _on_player_gold_gained(_amount: int):
	gold += _amount
	gold_label.text = str(gold)
	SaveManager.current_gold = gold

func _on_upgrade_applied(_upgrade: Dictionary):
	_refresh_exp_bar()
	_refresh_all_item_labels()

func _refresh_all_item_labels() -> void:
	for i in weapon_manager.active_items.size():
		var item_data: ItemData = weapon_manager.active_items[i]
		var level: int = leveling.item_levels.get(item_data, 0)
		_refresh_item_label(i, item_data, level)

func _refresh_exp_bar():
	var needed: int = leveling._required_blood(leveling.player_level + 1)
	exp_progress_bar.max_value = needed
	exp_progress_bar.value = min(leveling.blood_exp, needed)
	level_label.text = "LVL " + str(leveling.player_level)

func _to_roman(n: int) -> String:
	var romans := ["I", "II", "III", "IV", "V"]
	return romans[clampi(n - 1, 0, romans.size() - 1)]
