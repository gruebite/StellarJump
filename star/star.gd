class_name Star extends Node2D

enum State {
	FORMING,
	DYING,
	COLLAPSING,
}

signal formed()
signal died()
signal collapsed()

export var formtime := 1.0
export var lifetime := 10.0
export var target_radius := 30.0
export var orbital_rate := 1.0
export var points := 0

export var ring_color := Color.white
export var core_color := Color.white

var state: int = State.FORMING

var age := 0.0
var core_radius := 0.0
var radius := 0.0 setget set_radius, get_radius

func _ready() -> void:
	pass

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
			$Area.monitorable = true
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
	update()
	
func _draw() -> void:
	draw_circle(Vector2.ZERO, core_radius, core_color)
	draw_arc(Vector2.ZERO, radius - 1.0, 0, 2 * PI, 32, ring_color, 2.0, true)
	#draw_arc(Vector2.ZERO, radius, 0.0, 0.2, 32, Color.white, 2.0, true)
	#draw_arc(Vector2.ZERO, radius, PI, PI + 0.2, 32, Color.white, 2.0, true)
	
func set_radius(value: float) -> void:
	radius = value
	$Area/Shape.shape.radius = radius

func get_radius() -> float:
	return radius

func siphon() -> void:
	assert(state == State.DYING)
	# Percentage of lifetime passed.
	var p := clamp((age - formtime) / lifetime, 0.0, 0.999999999)
	var desired_remaining := min(lifetime - (age - formtime), 1.0 / orbital_rate)
	lifetime = (1 / (1-p)) * desired_remaining
	age = formtime + p * lifetime

func kill() -> void:
	age = max(age, formtime + lifetime)
	state = State.COLLAPSING
	emit_signal("died")
