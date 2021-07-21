extends Node

const star_max := 10
const star_min_spawn_rate := 3.0

const star_scenes := {
	"Brown Dwarf": preload("res://star/kinds/brown_dwarf.tscn"),
	"Low Mass": preload("res://star/kinds/low_mass.tscn"),
	"High Mass": preload("res://star/kinds/high_mass.tscn"),
}

const star_weights := {
	"Brown Dwarf": 5,
	"Low Mass": 10,
	"High Mass" : 3,
	#"Giant"
	#"Super Giant"
	#"White Dwarf"
	#"Neutron"
	#"Black Hole"
}

var _star_weight_total := 0

signal star_formed(star)
signal star_died(star)
signal star_collapsed(star)


var _t := 0.0

func _ready() -> void:
	for kind in star_weights:
		_star_weight_total += star_weights[kind]

func _process(delta: float) -> void:
	_t += delta
	if get_child_count() < star_max and _t >= star_min_spawn_rate:
		_t = 0
		form_star(Vector2(randi()%1280, randi()%720))

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
