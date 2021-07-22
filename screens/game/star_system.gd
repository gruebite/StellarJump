extends Node2D

const star_max := 10
const star_min_spawn_rate := 2.5

const star_scenes := {
	"Brown Dwarf": preload("res://star/kinds/brown_dwarf.tscn"),
	"Low Mass": preload("res://star/kinds/low_mass.tscn"),
	"High Mass": preload("res://star/kinds/high_mass.tscn"),
	"Giant": preload("res://star/kinds/giant.tscn"),
	"Super Giant": preload("res://star/kinds/super_giant.tscn"),
	"White Dwarf": preload("res://star/kinds/white_dwarf.tscn"),
	"Neutron": preload("res://star/kinds/neutron.tscn"),
}

const star_weights := {
	"Brown Dwarf": 5,
	"Low Mass": 10,
	"High Mass" : 3,
	"Giant": 3,
	"Super Giant": 5,
	"White Dwarf": 1,
	"Neutron": 1,
	#"Black Hole"
}

var _star_weight_total := 0

signal star_formed(star)
signal star_died(star)
signal star_collapsed(star)

var _physics_shape: Physics2DShapeQueryParameters
var _shape: CircleShape2D
var _t := 0.0

func _ready() -> void:
	for kind in star_weights:
		_star_weight_total += star_weights[kind]

	_shape = CircleShape2D.new()
	_shape.radius = 30

	_physics_shape = Physics2DShapeQueryParameters.new()
	_physics_shape.set_shape(_shape)
	_physics_shape.transform = Transform2D(0, Vector2())
	_physics_shape.collision_layer = 1
	_physics_shape.collide_with_bodies = false
	_physics_shape.collide_with_areas = true

func _physics_process(delta: float) -> void:
	_t += delta
	if get_child_count() < star_max and _t >= star_min_spawn_rate:
		_t = 0
		form_star(Vector2(randi()%(1280-360)+180, randi()%(720-360)+180))

func pick_star_scene() -> PackedScene:
	var pick := randi() % _star_weight_total
	for kind in star_weights:
		pick -= star_weights[kind]
		if pick <= 0:
			return star_scenes[kind]
	assert(false)
	return null

func reset() -> void:
	for child in get_children():
		child.queue_free()
	
	form_star(Vector2(1280/4, 1280/4))

func form_star(pos: Vector2) -> void:
	# Query space
	_physics_shape.transform = Transform2D(0, pos)
	var space_state := get_world_2d().direct_space_state
	var query_results := space_state.intersect_shape(_physics_shape, 1)
	for result in query_results:
		var actual_collider_object = result.collider
		print("SKIPPED")
		return
	
	var star: Star = pick_star_scene().instance()
	star.position = pos
	var _ignore: int
	_ignore = star.connect("formed", self, "_on_star_formed", [star])
	_ignore = star.connect("died", self, "_on_star_died", [star])
	_ignore = star.connect("collapsed", self, "_on_star_collapsed", [star])
	add_child(star)

func _on_star_formed(star: Star) -> void:
	emit_signal("star_formed", star)

func _on_star_died(star: Star) -> void:
	emit_signal("star_died", star)
	
func _on_star_collapsed(star: Star) -> void:
	emit_signal("star_collapsed", star)
