extends Button
## A small highlight on hover; layout and hitboxes stay still.

@export_range(0.05, 0.4) var hover_seconds: float = 0.12

var highlight: ShaderMaterial
var hover_tween: Tween
var press_tween: Tween


func _ready() -> void:
	# Buttons in the same scene must not share their animated shader values.
	material = material.duplicate()
	highlight = material
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	visibility_changed.connect(_on_visibility_changed)


func _on_mouse_entered() -> void:
	if not disabled:
		_set_hover(1.0)


func _on_mouse_exited() -> void:
	_set_hover(0.0)


func _set_hover(amount: float) -> void:
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(highlight, "shader_parameter/hover_amount", amount, hover_seconds)


func _on_button_down() -> void:
	if press_tween:
		press_tween.kill()
	highlight.set_shader_parameter("flash_amount", 0.7)
	press_tween = create_tween()
	press_tween.tween_property(highlight, "shader_parameter/flash_amount", 0.0, 0.22)


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		if hover_tween:
			hover_tween.kill()
		if press_tween:
			press_tween.kill()
		highlight.set_shader_parameter("hover_amount", 0.0)
		highlight.set_shader_parameter("flash_amount", 0.0)
