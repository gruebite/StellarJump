class_name Star extends Node2D

enum State {
	FORMING,
	DYING,
	COLLAPSING,
	EXPLODING,
}

signal formed()
signal died()
signal collapsed()

export var formtime := 1.0
export var lifetime := 10.0
export var target_radius := 30.0
export var orbital_rate := 1.0
export var orbit_limit := 1.0
export var points := 0

export var ring_color := Color.white
export var core_color := Color.white

var state: int = State.FORMING

var age := 0.0
var core_radius := 0.0
var radius := 0.0 setget set_radius, get_radius

func _ready() -> void:
	$ExplosionParticles.modulate = ring_color

func _physics_process(delta: float) -> void:
	age += delta
	match state:
		State.FORMING:
			var t := min(1.0, age / formtime)
			self.core_radius = lerp(0.0, target_radius, t)
			self.radius = lerp(0.0, target_radius, t)
			if t >= 1.0:
				emit_signal("formed")
				state = State.DYING
		State.DYING:
			var t := min(1.0, (age - formtime) / lifetime)
			self.core_radius = lerp(radius, 0.0, t)
			if t >= 1.0:
				emit_signal("died")
				state = State.COLLAPSING
		State.COLLAPSING:
			var t := min(1.0, (age - formtime - lifetime) / 0.5)
			self.radius = lerp(target_radius, 0.0, t)
			self.core_radius = 0
			if t >= 1.0:
				emit_signal("collapsed")
				queue_free()
		State.EXPLODING:
			pass
	update()
	
func _draw() -> void:
	draw_circle(Vector2.ZERO, core_radius, core_color)
	draw_arc(Vector2.ZERO, radius - 1.0, 0, 2 * PI, 32, ring_color, 2.0, true)
	#draw_arc(Vector2.ZERO, radius, 0.0, 0.2, 32, Color.white, 2.0, true)
	#draw_arc(Vector2.ZERO, radius, PI, PI + 0.2, 32, Color.white, 2.0, true)

func _on_explosion_timeout():
	queue_free()
	
func set_radius(value: float) -> void:
	radius = value
	$Area/Shape.shape.radius = radius

func get_radius() -> float:
	return radius

func siphon() -> void:
	# Percentage of lifetime passed.
	var p := clamp((age - formtime) / lifetime, 0.0, 0.999999999)
	var speed_mult: float = get_tree().get_nodes_in_group("Player")[0].speed_mult
	var desired_remaining := min(lifetime - (age - formtime), 1.0 / orbital_rate * orbit_limit * speed_mult)
	lifetime = (1 / (1-p)) * desired_remaining
	age = formtime + p * lifetime

func kill() -> void:
	age = max(age, formtime + lifetime)
	state = State.COLLAPSING
	emit_signal("died")

func explode() -> void:
	kill()
	emit_signal("collapsed")
	self.radius = 0
	self.core_radius = 0
	$ExplosionParticles.emission_sphere_radius = target_radius
	$ExplosionParticles.emitting = true
	$ExplosionTimer.start()
