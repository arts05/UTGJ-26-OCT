extends Node2D
## Three poses make the danger readable before staring causes a crash.

signal attacked
signal retreated

@export var poses: Array[Texture2D]
@export var stare_seconds: float = 3.2
@export var look_away_seconds: float = 0.85
@export var appearance_grace: float = 0.7

@onready var portrait: TextureRect = $Portrait

var active: bool = false
var exposure: float = 0.0
var away_seconds: float = 0.0
var grace_remaining: float = 0.0
var fade: Tween


func reset() -> void:
	if fade:
		fade.kill()
	active = false
	exposure = 0.0
	away_seconds = 0.0
	portrait.texture = poses[0]
	portrait.scale = Vector2.ONE
	portrait.modulate.a = 0.0
	hide()


func appear(hostile: bool = true) -> void:
	reset()
	active = hostile
	grace_remaining = appearance_grace
	show()
	fade = create_tween()
	fade.tween_property(portrait, "modulate:a", 1.0, 0.45)


func observe(looking: bool, delta: float) -> void:
	if not active:
		return
	grace_remaining = maxf(0.0, grace_remaining - delta)
	if grace_remaining > 0.0:
		return
	if looking:
		away_seconds = 0.0
		exposure = minf(1.0, exposure + delta / stare_seconds)
	else:
		away_seconds += delta
		exposure = maxf(0.0, exposure - delta / look_away_seconds)
		if away_seconds >= look_away_seconds:
			disappear(0.35)
			retreated.emit()
			return
	var pose_index := mini(int(exposure * poses.size()), poses.size() - 1)
	portrait.texture = poses[pose_index]
	portrait.scale = Vector2.ONE * lerpf(1.0, 1.12, exposure)
	if exposure >= 1.0:
		active = false
		attacked.emit()


func disappear(seconds: float) -> void:
	if fade:
		fade.kill()
	active = false
	exposure = 0.0
	fade = create_tween()
	fade.tween_property(portrait, "modulate:a", 0.0, seconds)
	fade.tween_callback(hide)
