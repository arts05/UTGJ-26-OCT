class_name OptionsMenu
extends VBoxContainer
## The same audio, display, and control settings in both menus.

signal closed

@onready var master_volume: HSlider = %MasterVolume
@onready var music_volume: HSlider = %MusicVolume
@onready var effects_volume: HSlider = %EffectsVolume
@onready var fullscreen: CheckButton = %Fullscreen


func open() -> void:
	master_volume.set_value_no_signal(_bus_volume(&"Master"))
	music_volume.set_value_no_signal(_bus_volume(&"Music"))
	effects_volume.set_value_no_signal(_bus_volume(&"Computer"))
	fullscreen.set_pressed_no_signal(get_window().mode == Window.MODE_FULLSCREEN)
	_update_volume_labels()
	show()
	master_volume.grab_focus()


func close() -> void:
	_save_settings()
	hide()
	closed.emit()


func _on_volume_changed(_value: float) -> void:
	GameSettings.set_audio_volumes(master_volume.value, music_volume.value, effects_volume.value)
	_update_volume_labels()


func _update_volume_labels() -> void:
	%MasterValue.text = "%d%%" % master_volume.value
	%MusicValue.text = "%d%%" % music_volume.value
	%EffectsValue.text = "%d%%" % effects_volume.value


func _bus_volume(bus: StringName) -> float:
	return AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus)) * 100.0


func _on_fullscreen_toggled(enabled: bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED


func _save_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("audio", "master", master_volume.value)
	settings.set_value("audio", "music", music_volume.value)
	settings.set_value("audio", "effects", effects_volume.value)
	settings.set_value("display", "fullscreen", get_window().mode == Window.MODE_FULLSCREEN)
	var error := settings.save(GameSettings.SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save game settings: " + error_string(error))
