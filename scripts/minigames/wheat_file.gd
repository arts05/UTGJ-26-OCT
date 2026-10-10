extends Control

@onready var icon: ColorRect = $Icon
@onready var file_name: Label = $Name


func _ready() -> void:
	icon.pivot_offset = icon.size * 0.5
	icon.scale = Vector2.ONE * 0.65
	file_name.modulate.a = 0.0
	var highlight: ShaderMaterial = icon.material
	highlight.set_shader_parameter("flash_amount", 1.0)
	var arrival := create_tween().set_parallel(true)
	arrival.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	arrival.tween_property(icon, "scale", Vector2.ONE, 0.25)
	arrival.tween_property(file_name, "modulate:a", 1.0, 0.25)
	arrival.tween_property(highlight, "shader_parameter/flash_amount", 0.0, 0.5)
