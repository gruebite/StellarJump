class_name Player extends Node2D

signal died()
signal used_boost()
signal consumed_star(star)

const radius := 5
const satellite_speed := PI
const satellite_distance := radius * 2

var speed := 120.0
var speed_mult = 1.01
var direction := Vector2(1, 1).normalized()

var orbiting: Star = null
var clockwise := true

var boosts := 5

var satellite := Vector2.LEFT

func _ready() -> void:
	$Area/Shape.shape.radius = radius

func _physics_process(delta: float) -> void:
	if orbiting and not is_instance_valid(orbiting):
		orbiting = null
	if orbiting:
		var r := orbiting.radius
		var p := TAU * r
		var d := speed * delta
		var a := d / p
		if not clockwise:
			a *= -1
		direction = direction.rotated(a * TAU * orbiting.get_state().orbit_multiplier * speed_mult)
		position = orbiting.position + direction * (r + radius*2)
		rotation = direction.angle()
	else:
		position += direction * delta * speed * speed_mult
		rotation += delta * satellite_speed * (1 if clockwise else -1)
	update()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			action()
	if event is InputEventKey:
		if event.scancode == KEY_SPACE and event.pressed:
			action()

func _draw() -> void:
	pass
	#draw_circle(Vector2.ZERO, radius, Color.white)
	#draw_circle(satellite * satellite_distance, radius / 2.0, Color.white)

func _on_area_entered(area: Area2D) -> void:
	var node: Node2D = area.get_parent()
	var new_direction := (position - node.position).normalized()
	# Only set direction if we are not already in orbit.
	if not orbiting:
		clockwise = direction.dot(new_direction.rotated(PI / 2)) >= 0
	orbiting = node as Star
	direction = new_direction


func _on_screen_exited():
	print("DIED")
	emit_signal("died")

func action() -> void:
	if orbiting:
		if orbiting.get_state().name == "Neutron" or orbiting.get_state().name == "Blackhole":
			boosts += 1
			emit_signal("used_boost")
		emit_signal("consumed_star", orbiting)
		orbiting = null
	elif boosts > 0:
		direction = Vector2.RIGHT.rotated(rotation)
		boosts -= 1
		emit_signal("used_boost")

func level_up() -> void:
	speed_mult *= 1.01
	print("SPEED, ", speed_mult)

func reset() -> void:
	boosts = 5
	speed_mult = 1.01
	position = Vector2()
	direction = Vector2(1, 1).normalized()
