extends Node3D
## Keeps the connections between the desktop and the room effects together.

@onready var desktop = $Computer/ComputerViewport/Desktop
@onready var case_lights = $Room/PCCase/StatusLights
@onready var ghost_release = $Room/GhostRelease


func _ready() -> void:
	desktop.drive_activity_changed.connect(case_lights.set_drive_busy)
	desktop.restart_state_changed.connect(case_lights.set_restarting)
	desktop.encounter_won.connect(ghost_release.play)
