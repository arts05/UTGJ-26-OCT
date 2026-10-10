extends "res://scripts/apps/window_art.gd"

signal accepted
signal declined


func _on_run_pressed() -> void:
	accepted.emit()


func _on_back_pressed() -> void:
	declined.emit()


func _on_details_toggled(show_details: bool) -> void:
	$Details.visible = show_details
