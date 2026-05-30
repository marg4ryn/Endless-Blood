extends Node

signal stats_changed
signal gold_changed

var gold: int = 0
var upgrade_cost: int = 50
var best_time: float = 0.0
var best_kills: int = 0
var tutorial_seen: bool = false
var selected_hero: HeroData = null
var selected_hero_index: int = 0

var all_heroes: Array[HeroData] = [
	preload("res://data/heroes/blood_hunter.tres"),
	preload("res://data/heroes/gwen.tres"),
]
var heroes: Array = [
	{"max_health_level": 0, "speed_level": 0, "luck_level": 0},
	{"max_health_level": 0, "speed_level": 0, "luck_level": 0},
]

const STAT_PER_LEVEL = {
	"max_health": 4,
	"speed": 3,
	"luck": 1,
}
const SAVE_PATH = "user://save.json"

func _ready() -> void:
	_ensure_hero_slots()
	if selected_hero == null and not all_heroes.is_empty():
		selected_hero = all_heroes[clampi(selected_hero_index, 0, all_heroes.size() - 1)]
	load_game()
	_ensure_hero_slots()
	if selected_hero == null and not all_heroes.is_empty():
		selected_hero = all_heroes[clampi(selected_hero_index, 0, all_heroes.size() - 1)]

func on_game_over(time: float, kills: int) -> void:
	if time > best_time:
		best_time = time
	if kills > best_kills:
		best_kills = kills
	GameData.reset_state()
	save_game()

func get_stat(hero_index: int, stat: String, base: int) -> int:
	if hero_index < 0 or hero_index >= heroes.size():
		return base
	var level = heroes[hero_index].get(stat + "_level", 0)
	return base + level * STAT_PER_LEVEL.get(stat, 10)

func get_level(hero_index: int, stat: String) -> int:
	if hero_index < 0 or hero_index >= heroes.size():
		return 0
	return heroes[hero_index].get(stat + "_level", 0)
	
func upgrade_hero_stat(hero_index: int, stat: String) -> bool:
	if hero_index < 0 or hero_index >= heroes.size():
		return false
	if gold < upgrade_cost:
		return false
	var level_key = stat + "_level"
	var current_level = heroes[hero_index].get(level_key, 0)
	if current_level >= 10:
		return false
	gold -= upgrade_cost
	upgrade_cost += 10
	heroes[hero_index][level_key] = current_level + 1
	stats_changed.emit()
	gold_changed.emit()
	save_game()
	return true

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit()

func _ensure_hero_slots() -> void:
	while heroes.size() < all_heroes.size():
		heroes.append({"max_health_level": 0, "speed_level": 0, "luck_level": 0})
	if heroes.size() > all_heroes.size():
		heroes.resize(all_heroes.size())
	if selected_hero_index < 0 or selected_hero_index >= all_heroes.size():
		selected_hero_index = 0

func reset_save() -> void:
	gold = 2000
	upgrade_cost = 50
	best_time = 0.0
	best_kills = 0
	tutorial_seen = false
	heroes = [
		{"max_health_level": 0, "speed_level": 0, "luck_level": 0},
		{"max_health_level": 0, "speed_level": 0, "luck_level": 0},
	]
	selected_hero_index = 0
	if not all_heroes.is_empty():
		selected_hero = all_heroes[0]
	save_game()
	stats_changed.emit()
	gold_changed.emit()

func save_game() -> void:
	var data = {
		"gold": gold,
		"upgrade_cost": upgrade_cost,
		"best_time": best_time,
		"best_kills": best_kills,
		"heroes": heroes,
		"tutorial_seen": tutorial_seen
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		printerr("Unable to save data")
		return
	file.store_var(data)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_ensure_hero_slots()
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		printerr("Unable to load data")
		return
	var data = file.get_var()
	gold         = data.get("gold", gold)
	upgrade_cost = data.get("upgrade_cost", upgrade_cost)
	best_time    = data.get("best_time", best_time)
	best_kills   = data.get("best_kills", best_kills)
	tutorial_seen = data.get("tutorial_seen", tutorial_seen)
	heroes       = data.get("heroes", heroes)
	_ensure_hero_slots()
	stats_changed.emit()
	gold_changed.emit()
	if not all_heroes.is_empty():
		selected_hero_index = clampi(selected_hero_index, 0, all_heroes.size() - 1)
		selected_hero = all_heroes[selected_hero_index]

func mark_tutorial_seen() -> void:
	if tutorial_seen:
		return
	tutorial_seen = true
	save_game()
	
