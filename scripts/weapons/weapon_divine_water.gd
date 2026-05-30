class_name WeaponGarlic
extends BaseWeapon

@onready var aura = $Aura

func setup(data: WeaponData, player_node: Node2D) -> void:
	super(data, player_node)
	aura.position.y = 20.0
	aura.set_radius(80.0 * stats.size)
	
func upgrade() -> bool:
	var ok = super.upgrade()
	if ok:
		aura.set_radius(80.0 * stats.size)
	return ok
	
func _do_attack() -> void:
	var radius = 80.0 * stats.size
	var center = player.global_position + Vector2(0, 20)
	for enemy in get_enemies_sorted_by_distance():
		if enemy.global_position.distance_to(center) <= radius:
			enemy.take_damage(make_attack())
