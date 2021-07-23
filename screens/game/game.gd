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
	
	_ignore = $Stars.connect("star_collapsed", self, "_on_star_collapsed")
	
	reset()

func _process(delta: float) -> void:
	var sec := int(OS.get_ticks_msec() / 1000.0) - _start_time
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

func _on_player_used_boost() -> void:
	$UI/HUD/Top/Bar/Boosts.text = "|".repeat($Player.boosts)
	$UI/HUD/Top/Bar/Warp.text = "=".repeat($Player.warp_level)
	
func _on_player_gained_boost() -> void:
	$UI/HUD/Top/Bar/Boosts.text = "|".repeat($Player.boosts)

func _on_player_consumed_star(star: Star) -> void:
	_fake_score = score
	var p := star.points
	score += p
	_collected_score = p
	_wait_score = 0.5
	$UI/HUD/Top/Bar/Warp.text = "=".repeat($Player.warp_level)

func _on_star_collapsed(star: Star) -> void:
	if $Player.orbiting == star:
		_on_player_died()
	else:
		if !star.consumed:
			$Player.unstable_level += 1
			print("UNSTABLE ", $Player.unstable_level)

func reset() -> void:
	score = 0
	_start_time = int(OS.get_ticks_msec() / 1000.0)
	
	$Player.reset()
	$Stars.reset()
	
	$UI/HUD/Top/Bar/Boosts.text = "|".repeat($Player.boosts)
	$UI/HUD/Top/Bar/Warp.text = "=".repeat($Player.warp_level)
	$UI/HUD/Top/Score/Label.text = str(score)
	
	$UI/GameOver.hide()
