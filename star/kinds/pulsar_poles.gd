extends Node2D

onready var _rotation_speed = randf() + 0.5

func _process(delta: float) -> void:
	rotation += TAU * delta * _rotation_speed
	update()

func _draw() -> void:
	draw_line(Vector2.RIGHT * owner.radius, Vector2.RIGHT * owner.radius * 3, owner.ring_color)
	draw_line(Vector2.LEFT * owner.radius, Vector2.LEFT * owner.radius * 3, owner.ring_color)
