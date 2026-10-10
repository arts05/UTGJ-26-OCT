extends Node3D
## Occasional sounds beyond the balcony, with a quiet gap after each recording.

@export_range(10.0, 180.0) var minimum_delay_seconds: float = 35.0
@export_range(10.0, 180.0) var maximum_delay_seconds: float = 75.0
@export_range(0.0, 0.5) var distant_voice_chance: float = 0.1

@onready var timer: Timer = $NextSound
@onready var footsteps: AudioStreamPlayer3D = $Footsteps
@onready var car: AudioStreamPlayer3D = $Car
@onready var cough: AudioStreamPlayer3D = $Cough
@onready var distant_voice: AudioStreamPlayer3D = $DistantVoice

var last_sound: AudioStreamPlayer3D
var stopped: bool = false


func _ready() -> void:
	for player in [footsteps, car, cough, distant_voice]:
		player.finished.connect(_schedule_next)
	_schedule_next()


func _schedule_next() -> void:
	if not stopped:
		timer.start(randf_range(minimum_delay_seconds, maximum_delay_seconds))


func _on_next_sound_timeout() -> void:
	var choices: Array[AudioStreamPlayer3D] = [footsteps, car, cough]
	choices.erase(last_sound)
	var next_sound: AudioStreamPlayer3D = choices.pick_random()
	if last_sound != distant_voice and randf() < distant_voice_chance:
		next_sound = distant_voice
	last_sound = next_sound
	next_sound.play()


func stop() -> void:
	stopped = true
	timer.stop()
	for player in [footsteps, car, cough, distant_voice]:
		player.stop()


func _exit_tree() -> void:
	stop()
