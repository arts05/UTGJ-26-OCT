extends Node3D
## Connects desktop events to the room effects and level music.

@onready var ambient_music: AudioStreamPlayer = $AmbientMusic
@onready var desktop = $Computer/ComputerViewport/Desktop
@onready var case_lights = $Room/PCCase/StatusLights
@onready var ghost_release = $Room/GhostRelease


func _ready() -> void:
	desktop.drive_activity_changed.connect(case_lights.set_drive_busy)
	desktop.restart_state_changed.connect(case_lights.set_restarting)
	desktop.encounter_won.connect(ghost_release.play)
	desktop.ending_reached.connect(ambient_music.stop)


func _exit_tree() -> void:
	ambient_music.stop()
