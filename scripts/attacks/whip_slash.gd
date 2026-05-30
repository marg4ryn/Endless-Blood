extends Area2D

var attack: Attack
var _hit: Array[Node] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	$AnimationPlayer.play("attack")
	await $AnimationPlayer.animation_finished
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if area.is_in_group("enemies") and enemy not in _hit:
		_hit.append(enemy)
		enemy.take_damage(attack)
