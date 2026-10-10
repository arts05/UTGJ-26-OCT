extends Node3D
## The case lights reflect disk activity and the simulated restart sequence.

@export_group("Drive activity")
@export var idle_pause: Vector2 = Vector2(0.65, 1.2)
@export var idle_pulse_seconds: float = 0.12
@export var busy_pause: Vector2 = Vector2(0.025, 0.09)
@export var busy_pulse: Vector2 = Vector2(0.035, 0.08)
@export var drive_emission_energy: float = 2.5
@export var drive_light_energy: float = 0.0025

@export_group("Restart")
@export var restart_emission_energy: float = 2.0
@export var restart_light_energy: float = 0.0025

@onready var drive_material: StandardMaterial3D = $Drive/Lens.material_override
@onready var restart_material: StandardMaterial3D = $Restart/Lens.material_override
@onready var drive_light: OmniLight3D = $Drive/Light
@onready var restart_light: OmniLight3D = $Restart/Light

var drive_busy: bool = false
var restarting: bool = false
var drive_on: bool = false
var drive_brightness: float = 0.0
var seconds_to_toggle: float = 0.6


func _process(delta: float) -> void:
	if not restarting:
		seconds_to_toggle -= delta
		if seconds_to_toggle <= 0.0:
			drive_on = not drive_on
			if drive_on:
				seconds_to_toggle = idle_pulse_seconds
				if drive_busy:
					seconds_to_toggle = randf_range(busy_pulse.x, busy_pulse.y)
			else:
				var pause := busy_pause if drive_busy else idle_pause
				seconds_to_toggle = randf_range(pause.x, pause.y)

	var target_brightness := 1.0 if drive_on else 0.0
	drive_brightness = move_toward(drive_brightness, target_brightness, delta * 45.0)
	drive_material.emission_energy_multiplier = drive_brightness * drive_emission_energy
	drive_light.light_energy = drive_brightness * drive_light_energy


func set_drive_busy(busy: bool) -> void:
	drive_busy = busy
	seconds_to_toggle = 0.0


func set_restarting(active: bool) -> void:
	restarting = active
	drive_on = false
	drive_brightness = 0.0
	seconds_to_toggle = idle_pause.x
	drive_material.emission_energy_multiplier = 0.0
	drive_light.light_energy = 0.0
	restart_material.emission_energy_multiplier = restart_emission_energy if active else 0.0
	restart_light.light_energy = restart_light_energy if active else 0.0
