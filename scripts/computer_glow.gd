class_name ComputerGlow
extends Node3D
## Shader-driven orange backglow for the computer's bad-ending shutdown.

@export var backlight_energy: float = 1.4
@export var backlight_range: float = 2.6
@export var desk_light_energy: float = 0.65

var glow_strength: float = 0.0
var elapsed: float = 0.0
var halo_material: ShaderMaterial
var backlight: OmniLight3D
var desk_light: OmniLight3D


func _ready() -> void:
	var halo := MeshInstance3D.new()
	halo.name = "OrangeHalo"
	halo.position = Vector3(0.0, 0.08, -0.24)
	var halo_quad := QuadMesh.new()
	halo_quad.size = Vector2(1.12, 0.88)
	halo.mesh = halo_quad
	halo_material = ShaderMaterial.new()
	halo_material.shader = load("res://shaders/computer_glow.gdshader") as Shader
	halo_material.set_shader_parameter("glow_strength", 0.0)
	halo.material_override = halo_material
	add_child(halo)

	backlight = OmniLight3D.new()
	backlight.name = "OrangeBacklight"
	backlight.position = Vector3(0.0, 0.12, -0.12)
	backlight.light_color = Color(1.0, 0.2, 0.035)
	backlight.light_energy = 0.0
	backlight.light_cull_mask = 3
	backlight.omni_range = backlight_range
	backlight.shadow_enabled = true
	add_child(backlight)

	# Bounce a softer orange light onto the desk below and in front of the CRT.
	desk_light = OmniLight3D.new()
	desk_light.name = "DeskBounce"
	desk_light.position = Vector3(0.0, -0.2, 0.08)
	desk_light.light_color = Color(1.0, 0.31, 0.075)
	desk_light.light_energy = 0.0
	desk_light.light_cull_mask = 1
	desk_light.omni_range = 1.8
	add_child(desk_light)
	set_process(false)


func start_glow() -> void:
	if is_processing():
		return
	set_process(true)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "glow_strength", 1.0, 1.4)


func stop_glow(fade_seconds: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "glow_strength", 0.0, fade_seconds)
	tween.finished.connect(_finish_glow)


func _process(delta: float) -> void:
	elapsed += delta
	var flicker := 0.94 + 0.06 * sin(elapsed * 8.0) + 0.025 * sin(elapsed * 19.0)
	backlight.light_energy = backlight_energy * glow_strength * flicker
	desk_light.light_energy = desk_light_energy * glow_strength * flicker
	halo_material.set_shader_parameter("glow_strength", glow_strength * flicker)


func _finish_glow() -> void:
	backlight.light_energy = 0.0
	desk_light.light_energy = 0.0
	halo_material.set_shader_parameter("glow_strength", 0.0)
	set_process(false)
