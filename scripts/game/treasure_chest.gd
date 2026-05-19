class_name TreasureChest
extends Area2D

const OPEN_SOUND: AudioStream = preload("res://assets/sounds/treasure.mp3")
const CHEST_SHEET: Texture2D = preload("res://assets/chests/Treasures_Spritesheet.png")
const CLOSED_REGION := Rect2(0, 0, 48, 40)
const WORLD_SCALE: float = 1.4
const GOLD_MIN := 40
const GOLD_MAX := 100

var _player: Node2D = null
var _opened := false
var _sprite: Sprite2D
var _collision_shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 8
	monitoring = true
	monitorable = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 1
	body_entered.connect(_on_body_entered)
	_build_visuals()

func configure(player: Node2D) -> void:
	_player = player

func _build_visuals() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = true
	_sprite.z_index = 1
	_sprite.texture = _build_closed_texture()
	_sprite.scale = Vector2.ONE * WORLD_SCALE
	add_child(_sprite)
	_collision_shape = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34.0, 24.0) * WORLD_SCALE
	_collision_shape.shape = shape
	_collision_shape.position = Vector2(0.0, 10.0 * WORLD_SCALE)
	add_child(_collision_shape)

func _build_closed_texture() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = CHEST_SHEET
	atlas.region = CLOSED_REGION
	return atlas

func _on_body_entered(body: Node) -> void:
	if _opened or _player == null or body != _player:
		return
	_opened = true
	monitoring = false
	_collision_shape.set_deferred("disabled", true)
	var gold := randi_range(GOLD_MIN, GOLD_MAX)
	var menu := _player.get_node_or_null("TreasureMenu")
	if menu != null:
		await menu.play_opening(gold)
	_apply_gold_reward(gold)
	queue_free()

func _apply_gold_reward(gold: int) -> void:
	if gold <= 0 or _player == null:
		return
	var hud := _player.get_node_or_null("PlayerHud")
	if hud != null and hud.has_method("add_gold"):
		hud.call("add_gold", gold)
