class_name Player extends Node2D

signal died()

signal energy_changed(by)
signal entered_orbit(star)
signal consumed_star(star)
signal orbited(star)
signal gained_points(by)

const radius := 10
const speed := 120.0
const rotation_speed := PI

const energy_max := 30
const energy_start := 10
const boost_cost := 3

var energy := energy_start

var direction := Vector2(1, 1).normalized()

var orbiting: Star = null
var clockwise := true

var _orbit_traveled := 0.0
var _orbit_count := 0

func _ready() -> void:
	$Area/Shape.shape.radius = radius

func _physics_process(delta: float) -> void:
	if orbiting:
		if is_instance_valid(orbiting):
			var orb := 1 + (get_energy_speed() - 1) * 0.25
			var rads: float = TAU * orbiting.get_orbital_rate(speed) * delta * orb * (1 if clockwise else -1)
			_orbit_traveled += abs(rads)
			if _orbit_traveled >= TAU:
				_orbit_count += 1
				_orbit_traveled = 0.0
				$OrbitParticles.emitting = true
				emit_signal("orbited", orbiting)
				dec_energy()
			direction = direction.rotated(rads)
			position = orbiting.position + direction * (orbiting.radius + radius)
			rotation = direction.angle()
		else:
			orbiting = null
	else:
		position += direction * delta * speed * get_energy_speed()
		rotation += delta * rotation_speed * get_energy_speed() * (1 if clockwise else -1)
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
	var star: Star = area.get_parent()
	if star.deadly:
		explode()
	var new_direction := (position - star.position).normalized()
	# Only set direction if we are not already in orbit.
	if orbiting and is_instance_valid(orbiting):
		emit_signal("gained_points", int(orbiting.points * get_energy_speed()))
		orbiting.consume()
		emit_signal("consumed_star", orbiting)
	else:
		clockwise = direction.dot(new_direction.rotated(PI / 2)) >= 0
	direction = new_direction
	orbiting = star
	_orbit_traveled = 0.0
	_orbit_count = 0
	emit_signal("entered_orbit", orbiting)
	inc_energy()

func _on_explosion_timeout():
	print("DIED")
	emit_signal("died")

func _on_screen_exited():
	print("DIED")
	emit_signal("died")

func explode() -> void:
	if $ExplosionTimer.is_stopped():
		$Sprite.hide()
		$ExplosionParticles.emitting = true
		$ExplosionTimer.start()

func get_energy_speed() -> float:
	return max(1.0, energy / 10.0)

func inc_energy(by: int = 1) -> void:
	var new := int(min(energy_max, energy + by))
	energy = new
	emit_signal("energy_changed", int(abs(energy - new)))

func dec_energy(by: int = 1) -> void:
	var new := int(max(0, energy - by))
	energy = new
	emit_signal("energy_changed", int(abs(energy - new)))
	if energy == 0:
		explode()

func action() -> void:
	if orbiting:
		if orbiting.state != Star.State.COLLAPSING and orbiting.state != Star.State.EXPLODING:
			emit_signal("gained_points", int(orbiting.points * get_energy_speed()))
			var star := orbiting
			orbiting = null
			star.consume()
			emit_signal("consumed_star", star)
	elif energy > boost_cost:
		direction = Vector2.RIGHT.rotated(rotation)
		$BoostParticles.emitting = true
		dec_energy(boost_cost)

func reset() -> void:
	$Sprite.show()
	orbiting = null
	energy = energy_start
	position = Vector2()
	direction = Vector2(1, 1).normalized()
