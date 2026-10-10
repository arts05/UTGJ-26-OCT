extends Node3D
## Maps mouse hits on the curved screen through its UVs into desktop pixels.

const OUTSIDE_SCREEN := Vector2(-1.0, -1.0)

@onready var screen: MeshInstance3D = $Model/Screen
@onready var computer_viewport: SubViewport = $ComputerViewport
@onready var desktop = $ComputerViewport/Desktop

var interactive: bool = false
var mouse_inside: bool = false
var left_button_down: bool = false
var last_mouse_position := Vector2.ZERO
var screen_triangles: TriangleMesh
var screen_vertices: PackedVector3Array
var screen_uvs: PackedVector2Array
var screen_indices: PackedInt32Array
var last_hit_face_start: int = -1
var drag_plane: Plane


func _ready() -> void:
	assert(screen.mesh.get_surface_count() == 1, "The screen needs one surface with desktop UVs.")
	var arrays := screen.mesh.surface_get_arrays(0)
	screen_vertices = arrays[Mesh.ARRAY_VERTEX]
	screen_uvs = arrays[Mesh.ARRAY_TEX_UV]
	screen_indices = arrays[Mesh.ARRAY_INDEX]
	screen_triangles = screen.mesh.generate_triangle_mesh()
	get_window().mouse_exited.connect(_clear_pointer)
	get_window().focus_exited.connect(_on_window_focus_exited)
	get_window().focus_entered.connect(_restore_desktop_focus)


func set_interactive(enabled: bool) -> void:
	interactive = enabled
	desktop.set_computer_focused(enabled)
	if not enabled:
		_clear_pointer()
		computer_viewport.gui_release_focus()
		return

	# Refresh hover after zooming, even if the mouse hasn't moved yet.
	var motion := InputEventMouseMotion.new()
	motion.position = get_viewport().get_mouse_position()
	_forward_mouse(motion)


func _unhandled_input(event: InputEvent) -> void:
	if not interactive:
		return

	if event is InputEventMouseMotion:
		_forward_mouse(event)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_forward_mouse(event)
	elif event is InputEventKey and not event.is_action("leave_computer"):
		# Letters, Enter, and editing shortcuts belong to the focused desktop control.
		# Escape stays with the room camera.
		computer_viewport.push_input(event, true)
		get_viewport().set_input_as_handled()


func _forward_mouse(event: InputEventMouse) -> void:
	var desktop_position := _get_desktop_position(event.position)
	if desktop_position == OUTSIDE_SCREEN:
		_clear_pointer()
		return

	if not mouse_inside:
		computer_viewport.notify_mouse_entered()
		mouse_inside = true
		last_mouse_position = desktop_position

	var forwarded := event.duplicate() as InputEventMouse
	forwarded.position = desktop_position
	forwarded.global_position = desktop_position
	if forwarded is InputEventMouseMotion:
		forwarded.relative = desktop_position - last_mouse_position
	if forwarded is InputEventMouseButton:
		left_button_down = forwarded.pressed

	last_mouse_position = desktop_position
	computer_viewport.push_input(forwarded, true)
	get_viewport().set_input_as_handled()


func _get_desktop_position(window_position: Vector2) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	var screen_inverse := screen.global_transform.affine_inverse()
	var ray_origin := screen_inverse * camera.project_ray_origin(window_position)
	var ray_direction := screen_inverse.basis * camera.project_ray_normal(window_position)
	var hit := screen_triangles.intersect_ray(ray_origin, ray_direction)
	var face_start := last_hit_face_start
	var hit_position: Vector3
	if hit.is_empty():
		if not left_button_down or last_hit_face_start < 0:
			return OUTSIDE_SCREEN
		# Continue a held drag on the last touched triangle's plane, beyond the glass.
		var continued_hit = drag_plane.intersects_ray(ray_origin, ray_direction)
		if continued_hit == null:
			return OUTSIDE_SCREEN
		hit_position = continued_hit
	else:
		face_start = hit.face_index * 3
		hit_position = hit.position

	var first_index := screen_indices[face_start]
	var second_index := screen_indices[face_start + 1]
	var third_index := screen_indices[face_start + 2]
	var first := screen_vertices[first_index]
	var second := screen_vertices[second_index]
	var third := screen_vertices[third_index]
	# Godot uses clockwise front faces. Ignore hits on the back of the glass.
	var face_normal := (third - first).cross(second - first)
	if face_normal.dot(ray_direction) >= 0.0:
		return OUTSIDE_SCREEN
	last_hit_face_start = face_start
	drag_plane = Plane(face_normal.normalized(), first)

	# Barycentric weights also extend the UV mapping outside a triangle during a drag.
	var weights := Geometry3D.get_triangle_barycentric_coords(hit_position, first, second, third)
	var uv := (
		screen_uvs[first_index] * weights.x
		+ screen_uvs[second_index] * weights.y
		+ screen_uvs[third_index] * weights.z
	)
	# Match the shader's inset so clicks still land on the displayed desktop pixels.
	var material := screen.material_override as ShaderMaterial
	var border_pixels: float = material.get_shader_parameter("border_pixels")
	var border := Vector2.ONE * border_pixels / Vector2(computer_viewport.size)
	var desktop_uv := (uv - border) / (Vector2.ONE - border * 2.0)
	if not left_button_down and not Rect2(Vector2.ZERO, Vector2.ONE).has_point(desktop_uv):
		return OUTSIDE_SCREEN
	return desktop_uv * Vector2(computer_viewport.size)


func _clear_pointer() -> void:
	if left_button_down:
		# Cancel at the last position; a fake outside motion would move a dragged window.
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.position = last_mouse_position
		release.global_position = last_mouse_position
		release.canceled = true
		computer_viewport.push_input(release, true)
		left_button_down = false
	last_hit_face_start = -1

	if mouse_inside:
		computer_viewport.notify_mouse_exited()
		mouse_inside = false


func _on_window_focus_exited() -> void:
	_clear_pointer()
	computer_viewport.gui_release_focus()
	desktop.set_computer_focused(false)


func _restore_desktop_focus() -> void:
	desktop.set_computer_focused(interactive)
