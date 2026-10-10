extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/Main.tscn"

@onready var menu: VBoxContainer = $Center/Menu
@onready var options: OptionsMenu = $Center/Options
@onready var play_button: Button = %PlayButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var scene_fade: SceneFade = $SceneFade


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameSettings.load_and_apply()
	var target_volume_db := menu_music.volume_db
	menu_music.volume_db = -80.0
	menu_music.play()
	create_tween().tween_property(menu_music, "volume_db", target_volume_db, scene_fade.fade_seconds)
	play_button.grab_focus()
	if OS.has_feature("web"):
		quit_button.disabled = true
		quit_button.tooltip_text = "Close the game tab to quit."


func _exit_tree() -> void:
	menu_music.stop()


func _unhandled_input(event: InputEvent) -> void:
	if options.visible and event.is_action_pressed("ui_cancel"):
		options.close()
		get_viewport().set_input_as_handled()


func _on_play_pressed() -> void:
	if scene_fade.is_fading or play_button.disabled:
		return
	play_button.disabled = true
	var original_volume_db := menu_music.volume_db
	create_tween().tween_property(menu_music, "volume_db", -80.0, scene_fade.fade_seconds)
	await scene_fade.fade_to_black()
	menu_music.stop()
	var error := get_tree().change_scene_to_file(game_scene_path)
	if error != OK:
		play_button.disabled = false
		menu_music.volume_db = original_volume_db
		menu_music.play()
		scene_fade.fade_from_black()
		push_error("Could not open the game: " + error_string(error))


func _on_options_pressed() -> void:
	menu.hide()
	options.open()


func _on_options_closed() -> void:
	menu.show()
	options_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
