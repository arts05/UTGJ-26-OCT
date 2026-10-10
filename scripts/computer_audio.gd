extends Node3D
## Plays desktop events at the monitor, outside the UI scenes that open and close.

@onready var desktop = $"../ComputerViewport/Desktop"
@onready var crt_loop: AudioStreamPlayer3D = $CRTLoop
@onready var wrong_answer: AudioStreamPlayer3D = $WrongAnswer


func _ready() -> void:
	desktop.button_clicked.connect($Click.play)
	desktop.notification_requested.connect($Notification.play)
	desktop.installation.installation_completed.connect($Notification.play)
	desktop.viljaneitsi.answer_accepted.connect($CorrectAnswer.play)
	desktop.viljaneitsi.answer_rejected.connect(_on_answer_rejected)
	desktop.restart_state_changed.connect(_on_restart_state_changed)
	desktop.crash_screen.shutdown_started.connect($Shutdown.play)
	desktop.crash_screen.screen_power_changed.connect(_on_screen_power_changed)


func _exit_tree() -> void:
	for player: AudioStreamPlayer3D in get_children():
		player.stop()


func _on_answer_rejected() -> void:
	# Holding Enter should not repeatedly cut off and restart the error sound.
	if not wrong_answer.playing:
		wrong_answer.play()


func _on_restart_state_changed(restarting: bool) -> void:
	if restarting:
		$Click.stop()
		$Notification.stop()
		$CorrectAnswer.stop()
		wrong_answer.stop()
		$Shutdown.stop()
		$Startup.stop()
		$Crash.play()
	else:
		$Startup.play()


func _on_screen_power_changed(powered_on: bool) -> void:
	if powered_on:
		crt_loop.play()
	else:
		crt_loop.stop()
