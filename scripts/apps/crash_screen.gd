extends ColorRect

signal restarted
signal shutdown_started
signal screen_power_changed(powered_on: bool)

enum Phase { CRASH, SHUTDOWN, POWER_DOWN, BLACKOUT, BOOT, RESTORE }

const SHUTDOWN_ART: Texture2D = preload("res://assets/sprites/shutdownscreen.png")
const RESTART_ART: Texture2D = preload("res://assets/sprites/restart.png")

@export_range(0.1, 5.0) var crash_seconds: float = 2.0
# Leave time for the 3.2-second shutdown sound before the picture collapses.
@export_range(0.1, 10.0) var shutdown_seconds: float = 3.3
@export_range(0.1, 2.0) var power_down_seconds: float = 0.5
@export_range(0.1, 3.0) var blackout_seconds: float = 0.7
@export_range(1.0, 15.0) var reboot_seconds: float = 5.0
@export_range(0.1, 2.0) var restore_seconds: float = 0.5
@export_range(0.5, 3.0) var loading_cycle_seconds: float = 1.3

@onready var message: Label = $Message
@onready var artwork: TextureRect = $Artwork
@onready var signal_material: ShaderMaterial = $Artwork.material
@onready var loading_bar: Panel = $LoadingBar
@onready var loading_material: ShaderMaterial = $LoadingBar/Blocks.material

var phase: Phase = Phase.CRASH
var boot_elapsed: float = 0.0
var sequence: Tween


func _ready() -> void:
	set_process(false)


func restart() -> void:
	if sequence:
		sequence.kill()
	phase = Phase.CRASH
	artwork.texture = SHUTDOWN_ART
	artwork.scale = Vector2.ONE
	artwork.pivot_offset = artwork.size * 0.5
	artwork.modulate.a = 1.0
	message.text = "Restarting..."
	message.modulate.a = 1.0
	message.show()
	loading_bar.hide()
	_set_interference(1.0)
	set_process(false)

	sequence = create_tween()
	sequence.tween_method(_set_interference, 1.0, 0.15, crash_seconds)
	sequence.tween_callback(_begin_shutdown)
	sequence.tween_interval(shutdown_seconds)
	sequence.tween_callback(_begin_power_down)
	var collapse := sequence.tween_property(artwork, "scale:y", 0.008, power_down_seconds * 0.6)
	collapse.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	sequence.tween_property(artwork, "scale:x", 0.01, power_down_seconds * 0.4)
	sequence.tween_callback(_begin_blackout)
	sequence.tween_interval(blackout_seconds)
	sequence.tween_callback(_begin_boot)
	sequence.tween_property(artwork, "modulate:a", 1.0, reboot_seconds * 0.15)
	sequence.parallel().tween_property(loading_bar, "modulate:a", 1.0, reboot_seconds * 0.15)
	sequence.parallel().tween_property(message, "modulate:a", 1.0, reboot_seconds * 0.15)
	sequence.tween_interval(reboot_seconds * 0.85)
	sequence.tween_callback(_begin_restore)
	sequence.tween_property(artwork, "modulate:a", 0.0, restore_seconds)
	sequence.parallel().tween_property(loading_bar, "modulate:a", 0.0, restore_seconds)
	sequence.parallel().tween_property(message, "modulate:a", 0.0, restore_seconds)
	sequence.tween_callback(_finish_restart)


func _begin_shutdown() -> void:
	phase = Phase.SHUTDOWN
	message.text = "Shutting down..."
	_set_interference(0.0)
	shutdown_started.emit()


func _begin_power_down() -> void:
	phase = Phase.POWER_DOWN
	message.hide()
	_set_interference(0.0)


func _begin_blackout() -> void:
	phase = Phase.BLACKOUT
	artwork.modulate.a = 0.0
	screen_power_changed.emit(false)


func _begin_boot() -> void:
	phase = Phase.BOOT
	boot_elapsed = 0.0
	artwork.texture = RESTART_ART
	artwork.scale = Vector2.ONE
	loading_bar.modulate.a = 0.0
	loading_bar.show()
	loading_material.set_shader_parameter("travel", 0.0)
	message.text = "Starting..."
	message.modulate.a = 0.0
	message.show()
	set_process(true)
	screen_power_changed.emit(true)


func _process(delta: float) -> void:
	boot_elapsed += delta
	loading_material.set_shader_parameter("travel", boot_elapsed / loading_cycle_seconds)
	if phase == Phase.BOOT and boot_elapsed >= reboot_seconds * 0.75:
		message.text = "Restoring your session..."


func _begin_restore() -> void:
	phase = Phase.RESTORE


func _finish_restart() -> void:
	set_process(false)
	restarted.emit()


func _set_interference(amount: float) -> void:
	signal_material.set_shader_parameter("interference", amount)
