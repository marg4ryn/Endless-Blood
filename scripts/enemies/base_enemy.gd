class_name BaseEnemy
extends CharacterBody2D

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var collision_shape: CollisionShape2D = $HurtboxArea/Hurtbox
@export var blood_exp_reward := 1

const TREASURE_CHEST_SCRIPT: Script = preload("res://scripts/game/treasure_chest.gd")
const DAMAGE_FONT: FontFile = preload("res://assets/fonts/Gothikka.ttf")
const BLOOD_TEXTURES: Array[Texture2D] = [
	preload("res://assets/blood/blood_1.png"),
	preload("res://assets/blood/blood_2.png"),
	preload("res://assets/blood/blood_3.png"),
	preload("res://assets/blood/blood_4.png"),
	preload("res://assets/blood/blood_5.png")
]

const CHEST_DROP_BASE := 0.001
const CHEST_DROP_PER_LUCK := 0.0005
const CHEST_DROP_MAX := 0.01

var speed := 100.0
var max_health := 100
var health := max_health
var damage := 10
var is_dead := false
var _player_in_range: Node2D = null
var blood_scale := 1.0

var _last_dir := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var knockback_duration := 0.0
var knockback_speed := 300.0

var xp_gem_table: Array = [
	[XpGem.Type.NONE, 40],
	[XpGem.Type.SMALL, 60],
	[XpGem.Type.MEDIUM, 0],
	[XpGem.Type.LARGE, 0],
]

func _ready() -> void:
	add_to_group("enemies") 
	health = max_health
	_setup_visuals()

func _physics_process(_delta: float) -> void:
	if is_dead or player == null:
		return

	if knockback_duration > 0:
		knockback_duration -= _delta
		velocity = knockback_velocity
	else:
		var dir := global_position.direction_to(player.global_position)
		_last_dir = dir
		velocity = dir * speed

	move_and_slide()
	_update_animation(_last_dir)

func _get_enemy_height() -> float:
	for child in get_children():
		if child is CollisionShape2D:
			var shape = child.shape
			if shape is CapsuleShape2D:
				return shape.height
			elif shape is RectangleShape2D:
				return shape.size.y
	return 30.0

func _setup_visuals() -> void:
	pass

func _update_animation(_dir: Vector2) -> void:
	pass

func flash_red() -> void:
	pass

func take_damage(attack: Attack) -> void:
	if is_dead:
		return
	_show_damage_number(attack.total_damage())
	health -= attack.total_damage()
	_spawn_blood_hit()
	flash_red()

	if is_instance_valid(player) && attack.knockback > 0:
		var knockback_dir := (global_position - player.global_position).normalized()
		knockback_velocity = knockback_dir * knockback_speed
		knockback_duration = 0.2

	if health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	if is_instance_valid(player) and player.has_method("gain_blood_exp"):
		player.gain_blood_exp(blood_exp_reward)
	velocity = Vector2.ZERO
	$HurtboxArea.set_deferred("monitoring", false)
	$HurtboxArea.set_deferred("monitorable", false)
	$Collision.set_deferred("disabled", true)
	$DamageTimer.stop()
	player.add_kill()
	_spawn_blood_death()
	_spawn_blood_decal()
	_try_spawn_chest()
	_drop_xp_gems()
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

func attack() -> void:
	if _player_in_range == null or not is_instance_valid(_player_in_range):
		return
	var atk := Attack.new()
	atk.damage_physical = damage
	atk.source_position = global_position
	_player_in_range.get_parent().take_damage(atk)

func _drop_xp_gems() -> void:
	var gem_type := _roll_gem_type()
	if gem_type == XpGem.Type.NONE:
		return
	_spawn_gem(gem_type)

func _roll_gem_type() -> XpGem.Type:
	var total_weight := 0
	for entry in xp_gem_table:
		total_weight += entry[1]

	var roll := randi_range(0, total_weight - 1)
	var cumulative := 0
	for entry in xp_gem_table:
		cumulative += entry[1]
		if roll < cumulative:
			return entry[0]

	return xp_gem_table[0][0]

func _spawn_gem(gem_type: XpGem.Type) -> void:
	var gem := XpGem.new()
	gem.gem_type = gem_type
	gem.global_position = global_position + Vector2(0, _get_enemy_height())
	get_parent().add_child(gem)

func _try_spawn_chest() -> void:
	if not is_instance_valid(player):
		return

	var luck: int = int(player.get("luck"))
	var chance := clampf(
		CHEST_DROP_BASE + float(luck) * CHEST_DROP_PER_LUCK,
		CHEST_DROP_BASE,
		CHEST_DROP_MAX
	)
	if randf() > chance:
		return

	var chest: TreasureChest = TREASURE_CHEST_SCRIPT.new()
	chest.configure(player)
	chest.global_position = global_position + Vector2(0, _get_enemy_height())
	var scene := get_tree().current_scene if is_instance_valid(get_tree().current_scene) else get_parent()
	scene.add_child(chest)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_dead or not area.is_in_group("player"):
		return
	_player_in_range = area
	attack()
	$DamageTimer.start()

func _on_hitbox_area_exited(area: Area2D) -> void:
	if area == _player_in_range:
		_player_in_range = null
		$DamageTimer.stop()

func _on_damage_timer_timeout() -> void:
	if _player_in_range and not is_dead:
		attack()

func _spawn_blood_hit() -> void:
	var p := CPUParticles2D.new()
	p.amount = 20
	p.one_shot = true
	p.lifetime = 0.35
	p.spread = 60.0
	p.direction = player.global_position.direction_to(global_position)
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 180.0
	p.gravity = Vector2(0, 300)
	p.damping_min = 60.0
	p.damping_max = 140.0
	p.scale_amount_min = 1.2 * blood_scale
	p.scale_amount_max = 3.0 * blood_scale
	p.color = Color(0.73, 0.05, 0.08, 0.9)
	p.local_coords = false
	p.z_index = 2
	p.global_position = global_position
	get_parent().add_child(p)
	p.emitting = true
	await get_tree().create_timer(p.lifetime + 0.3).timeout
	if is_instance_valid(p):
		p.queue_free()

func _spawn_blood_death() -> void:
	var p := CPUParticles2D.new()
	p.amount = 50
	p.one_shot = true
	p.lifetime = 0.4
	p.spread = 60.0
	p.direction = Vector2(0, -1)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.gravity = Vector2(0, 700)
	p.damping_min = 40.0
	p.damping_max = 160.0
	p.scale_amount_min = 1.0 * blood_scale
	p.scale_amount_max = 4.0 * blood_scale
	p.color = Color(0.73, 0.05, 0.08, 0.95)
	p.local_coords = false
	p.z_index = 2
	p.global_position = global_position + Vector2(0, -_get_enemy_height() * 0.2)
	get_parent().add_child(p)
	p.emitting = true
	await get_tree().create_timer(p.lifetime + 0.1).timeout
	if is_instance_valid(p):
		p.queue_free()

func _spawn_blood_decal() -> void:
	var decal := Node2D.new()
	decal.global_position = global_position + Vector2(0, _get_enemy_height())
	decal.z_index = 1

	var sprite := Sprite2D.new()
	sprite.centered = true
	sprite.texture = BLOOD_TEXTURES.pick_random()
	sprite.scale = Vector2.ONE * blood_scale

	decal.add_child(sprite)
	get_parent().add_child(decal)

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
