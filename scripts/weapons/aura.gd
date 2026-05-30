extends Node2D

var radius: float = 80.0

func set_radius(r: float) -> void:
	radius = r
	z_index = 2
	z_as_relative = false
	queue_redraw()

func _draw() -> void:
	var color_fill = Color(0.2, 0.5, 1.0, 0.15)
	var color_edge = Color(0.3, 0.6, 1.0, 0.6)
	draw_circle(Vector2.ZERO, radius, color_fill)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, color_edge, 2.0)
