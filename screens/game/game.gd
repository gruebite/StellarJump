class_name Game extends Node2D

const drain_collected_duration := 0.1

var score := 0

var _fake_score := 0
var _collected_score := 0
var _wait_score := 0.5
var _start_time := 0

var _drain_t := 0.0

func _ready() -> void:
	randomize()
	var _ignore: int
	_ignore = $Player.connect("died", self, "_on_player_died")
	_ignore = $Player.connect("used_boost", self, "_on_player_used_boost")
	_ignore = $Player.connect("gained_boost", self, "_on_player_gained_boost")
	_ignore = $Player.connect("consumed_star", self, "_on_player_consumed_star")
	_ignore = $Player.connect("chained_changed", self, "_on_player_chained_changed")
	_ignore = $Player.connect("gained_points", self, "gain_points")
	
	_ignore = $Stars.connect("star_collapsed", self, "_on_star_collapsed")
	
	reset()

func _process(delta: float) -> void:
	var sec := get_game_seconds()
	$UI/HUD/Top/Time.text = "%02d:%02d" % [sec / 60, sec % 60]
	
	
	if _collected_score > 0:
		_drain_t += delta
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
	if event is InputEventMouseButton and event.pressed:
		reset()

func _on_player_died() -> void:
	$UI/GameOver/Grid/Score.text = "Score: " + str(score)
	$UI/GameOver.show()

func _on_player_chained_changed() -> void:
	var extra: String
	match $Player.get_chain_overflow():
		0: extra = ""
		1: extra = "-"
		2: extra = "="
	$UI/HUD/Top/Bar/Chain.text = "Ξ".repeat($Player.get_warp_level()) + extra

func _on_player_used_boost() -> void:
	$UI/HUD/Top/Bar/Boosts.text = "ж".repeat($Player.boosts)
	
func _on_player_gained_boost() -> void:
	$UI/HUD/Top/Bar/Boosts.text = "ж".repeat($Player.boosts)

func _on_player_consumed_star(star: Star) -> void:
	gain_points(star.points)

func _on_star_collapsed(star: Star) -> void:
	if !star.consumed and !star.instantly_consumable:
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
	
	_on_player_gained_boost()
	_on_player_chained_changed()
	$UI/HUD/Top/Score/Label.text = str(score)
	
	$UI/GameOver.hide()
