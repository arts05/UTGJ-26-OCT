extends TextureRect
## A little life for Kratt, without moving the speech bubble or its button.

@export_range(0.0, 12.0) var float_height: float = 6.0
@export_range(2.0, 8.0) var float_period: float = 4.2
@export_range(0.0, 3.0) var sway_degrees: float = 0.8

var resting_position := Vector2.ZERO
var elapsed: float = 0.0
var hover_amount: float = 0.0
var reaction: float = 0.0
var reaction_tween: Tween


func _ready() -> void:
	resting_position = position
	pivot_offset = size * Vector2(0.5, 0.75)


func _process(delta: float) -> void:
	elapsed += delta
	var hovered := Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())
	hover_amount = lerpf(hover_amount, float(hovered), 1.0 - exp(-10.0 * delta))
	var phase := elapsed * TAU / float_period
	position = resting_position + Vector2(sin(phase * 0.7) * 2.0, sin(phase) * float_height - reaction * 7.0)
	rotation_degrees = sin(phase * 0.8) * sway_degrees + hover_amount * 1.2
	scale = Vector2.ONE * (1.0 + hover_amount * 0.025 + reaction * 0.025)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if reaction_tween:
			reaction_tween.kill()
		reaction_tween = create_tween()
		reaction_tween.tween_property(self, "reaction", 1.0, 0.1)
		reaction_tween.tween_property(self, "reaction", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
		accept_event()
