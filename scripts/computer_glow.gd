class_name ComputerGlow
extends Node3D
## Fire, smoke, and orange light from the failing CRT. All emitters live in the scene.

@export var backlight_energy: float = 1.4
@export var desk_light_energy: float = 0.65

@onready var halo_material: ShaderMaterial = $OrangeHalo.material_override
@onready var backlight: OmniLight3D = $OrangeBacklight
@onready var desk_light: OmniLight3D = $DeskBounce
@onready var flames: CPUParticles3D = $Flames
@onready var smoke: CPUParticles3D = $Smoke
@onready var pop_smoke: CPUParticles3D = $PopSmoke
@onready var flame_material: ShaderMaterial = flames.mesh.material
@onready var smoke_material: ShaderMaterial = smoke.mesh.material

var glow_strength: float = 0.0
var elapsed: float = 0.0
var buildup: Tween


func _ready() -> void:
	reset()


func play_pop_puff() -> void:
	show()
	pop_smoke.restart()
	pop_smoke.emitting = true


func start_glow(buildup_seconds: float = 1.4) -> void:
	if buildup != null:
		buildup.kill()
	elapsed = 0.0
	flame_material.set_shader_parameter("emitter_origin", flames.global_position)
	smoke_material.set_shader_parameter("emitter_origin", smoke.global_position)
	show()
	flames.restart()
	smoke.restart()
	flames.emitting = true
	smoke.emitting = true
	set_process(true)
	buildup = create_tween()
	buildup.tween_property(self, "glow_strength", 1.0, buildup_seconds)


func reset() -> void:
	if buildup != null:
		buildup.kill()
	glow_strength = 0.0
	backlight.light_energy = 0.0
	desk_light.light_energy = 0.0
	halo_material.set_shader_parameter("glow_strength", 0.0)
	flame_material.set_shader_parameter("burn_strength", 0.0)
	smoke_material.set_shader_parameter("burn_strength", 0.0)
	flames.emitting = false
	smoke.emitting = false
	pop_smoke.emitting = false
	hide()
	set_process(false)


func _process(delta: float) -> void:
	elapsed += delta
	var flicker := 0.94 + 0.06 * sin(elapsed * 8.0) + 0.025 * sin(elapsed * 19.0)
	backlight.light_energy = backlight_energy * glow_strength * flicker
	desk_light.light_energy = desk_light_energy * glow_strength * flicker
	halo_material.set_shader_parameter("glow_strength", glow_strength * flicker)
	flame_material.set_shader_parameter("burn_strength", glow_strength)
	smoke_material.set_shader_parameter("burn_strength", glow_strength)
