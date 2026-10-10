extends Node3D
## A room light pulse and a wisp drifting up behind the computer.

@export var flash_energy: float = 1.0
@export_range(0.5, 5.0) var release_seconds: float = 2.4
@export var drift_offset: Vector3 = Vector3(0.3, 0.65, -0.18)
@export_range(0.0, 1.0) var mist_opacity: float = 0.33

const FLASH_RISE_SECONDS: float = 0.08
const FLASH_FADE_START: float = 0.2
const FLASH_FADE_END: float = 1.1

@onready var flash_light: OmniLight3D = $FlashLight
@onready var mist: MeshInstance3D = $Mist
@onready var mist_material: ShaderMaterial = $Mist.material_override
@onready var mist_start_position: Vector3 = $Mist.position
@onready var mist_start_scale: Vector3 = $Mist.scale

var release_tween: Tween


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	# Draw the transparent mist once so its shader is ready before the first victory.
	mist.show()
	await RenderingServer.frame_post_draw
	mist.hide()


func play() -> void:
	if release_tween:
		release_tween.kill()
	mist.position = mist_start_position
	mist.scale = mist_start_scale
	mist.show()
	_set_effect_progress(0.0)

	var mist_end_position := mist_start_position + drift_offset
	var mist_end_scale := mist_start_scale * Vector3(1.6, 1.7, 1)
	release_tween = create_tween().set_parallel()
	release_tween.tween_property(mist, "position", mist_end_position, release_seconds)
	release_tween.tween_property(mist, "scale", mist_end_scale, release_seconds)
	release_tween.tween_method(_set_effect_progress, 0.0, 1.0, release_seconds)
	release_tween.chain().tween_callback(_finish)


func _set_effect_progress(progress: float) -> void:
	var elapsed := progress * release_seconds
	var flash_rise := smoothstep(0.0, FLASH_RISE_SECONDS, elapsed)
	var flash_fade := 1.0 - smoothstep(FLASH_FADE_START, FLASH_FADE_END, elapsed)
	flash_light.light_energy = flash_rise * flash_fade * flash_energy

	var fade_in := smoothstep(0.0, 0.12, progress)
	var fade_out := 1.0 - smoothstep(0.2, 1.0, progress)
	mist_material.set_shader_parameter("opacity", fade_in * fade_out * mist_opacity)


func _finish() -> void:
	flash_light.light_energy = 0.0
	mist.hide()
