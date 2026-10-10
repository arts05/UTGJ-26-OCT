class_name ContainmentTask
extends Control

signal finished(success: bool)

@export_range(1, 20, 1) var captures_required: int = 5
@export_range(1.0, 60.0, 0.5) var time_limit_seconds: float = 15.0

@onready var instructions: Label = $Instructions
@onready var status_label: Label = $StatusLabel
@onready var play_area: Control = $PlayArea
@onready var target: Button = $PlayArea/SignalTarget
@onready var move_timer: Timer = $MoveTimer

var running: bool = false
var captures: int = 0
var remaining_seconds: float = 0.0


func _ready() -> void:
	set_process(false)


func start() -> void:
	captures = 0
	remaining_seconds = time_limit_seconds
	running = true
	target.disabled = false
	instructions.text = "Click the moving signal %d times before time runs out." % captures_required
	show()
	_update_status()
	_move_target()
	move_timer.start()
	set_process(true)


func _process(delta: float) -> void:
	remaining_seconds = maxf(remaining_seconds - delta, 0.0)
	_update_status()
	if remaining_seconds <= 0.0:
		_finish(false)


func _on_signal_target_pressed() -> void:
	if not running:
		return

	captures += 1
	_update_status()
	if captures >= captures_required:
		_finish(true)
		return

	_move_target()
	move_timer.start()


func _move_target() -> void:
	var maximum_position := play_area.size - target.size
	target.position = Vector2(
		randf_range(0.0, maximum_position.x),
		randf_range(0.0, maximum_position.y)
	)


func _update_status() -> void:
	status_label.text = "Captured: %d / %d     Time: %d s" % [
		captures, captures_required, ceili(remaining_seconds)
	]


func _finish(success: bool) -> void:
	running = false
	set_process(false)
	move_timer.stop()
	target.disabled = true
	finished.emit(success)
