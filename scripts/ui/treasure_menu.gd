class_name TreasureMenu
extends CanvasLayer

@onready var submit_button: Button = %SubmitButton
@onready var gold_label: Label = %TreasureGoldLabel
@onready var gif: TextureRect = %ChestAnimation
@onready var coin: TextureRect = %CoinTexture
@onready var panel: PanelContainer = %TreasurePanel
@onready var audio: AudioStreamPlayer = %TreasureAudioPlayer

const CHEST_SHEET: Texture2D = preload("res://assets/chests/Treasures_Spritesheet.png")
const FRAME_SIZE := Vector2i(48, 41)
const FIRST_ROW_FRAME_COUNT := 20
const SECOND_ROW_FRAME_COUNT := 19
const FRAME_DURATION := 0.069

var _frames: Array[Texture2D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_frames = _build_frames()
	gif.texture = _frames[0]
	_reset_ui()

func play_opening(gold: int) -> void:
	panel.visible = true
	_reset_ui()
	get_tree().paused = true
	audio.play()
	await _run_animation()
	_show_reward(gold)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	submit_button.modulate.a = 1.0
	submit_button.disabled = false
	submit_button.grab_focus()

func _reset_ui() -> void:
	submit_button.modulate.a = 0.0
	submit_button.disabled = true
	gold_label.visible = false
	coin.visible = false

func _run_animation() -> void:
	for frame in _frames:
		if not is_instance_valid(gif):
			return
		gif.texture = frame
		await get_tree().create_timer(FRAME_DURATION, true).timeout

func _show_reward(gold: int) -> void:
	coin.visible = true
	gold_label.visible = true
	gold_label.text = "+ %d" % gold

func _build_frames() -> Array[Texture2D]:
	var frames: Array[Texture2D] = []

	for i in range(FIRST_ROW_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = CHEST_SHEET
		atlas.region = Rect2(
			i * FRAME_SIZE.x,
			0,
			FRAME_SIZE.x,
			FRAME_SIZE.y
		)
		frames.append(atlas)

	for i in range(SECOND_ROW_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = CHEST_SHEET
		atlas.region = Rect2(
			i * FRAME_SIZE.x,
			FRAME_SIZE.y,
			FRAME_SIZE.x,
			FRAME_SIZE.y
		)
		frames.append(atlas)
	return frames

func _on_submit_button_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_tree().paused = false
	panel.visible = false
