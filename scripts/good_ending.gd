extends Node3D
## The final release, shoulder touch, and camera turn before the shared credits.

signal title_reached

@export var player_camera: Camera3D
@export var ghost_release: Node3D
@export var credits: EndingCredits

@export_group("Cinematic timing")
@export_range(0.1, 1.0) var pullback_seconds: float = 0.45
@export_range(1.0, 5.0) var approach_seconds: float = 2.6
@export_range(0.3, 2.0) var reach_seconds: float = 0.85
@export_range(0.0, 1.0) var touch_pause_seconds: float = 0.3
@export_range(0.1, 1.0) var turn_seconds: float = 0.32
@export_range(0.5, 3.0) var face_hold_seconds: float = 1.0

@export_group("Shoulder contact")
## The hand reaches its resting pose at 80% of the shoulder-touch animation.
@export_range(0.0, 1.0, 0.01) var shoulder_contact_progress: float = 0.8

@onready var camera: Camera3D = $EndingCamera
@onready var seated_view: Marker3D = $SeatedView
@onready var shoulder_view: Marker3D = $ShoulderView
@onready var reveal_view: Marker3D = $RevealView
@onready var actor: Node3D = $Kalev
@onready var animation: AnimationPlayer = $Kalev/AnimationPlayer
@onready var footsteps: AudioStreamPlayer3D = $Footsteps
@onready var footstep_timing: AnimationPlayer = $FootstepTiming
@onready var shoulder_pat: AudioStreamPlayer3D = $ShoulderPat
@onready var approach_start: Marker3D = $ApproachStart
@onready var approach_end: Marker3D = $ApproachEnd
@onready var reveal_light: OmniLight3D = $RevealLight

var running: bool = false
var sequence: Tween


func warm_up_visuals() -> void:
	# Render the face and skinned model in the hidden loading viewport, so their
	# first appearance does not compile shaders during the camera turn on Web.
	camera.global_transform = reveal_view.global_transform
	camera.make_current()
	actor.show()
	reveal_light.show()
	animation.play("shoulder_touch")
	animation.seek(animation.current_animation_length, true)
	animation.pause()
	for frame in 2:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	animation.play("RESET")
	animation.advance(0.0)
	animation.stop()
	actor.hide()
	reveal_light.hide()
	player_camera.make_current()


func play() -> void:
	if running:
		return
	running = true
	player_camera.set_controls_locked(true)
	camera.global_transform = player_camera.global_transform
	camera.fov = player_camera.fov
	camera.make_current()
	actor.show()
	reveal_light.show()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	sequence = create_tween()
	sequence.tween_property(camera, "global_transform", seated_view.global_transform, pullback_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sequence.tween_callback(ghost_release.play)
	sequence.tween_interval(ghost_release.release_seconds)
	# Clear the release sound before the footsteps become the focus.
	sequence.tween_property(ghost_release.release_sound, "volume_db", -60.0, 0.4)
	sequence.tween_callback(ghost_release.release_sound.stop)
	sequence.tween_callback(_begin_approach)
	sequence.tween_property(footsteps, "global_position", approach_end.global_position, approach_seconds)
	sequence.tween_callback(_reach_shoulder)
	sequence.tween_property(camera, "global_transform", shoulder_view.global_transform, reach_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence.parallel().tween_callback(shoulder_pat.play).set_delay(reach_seconds * shoulder_contact_progress)
	sequence.tween_interval(touch_pause_seconds)
	# Turn up and right, hold on the face, then cut directly to the title card.
	sequence.tween_property(camera, "global_transform", reveal_view.global_transform, turn_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	sequence.tween_interval(face_hold_seconds)
	sequence.tween_callback(_cut_to_title)


func _begin_approach() -> void:
	footsteps.global_position = approach_start.global_position
	# Retiming the animation changes the cadence without changing the sound's pitch.
	var approach: Animation = footstep_timing.get_animation("approach")
	footstep_timing.play("approach", -1.0, approach.length / approach_seconds)


func _reach_shoulder() -> void:
	footstep_timing.stop()
	footsteps.stop()
	var reach: Animation = animation.get_animation("shoulder_touch")
	animation.play("shoulder_touch", -1.0, reach.length / reach_seconds)


func _cut_to_title() -> void:
	actor.hide()
	reveal_light.hide()
	credits.play()
	title_reached.emit()


func _exit_tree() -> void:
	footstep_timing.stop()
	footsteps.stop()
	shoulder_pat.stop()
