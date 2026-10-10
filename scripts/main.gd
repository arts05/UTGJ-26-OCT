extends Node3D
## Connects desktop events to the room effects and level music.

@onready var ambient_music: AudioStreamPlayer = $AmbientMusic
@onready var desktop = $Computer/ComputerViewport/Desktop
@onready var case_lights = $Room/PCCase/StatusLights
@onready var ghost_release = $Room/GhostRelease
@onready var scene_fade: SceneFade = $SceneFade


func _ready() -> void:
	desktop.drive_activity_changed.connect(case_lights.set_drive_busy)
	desktop.restart_state_changed.connect(case_lights.set_restarting)
	desktop.encounter_won.connect(ghost_release.play)
	desktop.ending_reached.connect(ambient_music.stop)
	var target_volume_db := ambient_music.volume_db
	ambient_music.volume_db = -80.0
	ambient_music.play()
	create_tween().tween_property(ambient_music, "volume_db", target_volume_db, scene_fade.fade_seconds)


func _exit_tree() -> void:
	ambient_music.stop()
