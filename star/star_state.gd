class_name StarState extends StateNode

export var lifetime := 0.0
export var orbit_multiplier := 1.0
export var target_core_radius := 0.0
export var target_radius := 0.0
export var target_color := Color()
export var override_color := false
export var points := 0
export(Array, String) var next_state_names := []
export(Array, int) var next_state_weights := []

onready var star: Node2D = owner

var age := 0.0

var _start_core_radius := 0.0
var _start_radius := 0.0
var _start_color := Color()

var _state_weights := 0

func _ready() -> void:
	for i in range(next_state_names.size()):
		_state_weights += next_state_weights[i]

func enter(_args: Dictionary={}) -> void:
	_start_core_radius = star.core_radius
	_start_radius = star.radius
	_start_color = star.modulate

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		if next_state_names.size() > 0:
			state_machine.transition_to(next_state())
	else:
		var t := min(1.0, age / lifetime)
		star.radius = lerp(_start_radius, target_radius, t)
		star.core_radius = lerp(_start_core_radius, target_core_radius, t)
		if override_color:
			star.modulate = target_color
		else:
			star.modulate = _start_color.linear_interpolate(target_color, t)
		star.update()

func next_state() -> String:
	var roll := randi() % _state_weights
	for i in range(next_state_names.size()):
		roll -= next_state_weights[i]
		if roll < 0:
			return next_state_names[i]
	assert(false)
	return ""
