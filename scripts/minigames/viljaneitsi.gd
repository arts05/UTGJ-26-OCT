extends Control

signal completed
signal failed
signal started
signal won
signal answer_accepted
signal answer_rejected
signal typing_key_pressed

enum Phase { INTRODUCTION, READY, TYPING, SUCCESS }

@export_range(5.0, 180.0) var time_limit_seconds: float = 60.0
@export_range(1, 10) var required_repetitions: int = 3
@export var phrase: String = "Kulla neitsid, ärge tehke paha!"

@export_group("Folder feedback")
@export_range(0.1, 1.5, 0.05) var answer_effect_seconds: float = 0.65

const WOLF_EXPRESSIONS: Array[Texture2D] = [
	preload("res://assets/sprites/vilja1.png"),
	preload("res://assets/sprites/vilja2.png"),
	preload("res://assets/sprites/vilja3.png"),
]

@onready var folder = $FolderWindow
@onready var wheat = $FolderWindow/Contents/Wheat
@onready var field_material: ShaderMaterial = $FolderWindow/Contents/FieldEffect.material
@onready var character_window: Control = $CharacterWindow
@onready var speech = $CharacterWindow/Speech
@onready var action_button: Button = $CharacterWindow/Speech/Panel/Margins/Stack/Actions/ActionButton
@onready var instruction: Label = $FolderWindow/Contents/Prompt/Instruction
@onready var phrase_label: Label = $FolderWindow/Contents/Prompt/Phrase
@onready var answer: LineEdit = $FolderWindow/Contents/Prompt/Answer
@onready var feedback: Label = $FolderWindow/Contents/Prompt/Feedback

var phase: Phase = Phase.INTRODUCTION
var elapsed_seconds: float = 0.0
var accepted_repetitions: int = 0
var answer_tween: Tween


func _ready() -> void:
	reset()


func reset() -> void:
	if answer_tween:
		answer_tween.kill()
	field_material.set_shader_parameter("pressure", 0.0)
	field_material.set_shader_parameter("success_amount", 0.0)
	set_process(false)
	phase = Phase.INTRODUCTION
	elapsed_seconds = 0.0
	accepted_repetitions = 0
	wheat.reset()
	folder.hide()
	folder.show_parent_folder()
	character_window.show()
	character_window.set_artwork_texture(WOLF_EXPRESSIONS[0])
	speech.say("I am Viljaneitsi.\n\nThis disk is my field. Every grain I grow becomes another file.", "Open my folder")
	instruction.text = "Type this %d times to stop the new files." % required_repetitions
	phrase_label.text = phrase
	feedback.text = "Press Enter after each line."
	answer.clear()
	answer.hide()


func restart() -> void:
	# A crash returns to the instructions without replaying the introductions.
	reset()
	_show_folder()


func _show_folder() -> void:
	phase = Phase.READY
	folder.open_folder()
	folder.show()
	speech.say(
		"Want me to stop growing?\n\nType the line %d times before my files fill this folder." % required_repetitions,
		"Begin"
	)


func set_computer_focused(focused: bool) -> void:
	if focused and phase == Phase.TYPING:
		answer.grab_focus()
		answer.edit()
	else:
		answer.release_focus()


func _on_action_pressed() -> void:
	match phase:
		Phase.INTRODUCTION:
			_show_folder()
		Phase.READY:
			_start_typing()
		Phase.SUCCESS:
			completed.emit()


func _start_typing() -> void:
	phase = Phase.TYPING
	speech.say("More files. More grain.")
	answer.show()
	answer.grab_focus()
	answer.edit()
	set_process(true)
	started.emit()


func _process(delta: float) -> void:
	elapsed_seconds = minf(elapsed_seconds + delta, time_limit_seconds)
	wheat.set_coverage(elapsed_seconds / time_limit_seconds)
	field_material.set_shader_parameter("pressure", elapsed_seconds / time_limit_seconds)
	folder.status.text = "%d files" % wheat.filled_cells
	if elapsed_seconds >= time_limit_seconds:
		set_process(false)
		failed.emit()


func _on_answer_gui_input(event: InputEvent) -> void:
	if phase != Phase.TYPING or not answer.has_focus():
		return
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	# One click per physical press; clearing the field and holding a key stay quiet.
	if event.unicode >= 32 or event.keycode in [KEY_BACKSPACE, KEY_DELETE, KEY_ENTER, KEY_KP_ENTER]:
		typing_key_pressed.emit()


func _on_answer_submitted(text: String) -> void:
	if phase != Phase.TYPING:
		return
	if _normalize_phrase(text) != _normalize_phrase(phrase):
		feedback.text = "Try that line again."
		answer.select_all()
		answer_rejected.emit()
		return

	accepted_repetitions += 1
	answer_accepted.emit()
	folder.flash()
	character_window.flash()
	_play_answer_effect()
	answer.clear()
	var expression_index := mini(accepted_repetitions, WOLF_EXPRESSIONS.size() - 1)
	character_window.set_artwork_texture(WOLF_EXPRESSIONS[expression_index])
	feedback.text = "%d of %d." % [accepted_repetitions, required_repetitions]
	if accepted_repetitions == required_repetitions:
		phase = Phase.SUCCESS
		set_process(false)
		wheat.reset()
		answer_tween.parallel().tween_property(field_material, "shader_parameter/pressure", 0.0, answer_effect_seconds)
		folder.status.text = "0 files"
		instruction.text = "The folder is clear."
		speech.say("All right. No more grain.", "Continue")
		feedback.text = ""
		answer.hide()
		won.emit()


func _play_answer_effect() -> void:
	if answer_tween:
		answer_tween.kill()
	field_material.set_shader_parameter("success_amount", 1.0)
	answer_tween = create_tween()
	answer_tween.tween_property(field_material, "shader_parameter/success_amount", 0.0, answer_effect_seconds)


func _normalize_phrase(text: String) -> String:
	# Keep Estonian letters, but don't punish capitalization, punctuation, or extra spaces.
	var normalized := text.to_lower().strip_edges()
	for punctuation in [",", ".", "!", "?", "\"", "“", "”", "„"]:
		normalized = normalized.replace(punctuation, "")
	return " ".join(normalized.split(" ", false))
