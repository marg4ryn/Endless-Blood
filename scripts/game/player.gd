extends CharacterBody2D

signal exp_gained(amount: int)

const DAMAGE_FONT: FontFile = preload("res://assets/fonts/Gothikka.ttf")

@onready var save_manager := SaveManager
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera := $Camera2D
@onready var health_bar: TextureProgressBar = $TextureProgressBar
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var audio = $AudioStreamPlayer
@onready var timer: Timer = $HealTimer
@onready var player_hud := $PlayerHud
@onready var mobile_hud := $MobileHud
@onready var hud := player_hud

@export var die_sound: AudioStream
@export var hurt_sounds: Array[AudioStream]

var facing_direction := Vector2.DOWN
var facing_direction_x := 1
var is_dead := false
var is_attacking := false
var health := 0

var base_max_health: int = 20
var base_speed: int = 200
var base_luck: int = 0
var base_hp_regen: int = 1
var base_gold_gain: int = 3

var bonus_max_hp: int = 0
var bonus_luck: int = 0
var bonus_hp_regen: int = 0
var bonus_gold_gain: int = 0
var bonus_pickup_range: int = 0
var bonus_attack_size: int = 0
var bonus_shield: int = 0
var bonus_move_speed: int = 0
var bonus_attack_speed: int = 0
var bonus_holy_damage: int = 0
var bonus_fire_damage: int = 0
var bonus_physical_damage: int = 0

var _frame_offsets: Dictionary = {}

var max_health: int: 
	get: return base_max_health + bonus_max_hp
var speed: int:
	get: return base_speed + bonus_move_speed
var luck: int:
	get: return base_luck + bonus_luck
var hp_regen: int:
	get: return base_hp_regen + bonus_hp_regen
var gold_gain: int:
	get: return base_gold_gain + bonus_gold_gain

func _ready():
	camera.make_current()
	
	if OS.has_feature("mobile"):
		hud = mobile_hud
	
	var h = SaveManager.selected_hero
	var i = SaveManager.selected_hero_index
	base_max_health = SaveManager.get_stat(i, "max_health", h.max_health)
	base_speed      = SaveManager.get_stat(i, "speed", h.speed)
	base_luck       = SaveManager.get_stat(i, "luck", h.luck)
	sprite.sprite_frames = h.sprite_frames
	sprite.centered = true
	_compute_frame_offsets()
	sprite.connect("frame_changed", Callable(self, "_on_sprite_frame_changed"))
	_on_sprite_frame_changed()
	
	health = max_health
	health_bar.value = health
	health_bar.max_value = max_health
	
	var whip_data = load("res://data/weapons/whip_data.tres")
	weapon_manager.add_or_upgrade_weapon(whip_data)
	GameTimer.start()
	
func _physics_process(_delta):
	if is_dead:
		return
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		get_parent().handle_tutorial_direction(direction)
		facing_direction = direction.normalized()
		calculate_facing_direction_x()
	velocity = Vector2.ZERO if is_attacking else direction * speed
	move_and_slide()
	update_animation(direction if not is_attacking else Vector2.ZERO)

func calculate_facing_direction_x():
	if facing_direction.x != 0:
		if facing_direction.x < 0:
			facing_direction_x = -1
		if facing_direction.x > 0:
			facing_direction_x = 1

func update_animation(direction: Vector2):
	var target_animation := &"idle"

	if is_attacking or direction == Vector2.ZERO:
		target_animation = &"idle"
	elif abs(direction.x) > abs(direction.y):
		target_animation = &"walk_right" if direction.x > 0 else &"walk_left"
	else:
		target_animation = &"walk_down" if direction.y > 0 else &"walk_up"

	if sprite.animation != target_animation:
		sprite.play(target_animation)
		_on_sprite_frame_changed()

