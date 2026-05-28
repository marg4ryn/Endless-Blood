extends Node

var hover_sound = preload("res://assets/sounds/button_hover.mp3")
var audio: AudioStreamPlayer

func _ready() -> void:
	audio = AudioStreamPlayer.new()
	audio.stream = hover_sound
	add_child(audio)

func setup_buttons(buttons: Array[Button]) -> void:
	for btn in buttons:
		btn.mouse_entered.connect(_on_hover)
		btn.focus_entered.connect(_on_hover)
		if OS.has_feature("mobile"):
			btn.focus_mode = Control.FOCUS_NONE
	
	_setup_vertical_navigation(buttons)

func _setup_vertical_navigation(buttons: Array[Button]) -> void:
	for i in buttons.size():
		var btn = buttons[i]
		if i > 0:
			btn.focus_neighbor_top = buttons[i - 1].get_path()
		if i < buttons.size() - 1:
			btn.focus_neighbor_bottom = buttons[i + 1].get_path()

func _on_hover() -> void:
	audio.play()
