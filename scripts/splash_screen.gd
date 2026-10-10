extends Control

@export_file("*.tscn") var menu_scene_path: String = "res://scenes/main_menu.tscn"

@onready var logo: Control = $Logo
@onready var godot_logo: TextureRect = $GodotLogo
@onready var artwork: TextureRect = $Logo/Artwork
@onready var placeholder: Label = $Logo/Placeholder
@onready var start_prompt: Label = $StartPrompt
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var splash_audio: AudioStreamPlayer = $SplashAudio

var waiting_for_input: bool = false
var menu_scene: PackedScene


func _ready() -> void:
	GameSettings.load_and_apply()
	# Load menu resources before the jingle starts, so they don't delay its final fade.
	menu_scene = load(menu_scene_path)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	logo.modulate.a = 0.0
	godot_logo.modulate.a = 0.0
	placeholder.visible = artwork.texture == null
	if OS.has_feature("web"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		waiting_for_input = true
		start_prompt.show()
	else:
		_start_intro()


func _exit_tree() -> void:
	if splash_audio.get_parent() == self:
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
	# Both logos finish at 5.4 s. The menu's 0.6 s fade fits inside the 6.14 s jingle.
	# Keep the audio alive across the scene change, then free it when its tail ends.
	splash_audio.reparent(get_tree().root)
	splash_audio.finished.connect(splash_audio.queue_free)
	var error := get_tree().change_scene_to_packed(menu_scene)
	if error != OK:
		push_error("Could not open the main menu: " + error_string(error))
