extends Control

@onready var blood_icon: TextureRect = %HeroIcon
@onready var blood_name_label: Label = %NameLabel
@onready var blood_gold_label: Label = %GoldLabel
@onready var blood_cost_label: Label = %CostLabel
@onready var blood_health_label: Label = %HealthLabel
@onready var blood_speed_label: Label = %SpeedLabel
@onready var blood_luck_label: Label = %LuckLabel
@onready var blood_health_button: Button = %HealthButton
@onready var blood_speed_button: Button = %SpeedButton
@onready var blood_luck_button: Button = %LuckButton
@onready var blood_health_segments: Container = %HealthSegments
@onready var blood_speed_segments: Container = %SpeedSegments
@onready var blood_luck_segments: Container = %LuckSegments

@onready var gwen_icon: TextureRect = %GwenHeroIcon
@onready var gwen_name_label: Label = %GwenNameLabel
@onready var gwen_cost_label: Label = %GwenCostLabel
@onready var gwen_health_label: Label = %GwenHealthLabel
@onready var gwen_speed_label: Label = %GwenSpeedLabel
@onready var gwen_luck_label: Label = %GwenLuckLabel
@onready var gwen_health_button: Button = %GwenHealthButton
@onready var gwen_speed_button: Button = %GwenSpeedButton
@onready var gwen_luck_button: Button = %GwenLuckButton
@onready var gwen_health_segments: Container = %GwenHealthSegments
@onready var gwen_speed_segments: Container = %GwenSpeedSegments
@onready var gwen_luck_segments: Container = %GwenLuckSegments

@onready var back_button: Button = %BackButton
@onready var audio_purchase = $AudioPlayerPurchase
@onready var audio_buzz = $AudioPlayerBuzz

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveManager.gold_changed.connect(_update_ui)
	SaveManager.stats_changed.connect(_update_ui)
	ButtonManager.setup_buttons([blood_health_button, blood_speed_button, blood_luck_button, gwen_health_button, gwen_speed_button, gwen_luck_button, back_button])
	back_button.grab_focus()
	_update_ui()

func _index_for_hero_name(hero_name: String) -> int:
	for i in range(SaveManager.all_heroes.size()):
		if SaveManager.all_heroes[i].hero_name == hero_name:
			return i
	return -1

func _update_ui() -> void:
	_update_hero_panel("Gehrman", blood_icon, blood_name_label, blood_gold_label, blood_cost_label, blood_health_label, blood_speed_label, blood_luck_label, blood_health_button, blood_speed_button, blood_luck_button, blood_health_segments, blood_speed_segments, blood_luck_segments)
	_update_hero_panel("Gwen", gwen_icon, gwen_name_label, null, gwen_cost_label, gwen_health_label, gwen_speed_label, gwen_luck_label, gwen_health_button, gwen_speed_button, gwen_luck_button, gwen_health_segments, gwen_speed_segments, gwen_luck_segments)

func _update_hero_panel(hero_name: String, icon: TextureRect, name_label: Label, gold_label: Label, cost_label: Label, health_label: Label, speed_label: Label, luck_label: Label, health_button: Button, speed_button: Button, luck_button: Button, health_segments: Container, speed_segments: Container, luck_segments: Container) -> void:
	var index := _index_for_hero_name(hero_name)
	if index == -1:
		return
	var hero: HeroData = SaveManager.all_heroes[index]
	icon.texture = hero.icon
	name_label.text = hero.hero_name
	if gold_label != null:
		gold_label.text = str(SaveManager.gold)
	cost_label.text = "COST: %d" % SaveManager.upgrade_cost
	health_label.text = "HEALTH: %d" % SaveManager.get_stat(index, "max_health", hero.max_health)
	speed_label.text = "SPEED: %d" % SaveManager.get_stat(index, "speed", hero.speed)
	luck_label.text = "LUCK: %d" % SaveManager.get_stat(index, "luck", hero.luck)
	if SaveManager.get_level(index, "max_health") >= 10:
		health_button.text = "MAX"
	if SaveManager.get_level(index, "speed") >= 10:
		speed_button.text = "MAX"
	if SaveManager.get_level(index, "luck") >= 10:
		luck_button.text = "MAX"
	draw_segments(health_segments, SaveManager.get_level(index, "max_health"), Color(0.639, 0.278, 0.278))
	draw_segments(speed_segments, SaveManager.get_level(index, "speed"), Color(0.290, 0.498, 0.710))
	draw_segments(luck_segments, SaveManager.get_level(index, "luck"), Color(0.247, 0.643, 0.416))

func draw_segments(container: HBoxContainer, level: int, active_color: Color) -> void:
	for child in container.get_children():
		child.queue_free()
	for i in 10:
		var segment = Panel.new()
		segment.custom_minimum_size = Vector2(8, 8)
		var style = StyleBoxFlat.new()
		style.bg_color = active_color if i < level else Color(0.2, 0.2, 0.2)
		style.corner_radius_top_left = 2
		style.corner_radius_top_right = 2
		style.corner_radius_bottom_left = 2
		style.corner_radius_bottom_right = 2
		segment.add_theme_stylebox_override("panel", style)
		container.add_child(segment)

func _can_upgrade(index: int, stat: String) -> bool:
	if index < 0 or index >= SaveManager.all_heroes.size():
		return false
	return SaveManager.gold >= SaveManager.upgrade_cost and SaveManager.get_level(index, stat) < 10

func _on_upgrade_health() -> void:
	_upgrade_hero("Gehrman", "max_health")

func _on_upgrade_speed() -> void:
	_upgrade_hero("Gehrman", "speed")

func _on_upgrade_luck() -> void:
	_upgrade_hero("Gehrman", "luck")

func _on_gwen_upgrade_health() -> void:
	_upgrade_hero("Gwen", "max_health")

func _on_gwen_upgrade_speed() -> void:
	_upgrade_hero("Gwen", "speed")

func _on_gwen_upgrade_luck() -> void:
	_upgrade_hero("Gwen", "luck")

func _upgrade_hero(hero_name: String, stat: String) -> void:
	var index := _index_for_hero_name(hero_name)
	if index == -1:
		audio_buzz.play()
		return
	if _can_upgrade(index, stat):
		audio_purchase.play()
		SaveManager.upgrade_hero_stat(index, stat)
		_update_ui()
	else:
		audio_buzz.play()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
