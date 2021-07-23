class_name Player extends Node2D

signal died()
signal used_boost()
signal gained_boost()
signal consumed_star(star)

const radius := 5
const speed := 120.0
const rotation_speed := PI

const warp_speeds := [
	1.0,
	1.5, # 3
	1.9, # 5
	2.2, # 8
	2.4, # 13
	2.5, # 21
]

const max_unstable_level := 70.0

var unstable_level := 0
var warp_level := 0
var chained := 0

var direction := Vector2(1, 1).normalized()

var orbiting: Star = null
var clockwise := true

var boosts := 5

var _orbit_traveled := 0.0

func _ready() -> void:
	$Area/Shape.shape.radius = radius

func _physics_process(delta: float) -> void:
	if orbiting:
		if is_instance_valid(orbiting):
			if orbiting.state == Star.State.COLLAPSING:
				explode()
			var rads: float = TAU * orbiting.orbital_rate * delta * pow(1.01, unstable_level) * (1 if clockwise else -1)
			_orbit_traveled += abs(rads)
			if _orbit_traveled >= TAU:
				orbiting.orbited = true
			direction = direction.rotated(rads)
			position = orbiting.position + direction * (orbiting.radius + radius*2)
			rotation = direction.angle()
	else:
		position += direction * delta * speed * warp_speeds[warp_level]
		rotation += delta * rotation_speed * warp_speeds[warp_level] * (1 if clockwise else -1)
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
	if star.instantly_consumable:
		if !star.consumed:
			star.consume()
			boosts += star.boosts
			emit_signal("gained_boost")
		return
	var new_direction := (position - star.position).normalized()
	# Only set direction if we are not already in orbit.
	if orbiting:
		orbiting.kill()
	else:
		clockwise = direction.dot(new_direction.rotated(PI / 2)) >= 0
	orbiting = star
	orbiting.siphon()
	direction = new_direction
	_orbit_traveled = 0.0

func _on_screen_exited():
	print("DIED")
	emit_signal("died")

func explode() -> void:
	$Sprite.hide()
	$ExplosionParticles.emitting = true

func action() -> void:
	if orbiting:
		if orbiting.state != Star.State.COLLAPSING:
			var star := orbiting
			orbiting = null
			star.consume()
			if !star.orbited:
				chained += 1
				warp_level = int(clamp(int((chained - 2) / 5), 0, warp_speeds.size() - 1))
			else:
				chained = 0
				warp_level = 0
			print("WARP ", warp_level)
			emit_signal("consumed_star", star)
	elif boosts > 0:
		direction = Vector2.RIGHT.rotated(rotation)
		boosts -= 1
		warp_level = int(max(0, warp_level - 1))
		chained = 0 if warp_level == 0 else warp_level * 5 + 2
		emit_signal("used_boost")
		$BoostParticles.emitting = true

func reset() -> void:
	$Sprite.show()
	orbiting = null
	boosts = 5
	unstable_level = 0
	warp_level = 0
	chained = 0
	position = Vector2()
	direction = Vector2(1, 1).normalized()
