extends Control
## The three authored portraits share a brief, broken-signal transition.

@export var hold_seconds: Vector2 = Vector2(3.5, 6.0)
@export_range(0.0, 1.0) var glitch_strength: float = 0.9
@export_range(0.1, 0.8) var settle_seconds: float = 0.26
@export var drift_pixels: Vector2 = Vector2(5.0, 3.0)

@onready var portrait_layer: Control = $Portraits
@onready var portraits: Array[Node] = $Portraits.get_children()
@onready var change_timer: Timer = $ChangeTimer
@onready var portrait_material: ShaderMaterial = $Portraits/Kalevipoeg.material

var current_portrait: int = 0
var interference: float = 0.0
var elapsed: float = 0.0
var quiet: bool = false
var transition: Tween
var dimming: Tween


func _ready() -> void:
	_show_portrait(current_portrait)
	_schedule_change()


func _process(delta: float) -> void:
	elapsed += delta
	portrait_layer.position = Vector2(sin(elapsed * 0.23), sin(elapsed * 0.31)) * drift_pixels
	portrait_material.set_shader_parameter("interference", 0.0 if quiet else interference)


func set_quiet(enabled: bool) -> void:
	quiet = enabled
	change_timer.paused = enabled
	if transition and transition.is_valid():
		if enabled:
			transition.pause()
		else:
			transition.play()
	if dimming:
		dimming.kill()
	dimming = create_tween()
	dimming.tween_property(self, "modulate:a", 0.18 if enabled else 1.0, 0.3)


func _on_change_timer_timeout() -> void:
	var previous := current_portrait
	var next := (current_portrait + 1) % portraits.size()
	transition = create_tween()
	transition.tween_property(self, "interference", glitch_strength, 0.045)
	transition.tween_callback(_show_portrait.bind(next))
	transition.tween_interval(0.065)
	transition.tween_callback(_show_portrait.bind(previous))
	transition.tween_interval(0.045)
	transition.tween_callback(_show_portrait.bind(next))
	transition.tween_property(self, "interference", 0.0, settle_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	transition.tween_callback(_schedule_change)


func _show_portrait(index: int) -> void:
	for portrait: TextureRect in portraits:
		portrait.hide()
	current_portrait = index
	portraits[index].show()


func _schedule_change() -> void:
	change_timer.start(randf_range(hold_seconds.x, hold_seconds.y))
