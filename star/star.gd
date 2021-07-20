class_name Star extends Node2D

signal transitioned(state)

export var initial_state := "ProtoRed"

var age := 0.0
var core_radius := 0.0
var radius := 0.0 setget set_radius, get_radius

func _ready() -> void:
	var _ignore = $StateMachine.connect("transitioned", self, "_on_transitioned")
	$StateMachine.initial_state = initial_state

func _physics_process(delta: float) -> void:
	age += delta
	
func _draw() -> void:
	draw_circle(Vector2.ZERO, core_radius, Color.white)
	draw_arc(Vector2.ZERO, radius - 1.0, 0, 2 * PI, 32, Color.white, 2.0, true)
	#draw_arc(Vector2.ZERO, radius, 0.0, 0.2, 32, Color.white, 2.0, true)
	#draw_arc(Vector2.ZERO, radius, PI, PI + 0.2, 32, Color.white, 2.0, true)

func _on_transitioned(state_name: String) -> void:
	emit_signal("transitioned", state_name)
	
func set_radius(value: float) -> void:
	radius = value
	$Area/Shape.shape.radius = radius

func get_radius() -> float:
	return radius

func get_state() -> StarState:
	return $StateMachine.state