func _compute_frame_offsets() -> void:
	_frame_offsets.clear()
	var frames_res := sprite.sprite_frames
	if frames_res == null:
		return
	for anim in frames_res.get_animation_names():
		var count := frames_res.get_frame_count(anim)
		_frame_offsets[anim] = []
		for i in range(count):
			var tex := frames_res.get_frame_texture(anim, i)
			var offset_vec := Vector2.ZERO
			if tex is AtlasTexture:
				var atlas: Texture2D = tex.atlas
				var region: Rect2 = tex.region
				if atlas is Texture2D and region.size.x > 0 and region.size.y > 0:
					var img: Image = null
					if atlas.has_method("get_data"):
						img = atlas.get_data()
					elif atlas.has_method("get_image"):
						img = atlas.get_image()
					elif atlas.has_method("decompress_to_image"):
						img = atlas.decompress_to_image()
					if img == null:
						_frame_offsets[anim].append(offset_vec)
						continue
					if img.has_method("lock"):
						img.lock()
					var rx: int = int(region.position.x)
					var ry: int = int(region.position.y)
					var rw: int = int(region.size.x)
					var rh: int = int(region.size.y)
					var img_w: int = img.get_width()
					var img_h: int = img.get_height()
					var start_x: int = clamp(rx, 0, img_w)
					var start_y: int = clamp(ry, 0, img_h)
					var end_x: int = clamp(rx + rw, 0, img_w)
					var end_y: int = clamp(ry + rh, 0, img_h)
					if start_x >= end_x or start_y >= end_y:
						_frame_offsets[anim].append(offset_vec)
						img.unlock()
						continue
					var minx: int = end_x
					var miny: int = end_y
					var maxx: int = start_x
					var maxy: int = start_y
					for x in range(start_x, end_x):
						for y in range(start_y, end_y):
							var c: Color = img.get_pixel(x, y)
							if c.a > 0.01:
								if x < minx:
									minx = x
								if y < miny:
									miny = y
								if x > maxx:
									maxx = x
								if y > maxy:
									maxy = y
					if img.has_method("unlock"):
						img.unlock()
					if maxx >= minx:
						var center: Vector2 = Vector2((minx + maxx) * 0.5, (miny + maxy) * 0.5)
						var local_center: Vector2 = center - region.position
						var ref: Vector2 = region.size * 0.5
						offset_vec = ref - local_center
			_frame_offsets[anim].append(offset_vec)

func _on_sprite_frame_changed() -> void:
	var anim := sprite.animation
	var idx := sprite.frame
	if _frame_offsets.has(anim):
		var arr: Array = _frame_offsets[anim]
		if idx >= 0 and idx < arr.size():
			sprite.offset = arr[idx]
			return
	sprite.offset = Vector2.ZERO

func take_damage(attack: Attack):
	if is_dead:
		return
	var damage: int = max(attack.total_damage() - bonus_shield, 0)
	if damage > 0:
		health -= damage
		health_bar.value = health
		_show_damage_number(damage)
		flash_red()
		if health <= 0:
			die()
		else:
			audio.stream = hurt_sounds.pick_random()
			audio.play()

func flash_red():
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1) 

func die():
	GameTimer.stop()
	audio.stream = die_sound
	audio.play()
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	weapon_manager.disable_all()
	sprite.play("die")
	await sprite.animation_finished
	get_tree().change_scene_to_file("res://scenes/ui/death_screen.tscn")

func add_kill():
	hud.add_kill()

func gain_xp(amount: int):
	if is_dead or amount <= 0:
		return
	exp_gained.emit(amount)

func gain_gold():
	var amount = base_gold_gain + bonus_gold_gain
	if is_dead or amount <= 0:
		return
	hud._on_player_gold_gained(amount)

func apply_bonus(bonus: ItemLevelData) -> void:
	bonus_gold_gain        += bonus.gold_gain
	bonus_pickup_range     += bonus.pickup_range
	bonus_luck             += bonus.luck
	bonus_attack_size      += bonus.attack_size
	bonus_shield           += bonus.shield
	bonus_move_speed       += bonus.move_speed
	bonus_max_hp           += bonus.max_hp
	bonus_hp_regen         += bonus.hp_regen
	bonus_attack_speed     += bonus.attack_speed
	bonus_holy_damage      += bonus.holy_damage
	bonus_fire_damage      += bonus.fire_damage
	bonus_physical_damage  += bonus.physical_damage
	health_bar.max_value = max_health
	health = min(health + bonus.max_hp, max_health)

	health_bar.max_value = max_health
	health = min(health + bonus_max_hp, max_health)

func _on_heal_timer_timeout() -> void:
	health = min(max_health, health + hp_regen)
	health_bar.value = health

func _show_damage_number(amount: int) -> void:
	if amount <= 0:
		return
	var label := Label.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DAMAGE_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.32, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	label.top_level = true
	label.z_index = 35
	label.global_position = global_position + Vector2(randf_range(-12.0, 12.0), -18.0)
	get_tree().current_scene.add_child(label)

	var tween := label.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -42), 0.55)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	if is_instance_valid(label):
		label.queue_free()
