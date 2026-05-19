extends "res://scripts/enemies/base_enemy.gd"

const RAT_TEXTURES := [
	preload("res://assets/enemies/rat_dark_grey.png"),
	preload("res://assets/enemies/rat_light_grey.png"),
	preload("res://assets/enemies/rat_white.png"),
]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	xp_gem_table = [
		[XpGem.Type.NONE,   20],
		[XpGem.Type.SMALL,  80],
		[XpGem.Type.MEDIUM, 0],
		[XpGem.Type.LARGE,  0],
	]
	speed       = 130.0
	max_health  = 12
	damage      = 4
	blood_scale = 0.4
	super()

func _setup_visuals() -> void:
	var tex: Texture2D = RAT_TEXTURES[randi() % RAT_TEXTURES.size()]
	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 10.0)
	var fw := int(tex.get_width() / 4)
	var fh := tex.get_height()
	for i in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame("walk", atlas)
	sprite.sprite_frames = frames
	sprite.play("walk")

func _update_animation(dir: Vector2) -> void:
	sprite.flip_h = dir.x < 0
	if sprite.animation != &"walk":
		sprite.play("walk")
