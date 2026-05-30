class_name WeaponStats
extends RefCounted

var knockback: int
var damage_physical: int
var damage_fire: int
var damage_holy: int
var cooldown: float
var projectile_count: int
var size: float

static func build(data: WeaponData, level: int) -> WeaponStats:
	var s := WeaponStats.new()
	s.knockback = data.base_knockback
	s.damage_physical = data.base_damage_physical
	s.damage_fire = data.base_damage_fire
	s.damage_holy = data.base_damage_holy
	s.cooldown = data.base_cooldown
	s.size = data.base_size

	for i in min(level, data.upgrades.size()):
		var u: WeaponUpgradeData = data.upgrades[i]
		s.damage_physical += u.damage_physical
		s.damage_fire += u.damage_fire
		s.damage_holy += u.damage_holy
		s.cooldown *= u.cooldown_multiplier
		s.size += u.size_bonus

	return s
