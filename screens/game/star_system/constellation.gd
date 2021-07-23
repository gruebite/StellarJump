class_name Constellation extends Reference

const star_scenes := {
	"Brown Dwarf": preload("res://star/kinds/brown_dwarf.tscn"),
	"Low Mass": preload("res://star/kinds/low_mass.tscn"),
	"High Mass": preload("res://star/kinds/high_mass.tscn"),
	"Giant": preload("res://star/kinds/giant.tscn"),
	"Super Giant": preload("res://star/kinds/super_giant.tscn"),
	"White Dwarf": preload("res://star/kinds/white_dwarf.tscn"),
	"Neutron": preload("res://star/kinds/neutron.tscn"),
	"Pulsar": preload("res://star/kinds/pulsar.tscn"),
	"Black Hole": preload("res://star/kinds/black_hole.tscn"),
}

const default_check_space_radius := 60.0

var star_system: Node2D
var lifetime := 30.0
var spawn_rate := 2.0
var min_stars := 3
var check_space := true
var star_weights := {}

var _star_weight_total := 0
var _spawn_t := 0.0
var _age := 0.0

var _physics_shape: Physics2DShapeQueryParameters
var _shape: CircleShape2D

var _spawn_func: FuncRef
var _check_func: FuncRef

func _init(_star_system: Node2D) -> void:
	star_system = _star_system

	_shape = CircleShape2D.new()
	_shape.radius = default_check_space_radius

	_physics_shape = Physics2DShapeQueryParameters.new()
	_physics_shape.set_shape(_shape)
	_physics_shape.transform = Transform2D(0, Vector2())
	_physics_shape.collision_layer = 1
	_physics_shape.collide_with_bodies = false
	_physics_shape.collide_with_areas = true
	
	_spawn_func = funcref(self, "_spawn_random")
	_check_func = funcref(self, "_check_proximity")

func with_lifetime(_lifetime: float) -> Constellation:
	lifetime = _lifetime
	return self

func with_spawn_rate(_spawn_rate: float) -> Constellation:
	spawn_rate = _spawn_rate
	return self

func with_min_stars(_min_stars: int) -> Constellation:
	min_stars = _min_stars
	return self

func with_star_weights(_star_weights: Dictionary) -> Constellation:
	star_weights = _star_weights
	_recalc_weights()
	return self

func with_check_space(_check_space: bool) -> Constellation:
	check_space = _check_space
	return self

func with_spawn_func(spawn_func: FuncRef) -> Constellation:
	_spawn_func = spawn_func
	return self

func with_check_func(check_func: FuncRef) -> Constellation:
	_check_func = check_func
	return self
	
func pick_star_scene() -> PackedScene:
	var pick := randi() % _star_weight_total
	for kind in star_weights:
		pick -= star_weights[kind]
		if pick < 0:
			return star_scenes[kind]
	print(_star_weight_total)
	assert(false)
	return null

func poll_stars(delta: float, array: Array) -> void:
	_age += delta
	
	var tries := 5
	while star_system.get_child_count() + array.size() < min_stars and tries > 0:
		var star := pick_star_scene().instance()
		var pos: Vector2 = _spawn_func.call_func(self, int(star.target_radius))
		if check_space and _check_func.call_func(self, pos, star.target_radius):
			star.position = pos
			print("ADDED ", pos)
			array.push_back(star)
		else:
			star.free()
			tries -= 1
			print("SKIPPED MIN ", tries)

	_spawn_t += delta
	if spawn_rate > 0.0 and _spawn_t >= spawn_rate:
		_spawn_t = 0.0
		
		tries = 5
		while tries > 0:
			var star := pick_star_scene().instance()
			var pos: Vector2 = _spawn_func.call_func(self, int(star.target_radius))
			if check_space and _check_func.call_func(self, pos, star.target_radius):
				star.position = pos
				array.push_back(star)
				break
			else:
				star.free()
				tries -= 1
				print("SKIPPED SPAWN ", tries)

func finished() -> bool:
	return _age >= lifetime

func reset() -> void:
	_age = 0.0
	_spawn_t = 0.0

func _recalc_weights() -> void:
	_star_weight_total = 0
	for kind in star_weights:
		_star_weight_total += star_weights[kind]

func _spawn_random(_con: Constellation, radius: int) -> Vector2:
	var r2 = radius*2
	return Vector2(randi()%(1280-r2)+radius, randi()%(720-r2)+radius)

func _check_proximity(_con: Constellation, pos: Vector2, radius: int) -> bool:
	_physics_shape.transform = Transform2D(0, pos)
	_shape.radius = radius
	var space_state := star_system.get_world_2d().direct_space_state
	var query_results := space_state.intersect_shape(_physics_shape, 1)
	for result in query_results:
		var _actual_collider_object = result.collider
		return false
	return true
