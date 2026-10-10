extends Control

signal won
signal failed
signal answer_accepted
signal answer_rejected

enum Phase { QUESTION, SUCCESS, FAILURE }

@export_range(1, 4) var passing_score: int = 3

const QUESTIONS: Array[Dictionary] = [
	{
		"question": "What words must one utter to compel a Viljaneitsi to take her leave?",
		"answers": ["Dear maidens, do no evil!", "Placeholder answer 1", "Placeholder answer 2", "Placeholder answer 3"],
		"correct_index": 0,
	},
	{
		"question": "What earthly guises might a Grain Maiden deign to reveal herself?",
		"answers": ["Placeholder answer 1", "Wolf and Fairy.", "Placeholder answer 2", "Placeholder answer 3"],
		"correct_index": 1,
	},
	{
		"question": "Where is one most likely to encounter a Revenant?",
		"answers": ["Placeholder answer 1", "Placeholder answer 2", "A revenant haunts its former place of residence.", "Placeholder answer 3"],
		"correct_index": 2,
	},
	{
		"question": "Which of these four remedies might grant one the means of escaping the clutches of a Revenant?",
		"answers": ["Placeholder answer 1", "Placeholder answer 2", "Placeholder answer 3", "Speak its name."],
		"correct_index": 3,
	},
]

@onready var quiz_window = $QuizWindow
@onready var quiz: Control = $QuizWindow/Quiz
@onready var question_number: Label = $QuizWindow/Quiz/QuestionNumber
@onready var question_label: Label = $QuizWindow/Quiz/Question
@onready var answer_buttons: Array[CheckBox] = [
	$QuizWindow/Quiz/Answers/Answer1,
	$QuizWindow/Quiz/Answers/Answer2,
	$QuizWindow/Quiz/Answers/Answer3,
	$QuizWindow/Quiz/Answers/Answer4,
]
@onready var feedback: Label = $QuizWindow/Quiz/Feedback
@onready var continue_button: Button = $QuizWindow/Quiz/ContinueButton
@onready var result_message: Label = $QuizWindow/ResultMessage

var phase: Phase = Phase.QUESTION
var question_index: int = 0
var selected_answer: int = -1
var correct_answers: int = 0


func _ready() -> void:
	var unchecked_icon := _radio_icon(false)
	var checked_icon := _radio_icon(true)
	for button in answer_buttons:
		button.add_theme_icon_override("radio_unchecked", unchecked_icon)
		button.add_theme_icon_override("radio_checked", checked_icon)
	answer_buttons[0].button_group.pressed.connect(_on_answer_selected)
	reset()


func _radio_icon(checked: bool) -> Texture2D:
	var dot := '<circle cx="12" cy="12" r="5" fill="#303841"/>' if checked else ""
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="#f6f7f6" stroke="#96a4b2" stroke-width="1.5"/>%s</svg>' % dot
	var icon_image := Image.new()
	icon_image.load_svg_from_string(svg)
	return ImageTexture.create_from_image(icon_image)


func reset() -> void:
	phase = Phase.QUESTION
	question_index = 0
	correct_answers = 0
	quiz.show()
	result_message.hide()
	_show_question()


func _show_question() -> void:
	var current_question: Dictionary = QUESTIONS[question_index]
	question_number.text = "QUESTION %d OF %d" % [question_index + 1, QUESTIONS.size()]
	question_label.text = current_question["question"]
	for index in range(answer_buttons.size()):
		answer_buttons[index].text = current_question["answers"][index]
	feedback.text = "" if question_index == 0 else "Answer recorded."
	_clear_selection()


func _clear_selection() -> void:
	selected_answer = -1
	for button in answer_buttons:
		button.set_pressed_no_signal(false)
	continue_button.disabled = true
	continue_button.hide()


func _on_answer_selected(button: BaseButton) -> void:
	if phase != Phase.QUESTION:
		return
	selected_answer = answer_buttons.find(button)
	feedback.text = ""
	continue_button.disabled = selected_answer < 0
	continue_button.visible = selected_answer >= 0


func _on_continue_pressed() -> void:
	if phase != Phase.QUESTION or selected_answer < 0:
		return
	if selected_answer == QUESTIONS[question_index]["correct_index"]:
		correct_answers += 1
		answer_accepted.emit()
		quiz_window.flash()
	else:
		answer_rejected.emit()
	question_index += 1
	if question_index == QUESTIONS.size():
		_finish_quiz()
	else:
		_show_question()


func _finish_quiz() -> void:
	var passed := correct_answers >= passing_score
	phase = Phase.SUCCESS if passed else Phase.FAILURE
	_clear_selection()
	quiz.hide()
	result_message.text = "%d of %d correct." % [correct_answers, QUESTIONS.size()]
	result_message.show()
	if passed:
		won.emit()
	else:
		failed.emit()
