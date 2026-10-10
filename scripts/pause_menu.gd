extends CanvasLayer
## Pauses the room and desktop together, while this menu keeps accepting input.

@export var computer: Node3D
@export var scene_fade: SceneFade
@export_file("*.tscn") var menu_scene_path: String = "res://scenes/main_menu.tscn"

@onready var overlay: Control = $Overlay
@onready var menu: VBoxContainer = $Overlay/Center/Menu
@onready var options: OptionsMenu = $Overlay/Center/Options
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton

var mouse_mode_before_pause: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var returning_to_menu: bool = false


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	# P is also part of Viljaneitsi's sentence. Escape still pauses while typing.
	if not get_tree().paused and event is InputEventKey:
		if event.physical_keycode == KEY_P and computer.is_typing():
			return
	get_viewport().set_input_as_handled()
	if returning_to_menu:
		return
	if not get_tree().paused:
		_pause()
	elif options.visible:
		options.close()
	else:
		_on_resume_pressed()


func _pause() -> void:
	mouse_mode_before_pause = Input.mouse_mode
	# Release held drags and movement keys before pausing their input handlers.
	computer.set_input_paused(true)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.show()
	menu.show()
	resume_button.grab_focus()


func _on_resume_pressed() -> void:
	if returning_to_menu:
		return
	get_viewport().set_input_as_handled()
	get_viewport().gui_release_focus()
	overlay.hide()
	get_tree().paused = false
	# Restore capture during the button/key event, as required by browsers.
	Input.mouse_mode = mouse_mode_before_pause
	computer.set_input_paused(false)


func _on_options_pressed() -> void:
	menu.hide()
	options.open()


func _on_options_closed() -> void:
	menu.show()
	options_button.grab_focus()


func _on_main_menu_pressed() -> void:
	if returning_to_menu:
		return
	returning_to_menu = true
	await scene_fade.fade_to_black()
	var tree := get_tree()
	var error := tree.change_scene_to_file(menu_scene_path)
	if error == OK:
		# The old scene has left the tree, so it cannot advance during the switch.
		tree.paused = false
	else:
		returning_to_menu = false
		scene_fade.fade_from_black()
		push_error("Could not return to the main menu: " + error_string(error))
