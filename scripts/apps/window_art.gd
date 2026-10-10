extends Control
## A movable art preview while the OS design is being developed.

var dragging: bool = false
var drag_offset := Vector2.ZERO


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed and not event.canceled
		if dragging:
			drag_offset = event.global_position - position
		accept_event()

	if event is InputEventMouseMotion and dragging:
		var desktop_size := get_parent_control().size
		position = (event.global_position - drag_offset).clamp(
			Vector2.ZERO, desktop_size - size
		)
		accept_event()
