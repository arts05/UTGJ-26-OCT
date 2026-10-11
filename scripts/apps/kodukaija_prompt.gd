extends "res://scripts/apps/window_art.gd"

signal accepted
signal declined

@export_range(1.5, 5.0, 0.5) var metadata_display_seconds: float = 1.5

@onready var details: ColorRect = $Details
@onready var instructions: Label = $Details/Instructions
@onready var buttons_cover: ColorRect = $ButtonsCover
@onready var yes_button: Button = $YesButton
@onready var no_button: Button = $NoButton

var details_tween: Tween
var auto_reveal_started := false


func _ready() -> void:
	super._ready()
	var material := details.material as ShaderMaterial
	material.set_shader_parameter("reveal_amount", 0.0)
	instructions.modulate.a = 0.0
	buttons_cover.show()
	yes_button.disabled = true
	no_button.disabled = true
	visibility_changed.connect(_on_prompt_visibility_changed)
	_center_prompt()
	_on_prompt_visibility_changed()


func _on_run_pressed() -> void:
	accepted.emit()


func _on_back_pressed() -> void:
	declined.emit()


func _on_prompt_visibility_changed() -> void:
	if not is_visible_in_tree() or auto_reveal_started:
		return
	_center_prompt()
	auto_reveal_started = true
	details_tween = create_tween()
	details_tween.tween_interval(metadata_display_seconds)
	details_tween.tween_callback(_reveal_tutorial)


func _center_prompt() -> void:
	var desktop := get_parent_control()
	if desktop == null:
		return
	set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	position = ((desktop.size - size) * 0.5).round()
	resting_position = position


func _reveal_tutorial() -> void:
	var material := details.material as ShaderMaterial
	details.show()
	details_tween = create_tween()
	details_tween.set_parallel(true)
	details_tween.tween_property(material, "shader_parameter/reveal_amount", 1.0, 0.5)
	details_tween.tween_property(buttons_cover, "color:a", 0.0, 0.5)
	details_tween.tween_property(instructions, "modulate:a", 1.0, 0.5)
	details_tween.set_parallel(false)
	details_tween.tween_callback(_enable_action_buttons)


func _enable_action_buttons() -> void:
	buttons_cover.hide()
	yes_button.disabled = false
	no_button.disabled = false
