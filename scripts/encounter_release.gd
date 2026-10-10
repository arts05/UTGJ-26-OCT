extends Node
## One physical release sequence shared by all three successful encounters.

signal finished

@export var camera: Camera3D
@export var computer: Node3D
@export var pc_case: Node3D
@export var ghost_release: Node3D

@export_group("Timing")
@export_range(0.0, 2.0) var anticipation_seconds: float = 0.5
@export_range(0.5, 3.0) var buildup_seconds: float = 1.0
@export_range(0.1, 0.5) var pullback_seconds: float = 0.35
@export_range(0.2, 3.0) var recovery_seconds: float = 1.0

@export_group("Shake")
@export_range(0.0, 0.02, 0.001) var movement_amount: float = 0.006
@export_range(0.0, 2.0) var rotation_degrees: float = 0.6
@export_range(0.0, 20.0) var screen_pixels: float = 6.0

const SETTLE_SECONDS: float = 0.2

var running: bool = false
var shake_strength: float = 0.0
var shake_time: float = 0.0
var computer_rest: Transform3D
var case_rest: Transform3D
var desktop_rest: Vector2
var sequence: Tween


func _ready() -> void:
	set_process(false)


func play() -> void:
	if running:
		return
	running = true
	set_process(true)
	computer_rest = computer.transform
	case_rest = pc_case.transform
	desktop_rest = computer.desktop.position
	shake_time = 0.0
	shake_strength = 0.0
	camera.set_controls_locked(true)

	sequence = create_tween()
	sequence.tween_interval(anticipation_seconds)
	sequence.tween_callback(_begin_shaking)
	sequence.tween_property(self, "shake_strength", 1.0, buildup_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sequence.tween_callback(ghost_release.play)
	sequence.tween_property(self, "shake_strength", 0.0, SETTLE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sequence.tween_callback(_restore_positions)
	sequence.tween_interval(recovery_seconds - SETTLE_SECONDS)
	sequence.tween_callback(_finish)


func _begin_shaking() -> void:
	shake_strength = 0.2
	camera.pull_back(pullback_seconds)


func _process(delta: float) -> void:
	if not running or shake_strength <= 0.0:
		return
	shake_time += delta
	# Layer two small oscillations so the rumble doesn't depend on frame rate.
	var horizontal := sin(shake_time * 91.0) + sin(shake_time * 143.0) * 0.35
	var vertical := cos(shake_time * 77.0) * 0.4
	var movement := Vector3(horizontal, vertical, 0.0) * movement_amount * shake_strength
	var tilt := sin(shake_time * 83.0) * deg_to_rad(rotation_degrees) * shake_strength

	computer.transform = computer_rest
	computer.position += movement
	computer.basis = Basis(Vector3.BACK, tilt) * computer_rest.basis
	pc_case.transform = case_rest
	pc_case.position -= movement * 0.7
	pc_case.basis = Basis(Vector3.BACK, -tilt * 0.7) * case_rest.basis
	computer.desktop.position = desktop_rest + Vector2(horizontal, vertical) * screen_pixels * shake_strength


func _restore_positions() -> void:
	computer.transform = computer_rest
	pc_case.transform = case_rest
	computer.desktop.position = desktop_rest


func _finish() -> void:
	running = false
	set_process(false)
	camera.set_controls_locked(false)
	finished.emit()
