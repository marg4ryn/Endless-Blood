extends Control

@export var heroes: Array[HeroData] = []

@onready var start_button: Button= %StartButton
@onready var health_label: Label = %HealthLabel
@onready var speed_label: Label = %SpeedLabel
@onready var luck_label: Label = %LuckLabel
@onready var name_label: Label = %NameLabel
@onready var hero_icon: TextureRect = %HeroIcon
@onready var back_button: Button = %BackButton

func _ready() -> void:
	ButtonManager.setup_buttons([start_button, back_button])
	_load_hero(0)
	start_button.grab_focus()
	
func _load_hero(index: int) -> void:
	var h = heroes[index]
	name_label.text = h.hero_name
	health_label.text = "HEALTH: %d" % SaveManager.get_stat(index, "max_health", h.max_health)
	speed_label.text = "SPEED: %d" % SaveManager.get_stat(index, "speed", h.speed)
	luck_label.text = "LUCK: %d" % SaveManager.get_stat(index, "luck", h.luck)
	hero_icon.texture = h.icon

func _on_start_button_1_pressed() -> void:
	SaveManager.selected_hero = heroes[0]
	SaveManager.selected_hero_index = 0
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
