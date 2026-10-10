extends Control
## Both characters share the desktop, with one button to begin the good ending.

signal continued

@export_multiline var kratt_message: String = "You did it!\n\nThe last check is complete. Congratulations!"

@onready var kratt = $Kratt


func start() -> void:
	kratt.say(kratt_message, "Finish", 2)


func _on_kratt_continued() -> void:
	continued.emit()
