extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/Main.tscn"

@onready var menu: VBoxContainer = $Center/Menu
@onready var options: OptionsMenu = $Center/Options
@onready var play_button: Button = %PlayButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var scene_fade: SceneFade = $SceneFade
@onready var loading_screen: GameLoadingScreen = $LoadingScreen

var loading_game: bool = false
var menu_volume_db: float


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameSettings.load_and_apply()
	menu_volume_db = menu_music.volume_db
	menu_music.volume_db = -80.0
	menu_music.play()
	create_tween().tween_property(menu_music, "volume_db", menu_volume_db, scene_fade.fade_seconds)
	play_button.grab_focus()
	if OS.has_feature("web"):
		quit_button.disabled = true
		quit_button.tooltip_text = "Close the game tab to quit."


func _on_play_pressed() -> void:
	if scene_fade.is_fading or loading_game:
		return
	loading_game = true
	play_button.disabled = true
	create_tween().tween_property(menu_music, "volume_db", -80.0, scene_fade.fade_seconds)
	if RoomStartup.prepared_room == null:
		# F6 on the menu, or a new game after returning from the room.
		loading_screen.message.text = "Loading…"
		loading_screen.progress.show()
		loading_screen.back_button.hide()
		loading_screen.panel.modulate.a = 0.0
		loading_screen.show()
		var tween := create_tween()
		tween.tween_property(loading_screen.panel, "modulate:a", 1.0, scene_fade.fade_seconds)
		await tween.finished
		menu_music.stop()
		var error := await RoomStartup.prepare(game_scene_path)
		if error != OK:
			_show_loading_error(error_string(error))
			return
	else:
		await scene_fade.fade_to_black()
		menu_music.stop()
	_open_game()


func _open_game() -> void:
	# Use the same room that startup already created and rendered.
	var level := RoomStartup.take_room()
	var tree := get_tree()
	tree.current_scene = level
	level.start_game()
	level.scene_fade.fade_from_black()
	queue_free()


func _show_loading_error(message: String) -> void:
	loading_screen.message.text = "Could not load the room."
	loading_screen.progress.hide()
	loading_screen.back_button.show()
	loading_screen.back_button.grab_focus()
	push_error("Could not prepare the game: " + message)


func _on_loading_back_pressed() -> void:
	loading_screen.hide()
	loading_game = false
	play_button.disabled = false
	play_button.grab_focus()
	menu_music.volume_db = menu_volume_db
	menu_music.play()


func _exit_tree() -> void:
	menu_music.stop()


func _unhandled_input(event: InputEvent) -> void:
	if options.visible and event.is_action_pressed("ui_cancel"):
		options.close()
		get_viewport().set_input_as_handled()


func _on_options_pressed() -> void:
	menu.hide()
	options.open()


func _on_options_closed() -> void:
	menu.show()
	options_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
