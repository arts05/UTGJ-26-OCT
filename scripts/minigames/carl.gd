extends Control

signal won
signal failed
signal answer_accepted
signal answer_rejected

enum Phase { QUESTION, RESPONSE, SUCCESS, FAILURE }

@export_range(1, 4) var passing_score: int = 3

const CARL_QUESTION_SPRITE: Texture2D = preload("res://assets/sprites/carl1.png")
const CARL_LAST_ANSWER_CORRECT_SPRITE: Texture2D = preload("res://assets/sprites/carl3.png")
const CARL_LAST_ANSWER_WRONG_SPRITE: Texture2D = preload("res://assets/sprites/carl2.png")

const QUESTIONS: Array[Dictionary] = [
	{
		"question": "What words must one utter to compel a Viljaneitsi to take her leave?",
		"answers": ["Dear maidens, do no evil!", "Dear maidens, fear no evil!", "Maiden, please leave.", "The land upon which you stand belongs to the Estonian people."],
		"correct_index": 0,
	},
	{
		"question": "What earthly guises might a Viljaneitsi deign to reveal herself?",
		"answers": ["Fox and Siren.", "Wolf and Fairy.", "Sheep and Cat.", "Hawk and Human."],
		"correct_index": 1,
	},
	{
		"question": "Where is one most likely to encounter a Kodukäija?",
		"answers": ["A Kodukäija roams around the town hall.", "A Kodukäija haunts its former place of residence.",
		 "A Kodukäija spends its life living under a bridge.", "A Kodukäija torments the local well."],
		"correct_index": 1,
	},
	{
		"question": "Which of these four remedies might grant one the means of escaping the clutches of a Kodukäija?",
		"answers": ["Fighting a Kodukäija with a birch bundle.", "Look them deep in their eyes.", "Start singing the national anthem of Estonia.",
		"Speak its name."],
		"correct_index": 3,
	},
	{
		"question": "What is the name of Kalevipoeg's assistant?",
		"answers": ["Kalev.", "Scrat.", "Kratt.",
		"Vahur."],
		"correct_index": 2,
	},
]

const RESPONSE_LINES: Array[String] = [
	"Viljaneitsi, often referred to as the Guardian of the Grain, is said to bestow prosperity and vigour upon the crops, provided that proper offerings are made both ere the harvest and upon its conclusion.",
	"It is said that Viljaneitsi assumes the guise of a wolf only when her intentions are of a most malevolent nature, seeking to bring misfortune and harm upon the unfortunate.",
	"There exists yet another manifestation of the Kodukäija, known as Kääbas, whose restless spirit is most commonly found haunting the very grounds upon which its mortal life was brought to an end.",
	"One may also seek to ward off or diminish the dreadful influence of a Kodukäija through the employment of silver, or by seeking refuge in the blessed light of the morning sun.",
	"A Kratt must, under all circumstances, be furnished with labour by its creator, for should the creature find itself without purpose, it shall inevitably turn its wrath upon the very master who brought it into existence.",
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
@onready var answers_container: Control = $QuizWindow/Quiz/Answers
@onready var feedback: Label = $QuizWindow/Quiz/Feedback
@onready var continue_button: Button = $QuizWindow/Quiz/ContinueButton
@onready var result_message: Label = $QuizWindow/ResultMessage
@onready var carl_portrait: TextureRect = $QuizWindow/CarlPortrait

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
	carl_portrait.texture = CARL_QUESTION_SPRITE
	quiz.show()
	result_message.hide()
	_show_question()


func _show_question() -> void:
	var current_question: Dictionary = QUESTIONS[question_index]
	carl_portrait.texture = CARL_QUESTION_SPRITE
	answers_container.show()
	question_number.text = "QUESTION %d OF %d" % [question_index + 1, QUESTIONS.size()]
	question_label.text = current_question["question"]
	for index in range(answer_buttons.size()):
		answer_buttons[index].text = current_question["answers"][index]
	feedback.text = ""
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
	if phase == Phase.RESPONSE:
		_advance_after_response()
		return
	if phase != Phase.QUESTION or selected_answer < 0:
		return
	var was_correct: bool = selected_answer == QUESTIONS[question_index]["correct_index"]
	if was_correct:
		correct_answers += 1
		answer_accepted.emit()
		quiz_window.flash()
		carl_portrait.texture = CARL_LAST_ANSWER_CORRECT_SPRITE
	else:
		answer_rejected.emit()
		carl_portrait.texture = CARL_LAST_ANSWER_WRONG_SPRITE
	question_index += 1
	phase = Phase.RESPONSE
	answers_container.hide()
	question_number.text = "Carl's sage of reflection: "
	question_label.text = RESPONSE_LINES[question_index - 1]
	feedback.text = ""
	selected_answer = -1
	for button in answer_buttons:
		button.set_pressed_no_signal(false)
	continue_button.text = "Continue"
	continue_button.disabled = false
	continue_button.show()


func _advance_after_response() -> void:
	if question_index >= QUESTIONS.size():
		_finish_quiz()
	else:
		phase = Phase.QUESTION
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
