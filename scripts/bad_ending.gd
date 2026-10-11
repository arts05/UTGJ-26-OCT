extends Node3D
## The computer burns out through the full sound clip, then cuts to shared credits.

@export var player_camera: Camera3D
@export var computer: Node3D
@export var case_lights: Node3D
@export var credits: EndingCredits

@export_group("Timing")
@export_range(0.0, 1.0) var anticipation_seconds: float = 0.4
@export_range(1.0, 10.0) var failure_seconds: float = 6.0
@export_range(0.3, 2.0) var pullback_seconds: float = 0.9
@export_range(0.0, 2.0) var pullback_delay_seconds: float = 0.25
@export_range(0.2, 1.5) var collapse_seconds: float = 0.65

@export_group("Sound cues")
## Seconds into the pop-and-fire clip. The burning sound starts around 4 seconds.
@export_range(0.0, 10.0) var fire_start_seconds: float = 4.0
@export_range(0.0, 10.0) var alarm_start_seconds: float = 6.0

@export_group("Shake")
@export_range(0.0, 0.015, 0.0005) var camera_shake_amount: float = 0.004

@onready var glow: ComputerGlow = computer.get_node("FailureGlow")
@onready var screen_material: ShaderMaterial = computer.get_node("Model/Screen").material_override
@onready var screen_light: OmniLight3D = computer.get_node("ScreenSpill")
@onready var crt_loop: AudioStreamPlayer3D = computer.get_node("Audio/CRTLoop")
@onready var fire_sound: AudioStreamPlayer3D = $FireSound
@onready var alarm: AudioStreamPlayer3D = $SmokeAlarm
@onready var burning_view: Marker3D = $BurningView

var running: bool = false
var shake_strength: float = 0.0
var shake_time: float = 0.0
var sequence: Tween


func _ready() -> void:
	set_process(false)


func warm_up_visuals() -> void:
	# Compile the fire particles and extra light variants before the player starts.
	# This runs only in the existing hidden loading viewport, without any audio.
	glow.start_glow(0.01)
	glow.play_pop_puff()
	for frame in 3:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	glow.reset()


func play() -> void:
	if running:
		return
	running = true
	player_camera.set_controls_locked(true)
	if get_window().has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_process(true)

	sequence = create_tween()
	sequence.tween_interval(anticipation_seconds)
	sequence.tween_callback(_start_failure)
	sequence.tween_method(_set_failure, 0.0, 1.0, failure_seconds)
	sequence.parallel().tween_property(self, "shake_strength", 0.08, failure_seconds).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	sequence.parallel().tween_callback(player_camera.pull_back.bind(pullback_seconds, burning_view)).set_delay(pullback_delay_seconds)
	sequence.parallel().tween_callback(_start_fire).set_delay(fire_start_seconds)
	sequence.parallel().tween_callback(alarm.play).set_delay(alarm_start_seconds)
	sequence.tween_method(_set_shutdown, 0.0, 1.0, collapse_seconds)
	sequence.parallel().tween_property(screen_light, "power", 0.0, collapse_seconds)
	sequence.parallel().tween_property(crt_loop, "volume_db", -60.0, collapse_seconds)
	sequence.parallel().tween_property(self, "shake_strength", 0.0, collapse_seconds)
	sequence.tween_callback(_power_off)
	# FireSound.finished makes the hard cut; the recording always plays in full.


func _start_failure() -> void:
	shake_strength = 1.0
	fire_sound.play()
	glow.play_pop_puff()
	case_lights.set_restarting(true)


func _start_fire() -> void:
	# Grow for the rest of the recording, reaching full intensity at the title cut.
	var buildup_seconds := maxf(fire_sound.stream.get_length() - fire_start_seconds, 0.1)
	glow.start_glow(buildup_seconds)


func _process(delta: float) -> void:
	shake_time += delta
	# Camera offsets do not fight the separate pullback tween or seated look motion.
	player_camera.h_offset = sin(shake_time * 71.0) * camera_shake_amount * shake_strength
	player_camera.v_offset = cos(shake_time * 89.0) * camera_shake_amount * shake_strength * 0.6


func _set_failure(strength: float) -> void:
	screen_material.set_shader_parameter("failure_strength", strength)


func _set_shutdown(progress: float) -> void:
	screen_material.set_shader_parameter("shutdown_progress", progress)


func _power_off() -> void:
	crt_loop.stop()
	case_lights.power_off()
	player_camera.h_offset = 0.0
	player_camera.v_offset = 0.0
	set_process(false)


func _on_fire_sound_finished() -> void:
	sequence.kill()
	_power_off()
	alarm.stop()
	glow.reset()
	credits.play()


func _exit_tree() -> void:
	fire_sound.stop()
	alarm.stop()
