class_name Game extends Node2D

const star_scene := preload("res://star/star.tscn")

const star_max := 10

var star_count := 0
var score := 0

var _t := 0.0

func _ready() -> void:
	randomize()
	var _ignore: int
	_ignore = $Player.connect("died", self, "_on_player_died")
	_ignore = $Player.connect("used_boost", self, "_on_player_used_boost")
	_ignore = $Player.connect("consumed_star", self, "_on_player_consumed_star")
	
	reset()

func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= (30.0 / star_max) and star_count < star_max:
		_t = 0
		var star: Star = star_scene.instance()
		star.position = Vector2(randi() % 1280, randi() % 720)
		$Stars.add_child(star)
		star_count -= 1

func _on_player_died() -> void:
	$UI/GameOver/Grid/Score.text = "Score: " + str(score)
	$UI/GameOver.show()

func _on_player_used_boost() -> void:
	$UI/HUD/Top/Boosts.text = "|".repeat($Player.boosts)

func _on_player_consumed_star(star: Star) -> void:
	star.queue_free()
	score += star.get_state().points
	$UI/HUD/Top/Score.text = str(score)
	star_count += 1
	$Player.level_up()

func reset() -> void:
	score = 0
	
	for child in $Stars.get_children():
		child.queue_free()
		
	var star: Star = star_scene.instance()
	star.position = Vector2(1280/4, 1280/4)
	$Stars.add_child(star)
	
	$Player.reset()
	
	$UI/HUD/Top/Boosts.text = "|".repeat($Player.boosts)
	$UI/HUD/Top/Score.text = str(score)
	
	$UI/GameOver.hide()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		reset()
