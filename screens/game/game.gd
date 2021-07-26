class_name Game extends Node2D

const drain_collected_duration := 0.1

var score := 0

var _fake_score := 0
var _collected_score := 0
var _wait_score := 0.5
var _start_time := 0

var _drain_t := 0.0

var _game_over_t := 0.0

func _ready() -> void:
	randomize()
	var _ignore: int
	_ignore = $Player.connect("died", self, "_on_player_died")
	_ignore = $Player.connect("energy_changed", self, "_on_player_energy_changed")
	_ignore = $Player.connect("entered_orbit", self, "_on_player_entered_orbit")
	_ignore = $Player.connect("consumed_star", self, "_on_player_consumed_star")
	_ignore = $Player.connect("orbited", self, "_on_player_orbited")
	_ignore = $Player.connect("gained_points", self, "gain_points")
	
	_ignore = $Stars.connect("star_collapsed", self, "_on_star_collapsed")
	
	reset()

func _process(delta: float) -> void:
	var sec := get_game_seconds()
	$UI/HUD/Top/Time.text = "%02d:%02d" % [sec / 60, sec % 60]
	
	_game_over_t -= delta
	
	if _collected_score > 0:
		_drain_t += delta * 3.0
		$UI/HUD/Top/Score/Collected.text = " +" + str(_collected_score)
		if _wait_score > 0:
			_wait_score -= delta
		elif _drain_t >= drain_collected_duration:
			_drain_t = 0.0
			_fake_score += 1
			_collected_score -= 1
			$UI/HUD/Top/Score/Label.text = str(_fake_score)
	else:
		$UI/HUD/Top/Score/Collected.text = ""

func _on_gui_input(event: InputEvent) -> void:
	if _game_over_t <= 0.0:
		if event is InputEventMouseButton and event.pressed:
			reset()
		if event is InputEventKey and event.pressed and event.scancode == KEY_SPACE:
			reset()
	get_tree().set_input_as_handled()

func _on_player_died() -> void:
	$UI/GameOver/Grid/Score.text = "Score: " + str(score)
	$UI/GameOver.show()
	$UI/GameOver.grab_focus()
	_game_over_t = 0.5

func _on_player_energy_changed(_by: int) -> void:
	_update_energy_bar()

func _on_player_entered_orbit(_star: Star) -> void:
	pass

func _on_player_consumed_star(_star: Star) -> void:
	pass

func _on_player_orbited(_star: Star) -> void:
	pass

func _on_star_collapsed(star: Star) -> void:
	if !star.consumed:
		$Stars.form_star("Black Hole", star.position)
	
func gain_points(amount: int) -> void:
	_fake_score = score
	score += amount
	_collected_score = amount
	_wait_score = 0.5

func get_game_seconds() -> int:
	return int(OS.get_ticks_msec() / 1000.0) - _start_time

func reset() -> void:
	score = 0
	_start_time = int(OS.get_ticks_msec() / 1000.0)
	
	$Player.reset()
	$Stars.reset()
	
	_update_energy_bar()
	$UI/HUD/Top/Score/Label.text = str(score)
	
	$UI/GameOver.hide()

func _update_energy_bar() -> void:
	for i in range(Player.energy_max):
		var node := $UI/HUD/Top/Bar/Energy.get_node(str(i + 1))
		if i < $Player.energy:
			node.modulate.a = 1.0
		else:
			node.modulate.a = 0.0
