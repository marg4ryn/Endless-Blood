class_name TreasureChest
extends Area2D

const CHEST_SHEET: Texture2D = preload("res://assets/chests/15_Ready_to_use_Treasure_Chests_Spritesheet.png")
const CLOSED_REGION := Rect2(0, 0, 48, 40)
const OPEN_FRAME_SIZE := Vector2i(48, 40)
const OPEN_FRAME_COUNT := 21
const WORLD_SCALE_FACTORS: Array[float] = [1.45, 1.7, 2.0]
const GOLD_REWARDS: Array[int] = [20, 45, 90]
const GOLD_VARIANCE: Array[int] = [10, 15, 25]
const XP_CHANCES: Array[float] = [0.15, 0.4, 0.75]

var _tier: int = 0
var _player: Node2D = null
var _opened: bool = false

var _sprite: Sprite2D
var _collision_shape: CollisionShape2D
var _blink_tween: Tween

var _popup_overlay: CanvasLayer
var _popup_panel: PanelContainer
var _popup_title: Label
var _popup_status: Label
var _popup_gold_label: Label
var _popup_xp_label: Label
var _popup_gif: TextureRect
var _popup_frames: Array[Texture2D] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 8
	monitoring = true
	monitorable = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 1
	body_entered.connect(_on_body_entered)
	_build_visuals()
	_start_blink()

func configure(tier: int, player: Node2D) -> void:
	_tier = clampi(tier, 0, 2)
	_player = player
	if is_node_ready():
		_apply_visual_scaling()

func _build_visuals() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.z_index = 1
	_sprite.texture = _build_closed_texture()
	add_child(_sprite)

	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34.0, 24.0)
	_collision_shape.shape = shape
	_collision_shape.position = Vector2(0.0, 10.0)
	add_child(_collision_shape)

	_apply_visual_scaling()


func _build_closed_texture() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = CHEST_SHEET
	atlas.region = CLOSED_REGION
	return atlas

func _apply_visual_scaling() -> void:
	if _sprite == null:
		return
	var scale_factor: float = WORLD_SCALE_FACTORS[_tier]
	_sprite.scale = Vector2.ONE * scale_factor
	_collision_shape.position = Vector2(0.0, 10.0 * scale_factor)
	var shape := _collision_shape.shape as RectangleShape2D
	if shape != null:
		shape.size = Vector2(34.0, 24.0) * scale_factor

func _start_blink() -> void:
	if _sprite == null:
		return
	if _blink_tween != null:
		_blink_tween.kill()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(_sprite, "modulate:a", 0.72, 0.45)
	_blink_tween.tween_property(_sprite, "modulate:a", 1.0, 0.45)

func _stop_blink() -> void:
	if _blink_tween != null:
		_blink_tween.kill()
		_blink_tween = null
	if _sprite != null:
		_sprite.modulate.a = 1.0

func _on_body_entered(body: Node) -> void:
	if _opened or _player == null or body != _player:
		return
	_opened = true
	get_tree().paused = true
	monitoring = false
	_collision_shape.set_deferred("disabled", true)
	_stop_blink()
	await _play_open_sequence()
	queue_free()

func _play_open_sequence() -> void:
	_build_popup()
	var scene := get_tree().current_scene
	if scene != null:
		scene.add_child(_popup_overlay)
	await _run_popup_animation()
	var reward := _resolve_reward()
	_show_reward(reward)
	await get_tree().create_timer(0.9, true).timeout
	_apply_gold_reward(reward)
	if is_instance_valid(_popup_overlay):
		_popup_overlay.queue_free()
	get_tree().paused = false
	var xp_amount: int = int(reward.get("xp", 0))
	if xp_amount > 0:
		_apply_xp_reward(xp_amount)

func _run_popup_animation() -> void:
	if _popup_gif == null or _popup_frames.is_empty():
		await get_tree().create_timer(1.05, true).timeout
		return

	for frame in _popup_frames:
		if not is_instance_valid(_popup_gif):
			return
		_popup_gif.texture = frame
		await get_tree().create_timer(0.045, true).timeout

	await get_tree().create_timer(0.2, true).timeout

