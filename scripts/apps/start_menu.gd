extends Control
## The desktop menu slides from the taskbar; its contents remain editor nodes.

signal toggled(opened: bool)
signal kalevav_requested
signal settings_requested

@export_range(0.05, 0.5) var opening_seconds: float = 0.22
@export_range(0.05, 0.5) var closing_seconds: float = 0.14
@export_range(0.0, 40.0) var slide_distance: float = 16.0

@onready var panel: Control = $MenuPosition/Panel

var is_open: bool = false
var transition: Tween


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	if not visible:
		panel.position = Vector2(0, slide_distance)
		panel.modulate.a = 0.0
	show()
	is_open = true
	_animate(Vector2.ZERO, 1.0, opening_seconds)
	toggled.emit(true)


func close(immediately: bool = false) -> void:
	if not visible:
		return
	var was_open := is_open
	is_open = false
	if immediately:
		if transition:
			transition.kill()
		hide()
	else:
		_animate(Vector2(0, slide_distance), 0.0, closing_seconds)
		transition.chain().tween_callback(hide)
	if was_open:
		toggled.emit(false)


func _animate(target_position: Vector2, target_alpha: float, seconds: float) -> void:
	if transition:
		transition.kill()
	transition = create_tween().set_parallel(true)
	transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	transition.tween_property(panel, "position", target_position, seconds)
	transition.tween_property(panel, "modulate:a", target_alpha, seconds)


func _on_outside_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not event.canceled:
			close()
			accept_event()


func _on_kalevav_pressed() -> void:
	close(true)
	kalevav_requested.emit()


func _on_settings_pressed() -> void:
	close(true)
	settings_requested.emit()
