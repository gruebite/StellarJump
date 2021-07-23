class_name StarSystem extends Node2D

signal star_formed(star)
signal star_died(star)
signal star_collapsed(star)

var constellations := {
}

var decks := [
	ConstellationDeck.new([
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
			.with_lifetime(30.0) \
			.with_spawn_rate(3.0) \
			.with_min_stars(3) \
			.with_star_weights({
				"Brown Dwarf": 1,
				"Low Mass": 1,
				"High Mass": 1,
			}),
		Constellation.new(self) \
			.with_lifetime(5.0) \
			.with_spawn_rate(1.0) \
			.with_min_stars(2) \
			.with_star_weights({
				"Giant": 2,
				"Super Giant": 1,
			}),
	]),
	ConstellationDeck.new([
		Constellation.new(self) \
			.with_lifetime(30.0) \
			.with_spawn_rate(3.0) \
			.with_min_stars(3) \
			.with_star_weights({
				"Brown Dwarf": 1,
				"Low Mass": 3,
				"High Mass": 2,
			}),
		Constellation.new(self) \
			.with_lifetime(5.0) \
			.with_spawn_rate(1.0) \
			.with_min_stars(2) \
			.with_star_weights({
				"Giant": 2,
				"Super Giant": 1,
			}),
		Constellation.new(self) \
			.with_lifetime(3.0) \
			.with_spawn_rate(3.0) \
			.with_min_stars(1) \
			.with_star_weights({
				"White Dwarf": 5,
				"Neutron": 3,
				"Black Hole": 1,
			}),
		Constellation.new(self) \
			.with_lifetime(0.5) \
			.with_spawn_rate(0.5) \
			.with_min_stars(0) \
			.with_star_weights({
				"Pulsar": 1,
			}),
	])
]

var deck_weights := [
	
]

var _current_deck := 0
var _polled_stars := []

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	decks[_current_deck].poll_stars(delta * max(1.0, pow(owner.get_game_seconds() / 60.0, 0.5)), _polled_stars)
	while _polled_stars.size() > 0:
		var star: Star = _polled_stars.pop_back()
		add_star(star)

	if decks[_current_deck].finished():
		decks[_current_deck].reset()
		_current_deck = randi() % decks.size()

func add_star(star: Star) -> void:
	var _ignore: int
	_ignore = star.connect("formed", self, "_on_star_formed", [star])
	_ignore = star.connect("died", self, "_on_star_died", [star])
	_ignore = star.connect("collapsed", self, "_on_star_collapsed", [star])
	add_child(star)

func form_star(star_name: String, pos: Vector2) -> void:
	var star: Star = Constellation.star_scenes[star_name].instance()
	star.position = pos
	add_star(star)

func reset() -> void:
	for child in get_children():
		child.queue_free()
	
	for d in decks:
		d.reset()
	
	_current_deck = 0

func _on_star_formed(star: Star) -> void:
	emit_signal("star_formed", star)

func _on_star_died(star: Star) -> void:
	emit_signal("star_died", star)
	
func _on_star_collapsed(star: Star) -> void:
	emit_signal("star_collapsed", star)

func _spawn_start(_con: Constellation, _radius: int) -> Vector2:
	 return Vector2(1280/4, 1280/4)
