class_name StarSystem extends Node2D

signal star_formed(star)
signal star_died(star)
signal star_collapsed(star)

var constellations := [
	Constellation.new(self) \
		.with_lifetime(0.0) \
		.with_spawn_rate(0.0) \
		.with_min_stars(1) \
		.with_spawn_func(funcref(self, "_spawn_start")) \
		.with_star_weights({
			"Brown Dwarf": 0,
			"Low Mass": 1,
			"High Mass": 0,
			"Giant": 0,
			"Super Giant": 0,
			"White Dwarf": 0,
			"Neutron": 0,
			"Pulsar": 0,
			"Black Hole": 0,
		}),
	Constellation.new(self) \
		.with_lifetime(60.0) \
		.with_spawn_rate(2.0) \
		.with_min_stars(3) \
		.with_star_weights({
			"Brown Dwarf": 1,
			"Low Mass": 1,
			"High Mass": 1,
		}),
	Constellation.new(self) \
		.with_lifetime(10.0) \
		.with_spawn_rate(0.5) \
		.with_min_stars(6) \
		.with_star_weights({
			"Giant": 1,
			"Super Giant": 1,
		})
]

var shuffle_constellations := [
]

var _current_constellation := 0
var _shuffled_constellation: Constellation
var _polled_stars := []

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	var con: Constellation
	if _current_constellation < constellations.size():
		con = constellations[_current_constellation]
	else:
		con = _shuffled_constellation

	con.poll_stars(delta, _polled_stars)
	while _polled_stars.size() > 0:
		var star: Star = _polled_stars.pop_back()
		var _ignore: int
		_ignore = star.connect("formed", self, "_on_star_formed", [star])
		_ignore = star.connect("died", self, "_on_star_died", [star])
		_ignore = star.connect("collapsed", self, "_on_star_collapsed", [star])
		add_child(star)

	if _current_constellation < constellations.size():
		if constellations[_current_constellation].finished():
			_current_constellation += 1
	
	if _current_constellation == constellations.size():
		if _shuffled_constellation == null or _shuffled_constellation.finished():
			_shuffled_constellation = _shuffled_constellation[randi() % _shuffled_constellation.size()]
			_shuffled_constellation.reset()

func reset() -> void:
	for child in get_children():
		child.queue_free()
	
	for c in constellations:
		c.reset()
	
	_current_constellation = 0

func _on_star_formed(star: Star) -> void:
	emit_signal("star_formed", star)

func _on_star_died(star: Star) -> void:
	emit_signal("star_died", star)
	
func _on_star_collapsed(star: Star) -> void:
	emit_signal("star_collapsed", star)

func _spawn_start(_con: Constellation, _radius: int) -> Vector2:
	 return Vector2(1280/4, 1280/4)
