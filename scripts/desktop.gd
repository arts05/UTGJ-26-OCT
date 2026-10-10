extends Control
## Controls the guided installation, encounter introductions, and crash recovery.

enum Stage {
	DESKTOP,
	INSTALLATION,
	DISK_WARNING,
	VILJANEITSI,
	KODUKAIJA_INTRO,
	KODUKAIJA_PROMPT,
	KODUKAIJA,
	CRASH,
}

@onready var installation = $Screens/Installation
@onready var kratt = $Screens/Kratt
@onready var viljaneitsi = $Screens/Viljaneitsi
@onready var kodukaija_prompt = $Screens/KodukaijaPrompt
@onready var kodukaija = $Screens/Kodukaija
@onready var crash_screen = $Screens/CrashScreen
@onready var welcome_delay: Timer = $WelcomeDelay
@onready var taskbar: TextureRect = $Taskbar

var stage: Stage = Stage.DESKTOP
var active_screen: Control
var retry_screen: Control
var computer_focused: bool = false
var startup_started: bool = false


func _ready() -> void:
	_show_screen(null)


func set_computer_focused(focused: bool) -> void:
	computer_focused = focused
	if focused and stage == Stage.DESKTOP and not startup_started:
		startup_started = true
		welcome_delay.start()
	if active_screen == viljaneitsi:
		viljaneitsi.set_computer_focused(focused)
	elif active_screen == kodukaija:
		kodukaija.set_computer_focused(focused)


func _show_screen(next_screen: Control) -> void:
	for screen: Control in $Screens.get_children():
		screen.hide()
		screen.process_mode = Node.PROCESS_MODE_DISABLED
	active_screen = next_screen
	taskbar.visible = next_screen != crash_screen and next_screen != kodukaija
	if active_screen != null:
		active_screen.show()
		active_screen.process_mode = Node.PROCESS_MODE_INHERIT
	set_computer_focused(computer_focused)


func _on_welcome_delay_timeout() -> void:
	stage = Stage.INSTALLATION
	_show_screen(installation)


func _on_installation_finished() -> void:
	stage = Stage.DISK_WARNING
	kratt.say("Your disk is full.\n\nThe Viljaneitsi folder is taking up the space. Let's open it.", "Show folder", 0)
	_show_screen(kratt)


func _on_kratt_continued() -> void:
	match stage:
		Stage.DISK_WARNING:
			stage = Stage.VILJANEITSI
			viljaneitsi.reset()
			_show_screen(viljaneitsi)
		Stage.KODUKAIJA_INTRO:
			stage = Stage.KODUKAIJA_PROMPT
			_show_screen(kodukaija_prompt)


func _on_viljaneitsi_completed() -> void:
	_show_kodukaija_introduction()


func _show_kodukaija_introduction() -> void:
	stage = Stage.KODUKAIJA_INTRO
	kratt.say("The extra files are gone.\n\nThere is another file to check: Kodukäija.exe.", "Inspect file", 1)
	_show_screen(kratt)


func _on_kodukaija_accepted() -> void:
	stage = Stage.KODUKAIJA
	kodukaija.reset()
	_show_screen(kodukaija)


func _on_encounter_failed() -> void:
	retry_screen = active_screen
	stage = Stage.CRASH
	_show_screen(crash_screen)
	crash_screen.restart()


func _on_restart_finished() -> void:
	if retry_screen == viljaneitsi:
		stage = Stage.VILJANEITSI
		viljaneitsi.restart()
	else:
		stage = Stage.KODUKAIJA
		kodukaija.reset()
	_show_screen(retry_screen)


func _on_kodukaija_closed() -> void:
	_show_kodukaija_introduction()
