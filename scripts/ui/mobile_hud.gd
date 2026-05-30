extends CanvasLayer

const UI_FONT := preload("res://assets/fonts/Gothikka.ttf")

@onready var player         = get_parent()
@onready var leveling       = get_parent().get_node("LevelManager")
@onready var weapon_manager = get_parent().get_node("WeaponManager")

@onready var gold_label:       Label       = %MobileGoldLabel
@onready var kills_label:      Label       = %MobileKillsLabel
@onready var exp_progress_bar: ProgressBar = %MobileExpBar
@onready var time_label:       Label       = %MobileTimeLabel
@onready var level_label:      Label       = %MobileLevelLabel

@onready var weapon_slots: Array[Panel] = [
	%MobileWeaponSlot0, %MobileWeaponSlot1, %MobileWeaponSlot2, %MobileWeaponSlot3
]
@onready var weapon_labels: Array[Label] = [
	%MobileWeaponSlotLabel0, %MobileWeaponSlotLabel1, 
	%MobileWeaponSlotLabel2, %MobileWeaponSlotLabel3
]
@onready var item_slots: Array[Panel] = [
	%MobileItemSlot0, %MobileItemSlot1, %MobileItemSlot2,
	%MobileItemSlot3, %MobileItemSlot4, %MobileItemSlot5
]
@onready var item_labels: Array[Label] = [
	%MobileItemSlotLabel0, %MobileItemSlotLabel1, %MobileItemSlotLabel2,
	%MobileItemSlotLabel3, %MobileItemSlotLabel4, %MobileItemSlotLabel5
]

func _ready():
	if not OS.has_feature("mobile"):
		hide()
		return
	get_parent().get_node("PlayerHud").hide()
	
	player.exp_gained.connect(_on_player_exp_gained)
	leveling.upgrade_applied.connect(_on_upgrade_applied)
	weapon_manager.weapon_added.connect(_on_weapon_added)
	weapon_manager.item_added.connect(_on_item_added)
	weapon_manager.weapon_upgraded.connect(_on_weapon_upgraded)
	_refresh_exp_bar()

func _process(_delta):
	var minutes := int(GameTimer.seconds()) / 60
	var secs    := int(GameTimer.seconds()) % 60
	time_label.text = "%d:%02d" % [minutes, secs]

func add_kill():
	GameData.add_kill()
	kills_label.text = str(GameData.current_kills)

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	_on_player_gold_gained(amount)

func _on_player_gold_gained(amount: int):
	_show_gold_number(amount)
	GameData.add_gold(amount)
	gold_label.text = str(GameData.current_gold)
	
func _on_weapon_added(weapon_data: WeaponData):
	var index = weapon_manager.active_weapons.size() - 1
	update_weapon_slot(index, weapon_data.icon)
	_refresh_weapon_label(index, weapon_data, 0)

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

func _on_upgrade_applied(_upgrade: Dictionary):
	_refresh_exp_bar()
	_refresh_all_item_labels()
	_refresh_all_weapon_labels()

func _refresh_all_item_labels() -> void:
	for i in weapon_manager.active_items.size():
		var item_data: ItemData = weapon_manager.active_items[i]
		var level: int = leveling.item_levels.get(item_data, 0)
		_refresh_item_label(i, item_data, level)

func _on_weapon_upgraded(weapon_data: WeaponData, new_level: int):
	var index := _get_weapon_index(weapon_data)
	if index >= 0:
		_refresh_weapon_label(index, weapon_data, new_level)

func _refresh_weapon_label(index: int, weapon_data: WeaponData, level: int) -> void:
	if index >= weapon_labels.size():
		return
	var label := weapon_labels[index]
	if not is_instance_valid(label):
		return
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	label.text = _to_roman(level + 1)
	if level >= weapon_data.upgrades.size():
		label.add_theme_color_override("font_color", Color("#f5cf1d"))
	else:
		label.remove_theme_color_override("font_color")

func _get_weapon_index(weapon_data: WeaponData) -> int:
	for i in weapon_manager.active_weapons.size():
		if weapon_manager.active_weapons[i].data == weapon_data:
			return i
	return -1

func _refresh_all_weapon_labels() -> void:
	for i in weapon_manager.active_weapons.size():
		var w: BaseWeapon = weapon_manager.active_weapons[i]
		_refresh_weapon_label(i, w.data, w.current_level)

func _refresh_exp_bar():
	var needed: int = leveling._required_blood(leveling.player_level + 1)
	exp_progress_bar.max_value = needed
	exp_progress_bar.value = min(leveling.blood_exp, needed)
	level_label.text = "LVL " + str(leveling.player_level)

func _to_roman(n: int) -> String:
	var romans := ["I", "II", "III", "IV", "V"]
	return romans[clampi(n - 1, 0, romans.size() - 1)]

func _on_pause_button_pressed() -> void:
	var event = InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)

func _show_gold_number(amount: int) -> void:
	if amount <= 0:
		return
	var label := Label.new()
	label.text = "+%d" % amount
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.4, 0.25, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 35

	var parent := gold_label.get_parent().get_parent()
	parent.add_child(label)
	parent.move_child(label, 0)

	var gold_rect := gold_label.get_rect()
	label.position = gold_rect.get_center() + Vector2(0, -gold_rect.size.y)

	var tween := label.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "position", label.position + Vector2(-50, -18), 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	if is_instance_valid(label):
		label.queue_free()
