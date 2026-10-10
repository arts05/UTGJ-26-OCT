extends Control

signal failed
signal closed

@export_range(1, 10) var contacts_before_crash: int = 4
@export var initial_visibility: float = 300.0
@export var minimum_visibility: float = 85.0

@onready var player = $GameView/HouseViewport/House/Player
@onready var ghost = $GameView/HouseViewport/House/Ghost
@onready var spawn: Marker2D = $GameView/HouseViewport/House/PlayerSpawn
@onready var darkness: ColorRect = $Darkness

var contact_count: int = 0
var visibility_radius: float = 300.0
var target_visibility: float = 300.0
var encounter_failed: bool = false


func _ready() -> void:
	ghost.touched_player.connect(_on_ghost_contact)
	reset()


func reset() -> void:
	contact_count = 0
	encounter_failed = false
	visibility_radius = initial_visibility
	target_visibility = initial_visibility
	player.position = spawn.position
	player.set_controls_enabled(false)
	ghost.reset()
	darkness.material.set_shader_parameter("view_size", darkness.size)
	darkness.material.set_shader_parameter("radius", visibility_radius)


func set_computer_focused(focused: bool) -> void:
	player.set_controls_enabled(focused)


func _process(delta: float) -> void:
	visibility_radius = move_toward(visibility_radius, target_visibility, delta * 180.0)
	darkness.material.set_shader_parameter("radius", visibility_radius)
	if target_visibility == 0.0 and visibility_radius == 0.0 and not encounter_failed:
		encounter_failed = true
		player.set_controls_enabled(false)
		failed.emit()


func _on_ghost_contact() -> void:
	if encounter_failed:
		return
	contact_count += 1
	if contact_count >= contacts_before_crash:
		target_visibility = 0.0
	else:
		var damage := float(contact_count) / contacts_before_crash
		target_visibility = lerpf(initial_visibility, minimum_visibility, damage)


func _on_close_pressed() -> void:
	player.set_controls_enabled(false)
	closed.emit()
