class_name SceneFade
extends CanvasLayer
## A black curtain shared by the menu and room scenes.

@export_range(0.1, 2.0, 0.05) var fade_seconds: float = 0.6

@onready var black: ColorRect = $Black

var is_fading: bool = false


func _ready() -> void:
	black.modulate.a = 1.0
	fade_from_black()


func _input(_event: InputEvent) -> void:
	if black.visible:
		get_viewport().set_input_as_handled()


func fade_from_black() -> void:
	await _fade_to(0.0)
	black.hide()


func fade_to_black() -> void:
	await _fade_to(1.0)
	# Render a completely black frame before loading the next scene.
	await get_tree().process_frame


func _fade_to(opacity: float) -> void:
	is_fading = true
	black.show()
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(black, "modulate:a", opacity, fade_seconds)
	await tween.finished
	is_fading = false
