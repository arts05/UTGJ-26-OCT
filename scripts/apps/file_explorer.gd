extends "res://scripts/apps/window_art.gd"

signal folder_opened

@onready var folder_button: Button = $Folder
@onready var address: Label = $Address/Path
@onready var contents: Control = $Contents
@onready var status: Label = $Status


func show_parent_folder() -> void:
	address.text = "C:\\"
	folder_button.show()
	contents.hide()
	status.text = "Open the folder Kratt found."


func open_folder() -> void:
	address.text = "C:\\Viljahunt"
	folder_button.hide()
	contents.show()
	status.text = "0 files"


func _on_folder_pressed() -> void:
	open_folder()
	folder_opened.emit()
