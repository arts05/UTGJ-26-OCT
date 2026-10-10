extends Camera3D

signal computer_focus_changed(focused: bool)

enum ViewMode { ROOM, MOVING, COMPUTER }

@export var room_view: Marker3D
@export var computer_view: Marker3D
@export var computer: Node3D
@export var zoom_duration: float = 0.6

@export_group("Seated look")
@export var mouse_sensitivity: float = 0.12
@export var look_limit_degrees: float = 65.0
@export_range(0.0, 35.0) var look_up_degrees: float = 18.0
@export_range(0.0, 35.0) var look_down_degrees: float = 22.0
@export_range(1.0, 30.0) var look_smoothing: float = 14.0

@export_group("Subtle head motion")
@export_range(0.0, 1.0) var head_roll_degrees: float = 0.3
@export_range(0.0, 0.01, 0.0005) var breathing_height: float = 0.002
@export_range(2.0, 8.0) var breathing_period: float = 4.8

var view_mode: ViewMode = ViewMode.ROOM
var look_yaw_degrees: float = 0.0
var look_pitch_degrees: float = 0.0
var target_yaw_degrees: float = 0.0
var target_pitch_degrees: float = 0.0
var current_roll_degrees: float = 0.0
var breathing_time: float = 0.0
var room_motion_weight: float = 1.0
var view_transform: Transform3D
var returning_to_room: bool = false


func _ready() -> void:
	view_transform = room_view.global_transform
	_apply_view()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_window().focus_exited.connect(_on_window_focus_exited)


func _process(delta: float) -> void:
	# Exponential smoothing feels the same at different frame rates.
	var weight := 1.0 - exp(-look_smoothing * delta)
	look_yaw_degrees = lerpf(look_yaw_degrees, target_yaw_degrees, weight)
	look_pitch_degrees = lerpf(look_pitch_degrees, target_pitch_degrees, weight)
	var turn_lean := clampf((target_yaw_degrees - look_yaw_degrees) * 0.05, -1.0, 1.0)
	current_roll_degrees = lerpf(current_roll_degrees, turn_lean * head_roll_degrees, weight)
	breathing_time += delta
	_apply_view()


func _unhandled_input(event: InputEvent) -> void:
	if view_mode == ViewMode.MOVING and not returning_to_room:
		return

	if event.is_action_pressed("leave_computer"):
		if view_mode == ViewMode.COMPUTER:
			_move_to_view(room_view, ViewMode.ROOM)
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
			var aim_position: Vector2 = event.position
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				aim_position = get_viewport().get_visible_rect().get_center()
			if view_mode == ViewMode.ROOM and computer.is_monitor_at(aim_position):
				_move_to_view(computer_view, ViewMode.COMPUTER)
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_look_around(event.screen_relative)
			get_viewport().set_input_as_handled()


func _look_around(movement: Vector2) -> void:
	target_yaw_degrees = clampf(
		target_yaw_degrees - movement.x * mouse_sensitivity,
		-look_limit_degrees, look_limit_degrees
	)
	target_pitch_degrees = clampf(
		target_pitch_degrees - movement.y * mouse_sensitivity,
		-look_down_degrees, look_up_degrees
	)


func _apply_view() -> void:
	# Zoom moves the base view; mouse-look remains a separate rotation offset.
	global_transform = view_transform
	# Turn around the room's vertical axis so looking sideways keeps the horizon level.
	global_basis = Basis(Vector3.UP, deg_to_rad(look_yaw_degrees)) * view_transform.basis
	rotate_object_local(Vector3.RIGHT, deg_to_rad(look_pitch_degrees))
	rotate_object_local(Vector3.BACK, deg_to_rad(current_roll_degrees * room_motion_weight))
	var breath := sin(breathing_time * TAU / breathing_period) * breathing_height
	global_position.y += breath * room_motion_weight


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
	look_pitch_degrees = 0.0
	target_yaw_degrees = 0.0
	target_pitch_degrees = 0.0
	current_roll_degrees = 0.0
	room_motion_weight = 0.0

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "view_transform", target.global_transform, zoom_duration)
	if returning_to_room:
		tween.tween_property(self, "room_motion_weight", 1.0, zoom_duration)
	await tween.finished

	returning_to_room = false
	view_mode = next_mode
	computer_focus_changed.emit(view_mode == ViewMode.COMPUTER)


func _on_window_focus_exited() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	target_yaw_degrees = look_yaw_degrees
	target_pitch_degrees = look_pitch_degrees
