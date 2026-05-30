extends Node2D

const PAUSE_SCENE := preload("res://scenes/ui/pause_screen.tscn")
const TUTORIAL_PANEL_COLOR := Color(0.12, 0.02, 0.03, 0.96)
const TUTORIAL_ACCENT_COLOR := Color(0.86, 0.14, 0.14, 1.0)
const TUTORIAL_TEXT_COLOR := Color(1.0, 0.95, 0.95, 1.0)
const TUTORIAL_MUTED_COLOR := Color(0.9, 0.7, 0.7, 1.0)

const TUTORIAL_STEPS := [
	{"title": "Krok 1", "body": "Przytrzymaj [←] albo [A], żeby ruszyć w lewo.", "action": &"move_left", "icon": "←"},
	{"title": "Krok 2", "body": "Przytrzymaj [→] albo [D], żeby ruszyć w prawo.", "action": &"move_right", "icon": "→"},
	{"title": "Krok 3", "body": "Przytrzymaj [↑] albo [W], żeby iść w górę.", "action": &"move_up", "icon": "↑"},
	{"title": "Krok 4", "body": "Przytrzymaj [↓] albo [S], żeby zejść niżej.", "action": &"move_down", "icon": "↓"},
]

const TRACKS = [
	preload("res://assets/music/Before Concession.mp3"),
	preload("res://assets/music/Unholy Invocation.mp3")
]

var _tutorial_layer: CanvasLayer
var _tutorial_root: Control
var _tutorial_banner: PanelContainer
var _tutorial_content: Control
var _tutorial_title: Label
var _tutorial_body: Label
var _tutorial_step_label: Label
var _tutorial_progress_label: Label
var _tutorial_step_index: int = -1
var _tutorial_active: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	MusicPlayer.set_volume(0.1)
	MusicPlayer.play_music(TRACKS.pick_random())
	if not SaveManager.tutorial_seen:
		_start_first_run_tutorial()

func _unhandled_input(event: InputEvent) -> void:
	if _tutorial_active and _handle_tutorial_input(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
			get_tree().paused = true
			var pause := PAUSE_SCENE.instantiate()
			get_tree().root.add_child(pause)

func _on_gold_timer_timeout() -> void:
	$Player.gain_gold()


func _start_first_run_tutorial() -> void:
	_tutorial_active = true
	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 50
	add_child(_tutorial_layer)

	_tutorial_root = Control.new()
	_tutorial_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_layer.add_child(_tutorial_root)

	_tutorial_banner = PanelContainer.new()
	_tutorial_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_tutorial_banner.offset_left = 0
	_tutorial_banner.offset_top = 18
	_tutorial_banner.offset_right = 0
	_tutorial_banner.offset_bottom = 156
	_tutorial_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_root.add_child(_tutorial_banner)

	var style := StyleBoxFlat.new()
	style.bg_color = TUTORIAL_PANEL_COLOR
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = TUTORIAL_ACCENT_COLOR
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	_tutorial_banner.add_theme_stylebox_override("panel", style)

	_tutorial_content = Control.new()
	_tutorial_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_banner.add_child(_tutorial_content)

	_tutorial_step_label = Label.new()
	_tutorial_step_label.anchor_left = 0.0
	_tutorial_step_label.anchor_top = 0.0
	_tutorial_step_label.anchor_right = 1.0
	_tutorial_step_label.anchor_bottom = 0.0
	_tutorial_step_label.offset_left = 0
	_tutorial_step_label.offset_top = 6
	_tutorial_step_label.offset_right = 0
	_tutorial_step_label.offset_bottom = 24
	_tutorial_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_step_label.add_theme_font_size_override("font_size", 16)
	_tutorial_step_label.add_theme_color_override("font_color", TUTORIAL_ACCENT_COLOR)
	_tutorial_content.add_child(_tutorial_step_label)

	_tutorial_title = Label.new()
	_tutorial_title.anchor_left = 0.0
	_tutorial_title.anchor_top = 0.0
	_tutorial_title.anchor_right = 1.0
	_tutorial_title.anchor_bottom = 0.0
	_tutorial_title.offset_left = 0
	_tutorial_title.offset_top = 28
	_tutorial_title.offset_right = 0
	_tutorial_title.offset_bottom = 58
	_tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_title.add_theme_font_size_override("font_size", 26)
	_tutorial_title.add_theme_color_override("font_color", TUTORIAL_TEXT_COLOR)
	_tutorial_content.add_child(_tutorial_title)

	_tutorial_body = Label.new()
	_tutorial_body.anchor_left = 0.0
	_tutorial_body.anchor_top = 0.0
	_tutorial_body.anchor_right = 1.0
	_tutorial_body.anchor_bottom = 0.0
	_tutorial_body.offset_left = 32
	_tutorial_body.offset_top = 66
	_tutorial_body.offset_right = -32
	_tutorial_body.offset_bottom = 108
	_tutorial_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_body.add_theme_font_size_override("font_size", 20)
	_tutorial_body.add_theme_color_override("font_color", TUTORIAL_TEXT_COLOR)
	_tutorial_content.add_child(_tutorial_body)

	_tutorial_progress_label = Label.new()
	_tutorial_progress_label.anchor_left = 0.0
	_tutorial_progress_label.anchor_top = 0.0
	_tutorial_progress_label.anchor_right = 1.0
	_tutorial_progress_label.anchor_bottom = 0.0
	_tutorial_progress_label.offset_left = 24
	_tutorial_progress_label.offset_top = 112
	_tutorial_progress_label.offset_right = -24
	_tutorial_progress_label.offset_bottom = 138
	_tutorial_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_progress_label.add_theme_font_size_override("font_size", 14)
	_tutorial_progress_label.add_theme_color_override("font_color", TUTORIAL_MUTED_COLOR)
	_tutorial_content.add_child(_tutorial_progress_label)

	_tutorial_banner.modulate.a = 1.0
	_tutorial_banner.scale = Vector2.ONE

	_set_tutorial_step(0)


func _set_tutorial_step(step_index: int) -> void:
	_tutorial_step_index = step_index
	if _tutorial_step_index < 0 or _tutorial_step_index >= TUTORIAL_STEPS.size():
		_complete_first_run_tutorial()
		return
	var step: Dictionary = TUTORIAL_STEPS[_tutorial_step_index]
	_tutorial_step_label.text = "KROK %d/%d" % [_tutorial_step_index + 1, TUTORIAL_STEPS.size()]
	_tutorial_title.text = step.get("title", "")
	_tutorial_body.text = step.get("body", "")
	_tutorial_progress_label.text = "Wykonaj ruch, aby przejść dalej"


func _handle_tutorial_input(event: InputEvent) -> bool:
	if _tutorial_step_index < 0 or _tutorial_step_index >= TUTORIAL_STEPS.size():
		return false
	var expected_action: StringName = TUTORIAL_STEPS[_tutorial_step_index].get("action", &"")
	if expected_action != &"" and event.is_action_pressed(expected_action):
		_set_tutorial_step(_tutorial_step_index + 1)
		return true
	return false


func _complete_first_run_tutorial() -> void:
	SaveManager.mark_tutorial_seen()
	if _tutorial_banner == null:
		return
	_tutorial_progress_label.text = "Gotowe. Powodzenia."
	_tutorial_body.text = "Możesz już ruszać dalej."
	_tutorial_layer.queue_free()
	_tutorial_active = false
