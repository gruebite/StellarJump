class_name Star extends Node2D

enum State {
	FORMING,
	DYING,
	COLLAPSING,
	EXPLODING,
}

const orbital_rate_factor := 1.0
const orbital_rate_lifetime_factor := 0.1
const orbital_rate_radius_factor := 0.1
const points_factor := 1.0
const points_lifetime_factor := 0.01
const points_radius_factor := 0.1

signal formed()
signal died()
signal collapsed()

export var deadly := false
export var instantly_consumable := false
export var formtime := 1.0
export var lifetime := 20.0
export var target_radius := 40.0
export var orbital_rate := 0.5
export var orbit_limit := 1.0
export var points := 10
export var boosts := 0

export var ring_color := Color.white
export var core_color := Color.white

var consumed := false
var orbited := false

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
	if radius >= 2.0:
		draw_arc(Vector2.ZERO, radius, 0, 2 * PI, 32, ring_color, 3.0, true)
	#draw_arc(Vector2.ZERO, radius, 0.0, 0.2, 32, Color.white, 2.0, true)
	#draw_arc(Vector2.ZERO, radius, PI, PI + 0.2, 32, Color.white, 2.0, true)

func _on_explosion_timeout():
	queue_free()
	
func set_radius(value: float) -> void:
	radius = value
	# Buffer for the ring's width.
	$Area/Shape.shape.radius = radius + 3

func get_radius() -> float:
	return radius

func kill() -> void:
	age = max(age, formtime + lifetime)
	state = State.COLLAPSING
	emit_signal("died")

func consume() -> void:
	consumed = true
	kill()
	emit_signal("collapsed")
	self.radius = 0
	self.core_radius = 0
	state = State.EXPLODING
	if !orbited:
		$ExplosionParticles.emission_sphere_radius = target_radius
		$ExplosionParticles.emitting = true
		$ExplosionTimer.start()
