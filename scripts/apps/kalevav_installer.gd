extends "res://scripts/apps/window_art.gd"

signal installed
signal installation_completed

enum Page { WELCOME, EXPLANATION, INSTALLING, COMPLETE }

const KALEV_EXPLAINING: Texture2D = preload("res://assets/sprites/kalev2.png")
const KALEV_FINISHED: Texture2D = preload("res://assets/sprites/kalev3.png")

@export_range(0.5, 10.0) var installation_seconds: float = 4.0

@onready var install_button: Button = $Content/Stack/Actions/InstallButton
@onready var progress: ProgressBar = $Content/Stack/Progress
@onready var heading: Label = $Content/Stack/Heading
@onready var status: Label = $Content/Stack/Status
@onready var kalevipoeg: TextureRect = $Kalevipoeg

var page: Page = Page.WELCOME
var elapsed_seconds: float = 0.0


func _ready() -> void:
	super._ready()
	set_process(false)


func _on_install_pressed() -> void:
	match page:
		Page.WELCOME:
			page = Page.EXPLANATION
			kalevipoeg.texture = KALEV_EXPLAINING
			heading.text = "Before we begin"
			status.text = "Install KalevAV first.\n\nKratt will then help you check the files on this computer."
			install_button.text = "Install"
		Page.EXPLANATION:
			page = Page.INSTALLING
			install_button.disabled = true
			progress.show()
			elapsed_seconds = 0.0
			heading.text = "Installing KalevAV"
			status.text = "Downloading KalevAV..."
			set_process(true)
		Page.COMPLETE:
			installed.emit()


func _process(delta: float) -> void:
	elapsed_seconds += delta
	var completion := elapsed_seconds / installation_seconds
	progress.value = completion * 100.0
	if completion >= 0.85:
		status.text = "Checking your disk..."
	elif completion >= 0.45:
		status.text = "Installing KalevAV..."
	if elapsed_seconds >= installation_seconds:
		set_process(false)
		page = Page.COMPLETE
		kalevipoeg.texture = KALEV_FINISHED
		heading.text = "Installation complete"
		status.text = "KalevAV is ready.\n\nKratt has something to show you."
		install_button.disabled = false
		install_button.text = "Finish"
		installation_completed.emit()
