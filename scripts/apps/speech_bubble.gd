extends Control

signal action_pressed

@export var tail_above: bool = false
@export_range(0.0, 1.5) var reveal_seconds: float = 0.7

@onready var panel: PanelContainer = $Panel
@onready var tail: Polygon2D = $Tail
@onready var message: Label = $Panel/Margins/Stack/Message
@onready var action_button: Button = $Panel/Margins/Stack/Actions/ActionButton

var reveal_tween: Tween
var entrance_tween: Tween


func _ready() -> void:
	panel.resized.connect(_fit_to_text)
	visibility_changed.connect(_on_visibility_changed)
	_fit_to_text()


func say(text: String, button_text: String = "") -> void:
	message.text = text
	action_button.text = button_text
	action_button.get_parent().visible = not button_text.is_empty()
	# Let the container shrink as well as grow when the next line is shorter.
	panel.offset_bottom = 0.0
	if reveal_tween:
		reveal_tween.kill()
	message.visible_ratio = 0.0
	reveal_tween = create_tween()
	reveal_tween.tween_property(message, "visible_ratio", 1.0, reveal_seconds)


func _fit_to_text() -> void:
	size.y = panel.size.y
	tail.position = Vector2(size.x * 0.6, 0.0 if tail_above else size.y)
	tail.scale.y = -1.0 if tail_above else 1.0
	pivot_offset = tail.position


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	if entrance_tween:
		entrance_tween.kill()
	scale = Vector2.ONE * 0.96
	modulate.a = 0.0
	entrance_tween = create_tween().set_parallel(true)
	entrance_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance_tween.tween_property(self, "scale", Vector2.ONE, 0.22)
	entrance_tween.tween_property(self, "modulate:a", 1.0, 0.18)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if reveal_tween:
			reveal_tween.kill()
		message.visible_ratio = 1.0
		accept_event()


func _on_action_pressed() -> void:
	action_pressed.emit()
