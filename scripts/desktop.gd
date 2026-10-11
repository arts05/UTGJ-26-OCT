extends Control
## Controls the guided installation, encounter introductions, and crash recovery.

signal encounter_won
signal ending_reached
signal good_ending_requested
signal drive_activity_changed(busy: bool)
signal restart_state_changed(restarting: bool)
signal button_clicked
signal notification_requested
signal settings_requested

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
	OUTRO,
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
@onready var bad_ending: Control = $Screens/BadEnding
@onready var crash_screen = $Screens/CrashScreen
@onready var kratt_delay: Timer = $KrattDelay
@onready var victory_pause: Timer = $VictoryPause
@onready var taskbar: TextureRect = $Taskbar
@onready var start_button: Button = $Taskbar/StartButton
@onready var start_menu = $StartMenu
@onready var cursor: TextureRect = $Cursor

var stage: Stage = Stage.DESKTOP
var active_screen: Control
var retry_screen: Control
var computer_focused: bool = false
var pointer_position := Vector2(-1, -1)

# Pending Kratt dialogue. Each entry is [text: String, expression: int],
# where expression is 0 = neutral, 1 = serious, 2 = happy.
var kratt_lines: Array = []
var kratt_final_button: String = ""


func _ready() -> void:
	start_menu.settings_requested.connect(settings_requested.emit)
	# Sound follows button activation, so dragging and disabled buttons stay quiet.
	for button: BaseButton in find_children("*", "BaseButton", true, false):
		button.pressed.connect(button_clicked.emit)
	_show_screen(null)


func set_computer_focused(focused: bool) -> void:
	computer_focused = focused
	if not focused:
		start_menu.close(true)
	if active_screen == viljaneitsi:
		viljaneitsi.set_computer_focused(focused)
	elif active_screen == kodukaija:
		kodukaija.set_computer_focused(focused)


func set_cursor_position(desktop_position: Vector2) -> void:
	# Keep the arrow tip at the click point, allowing for the texture's transparent margin.
	pointer_position = desktop_position
	if active_screen == kodukaija:
		kodukaija.set_pointer_position(desktop_position)
	cursor.position = desktop_position.floor() - cursor_hotspot
	cursor.visible = (
		Rect2(Vector2.ZERO, size).has_point(desktop_position)
		and active_screen != crash_screen
		and stage != Stage.ENDING
	)


func _show_screen(next_screen: Control) -> void:
	start_menu.close(true)
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


## Queues Kratt's lines and shows the first one. Each click shows the next line;
## after the last one, _on_kratt_continued runs its stage logic.
## Call _show_screen(kratt) right after this to display Kratt.
func _start_kratt_dialogue(lines: Array, final_button: String) -> void:
	kratt_lines = lines.duplicate()
	kratt_final_button = final_button
	_say_next_kratt_line()


func _say_next_kratt_line() -> void:
	var line: Array = kratt_lines.pop_front()
	var button := "Next" if not kratt_lines.is_empty() else kratt_final_button
	kratt.say(line[0], button, line[1])


func _on_installer_shortcut_pressed() -> void:
	# Once installed, its Start entry simply returns to the active task.
	if stage != Stage.DESKTOP:
		return
	stage = Stage.INSTALLATION
	_show_screen(installation)


func _on_start_menu_toggled(opened: bool) -> void:
	start_button.set_pressed_no_signal(opened)
	if opened:
		get_viewport().gui_release_focus()
	elif computer_focused:
		set_computer_focused(true)


func _on_installation_finished() -> void:
	stage = Stage.DISK_WARNING
	_show_screen(null)
	kratt_delay.start()


func _on_kratt_delay_timeout() -> void:
	_start_kratt_dialogue([
		["Hello there! I'm Kratt, your personal helper friend.", 2],
		["Hey! Seems that your disk is full!", 1],
		["It's not malware or a virus either... in fact, I think there's someone inhabiting this folder I found... yes, she seems cunning!", 0],
		["But she really needs to move out of here, this is not where her presence should be. I can't help you, but the spirit of Kalevipoeg bundled with KalevAV will help you out.", 0],
	], "Meet Viljahunt")
	_show_screen(kratt)


func _on_kratt_continued() -> void:
	# More lines queued: show the next one and stay on the Kratt screen.
	if not kratt_lines.is_empty():
		_say_next_kratt_line()
		return
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
		Stage.OUTRO:
			_begin_ending(true)


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
		_show_carl_introduction()


func _on_carl_won() -> void:
	stage = Stage.CARL_VICTORY
	_on_encounter_won()


func finish_encounter_release() -> void:
	if stage == Stage.CARL_VICTORY:
		_show_screen(null)
		victory_pause.start()
	elif stage == Stage.KODUKAIJA:
		kodukaija.finish_release()


func _on_victory_pause_timeout() -> void:
	stage = Stage.CONGRATULATIONS
	_show_screen(congratulations)
	congratulations.start()


func _on_congratulations_finished() -> void:
	if stage == Stage.CONGRATULATIONS:
		stage = Stage.OUTRO
		_start_kratt_dialogue([
			["Look at that, all the spirits are free to roam the open lands of Estonia once again.", 2],
			["Right, and your computer is clean now.", 0],
			["Which means you are obligated to buy this software. Which you have not done. You just found this CD and plopped it in.", 1],
			["That's quite disrespectful to the spirit of Kalevipoeg.", 1],
			["Anyway, I'm taking my leave. Ciao!", 2],
		], "Goodbye")
		_show_screen(kratt)


func _on_carl_failed() -> void:
	_begin_ending(false)


func _begin_ending(good: bool) -> void:
	stage = Stage.ENDING
	ending_reached.emit()
	if good:
		_show_screen(null)
		good_ending_requested.emit()
	else:
		_show_screen(bad_ending)
		bad_ending.get_node("AnimationPlayer").play(&"reveal")


func _on_viljaneitsi_started() -> void:
	drive_activity_changed.emit(true)


func _on_encounter_won() -> void:
	drive_activity_changed.emit(false)
	encounter_won.emit()


func _show_kodukaija_introduction() -> void:
	stage = Stage.KODUKAIJA_INTRO
	_start_kratt_dialogue([
		["Cracking job, mate. I'll shuffle a bit through the files again.", 2],
		["I had a feeling in my bones, well, my... whatever; I found another resident evil here.", 0],
		["She makes unwelcome visits from home to home. Hence why she's called Kodukäija.", 1],
		["Have fun!", 2],
	], "Inspect file")
	_show_screen(kratt)


func _on_kodukaija_accepted() -> void:
	stage = Stage.KODUKAIJA
	kodukaija.reset()
	_show_screen(kodukaija)


func _on_kodukaija_completed() -> void:
	_show_carl_introduction()


func _show_carl_introduction() -> void:
	stage = Stage.CARL_INTRO
	_start_kratt_dialogue([
		["Had fun?", 2],
		["Whoa, looks like there's something else on your drive as well.", 1],
		["The well-known Carl R. Jakobson, but here he seems to go just by Carl, I guess.", 0],
		["I feel like he is here to ask you something. He wants the people to be educated so much he is willing to invade their computers now.", 0],
		["Hope you brushed up on your mythologies, go ahead and answer him. Don't make him upset.", 1],
	], "Inspect file")
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
