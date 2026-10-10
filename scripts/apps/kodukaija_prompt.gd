extends "res://scripts/apps/window_art.gd"

signal accepted
signal declined


func _on_run_pressed() -> void:
	accepted.emit()


func _on_back_pressed() -> void:
	declined.emit()
