extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/Main.tscn"

const MENU_REFERENCE_HEIGHT: float = 720.0

@onready var menu: Control = $Menu
@onready var options: OptionsMenu = $OptionsLayer/Anchor/Options
@onready var options_layer: Control = $OptionsLayer
@onready var portraits: Control = $MenuPortraits
@onready var background_material: ShaderMaterial = $Background.material
@onready var selection: ColorRect = $Menu/Navigation/Selection
@onready var play_button: Button = %PlayButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var scene_fade: SceneFade = $SceneFade
@onready var loading_screen: GameLoadingScreen = $LoadingScreen

var loading_game: bool = false
var menu_volume_db: float
var selection_tween: Tween


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameSettings.load_and_apply()
	menu_volume_db = menu_music.volume_db
	menu_music.volume_db = -80.0
	menu_music.play()
	create_tween().tween_property(menu_music, "volume_db", menu_volume_db, scene_fade.fade_seconds)
	if OS.has_feature("web"):
		quit_button.disabled = true
		quit_button.tooltip_text = "Close the game tab to quit."
	for button in [play_button, options_button, quit_button]:
		button.mouse_entered.connect(_on_button_hovered.bind(button))
		button.focus_entered.connect(_move_selection.bind(button))
	resized.connect(_update_layout)
	options.minimum_size_changed.connect(_update_layout.call_deferred)
	_update_layout.call_deferred()
	play_button.grab_focus()
	_move_selection.call_deferred(play_button)


func _process(_delta: float) -> void:
	background_material.set_shader_parameter("interference", 0.0 if portraits.quiet else portraits.interference)


func _update_layout() -> void:
	# The authored menu keeps its proportions inside smaller itch embeds.
	menu.scale = Vector2.ONE * clampf(size.y / MENU_REFERENCE_HEIGHT, 0.45, 1.3)
	options.reset_size()
	var available_size := size - Vector2(80.0, 80.0)
	var options_scale := minf(available_size.x / options.size.x, available_size.y / options.size.y)
	options.scale = Vector2.ONE * minf(1.0, options_scale)
	options.pivot_offset = options.size * 0.5
	options.position = -options.size * 0.5


func _on_button_hovered(button: Button) -> void:
	if not button.disabled and not loading_game:
		button.grab_focus()


func _move_selection(button: Button) -> void:
	if selection_tween:
		selection_tween.kill()
	selection_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	selection_tween.tween_property(selection, "position:y", button.position.y, 0.12)


func _on_play_pressed() -> void:
	if scene_fade.is_fading or loading_game:
		return
	loading_game = true
	play_button.disabled = true
	portraits.set_quiet(true)
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
	portraits.set_quiet(false)
	menu_music.volume_db = menu_volume_db
	menu_music.play()


func _exit_tree() -> void:
	menu_music.stop()


func _unhandled_input(event: InputEvent) -> void:
	if options.visible and event.is_action_pressed("ui_cancel"):
		options.close()
		get_viewport().set_input_as_handled()


func _on_options_pressed() -> void:
	if scene_fade.is_fading or loading_game:
		return
	menu.hide()
	options_layer.show()
	options.open()
	portraits.set_quiet(true)
	_update_layout.call_deferred()


func _on_options_closed() -> void:
	options_layer.hide()
	menu.show()
	portraits.set_quiet(false)
	options_button.grab_focus()


func _on_quit_pressed() -> void:
	get_tree().quit()
