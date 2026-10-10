extends ColorRect

signal restarted

const SHUTDOWN_ART: Texture2D = preload("res://assets/sprites/shutdownscreen.png")
const RESTART_ART: Texture2D = preload("res://assets/sprites/restart.png")

@export_range(0.1, 5.0) var crash_seconds: float = 1.2
@export_range(0.1, 5.0) var reboot_seconds: float = 1.6

@onready var message: Label = $Message
@onready var artwork: TextureRect = $Artwork
@onready var signal_material: ShaderMaterial = $Artwork.material

var elapsed_seconds: float = 0.0


func _ready() -> void:
	set_process(false)


func restart() -> void:
	elapsed_seconds = 0.0
	artwork.texture = SHUTDOWN_ART
	message.text = "Restarting..."
	signal_material.set_shader_parameter("interference", 1.0)
	set_process(true)


func _process(delta: float) -> void:
	elapsed_seconds += delta
	var interference := maxf(0.0, 1.0 - elapsed_seconds / (crash_seconds * 0.65))
	if elapsed_seconds >= crash_seconds:
		artwork.texture = RESTART_ART
		message.text = "Starting..."
		var reboot_elapsed := elapsed_seconds - crash_seconds
		interference = maxf(0.0, 1.0 - reboot_elapsed / (reboot_seconds * 0.35)) * 0.18
	signal_material.set_shader_parameter("interference", interference)
	if elapsed_seconds >= crash_seconds + reboot_seconds:
		set_process(false)
		restarted.emit()
