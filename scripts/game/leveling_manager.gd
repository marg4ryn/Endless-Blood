extends Node

signal level_up_ready(choices: Array[Dictionary])
signal upgrade_applied(upgrade: Dictionary)

@export var item_pool: Array[ItemData] = []
@export var weapon_pool: Array[WeaponData] = []

@onready var player = get_parent()
@onready var weapon_manager = player.get_node("WeaponManager")

const MAX_ITEMS := 6
const OWNED_WEIGHT := 3

var blood_exp := 0
var player_level := 1
var item_levels: Dictionary = {}
var _pending_requirement := 0
var _in_progress := false

func _ready():
	player.exp_gained.connect(_on_exp_gained)
	for item in item_pool:
		item_levels[item] = 0

func _on_exp_gained(amount: int):
	blood_exp += amount
	_try_trigger_level_up()

func _try_trigger_level_up():
	if _in_progress or player.is_dead:
		return
	var requirement := _required_blood(player_level + 1)
	if blood_exp < requirement:
		return
	var choices := _roll_choices()
	_pending_requirement = requirement
	_in_progress = true
	if choices.is_empty():
		_finish_level_up({})
	level_up_ready.emit(choices)

func on_upgrade_chosen(choice_index: int, choices: Array[Dictionary]):
	if choice_index >= 0 and choice_index < choices.size():
		var chosen := choices[choice_index]
		_apply_choice(chosen)
		_finish_level_up(chosen)
	else:
		_finish_level_up({})

func _apply_choice(choice: Dictionary):
	match choice.get("type", ""):
		"item":
			_apply_item_choice(choice)
		"weapon_new", "weapon_upgrade":
			_apply_weapon_choice(choice)

func _apply_item_choice(choice: Dictionary):
	var item: ItemData = choice.get("item", null)
	if item == null:
		return
	var current_level: int = item_levels.get(item, 0)
	var next_level := current_level + 1
	item_levels[item] = next_level
	if current_level == 0:
		weapon_manager.add_item(item)
	var bonus: ItemLevelData = item.bonuses[next_level - 1]
	player.apply_bonus(bonus)

func _apply_weapon_choice(choice: Dictionary):
	var weapon_data: WeaponData = choice.get("weapon", null)
	if weapon_data == null:
		return
	weapon_manager.add_or_upgrade_weapon(weapon_data)

func _finish_level_up(choice: Dictionary):
	blood_exp = max(0, blood_exp - _pending_requirement)
	player_level += 1
	_pending_requirement = 0
	_in_progress = false
	upgrade_applied.emit(choice)
	_try_trigger_level_up()

func _roll_choices() -> Array[Dictionary]:
	var all_candidates: Array[Dictionary] = []

	var slots_full_weapons: bool = weapon_manager.active_weapons.size() >= weapon_manager.MAX_WEAPONS
	var slots_used_items := 0
	for item in item_pool:
		if item_levels.get(item, 0) > 0:
			slots_used_items += 1
	var slots_full_items := slots_used_items >= MAX_ITEMS

	for weapon_data in weapon_pool:
		var weapon_node := _get_active_weapon(weapon_data)
		var is_new := weapon_node == null
		if is_new and slots_full_weapons:
			continue
		var current_level := 0 if is_new else weapon_node.current_level
		if not is_new and current_level >= weapon_data.upgrades.size():
			continue
		var weight := 4 if not is_new else 2
		for _i in range(weight):
			all_candidates.append({"kind": "weapon", "weapon_data": weapon_data})

	for item in item_pool:
		var level: int = item_levels.get(item, 0)
		if level >= item.max_level:
			continue
		if level == 0 and slots_full_items:
			continue
		var weight := 2 if level > 0 else 1
		for _i in range(weight):
			all_candidates.append({"kind": "item", "item": item})

	all_candidates.shuffle()

	var seen_weapons: Array[WeaponData] = []
	var seen_items: Array[ItemData] = []
	var result: Array[Dictionary] = []

	for candidate in all_candidates:
		if result.size() >= 3:
			break
		if candidate["kind"] == "weapon":
			var weapon_data: WeaponData = candidate["weapon_data"]
			if weapon_data in seen_weapons:
				continue
			seen_weapons.append(weapon_data)
			var entry := _build_weapon_entry(weapon_data)
			if entry.is_empty():
				continue
			result.append(entry)
		else:
			var item: ItemData = candidate["item"]
			if item in seen_items:
				continue
			seen_items.append(item)
			var entry := _build_item_entry(item)
			if entry.is_empty():
				continue
			result.append(entry)

	if result.size() < 3 and not result.is_empty():
		var original := result.duplicate()
		var i := 0
		while result.size() < 3:
			result.append(original[i % original.size()])
			i += 1

	return result

func _build_weapon_entry(weapon_data: WeaponData) -> Dictionary:
	var weapon_node := _get_active_weapon(weapon_data)
	var is_new := weapon_node == null
	var current_level := 0 if is_new else weapon_node.current_level
	var next_level := current_level + 1
	var display_level := 1 if is_new else current_level + 2

	var upgrade_preview = null
	if not is_new and current_level < weapon_data.upgrades.size():
		upgrade_preview = weapon_data.upgrades[current_level]

	var preview_stats: WeaponStats = WeaponStats.build(weapon_data, next_level)

	return {
		"type": "weapon_new" if is_new else "weapon_upgrade",
		"weapon": weapon_data,
		"name": weapon_data.name,
		"icon": weapon_data.icon,
		"preview_stats": preview_stats,
		"level": display_level,
		"upgrade_preview": upgrade_preview,
		"is_new": is_new,
	}

func _build_item_entry(item: ItemData) -> Dictionary:
	var current_level: int = item_levels.get(item, 0)
	var next_level := current_level + 1
	if item.bonuses.is_empty() or next_level > item.bonuses.size():
		return {}
	return {
		"type": "item",
		"item": item,
		"name": item.name,
		"level": next_level,
		"icon": item.icon,
		"bonus_preview": item.bonuses[next_level - 1],
		"is_new": current_level == 0,
	}
	
func _get_active_weapon(weapon_data: WeaponData) -> BaseWeapon:
	for w in weapon_manager.active_weapons:
		if w.data == weapon_data:
			return w
	return null

func _required_blood(target_level: int) -> int:
	return min(40, int(round(pow(1.8, min(target_level - 1, 20)))))
