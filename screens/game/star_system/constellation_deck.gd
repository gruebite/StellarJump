class_name ConstellationDeck extends Reference

var shuffle := false
var take := -1

var _constellations: Array
var _index := 0
var _taken := 0

func _init(constellations: Array) -> void:
	_constellations = constellations

func with_shuffle(enable: bool) -> ConstellationDeck:
	if !shuffle and enable:
		_constellations.shuffle()
	shuffle = enable
	return self
	
func with_take(count: int) -> ConstellationDeck:
	take = count
	return self

func poll_stars(delta: float, array: Array) -> void:
	if finished(): return
	
	_constellations[_index].poll_stars(delta, array)
	if _constellations[_index].finished():
		_index += 1
		_taken += 1
	
func finished() -> bool:
	return _index >= _constellations.size() and (take == -1 or _taken <= take)

func reset() -> void:
	for c in _constellations:
		c.reset()
	if shuffle:
		_constellations.shuffle()
	_index = 0
	_taken = 0
