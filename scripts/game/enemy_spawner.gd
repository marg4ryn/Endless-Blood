extends Node2D

class SpawnEntry:
	var scene: PackedScene
	var weight: float
	var min_time: float
	var group_min: int
	var group_max: int
	func _init(s, w, mt, gmin, gmax):
		scene = s
		weight = w
		min_time = mt
		group_min = gmin
		group_max = gmax

@export var huntsman_scene: PackedScene
@export var rat_scene: PackedScene
@onready var timer: Timer = $Timer

var _pool: Array = []
var _table: Array[SpawnEntry] = []
var _spawn_radius := 900.0

var counter := 2
var _time_offset := 0.0 
var base_time := 2.0
var current_time := base_time
var min_time := 0.1
var speed := 0.01

func _ready() -> void:
	_table.clear()
	if huntsman_scene:
		_table.append(SpawnEntry.new(huntsman_scene, 8.0, 0.0, 1, 1))
	if rat_scene:
		_table.append(SpawnEntry.new(rat_scene, 1.0, 15.0, 2, 5))

func _on_timer_timeout() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	var t: float = GameTimer.elapsed
	if counter < 2 && current_time <= min_time:
		reset_time()
		return
	if _get_active_count() >= 200:
		timer.wait_time = 0.5
		timer.start()
		return
	var entry := _pick_entry(t)
	if entry:
		var count := randi_range(entry.group_min, entry.group_max)
		var base_pos := _get_spawn_position(player)
		if base_pos == Vector2.ZERO:
			return
		for i in range(count):
			_spawn_one(entry.scene, base_pos, i, count)
		_update_spawn_rate()
		
func reset_time() -> void:
	counter += 1
	_time_offset = GameTimer.elapsed
	current_time = base_time
	timer.wait_time = current_time
	timer.start()

func _pick_entry(elapsed: float) -> SpawnEntry:
	var pool := _table.filter(func(e): return e.min_time <= elapsed)
	if pool.is_empty():
		return null
	var total: float = pool.reduce(func(acc, e): return acc + e.weight, 0.0)
	var roll := randf() * total
	for e in pool:
		roll -= e.weight
		if roll <= 0.0:
			return e
	return pool[-1]

func _get_spawn_position(player: Node2D) -> Vector2:
	var tries := 0
	while tries < 10:
		var angle := randf() * TAU
		var pos := player.global_position + Vector2(cos(angle), sin(angle)) * _spawn_radius
		if pos.x >= -4700 and pos.x <= 4700 and pos.y >= -4700 and pos.y <= 4700:
			return pos
		tries += 1
	return Vector2.ZERO

func _spawn_one(scene, base_pos, idx, total):
	if base_pos == Vector2.ZERO:
		return
	var enemy = _get_from_pool(scene)
	var offset := Vector2.ZERO
	if total > 1:
		var angle: float = (idx / float(total)) * TAU
		offset = Vector2(cos(angle), sin(angle)) * 50.0
		offset += Vector2(randf_range(-10, 10), randf_range(-10, 10))
	
	var player := get_tree().get_first_node_in_group("player")
	enemy.global_position = base_pos + offset
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().create_timer(0.1).timeout
	enemy.get_node("Collision").set_deferred("disabled", false)
	enemy.get_node("HurtboxArea").monitoring = true
	enemy.get_node("HurtboxArea").monitorable = true
	enemy.visible = true

func _update_spawn_rate() -> void:
	var t: float = GameTimer.elapsed - _time_offset
	current_time = max(min_time, base_time * exp(-speed * t))
	timer.wait_time = current_time
	timer.start()
	
func _get_from_pool(scene: PackedScene) -> Node:
	for enemy in _pool:
		if not enemy.visible:
			_reset_enemy(enemy)
			return enemy
	var enemy = scene.instantiate()
	enemy.get_node("Collision").disabled = true
	add_child(enemy)
	_pool.append(enemy)
	_reset_enemy(enemy)
	return enemy

func _reset_enemy(enemy: Node) -> void:
	enemy.is_dead = false
	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.get_node("HurtboxArea").monitoring = false
	enemy.get_node("HurtboxArea").monitorable = false
	enemy.get_node("Collision").set_deferred("disabled", true)
	enemy.health = enemy.max_health

func _get_active_count() -> int:
	var count := 0
	for enemy in _pool:
		if enemy.visible:
			count += 1
	return count
