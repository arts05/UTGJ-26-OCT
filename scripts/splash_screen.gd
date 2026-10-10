extends Control

@export_file("*.tscn") var menu_scene_path: String = "res://scenes/main_menu.tscn"

@onready var logo: Control = $Logo
@onready var artwork: TextureRect = $Logo/Artwork
@onready var placeholder: Label = $Logo/Placeholder
@onready var start_prompt: Label = $StartPrompt
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var splash_audio: AudioStreamPlayer = $SplashAudio

var waiting_for_input: bool = false


func _ready() -> void:
	GameSettings.load_and_apply()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	logo.modulate.a = 0.0
	placeholder.visible = artwork.texture == null
	if OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		waiting_for_input = true
		start_prompt.show()
	else:
		_start_intro()


func _exit_tree() -> void:
	splash_audio.stop()


func _input(event: InputEvent) -> void:
	if not waiting_for_input:
		return
	var clicked: bool = (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	)
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if clicked or tapped or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_start_intro()


func _start_intro() -> void:
	waiting_for_input = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	start_prompt.hide()
	splash_audio.play()
	animation.play(&"intro")
	await animation.animation_finished
	# The artwork has faded by five seconds; let the sound's remaining tail finish.
	if splash_audio.playing:
		await splash_audio.finished
	var error := get_tree().change_scene_to_file(menu_scene_path)
	if error != OK:
		push_error("Could not open the main menu: " + error_string(error))
