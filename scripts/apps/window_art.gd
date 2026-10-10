extends Control
## Shared opening, frame feedback, and title-bar dragging for the drawn windows.

@export var taskbar_height: float = 28.0
@export var artwork: TextureRect
@export var shadow: TextureRect
@export var shadow_offset := Vector2(6, 8)
@export var drag_shadow_offset := Vector2(11, 14)
@export_range(0.0, 0.5) var opening_seconds: float = 0.24
@export_range(0.0, 8.0) var idle_float_pixels: float = 0.0

var dragging: bool = false
var drag_offset := Vector2.ZERO
var resting_position := Vector2.ZERO
var float_time: float = 0.0
var frame_material: ShaderMaterial
var opening_tween: Tween
var highlight_tween: Tween
var flash_tween: Tween
var shadow_tween: Tween


func _ready() -> void:
	artwork.material = artwork.material.duplicate()
	frame_material = artwork.material
	resting_position = position
	visibility_changed.connect(_on_visibility_changed)
	$TitleBar.mouse_entered.connect(_on_title_bar_mouse_entered)
	$TitleBar.mouse_exited.connect(_on_title_bar_mouse_exited)
	set_process(idle_float_pixels > 0.0)
	if is_visible_in_tree():
		_on_visibility_changed()


func _process(delta: float) -> void:
	if not dragging:
		float_time += delta
		position.y = resting_position.y + sin(float_time * TAU / 4.5) * idle_float_pixels


func _on_visibility_changed() -> void:
	dragging = false
	if opening_tween:
		opening_tween.kill()
	if highlight_tween:
		highlight_tween.kill()
	if shadow_tween:
		shadow_tween.kill()
	shadow.position = artwork.position + shadow_offset
	frame_material.set_shader_parameter("highlight_amount", 0.0)
	if not is_visible_in_tree():
		return
	position = resting_position
	float_time = 0.0
	pivot_offset = size * 0.5
	scale = Vector2.ONE * 0.97
	modulate.a = 0.0
	opening_tween = create_tween().set_parallel(true)
	opening_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	opening_tween.tween_property(self, "scale", Vector2.ONE, opening_seconds)
	opening_tween.tween_property(self, "modulate:a", 1.0, opening_seconds)


func set_artwork_texture(texture: Texture2D) -> void:
	artwork.texture = texture
	shadow.texture = texture


func flash() -> void:
	if flash_tween:
		flash_tween.kill()
	frame_material.set_shader_parameter("flash_amount", 1.0)
	flash_tween = create_tween()
	flash_tween.tween_property(frame_material, "shader_parameter/flash_amount", 0.0, 0.4)


func _set_highlight(amount: float) -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = create_tween()
	highlight_tween.tween_property(frame_material, "shader_parameter/highlight_amount", amount, 0.12)


func _set_shadow_lift(lifted: bool) -> void:
	if shadow_tween:
		shadow_tween.kill()
	var target_offset := drag_shadow_offset if lifted else shadow_offset
	shadow_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	shadow_tween.tween_property(shadow, "position", artwork.position + target_offset, 0.14)


func _on_title_bar_mouse_entered() -> void:
	_set_highlight(1.0)


func _on_title_bar_mouse_exited() -> void:
	if not dragging:
		_set_highlight(0.0)


func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed and not event.canceled
		if dragging:
			# Drag the actual control, so its contents and input always move together.
			if opening_tween:
				opening_tween.kill()
			scale = Vector2.ONE
			modulate.a = 1.0
			drag_offset = event.global_position - position
			move_to_front()
			_set_highlight(1.0)
		else:
			resting_position = position
			float_time = 0.0
			_set_highlight(0.0)
		_set_shadow_lift(dragging)
		accept_event()

	if event is InputEventMouseMotion and dragging:
		var desktop_size := get_parent_control().size - Vector2(0, taskbar_height)
		position = (event.global_position - drag_offset).clamp(
			Vector2.ZERO, desktop_size - size
		)
		resting_position = position
		accept_event()
