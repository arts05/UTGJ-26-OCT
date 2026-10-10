extends Control

signal completed
signal failed
signal started
signal won

enum Phase { FOLDER, INTRODUCTION, TYPING, SUCCESS }

@export_range(5.0, 180.0) var time_limit_seconds: float = 60.0
@export_range(1, 10) var required_repetitions: int = 3
@export var phrase: String = "Kulla neitsid, ärge tehke paha!"

const WOLF_EXPRESSIONS: Array[Texture2D] = [
	preload("res://assets/sprites/vilja1.png"),
	preload("res://assets/sprites/vilja2.png"),
	preload("res://assets/sprites/vilja3.png"),
]

@onready var folder = $FolderWindow
@onready var wheat = $FolderWindow/Contents/Wheat
@onready var character_window: Control = $CharacterWindow
@onready var speech = $CharacterWindow/Speech
@onready var action_button: Button = $CharacterWindow/Speech/Panel/Margins/Stack/Actions/ActionButton
@onready var instruction: Label = $FolderWindow/Contents/Prompt/Instruction
@onready var phrase_label: Label = $FolderWindow/Contents/Prompt/Phrase
@onready var answer: LineEdit = $FolderWindow/Contents/Prompt/Answer
@onready var feedback: Label = $FolderWindow/Contents/Prompt/Feedback

var phase: Phase = Phase.FOLDER
var elapsed_seconds: float = 0.0
var accepted_repetitions: int = 0


func _ready() -> void:
	reset()


func reset() -> void:
	set_process(false)
	phase = Phase.FOLDER
	elapsed_seconds = 0.0
	accepted_repetitions = 0
	wheat.reset()
	folder.show_parent_folder()
	character_window.hide()
	character_window.set_artwork_texture(WOLF_EXPRESSIONS[0])
	speech.say("You want me to stop growing? Ask me properly.", "Begin")
	instruction.text = "Type this %d times to stop the new files." % required_repetitions
	phrase_label.text = phrase
	feedback.text = "Press Enter after each line."
	answer.clear()
	answer.hide()


func restart() -> void:
	# A crash retries this folder, without replaying installation or Kratt's introduction.
	reset()
	folder.open_folder()
	_on_folder_opened()


func _on_folder_opened() -> void:
	phase = Phase.INTRODUCTION
	character_window.show()


func set_computer_focused(focused: bool) -> void:
	if focused and phase == Phase.TYPING:
		answer.grab_focus()
		answer.edit()
	else:
		answer.release_focus()


func _on_action_pressed() -> void:
	if phase == Phase.SUCCESS:
		completed.emit()
		return
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
	folder.status.text = "%d files" % wheat.filled_cells
	if elapsed_seconds >= time_limit_seconds:
		set_process(false)
		failed.emit()


func _on_answer_submitted(text: String) -> void:
	if phase != Phase.TYPING:
		return
	if _normalize_phrase(text) != _normalize_phrase(phrase):
		feedback.text = "Try that line again."
		answer.select_all()
		return

	accepted_repetitions += 1
	folder.flash()
	character_window.flash()
	answer.clear()
	var expression_index := mini(accepted_repetitions, WOLF_EXPRESSIONS.size() - 1)
	character_window.set_artwork_texture(WOLF_EXPRESSIONS[expression_index])
	feedback.text = "%d of %d." % [accepted_repetitions, required_repetitions]
	if accepted_repetitions == required_repetitions:
		phase = Phase.SUCCESS
		set_process(false)
		wheat.reset()
		folder.status.text = "0 files"
		instruction.text = "The folder is clear."
		speech.say("All right. No more grain.", "Continue")
		feedback.text = ""
		answer.hide()
		won.emit()


func _normalize_phrase(text: String) -> String:
	# Keep Estonian letters, but don't punish capitalization, punctuation, or extra spaces.
	var normalized := text.to_lower().strip_edges()
	for punctuation in [",", ".", "!", "?", "\"", "“", "”", "„"]:
		normalized = normalized.replace(punctuation, "")
	return " ".join(normalized.split(" ", false))
