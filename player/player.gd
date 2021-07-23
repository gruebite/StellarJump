class_name Player extends Node2D

signal died()
signal used_boost()
signal gained_boost()
signal consumed_star(star)
signal chained_changed()
signal gained_points(amount)

const radius := 10
const speed := 120.0
const rotation_speed := PI

const warp_speeds := [
	1.0,
	1.2,
	1.4,
	1.6,
	1.8,
	2.0,
	2.1,
	2.2,
	2.3,
	2.4,
	2.5,
]

const chained_per_warp := 3
const max_boosts := 10
const boost_points := 1000

var chained := 0

var direction := Vector2(1, 1).normalized()

var orbiting: Star = null
var clockwise := true

var boosts := max_boosts / 2

var _orbit_traveled := 0.0

func _ready() -> void:
	$Area/Shape.shape.radius = radius

func _physics_process(delta: float) -> void:
	if orbiting:
		if is_instance_valid(orbiting):
			var orb := 1 + (get_warp_speed() - 1) * 0.5
			var rads: float = TAU * orbiting.orbital_rate * delta * orb * (1 if clockwise else -1)
			_orbit_traveled += abs(rads)
			if _orbit_traveled >= TAU:
				_orbit_traveled = 0.0
				orbiting.orbit()
				dec_warp()
			direction = direction.rotated(rads)
			position = orbiting.position + direction * (orbiting.radius + radius)
			rotation = direction.angle()
	else:
		position += direction * delta * speed * get_warp_speed()
		rotation += delta * rotation_speed * get_warp_speed() * (1 if clockwise else -1)
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
	if star.instantly_consumable:
		if !star.consumed:
			star.consume()
			var needs := max_boosts - boosts
			var takes := int(min(star.boosts, needs))
			boosts += takes
			var remains := star.boosts - takes
			if remains > 0:
				emit_signal("gained_points", remains * boost_points)
			emit_signal("gained_boost")
		return
	var new_direction := (position - star.position).normalized()
	# Only set direction if we are not already in orbit.
	if orbiting and is_instance_valid(orbiting):
		inc_chain()
		orbiting.consume()
		$BoostParticles.emitting = true
	else:
		clockwise = direction.dot(new_direction.rotated(PI / 2)) >= 0
	direction = new_direction
	orbiting = star
	_orbit_traveled = 0.0

func _on_explosion_timeout():
	print("DIED")
	emit_signal("died")
	
func _on_screen_exited():
	print("DIED")
	emit_signal("died")

func explode() -> void:
	$Sprite.hide()
	$ExplosionParticles.emitting = true
	$ExplosionTimer.start()

func get_chain_overflow() -> int:
	return chained % chained_per_warp
	
func get_warp_level() -> int:
	return int(clamp(int(chained / chained_per_warp), 0, warp_speeds.size() - 1))

func get_warp_speed() -> float:
	return warp_speeds[get_warp_level()]

func inc_chain() -> void:
	chained += 1
	emit_signal("chained_changed")

func dec_chain() -> void:
	chained = int(max(0, chained - 1))
	emit_signal("chained_changed")

func inc_warp() -> void:
	var warp_level := int(min(warp_speeds.size() - 1, get_warp_level() + 1))
	chained = warp_level * chained_per_warp
	emit_signal("chained_changed")

func dec_warp() -> void:
	var warp_level := int(max(0, get_warp_level() - 1))
	chained = 0 if warp_level == 0 else warp_level * chained_per_warp
	emit_signal("chained_changed")

func action() -> void:
	if orbiting:
		if orbiting.state != Star.State.COLLAPSING:
			var star := orbiting
			orbiting = null
			star.consume()
			if !star.orbited:
				$BoostParticles.emitting = true
				inc_chain()
			emit_signal("consumed_star", star)
	elif boosts > 0:
		direction = Vector2.RIGHT.rotated(rotation)
		boosts -= 1
		inc_chain()
		emit_signal("used_boost")
		$BoostParticles.emitting = true

func reset() -> void:
	$Sprite.show()
	orbiting = null
	boosts = max_boosts
	chained = 0
	position = Vector2()
	direction = Vector2(1, 1).normalized()
