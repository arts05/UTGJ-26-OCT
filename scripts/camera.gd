extends Camera3D

signal computer_focus_changed(focused: bool)

enum ViewMode { ROOM, MOVING, COMPUTER }

@export var room_view: Marker3D
@export var computer_view: Marker3D
@export var zoom_duration: float = 0.6
@export var mouse_sensitivity: float = 0.12
@export var look_limit_degrees: float = 65.0

var view_mode: ViewMode = ViewMode.ROOM
var look_yaw_degrees: float = 0.0
var view_transform: Transform3D
var returning_to_room: bool = false


func _ready() -> void:
	_apply_view(room_view.global_transform)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_window().focus_exited.connect(_on_window_focus_exited)


func _unhandled_input(event: InputEvent) -> void:
	if view_mode == ViewMode.MOVING and not returning_to_room:
		return

	if event.is_action_pressed("leave_computer"):
		if view_mode == ViewMode.COMPUTER:
			_move_to_view(room_view, ViewMode.ROOM)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("focus_computer") and view_mode == ViewMode.ROOM:
		_move_to_view(computer_view, ViewMode.COMPUTER)
		get_viewport().set_input_as_handled()
		return

	if view_mode != ViewMode.ROOM and not returning_to_room:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_look_around(event.screen_relative.x)


func _look_around(horizontal_movement: float) -> void:
	look_yaw_degrees -= horizontal_movement * mouse_sensitivity
	look_yaw_degrees = clampf(
		look_yaw_degrees, -look_limit_degrees, look_limit_degrees
	)

	_apply_view(view_transform)


func _apply_view(base_transform: Transform3D) -> void:
	# Zoom moves the base view; mouse-look remains a separate rotation offset.
	view_transform = base_transform
	global_transform = view_transform
	rotate_object_local(Vector3.UP, deg_to_rad(look_yaw_degrees))


func _move_to_view(target: Marker3D, next_mode: ViewMode) -> void:
	view_mode = ViewMode.MOVING
	returning_to_room = next_mode == ViewMode.ROOM
	computer_focus_changed.emit(false)

	# Capture during the key event, rather than after the animation completes.
	if returning_to_room:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	view_transform = global_transform
	look_yaw_degrees = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_apply_view, view_transform, target.global_transform, zoom_duration)
	await tween.finished

	returning_to_room = false
	view_mode = next_mode
	computer_focus_changed.emit(view_mode == ViewMode.COMPUTER)


func _on_window_focus_exited() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
