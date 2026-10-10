class_name GameSettings
extends RefCounted
## Applies the same saved preferences before either startup scene plays audio.

const SETTINGS_PATH: String = "user://settings.cfg"


static func load_and_apply() -> ConfigFile:
	var settings := ConfigFile.new()
	var error := settings.load(SETTINGS_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_warning("Could not load game settings: " + error_string(error))
	set_audio_volumes(
		settings.get_value("audio", "master", 100.0),
		settings.get_value("audio", "music", 100.0),
		settings.get_value("audio", "effects", 100.0)
	)
	# Browsers require a new user click to enter fullscreen.
	if not OS.has_feature("web"):
		var fullscreen: bool = settings.get_value("display", "fullscreen", false)
		var tree := Engine.get_main_loop() as SceneTree
		tree.root.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	return settings


static func set_audio_volumes(master: float, music: float, effects: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Master"), master / 100.0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Music"), music / 100.0)
	# Preserve each player's editor volume; Effects adjusts both sound buses together.
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"Computer"), effects / 100.0)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(&"CRT"), effects / 100.0)
