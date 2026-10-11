class_name GameRoom
extends Node3D
## Connects desktop events to the room effects and level music.

@export var start_on_ready: bool = true

@onready var ambient_music: AudioStreamPlayer = $AmbientMusic
@onready var desktop = $Computer/ComputerViewport/Desktop
@onready var case_lights = $Room/PCCase/StatusLights
@onready var encounter_release = $EncounterRelease
@onready var scene_fade: SceneFade = $SceneFade


func _ready() -> void:
	desktop.drive_activity_changed.connect(case_lights.set_drive_busy)
	desktop.restart_state_changed.connect(case_lights.set_restarting)
	desktop.encounter_won.connect(encounter_release.play)
	encounter_release.finished.connect(desktop.finish_encounter_release)
	desktop.ending_reached.connect(ambient_music.stop)
	desktop.ending_reached.connect($StreetAmbience.stop)
	if start_on_ready:
		start_game()


func start_game() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	$Computer/ComputerViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	$Computer/Audio/CRTLoop.play()
	$StreetAmbience.start()
	start_ambient_music()


func start_ambient_music() -> void:
	var target_volume_db := ambient_music.volume_db
	ambient_music.volume_db = -80.0
	ambient_music.play()
	create_tween().tween_property(ambient_music, "volume_db", target_volume_db, scene_fade.fade_seconds)


func _exit_tree() -> void:
	ambient_music.stop()
