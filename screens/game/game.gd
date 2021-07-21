class_name Game extends Node2D

var score := 0

func _ready() -> void:
	randomize()
	var _ignore: int
	_ignore = $Player.connect("died", self, "_on_player_died")
	_ignore = $Player.connect("used_boost", self, "_on_player_used_boost")
	_ignore = $Player.connect("consumed_star", self, "_on_player_consumed_star")
	
	_ignore = $Stars.connect("star_collapsed", self, "_on_star_collapsed")
	
	reset()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		reset()

func _on_player_died() -> void:
	$UI/GameOver/Grid/Score.text = "Score: " + str(score)
	$UI/GameOver.show()

func _on_player_used_boost() -> void:
	$UI/HUD/Top/Boosts.text = "|".repeat($Player.boosts)

func _on_player_consumed_star(star: Star) -> void:
	score += star.points
	$UI/HUD/Top/Score.text = str(score)

func _on_star_collapsed(star: Star) -> void:
	if $Player.orbiting == star:
		_on_player_died()
	else:
		$Player.speed_mult *= 1.01
		print("SPEED ", $Player.speed_mult)

func reset() -> void:
	score = 0
	
	$Player.reset()
	$Stars.reset()
	
	$UI/HUD/Top/Boosts.text = "|".repeat($Player.boosts)
	$UI/HUD/Top/Score.text = str(score)
	
	$UI/GameOver.hide()
