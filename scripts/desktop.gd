extends Control

@onready var status_label: Label = $StatusLabel

var elapsed_seconds: float = 0.0


func _process(delta: float) -> void:
    elapsed_seconds += delta
    status_label.text = "Running: %d seconds" % int(elapsed_seconds)