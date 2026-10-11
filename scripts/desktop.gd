extends Control
## Controls the guided installation, encounter introductions, and crash recovery.

signal encounter_won
signal ending_reached
signal drive_activity_changed(busy: bool)
signal restart_state_changed(restarting: bool)
signal button_clicked
signal notification_requested

enum Stage {
	DESKTOP,
	INSTALLATION,
	DISK_WARNING,
	VILJANEITSI,
	KODUKAIJA_INTRO,
	KODUKAIJA_PROMPT,
	KODUKAIJA,
	CARL_INTRO,
	CARL_PROMPT,
	CARL,
	CARL_VICTORY,
	CONGRATULATIONS,
	ENDING,
	CRASH,
}

@export var cursor_hotspot: Vector2 = Vector2(2, 2)
@export var skip_kodukaija_for_carl_testing: bool = false

@onready var installer_shortcut: Button = $InstallerShortcut
@onready var installation = $Screens/Installation
@onready var kratt = $Screens/Kratt
@onready var viljaneitsi = $Screens/Viljaneitsi
@onready var kodukaija_prompt = $Screens/KodukaijaPrompt
@onready var kodukaija = $Screens/Kodukaija
@onready var carl_prompt = $Screens/CarlPrompt
@onready var carl = $Screens/Carl
@onready var congratulations = $Screens/Congratulations
@onready var good_ending: Control = $Screens/GoodEnding
@onready var bad_ending: Control = $Screens/BadEnding
@onready var crash_screen = $Screens/CrashScreen
@onready var kratt_delay: Timer = $KrattDelay
@onready var victory_pause: Timer = $VictoryPause
@onready var taskbar: TextureRect = $Taskbar
@onready var cursor: TextureRect = $Cursor

var stage: Stage = Stage.DESKTOP
var active_screen: Control
var retry_screen: Control
var computer_focused: bool = false
var pointer_position := Vector2(-1, -1)


func _ready() -> void:
	# Sound follows button activation, so dragging and disabled buttons stay quiet.
	for button: BaseButton in find_children("*", "BaseButton", true, false):
		button.pressed.connect(button_clicked.emit)
	_show_screen(null)


func set_computer_focused(focused: bool) -> void:
	computer_focused = focused
	if active_screen == viljaneitsi:
		viljaneitsi.set_computer_focused(focused)
	elif active_screen == kodukaija:
		kodukaija.set_computer_focused(focused)


func set_cursor_position(desktop_position: Vector2) -> void:
	# Keep the arrow tip at the click point, allowing for the texture's transparent margin.
	pointer_position = desktop_position
	cursor.position = desktop_position.floor() - cursor_hotspot
	cursor.visible = (
		Rect2(Vector2.ZERO, size).has_point(desktop_position)
		and active_screen != crash_screen
		and stage != Stage.ENDING
	)


func _show_screen(next_screen: Control) -> void:
	for screen: Control in $Screens.get_children():
		screen.hide()
		screen.process_mode = Node.PROCESS_MODE_DISABLED
	active_screen = next_screen
	taskbar.visible = next_screen != crash_screen and next_screen != kodukaija and stage != Stage.ENDING
	installer_shortcut.visible = taskbar.visible
	installer_shortcut.disabled = stage != Stage.DESKTOP
	if active_screen != null:
		active_screen.show()
		active_screen.process_mode = Node.PROCESS_MODE_INHERIT
	if next_screen in [kratt, kodukaija_prompt, carl_prompt, congratulations]:
		notification_requested.emit()
	set_cursor_position(pointer_position)
	set_computer_focused(computer_focused)


func _on_installer_shortcut_pressed() -> void:
	stage = Stage.INSTALLATION
	_show_screen(installation)


func _on_installation_finished() -> void:
	stage = Stage.DISK_WARNING
	_show_screen(null)
	kratt_delay.start()


func _on_kratt_delay_timeout() -> void:
	kratt.say("Your disk is full.\n\nThe Viljahunt folder is taking up the space. Let's speak to her first.", "Meet Viljahunt", 0)
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
		Stage.CARL_INTRO:
			stage = Stage.CARL_PROMPT
			_show_screen(carl_prompt)


func _on_viljaneitsi_completed() -> void:
	if skip_kodukaija_for_carl_testing:
		_show_carl_introduction()
	else:
		_show_kodukaija_introduction()


func _on_carl_accepted() -> void:
	stage = Stage.CARL
	carl.reset()
	_show_screen(carl)


func _on_carl_declined() -> void:
	if skip_kodukaija_for_carl_testing:
		stage = Stage.VILJANEITSI
		_show_screen(viljaneitsi)
	else:
		stage = Stage.KODUKAIJA
		_show_screen(kodukaija)


func _on_carl_won() -> void:
	stage = Stage.CARL_VICTORY
	_on_encounter_won()


func finish_encounter_release() -> void:
	if stage == Stage.CARL_VICTORY:
		_show_screen(null)
		victory_pause.start()


func _on_victory_pause_timeout() -> void:
	stage = Stage.CONGRATULATIONS
	_show_screen(congratulations)
	congratulations.start()


func _on_congratulations_finished() -> void:
	if stage == Stage.CONGRATULATIONS:
		_begin_ending(true)


func _on_carl_failed() -> void:
	_begin_ending(false)


func _begin_ending(good: bool) -> void:
	stage = Stage.ENDING
	var ending := good_ending if good else bad_ending
	_show_screen(ending)
	ending_reached.emit()
	ending.get_node("AnimationPlayer").play(&"reveal")


func _on_viljaneitsi_started() -> void:
	drive_activity_changed.emit(true)


func _on_encounter_won() -> void:
	drive_activity_changed.emit(false)
	encounter_won.emit()


func _show_kodukaija_introduction() -> void:
	stage = Stage.KODUKAIJA_INTRO
	kratt.say("The extra files are gone.\n\nThere is another file to check: Kodukäija.exe.", "Inspect file", 1)
	_show_screen(kratt)


func _on_kodukaija_accepted() -> void:
	stage = Stage.KODUKAIJA
	kodukaija.reset()
	_show_screen(kodukaija)


func _on_kodukaija_completed() -> void:
	_show_carl_introduction()


func _show_carl_introduction() -> void:
	stage = Stage.CARL_INTRO
	kratt.say("I found the final file that you should check out.", "Inspect file", 1)
	_show_screen(kratt)


func _on_encounter_failed() -> void:
	retry_screen = active_screen
	stage = Stage.CRASH
	drive_activity_changed.emit(false)
	restart_state_changed.emit(true)
	_show_screen(crash_screen)
	crash_screen.restart()


func _on_restart_finished() -> void:
	restart_state_changed.emit(false)
	if retry_screen == viljaneitsi:
		stage = Stage.VILJANEITSI
		viljaneitsi.restart()
	else:
		stage = Stage.KODUKAIJA
		kodukaija.reset()
	_show_screen(retry_screen)


func _on_kodukaija_closed() -> void:
	_show_kodukaija_introduction()
