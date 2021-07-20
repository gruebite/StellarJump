
class_name StateMachine extends Node

signal transitioned(state_name)

export var initial_state := ""

onready var state: StateNode

func _ready() -> void:
	yield(owner, "ready")
	for child in get_children():
		child.state_machine = self
	state = get_node(initial_state)
	state.enter()

func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)

func _process(delta: float) -> void:
	state.process(delta)

func _physics_process(delta: float) -> void:
	state.physics_process(delta)

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	if not has_node(target_state_name):
		return

	state.exit()
	state = get_node(target_state_name)
	state.enter(msg)
	emit_signal("transitioned", state.name)
