class_name XpGem
extends Area2D

enum Type { NONE, SMALL, MEDIUM, LARGE }

const CONFIG := {
	Type.SMALL:  { "value": 1,  "color": Color(1.0, 0.0, 0.0), "radius": 5.0,  "label": "small"  },
	Type.MEDIUM: { "value": 5,  "color": Color(1.0, 0.886, 0.11, 1.0), "radius": 5.0,  "label": "medium" },
	Type.LARGE:  { "value": 10, "color": Color(0.96, 0.96, 0.94), "radius": 5.0,  "label": "large"  },
}

@export var gem_type: Type = Type.SMALL
@export var magnet_radius: float = 50.0
@export var magnet_speed: float = 100.0

var _value: int = 1
var _attracted: bool = false

@onready var _player: Node2D = get_tree().get_first_node_in_group("player")
@onready var audio_player := _player.get_node("LevelingAudioPlayer")

# ── lifecycle ───────────────────────────────────────────────────────────────

func _ready() -> void:
	var cfg: Dictionary = CONFIG[gem_type]
	_value = cfg["value"]
	_build_visuals(cfg)

func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var dist := global_position.distance_to(_player.global_position)

	if dist <= magnet_radius + _player.bonus_pickup_range:
		_attracted = true
	else:
		_attracted = false

	if _attracted:
		var dir := global_position.direction_to(_player.global_position)
		var t := 1.0 - clampf(dist / magnet_radius, 0.0, 1.0)
		var speed := lerpf(magnet_speed * 0.6, magnet_speed * 2.2, t)
		global_position += dir * speed * delta

	if dist <= 20.0:
		_collect()

func _collect() -> void:
	if _player.has_method("gain_xp"):
		_player.gain_xp(_value)
	audio_player.play()
	queue_free()

# ── budowanie wizualizacji ──────────────────────────────────────────────────

func _build_visuals(cfg: Dictionary) -> void:
	var r: float = cfg["radius"]
	var color: Color = cfg["color"]

	var ball := _GemBall.new(r, color)
	ball.z_index = 2
	add_child(ball)

	var tween := create_tween().set_loops()
	tween.tween_property(ball, "scale", Vector2(1.18, 1.18), 0.55).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ball, "scale", Vector2(1.0,  1.0),  0.55).set_ease(Tween.EASE_IN_OUT)

# ── wewnętrzna klasa rysująca kulkę ─────────────────────────────────────────

class _GemBall extends Node2D:
	var _r: float
	var _col: Color

	func _init(r: float, col: Color) -> void:
		_r = r
		_col = col

	func _draw() -> void:
		draw_circle(Vector2(1, 2), _r, Color(0, 0, 0, 0.25))
		draw_circle(Vector2.ZERO, _r, _col)
		draw_circle(Vector2(-_r * 0.28, -_r * 0.28), _r * 0.32, Color(1, 1, 1, 0.55))
		
