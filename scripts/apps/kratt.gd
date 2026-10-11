extends Control

signal continued

const EXPRESSIONS: Array[Texture2D] = [
	preload("res://assets/sprites/kratt1.png"),
	preload("res://assets/sprites/kratt2.png"),
	preload("res://assets/sprites/kratt3.png"),
]

@onready var portrait: TextureRect = $Portrait
@onready var speech = $Speech
@onready var continue_button: Button = $Speech/Panel/Margins/Stack/Actions/ActionButton


func say(text: String, button_text: String, expression: int = 0) -> void:
	speech.say(text, button_text)
	portrait.texture = EXPRESSIONS[expression]
	# The button keeps the width of its previous label when the text changes
	# while the screen is already visible, so re-fit it after the layout settles.
	await get_tree().process_frame
	continue_button.reset_size()


func _on_continue_pressed() -> void:
	continued.emit()
