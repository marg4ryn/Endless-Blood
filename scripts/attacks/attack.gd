class_name Attack
extends Resource

var damage_physical: int = 0
var damage_fire: int = 0
var damage_holy: int = 0
var knockback: float = 0.0
var source_position: Vector2 = Vector2.ZERO

func total_damage() -> int:
	return damage_physical + damage_fire + damage_holy
