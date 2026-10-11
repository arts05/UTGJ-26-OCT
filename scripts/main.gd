class_name GameRoom
extends Node3D
## Connects desktop events to the room effects and level music.

@export var start_on_ready: bool = true
## Keep only the opening part of the CD sound before fading it out.
@export_range(0.0, 4.0, 0.1) var intro_cd_seconds: float = 1.3
## Reveal the room this long after the startup chime begins.
@export_range(0.0, 3.0, 0.1) var intro_reveal_delay_seconds: float = 1.0

@onready var ambient_music: AudioStreamPlayer = $AmbientMusic
@onready var cd_insert: AudioStreamPlayer = $IntroAudio/CDInsert
@onready var startup_chime: AudioStreamPlayer = $IntroAudio/Startup
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
	desktop.good_ending_requested.connect($GoodEnding.play)
	desktop.bad_ending_requested.connect($BadEnding.play)
	$GoodEnding.title_reached.connect($Computer/Audio/CRTLoop.stop)
	$EndingCredits.finished.connect(_on_ending_finished)
	desktop.settings_requested.connect($PauseMenu.open_options_from_desktop)
	if start_on_ready:
		start_game()


func play_intro() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	scene_fade.black.modulate.a = 1.0
	scene_fade.black.show()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	# The curtain blocks input; room music and ambience begin with the reveal.
	var cd_volume_db := cd_insert.volume_db
	cd_insert.play()
	await get_tree().create_timer(intro_cd_seconds).timeout
	var cd_fade := create_tween()
	cd_fade.tween_property(cd_insert, "volume_db", -80.0, 0.2)
	await cd_fade.finished
	cd_insert.stop()
	cd_insert.volume_db = cd_volume_db
	startup_chime.play()
	await get_tree().create_timer(intro_reveal_delay_seconds).timeout
	start_game()
	await scene_fade.fade_from_black()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
	cd_insert.stop()
	startup_chime.stop()


func _on_ending_finished() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	if error != OK:
		push_error("Could not return to the main menu: " + error_string(error))
