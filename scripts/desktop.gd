extends Control

@onready var antivirus: Panel = $Antivirus
@onready var antivirus_button: Button = $Taskbar/AntivirusButton
@onready var uptime_label: Label = $Taskbar/UptimeLabel

var elapsed_seconds: float = 0.0


func _ready() -> void:
    antivirus.visibility_changed.connect(_on_antivirus_visibility_changed)
    antivirus_button.set_pressed_no_signal(antivirus.visible)


func _process(delta: float) -> void:
    elapsed_seconds += delta
    uptime_label.text = "Uptime: %d s" % int(elapsed_seconds)


func _on_antivirus_button_toggled(is_open: bool) -> void:
    # Keep the app in the tree so scans and tasks continue while minimized.
    antivirus.visible = is_open


func _on_antivirus_visibility_changed() -> void:
    antivirus_button.set_pressed_no_signal(antivirus.visible)
