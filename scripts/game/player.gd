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

var collected_bonuses: Array[ItemLevelData] = []

var bonus_max_hp: int = 0
var bonus_speed: int = 0
var bonus_luck: int = 0
var bonus_hp_regen: int = 0
var bonus_xp_gain: int = 0
var bonus_gold_gain: int = 0
var bonus_pickup_range: int = 0
var bonus_effect_duration: int = 0
var bonus_attack_size: int = 0
var bonus_shield: int = 0
var bonus_move_speed: int = 0
var bonus_attack_speed: int = 0
var bonus_projectile_count: int = 0
var bonus_holy_damage: int = 0
var bonus_fire_damage: int = 0
var bonus_physical_damage: int = 0

var max_health: int: 
	get: return base_max_health + bonus_max_hp
var speed: int:
	get: return base_speed + bonus_speed
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
	if is_attacking or direction == Vector2.ZERO:
		sprite.play("idle")
		return
	if abs(direction.x) > abs(direction.y):
		sprite.play("walk_right" if direction.x > 0 else "walk_left")
	else:
		sprite.play("walk_down" if direction.y > 0 else "walk_up")

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
	collected_bonuses = collected_bonuses.filter(func(b): return b.item_id != bonus.item_id)
	collected_bonuses.append(bonus)
	_recalculate_bonuses()

func _recalculate_bonuses() -> void:
	bonus_xp_gain          = 0
	bonus_gold_gain        = 0
	bonus_pickup_range     = 0
	bonus_effect_duration  = 0
	bonus_luck             = 0
	bonus_attack_size      = 0
	bonus_shield           = 0
	bonus_move_speed       = 0
	bonus_max_hp           = 0
	bonus_hp_regen         = 0
	bonus_attack_speed     = 0
	bonus_projectile_count = 0
	bonus_holy_damage      = 0
	bonus_fire_damage      = 0
	bonus_physical_damage  = 0

	for b in collected_bonuses:
		bonus_xp_gain          += b.xp_gain
		bonus_gold_gain        += b.gold_gain
		bonus_pickup_range     += b.pickup_range
		bonus_effect_duration  += b.effect_duration
		bonus_luck             += b.luck
		bonus_attack_size      += b.attack_size
		bonus_shield           += b.shield
		bonus_move_speed       += b.move_speed
		bonus_max_hp           += b.max_hp
		bonus_hp_regen         += b.hp_regen
		bonus_attack_speed     += b.attack_speed
		bonus_projectile_count += b.projectile_count
		bonus_holy_damage      += b.holy_damage
		bonus_fire_damage      += b.fire_damage
		bonus_physical_damage  += b.physical_damage

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
