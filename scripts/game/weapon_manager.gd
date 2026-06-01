class_name WeaponManager
extends Node

signal weapon_added(weapon_data: WeaponData)
signal weapon_upgraded(weapon_data: WeaponData, new_level: int)
signal item_added(item_data: ItemData)
signal item_upgraded(item_data: ItemData)

const MAX_WEAPONS = 4
const MAX_ITEMS = 6

var active_weapons: Array[BaseWeapon] = []
var active_items: Array[ItemData] = []

@onready var player: Node2D = get_parent()

func add_or_upgrade_weapon(weapon_data: WeaponData) -> bool:
	for w in active_weapons:
		if w.data == weapon_data:
			var ok = w.upgrade()
			if ok:
				weapon_upgraded.emit(weapon_data, w.current_level)
			return ok

	if active_weapons.size() >= MAX_WEAPONS:
		return false

	var weapon_node = weapon_data.weapon_scene.instantiate() as BaseWeapon
	add_child(weapon_node)
	weapon_node.setup(weapon_data, player)
	active_weapons.append(weapon_node)
	weapon_added.emit(weapon_data)
	return true

func add_item(item_data: ItemData) -> bool:
	if active_items.has(item_data):
		item_upgraded.emit(item_data)
		return false
	if active_items.size() >= MAX_ITEMS:
		return false
	active_items.append(item_data)
	item_added.emit(item_data)
	return true

func disable_all() -> void:
	for w in active_weapons:
		w.timer.stop()

func clear_all() -> void:
	for w in active_weapons:
		w.queue_free()
	active_weapons.clear()
	active_items.clear()
