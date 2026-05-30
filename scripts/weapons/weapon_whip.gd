class_name WeaponWhip
extends BaseWeapon

@export var slash_scene: PackedScene

func _do_attack() -> void:
	var dir = player.facing_direction_x
	var reach := 30.0
	var slash = slash_scene.instantiate()
	var attack = make_attack()
	attack.source_position = player.global_position
	slash.attack = attack
	slash.global_position = player.global_position + Vector2(dir, 0) * reach
	slash.scale = Vector2.ONE * stats.size
	slash.rotation = 0.0 if dir > 0 else PI
	get_tree().current_scene.add_child(slash)
