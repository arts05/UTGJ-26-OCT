class_name GameLoadingScreen
extends CanvasLayer
## Covers the room while it is loaded, created, and rendered for the first time.

@onready var panel: ColorRect = $Panel
@onready var message: Label = $Panel/Center/Content/Message
@onready var progress: ProgressBar = $Panel/Center/Content/Progress
@onready var back_button: Button = $Panel/Center/Content/Back


func _ready() -> void:
	RoomStartup.progress_changed.connect(_on_startup_progress)


func _on_startup_progress(value: float) -> void:
	progress.value = value * 100.0


func _input(_event: InputEvent) -> void:
	# The room is already in the tree during its first draws. Keep clicks and pause
	# keys from reaching it until the loading screen has completely faded away.
	if visible and not back_button.visible:
		get_viewport().set_input_as_handled()
