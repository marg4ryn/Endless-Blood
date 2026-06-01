class_name WeaponGarlic
extends BaseWeapon

@onready var aura = $Aura

func setup(data: WeaponData, player_node: Node2D) -> void:
	super(data, player_node)
	aura.position.y = 20.0
	aura.set_radius(_get_radius())

func upgrade() -> bool:
	var ok = super.upgrade()
	if ok:
		aura.set_radius(_get_radius())
	return ok

func _do_attack() -> void:
	var radius = _get_radius()
	var center = player.global_position + Vector2(0, 20)
	for enemy in get_enemies_sorted_by_distance():
		if enemy.global_position.distance_to(center) <= radius:
			enemy.take_damage(make_attack())

func _get_radius() -> float:
	return 80.0 * (stats.size + (player.bonus_attack_size / 100.0))

func _on_item_added_or_upgraded(_item_data) -> void:
	super._on_item_added_or_upgraded(_item_data)
	aura.set_radius(_get_radius())
