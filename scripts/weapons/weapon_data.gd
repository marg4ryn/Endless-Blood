class_name WeaponData
extends Resource

@export var name: String = ""
@export var base_knockback: int = 0
@export var base_damage_physical: int = 0
@export var base_damage_fire: int = 0
@export var base_damage_holy: int = 0
@export var base_cooldown: float = 1.0
@export var base_size: float = 1.0
@export var icon: Texture2D
@export var weapon_scene: PackedScene
@export var upgrades: Array[WeaponUpgradeData] = []
