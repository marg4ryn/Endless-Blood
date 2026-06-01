extends Control

var heroes: Array[HeroData] = []
var _selected_index: int = 0

@onready var select_gwen_button: Button = %SelectGwenButton
@onready var select_blood_hunter_button: Button = %SelectBloodHunterButton
@onready var play_button: Button = %PlayButton
@onready var back_button: Button = %BackButton

@onready var gwen_panel: Panel = %GwenPanel
@onready var blood_hunter_panel: Panel = %BloodHunterPanel
@onready var gwen_name_label: Label = %GwenNameLabel
@onready var blood_hunter_name_label: Label = %BloodHunterNameLabel
@onready var gwen_icon: TextureRect = %GwenIcon
@onready var blood_hunter_icon: TextureRect = %BloodHunterIcon

func _ready() -> void:
	heroes = SaveManager.all_heroes
	ButtonManager.setup_buttons([select_blood_hunter_button, select_gwen_button, play_button, back_button])
	_selected_index = 0
	_update_cards()
	play_button.grab_focus()
	
func _index_for_hero_name(hero_name: String) -> int:
	for i in range(heroes.size()):
		if heroes[i].hero_name == hero_name:
			return i
	return -1

func _apply_selection(index: int) -> void:
	if heroes.is_empty():
		return
	_selected_index = clampi(index, 0, heroes.size() - 1)
	SaveManager.selected_hero = heroes[_selected_index]
	SaveManager.selected_hero_index = _selected_index
	_update_cards()

func _update_cards() -> void:
	if heroes.is_empty():
		return

	for i in range(heroes.size()):
		var h: HeroData = heroes[i]
		if h.hero_name == "Gwen":
			gwen_name_label.text = h.hero_name
			gwen_icon.texture = h.icon
		elif h.hero_name == "Gehrman":
			blood_hunter_name_label.text = h.hero_name
			blood_hunter_icon.texture = h.icon

	var gwen_index := _index_for_hero_name("Gwen")
	var blood_index := _index_for_hero_name("Gehrman")
	var gwen_selected := _selected_index == gwen_index and gwen_index != -1
	var blood_selected := _selected_index == blood_index and blood_index != -1

	gwen_panel.modulate = Color(1, 1, 1, 1) if gwen_selected else Color(0.78, 0.78, 0.78, 1)
	blood_hunter_panel.modulate = Color(1, 1, 1, 1) if blood_selected else Color(0.78, 0.78, 0.78, 1)
	select_gwen_button.text = "Selected" if gwen_selected else "Select"
	select_blood_hunter_button.text = "Selected" if blood_selected else "Select"

func _on_play_button_pressed() -> void:
	if heroes.is_empty():
		return
	SaveManager.selected_hero = heroes[_selected_index]
	SaveManager.selected_hero_index = _selected_index
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_select_gwen_pressed() -> void:
	var index := _index_for_hero_name("Gwen")
	if index != -1:
		_apply_selection(index)

func _on_select_blood_hunter_pressed() -> void:
	var index := _index_for_hero_name("Gehrman")
	if index != -1:
		_apply_selection(index)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
