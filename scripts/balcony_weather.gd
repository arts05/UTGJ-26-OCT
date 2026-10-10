extends Node3D
## Spaces out the soft lightning pulses. Snow and lights are saved scene nodes.

@export_range(5.0, 120.0) var minimum_lightning_delay: float = 18.0
@export_range(5.0, 120.0) var maximum_lightning_delay: float = 38.0

@onready var lightning_timer: Timer = $LightningTimer
@onready var lightning: AnimationPlayer = $Lightning


func _ready() -> void:
	_schedule_lightning()


func _schedule_lightning() -> void:
	lightning_timer.start(randf_range(minimum_lightning_delay, maximum_lightning_delay))


func _on_lightning_timer_timeout() -> void:
	lightning.play(&"flash")


func _on_lightning_finished(animation_name: StringName) -> void:
	if animation_name == &"flash":
		_schedule_lightning()