func _resolve_reward() -> Dictionary:
	var reward: Dictionary = {
		"gold": 0,
		"xp": 0,
	}

	var gold_base: int = GOLD_REWARDS[_tier]
	var gold_bonus: int = GOLD_VARIANCE[_tier]
	reward["gold"] = gold_base + randi_range(0, gold_bonus) + _tier * 5

	var xp_chance: float = XP_CHANCES[_tier]
	if randf() < xp_chance and _player != null:
		var level_manager := _player.get_node_or_null("LevelManager")
		if level_manager != null and level_manager.has_method("_required_blood"):
			var next_level: int = int(level_manager.get("player_level")) + 1
			reward["xp"] = int(level_manager.call("_required_blood", next_level))

	return reward

func _apply_gold_reward(reward: Dictionary) -> void:
	var gold_amount: int = int(reward.get("gold", 0))
	if gold_amount > 0 and _player != null:
		var hud := _player.get_node_or_null("PlayerHud")
		if hud != null and hud.has_method("add_gold"):
			hud.call("add_gold", gold_amount)


func _apply_xp_reward(xp_amount: int) -> void:
	if xp_amount <= 0 or _player == null:
		return
	if _player.has_method("gain_xp"):
		_player.call("gain_xp", xp_amount)

func _show_reward(reward: Dictionary) -> void:
	if _popup_status != null:
		_popup_status.text = "Treasure opened"

	var gold_amount: int = int(reward.get("gold", 0))
	var xp_amount: int = int(reward.get("xp", 0))

	if _popup_gold_label != null:
		_popup_gold_label.visible = gold_amount > 0
		_popup_gold_label.text = "+ %d Gold" % gold_amount

	if _popup_xp_label != null:
		_popup_xp_label.visible = xp_amount > 0
		_popup_xp_label.text = "+ %d XP" % xp_amount

func _build_popup() -> void:
	_popup_overlay = CanvasLayer.new()
	_popup_overlay.layer = 100
	_popup_frames = _build_popup_frames()

	_popup_panel = PanelContainer.new()
	_popup_panel.custom_minimum_size = Vector2(720, 560)
	_popup_panel.set_anchors_preset(Control.PRESET_CENTER)
	_popup_panel.position = Vector2(-360, -280)
	_popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_overlay.add_child(_popup_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 16)
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 28
	outer.offset_top = 28
	outer.offset_right = -28
	outer.offset_bottom = -28
	_popup_panel.add_child(outer)

	_popup_title = Label.new()
	_popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_title.text = "TREASURE CHEST"
	_popup_title.add_theme_font_override("font", preload("res://assets/fonts/Gothikka.ttf"))
	_popup_title.add_theme_font_size_override("font_size", 44)
	_popup_title.add_theme_color_override("font_color", Color(0.97, 0.84, 0.22, 1.0))
	outer.add_child(_popup_title)

	_popup_gif = TextureRect.new()
	_popup_gif.texture = _popup_frames[0] if not _popup_frames.is_empty() else _build_closed_texture()
	_popup_gif.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_popup_gif.custom_minimum_size = Vector2(640, 340)
	outer.add_child(_popup_gif)

	_popup_status = Label.new()
	_popup_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_status.text = "Opening..."
	_popup_status.add_theme_font_override("font", preload("res://assets/fonts/Gothikka.ttf"))
	_popup_status.add_theme_font_size_override("font_size", 28)
	_popup_status.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	outer.add_child(_popup_status)

	_popup_gold_label = Label.new()
	_popup_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_gold_label.visible = false
	_popup_gold_label.add_theme_font_override("font", preload("res://assets/fonts/Gothikka.ttf"))
	_popup_gold_label.add_theme_font_size_override("font_size", 34)
	_popup_gold_label.add_theme_color_override("font_color", Color(0.96, 0.81, 0.11, 1.0))
	outer.add_child(_popup_gold_label)

	_popup_xp_label = Label.new()
	_popup_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_xp_label.visible = false
	_popup_xp_label.add_theme_font_override("font", preload("res://assets/fonts/Gothikka.ttf"))
	_popup_xp_label.add_theme_font_size_override("font_size", 30)
	_popup_xp_label.add_theme_color_override("font_color", Color(0.85, 0.16, 0.29, 1.0))
	outer.add_child(_popup_xp_label)

func _build_popup_frames() -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for i in range(OPEN_FRAME_COUNT):
		var atlas := AtlasTexture.new()
		atlas.atlas = CHEST_SHEET
		atlas.region = Rect2(i * OPEN_FRAME_SIZE.x, 0, OPEN_FRAME_SIZE.x, OPEN_FRAME_SIZE.y)
		frames.append(atlas)
	return frames
