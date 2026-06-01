class_name BaseWeapon
extends Node2D

var data: WeaponData
var player: Node2D
var stats: WeaponStats
var current_level: int = 0
var enemies_group := "enemies"

@onready var timer: Timer = $Timer

func setup(weapon_data: WeaponData, player_node: Node2D) -> void:
	data = weapon_data
	player = player_node
	_rebuild_stats()
	get_parent().item_added.connect(_on_item_added_or_upgraded)
	get_parent().item_upgraded.connect(_on_item_added_or_upgraded)
	update_timer()
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func upgrade() -> bool:
	if current_level >= data.upgrades.size():
		return false
	current_level += 1
	_rebuild_stats()
	update_timer()
	return true

func _rebuild_stats() -> void:
	stats = WeaponStats.build(data, current_level)

func _on_timer_timeout() -> void:
	_do_attack()

func _do_attack() -> void:
	pass

func make_attack() -> Attack:
	var a := Attack.new()
	a.knockback = stats.knockback 
	a.damage_physical = stats.damage_physical + player.bonus_physical_damage if stats.damage_physical > 0 else 0
	a.damage_fire = stats.damage_fire + player.bonus_fire_damage if stats.damage_fire > 0 else 0
	a.damage_holy = stats.damage_holy + player.bonus_holy_damage if stats.damage_holy > 0 else 0
	return a

func update_timer():
	timer.wait_time = stats.cooldown - ( player.bonus_attack_speed / 100.0)

func _on_item_added_or_upgraded(_item_data) -> void:
	update_timer()

func get_enemies_sorted_by_distance() -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	for e in get_tree().get_nodes_in_group(enemies_group):
		if is_instance_valid(e) and e.has_method("take_damage") and e.visible:
			enemies.append(e as Node2D)
	return enemies
