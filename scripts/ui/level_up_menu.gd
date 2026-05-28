extends CanvasLayer

var _current_choices: Array[Dictionary] = []

@onready var leveling = get_parent().get_node("LevelManager")
@onready var audioPlayer = get_parent().get_node("LevelUpAudioPlayer")
@onready var pass_button: Button = %PassButton
@onready var level_up_panel: PanelContainer = %LevelUpPanel
@onready var level_title: Label = %LevelTitle
@onready var level_up_buttons: Array[Button] = [
	%ChoiceButton1, %ChoiceButton2, %ChoiceButton3
]
@onready var name_labels: Array[Label] = [
	%NameLabel1, %NameLabel2, %NameLabel3
]
@onready var new_labels: Array[Label] = [
	%NewLabel1, %NewLabel2, %NewLabel3
]
@onready var stats_labels: Array[Label] = [
	%StatsLabel1, %StatsLabel2, %StatsLabel3
]
@onready var icons: Array[TextureRect] = [
	%Icon1, %Icon2, %Icon3
]

func _ready():
	leveling.level_up_ready.connect(_on_level_up_ready)
	pass_button.pressed.connect(_on_pass_pressed)
	ButtonManager.setup_buttons(level_up_buttons)
	ButtonManager.setup_buttons([pass_button])
	for i in range(level_up_buttons.size()):
		level_up_buttons[i].pressed.connect(_on_choice_pressed.bind(i))
	level_up_panel.visible = false

func _on_level_up_ready(choices: Array[Dictionary]):
	audioPlayer.play()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_current_choices = choices
	level_title.text = "LEVEL %d → %d" % [leveling.player_level, leveling.player_level + 1]

	if choices.is_empty():
		level_up_panel.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		get_tree().paused = false
		return

	for i in range(level_up_buttons.size()):
		var has_choice := i < choices.size()
		level_up_buttons[i].visible = has_choice
		name_labels[i].visible     = has_choice
		new_labels[i].visible      = has_choice
		stats_labels[i].visible    = has_choice
		icons[i].visible           = has_choice

		if not has_choice:
			continue

		var u: Dictionary = choices[i]
		var is_new: bool  = u.get("is_new", false)

		name_labels[i].text = "%s %s" % [u["name"], _to_roman(u["level"])]
		new_labels[i].text  = "NEW" if is_new else ""
		new_labels[i].visible = is_new
		stats_labels[i].text = _format_bonus(u["bonus_preview"])
		icons[i].texture     = u["icon"]

	level_up_panel.visible = true
	get_tree().paused = true
	if not OS.has_feature("mobile"):
		level_up_buttons[0].grab_focus()

func _on_choice_pressed(index: int):
	level_up_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	leveling.on_upgrade_chosen(index, _current_choices)

func _on_pass_pressed():
	level_up_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	leveling.on_upgrade_chosen(-1, _current_choices)

func _format_bonus(bonus: ItemLevelData) -> String:
	var parts: Array[String] = []

	if bonus.xp_gain > 0:
		parts.append("XP Gain +%d" % bonus.xp_gain)
	if bonus.gold_gain > 0:
		parts.append("Gold Gain +%d" % bonus.gold_gain)
	if bonus.pickup_range > 0:
		parts.append("Pickup Range +%d" % bonus.pickup_range)
	if bonus.effect_duration > 0:
		parts.append("Effect Duration +%d" % bonus.effect_duration)
	if bonus.luck > 0:
		parts.append("Luck +%d" % bonus.luck)
	if bonus.attack_size > 0:
		parts.append("Attack Size +%d" % bonus.attack_size)
	if bonus.shield > 0:
		parts.append("Shield +%d" % bonus.shield)
	if bonus.move_speed > 0:
		parts.append("Movement Speed +%d" % bonus.move_speed)
	if bonus.max_hp > 0:
		parts.append("Max HP +%d" % bonus.max_hp)
	if bonus.hp_regen > 0:
		parts.append("HP Regen +%d" % bonus.hp_regen)
	if bonus.attack_speed > 0:
		parts.append("Attack Speed +%d" % bonus.attack_speed)
	if bonus.projectile_count > 0:
		parts.append("Projectile Count +%d" % bonus.projectile_count)
	if bonus.holy_damage > 0:
		parts.append("Holy Damage +%d" % bonus.holy_damage)
	if bonus.fire_damage > 0:
		parts.append("Fire Damage +%d" % bonus.fire_damage)
	if bonus.physical_damage > 0:
		parts.append("Physical Damage +%d" % bonus.physical_damage)
	return "\n".join(parts)

func _to_roman(n: int) -> String:
	var romans := ["I", "II", "III", "IV", "V"]
	return romans[clampi(n - 1, 0, romans.size() - 1)]
