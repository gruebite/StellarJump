class_name Player extends Node2D

signal died()
signal used_boost()
signal consumed_star(star)

const radius := 5
const rotation_speed := PI

var speed := 120.0
var speed_mult = 1.01
var direction := Vector2(1, 1).normalized()

var orbiting: Star = null
var clockwise := true

var boosts := 5

func _ready() -> void:
	$Area/Shape.shape.radius = radius

func _physics_process(delta: float) -> void:
	if orbiting:
		if is_instance_valid(orbiting):
			if orbiting.state == Star.State.COLLAPSING:
				explode()
			direction = direction.rotated(TAU * orbiting.orbital_rate * delta * speed_mult * (1 if clockwise else -1))
			position = orbiting.position + direction * (orbiting.radius + radius*2)
			rotation = direction.angle()
	else:
		position += direction * delta * speed * speed_mult
		rotation += delta * rotation_speed * speed_mult * (1 if clockwise else -1)
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
	if orbiting:
		orbiting.kill()
	else:
		clockwise = direction.dot(new_direction.rotated(PI / 2)) >= 0
	orbiting = node as Star
	orbiting.siphon()
	direction = new_direction

func _on_screen_exited():
	print("DIED")
	emit_signal("died")

func explode() -> void:
	$Sprite.hide()
	$ExplosionParticles.emitting = true

func action() -> void:
	if orbiting:
		if orbiting.state != Star.State.COLLAPSING:
			emit_signal("consumed_star", orbiting)
			var star := orbiting
			orbiting = null
			star.explode()
	elif boosts > 0:
		direction = Vector2.RIGHT.rotated(rotation)
		boosts -= 1
		emit_signal("used_boost")
		$BoostParticles.emitting = true

func reset() -> void:
	$Sprite.show()
	orbiting = null
	boosts = 5
	speed_mult = 1.01
	position = Vector2()
	direction = Vector2(1, 1).normalized()
