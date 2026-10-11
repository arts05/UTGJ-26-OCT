extends Control
## Search the panorama, recover a name, and look away when its owner watches.

signal failed
signal closed
signal won
signal completed
signal clue_found
signal hurt

enum Phase { SEARCHING, NAMING, BANISHING, ESCAPING, SUCCESS, FAILURE }

@export_group("Looking around")
@export var starting_view_x: float = 1850.0
@export var pan_speed: float = 1150.0
@export var pan_acceleration: float = 4800.0
@export_range(0.1, 0.4) var edge_zone: float = 0.24
@export var visibility_radius: float = 355.0
@export var threatened_visibility: float = 245.0

@export_group("Objective light")
@export var glow_distance: float = 3800.0
@export_range(0.0, 1.0) var distant_glow: float = 0.35
@export_range(0.0, 1.0) var nearby_glow: float = 0.95

@export_group("Haunting")
@export var first_appearance_delay: float = 2.4
@export var appearance_interval: Vector2 = Vector2(4.5, 7.0)
@export var banish_seconds: float = 1.0
@export var failure_seconds: float = 0.8

@onready var panorama: Node2D = $Panorama
@onready var map: TextureRect = $Panorama/Map
@onready var notes: Array[Node] = $Panorama/Notes.get_children()
@onready var ghost = $Panorama/Ghost
@onready var ghost_spawns: Array[Node] = $Panorama/GhostSpawns.get_children()
@onready var name_button: Button = $Panorama/Ghost/NameButton
@onready var ghost_focus: Marker2D = $Panorama/Ghost/FocusPoint
@onready var summoning_point: Marker2D = $Panorama/SummoningPoint
@onready var exit_door: Button = $Panorama/Exit
@onready var darkness: ColorRect = $Darkness
@onready var name_fragments: Label = $NameFragments
@onready var left_hint: Line2D = $LeftHint
@onready var right_hint: Line2D = $RightHint

var phase: Phase = Phase.SEARCHING
var collected_notes: Array[Button] = []
var computer_focused: bool = false
var pointer_position := Vector2(-1, -1)
var view_x: float = 1850.0
var pan_velocity: float = 0.0
var next_appearance: float = 0.0
var fog_time: float = 0.0
var light_amount: float = 1.0
var outcome_tween: Tween
var pickup_tween: Tween
var completion_sent: bool = false


func _ready() -> void:
	for note: Button in notes:
		note.pressed.connect(_collect_note.bind(note))
	ghost.attacked.connect(_on_ghost_attacked)
	ghost.retreated.connect(_on_ghost_retreated)
	reset()


func reset() -> void:
	if outcome_tween:
		outcome_tween.kill()
	if pickup_tween:
		pickup_tween.kill()
	phase = Phase.SEARCHING
	collected_notes.clear()
	completion_sent = false
	view_x = starting_view_x
	pan_velocity = 0.0
	next_appearance = first_appearance_delay
	fog_time = 0.0
	light_amount = 1.0
	ghost.reset()
	name_button.hide()
	name_fragments.show()
	name_fragments.modulate.a = 1.0
	exit_door.get_node("Outline").hide()
	for note: Button in notes:
		note.show()
	_update_name_fragments()
	_position_panorama()
	_update_interactions()
	_update_fog()


func set_computer_focused(focused: bool) -> void:
	computer_focused = focused
	if not focused:
		pan_velocity = 0.0
	_update_interactions()


func set_pointer_position(desktop_position: Vector2) -> void:
	# The CRT sends an outside position when the pointer leaves the physical glass.
	pointer_position = get_global_transform().affine_inverse() * desktop_position


func _process(delta: float) -> void:
	fog_time += delta
	if computer_focused:
		_pan_view(delta)
		_update_haunting(delta)
	_update_interactions()
	_update_fog()


func _pan_view(delta: float) -> void:
	if phase not in [Phase.SEARCHING, Phase.NAMING, Phase.ESCAPING]:
		return
	var direction := 0.0
	if Rect2(Vector2.ZERO, size).has_point(pointer_position):
		var edge_width := size.x * edge_zone
		if pointer_position.x < edge_width:
			direction = smoothstep(0.0, edge_width, pointer_position.x) - 1.0
		elif pointer_position.x > size.x - edge_width:
			direction = smoothstep(size.x - edge_width, size.x, pointer_position.x)
	pan_velocity = move_toward(pan_velocity, direction * pan_speed, pan_acceleration * delta)
	view_x += pan_velocity * delta
	_position_panorama()


func _position_panorama() -> void:
	var map_scale := size.y / map.size.y
	var half_view := size.x * 0.5 / map_scale
	view_x = clampf(view_x, half_view, map.size.x - half_view)
	panorama.scale = Vector2.ONE * map_scale
	panorama.position = Vector2(size.x * 0.5 - view_x * map_scale, 0.0)
	left_hint.visible = view_x > half_view + 1.0
	right_hint.visible = view_x < map.size.x - half_view - 1.0


func _view_position(map_position: Vector2) -> Vector2:
	return panorama.position + map_position * panorama.scale


func _is_in_light(map_position: Vector2) -> bool:
	var distance := _view_position(map_position).distance_to(size * 0.5)
	return distance < lerpf(visibility_radius, threatened_visibility, ghost.exposure) - 35.0


func _update_interactions() -> void:
	for note: Button in notes:
		note.disabled = (
			not computer_focused or phase != Phase.SEARCHING
			or collected_notes.has(note) or not _is_in_light(note.position + note.size * 0.5)
		)
		var paper: Polygon2D = note.get_node("Paper")
		paper.modulate = Color.WHITE if note.is_hovered() and not note.disabled else Color(0.8, 0.8, 0.8)
	var ghost_in_light := _is_in_light(ghost.position + ghost_focus.position)
	name_button.visible = phase == Phase.NAMING and ghost_in_light
	name_button.disabled = not computer_focused or not name_button.visible
	exit_door.disabled = (
		not computer_focused or phase != Phase.ESCAPING
		or not _is_in_light(exit_door.position + exit_door.size * 0.5)
	)
	left_hint.modulate.a = 0.55 if pan_velocity < -100.0 else 0.2
	right_hint.modulate.a = 0.55 if pan_velocity > 100.0 else 0.2
	left_hint.modulate.a *= light_amount
	right_hint.modulate.a *= light_amount


func _objective_position() -> Vector2:
	if phase == Phase.SEARCHING:
		for note: Button in notes:
			if not collected_notes.has(note):
				return note.position + note.size * 0.5
	if phase == Phase.NAMING:
		return ghost.position + ghost_focus.position
	return exit_door.position + exit_door.size * 0.5


func _update_fog() -> void:
	var material := darkness.material as ShaderMaterial
	var radius := lerpf(visibility_radius, threatened_visibility, ghost.exposure)
	material.set_shader_parameter("radius", radius * light_amount)
	material.set_shader_parameter("fog_time", fog_time)
	material.set_shader_parameter("view_size", size)
	material.set_shader_parameter("pan_offset", view_x / map.size.x)
	material.set_shader_parameter("dread", ghost.exposure)
	material.set_shader_parameter("escaping", phase == Phase.ESCAPING)
	var active := phase in [Phase.SEARCHING, Phase.NAMING, Phase.ESCAPING]
	var target := _objective_position()
	var center := size * 0.5
	var direction := _view_position(target) - center
	var bounds := center - Vector2(65, 65)
	# A distant item shines from the correct edge, then the light settles onto it.
	var edge_scale := maxf(1.0, maxf(absf(direction.x) / bounds.x, absf(direction.y) / bounds.y))
	material.set_shader_parameter("objective_position", center + direction / edge_scale)
	var proximity := 1.0 - smoothstep(120.0, glow_distance, absf(view_x - target.x))
	var strength := lerpf(distant_glow, nearby_glow, proximity) if active else 0.0
	material.set_shader_parameter("objective_strength", strength)


func _collect_note(note: Button) -> void:
	if phase != Phase.SEARCHING or note.disabled:
		return
	collected_notes.append(note)
	note.hide()
	_update_name_fragments()
	clue_found.emit()
	if pickup_tween:
		pickup_tween.kill()
	name_fragments.modulate.a = 0.35
	pickup_tween = create_tween()
	pickup_tween.tween_property(name_fragments, "modulate:a", 1.0, 0.3)
	if collected_notes.size() == notes.size():
		_begin_naming()


func _update_name_fragments() -> void:
	var fragments := PackedStringArray()
	for note: Button in notes:
		fragments.append(note.text if collected_notes.has(note) else "—")
	name_fragments.text = "  ".join(fragments)


func _update_haunting(delta: float) -> void:
	if phase != Phase.SEARCHING or collected_notes.is_empty():
		return
	if ghost.active:
		var ghost_x := _view_position(ghost.position).x
		# Looking is the direction of the view, not where the cursor happens to be.
		var looking_at_ghost := absf(ghost_x - size.x * 0.5) < visibility_radius * 0.75
		ghost.observe(looking_at_ghost, delta)
	else:
		next_appearance -= delta
		if next_appearance <= 0.0:
			_spawn_ghost()


func _spawn_ghost() -> void:
	var toward_objective := signf(_objective_position().x - view_x)
	var desired_x := view_x + toward_objective * 160.0
	var nearest: Marker2D = ghost_spawns[0]
	for point: Marker2D in ghost_spawns:
		if absf(point.position.x - desired_x) < absf(nearest.position.x - desired_x):
			nearest = point
	ghost.position = nearest.position
	ghost.appear()


func _on_ghost_retreated() -> void:
	next_appearance = randf_range(appearance_interval.x, appearance_interval.y)


func _begin_naming() -> void:
	phase = Phase.NAMING
	ghost.reset()
	ghost.position = summoning_point.position
	ghost.appear(false)
	var full_name := ""
	for note: Button in notes:
		full_name += note.text
	name_button.text = full_name
	name_fragments.hide()


func _on_name_pressed() -> void:
	if phase != Phase.NAMING or name_button.disabled:
		return
	phase = Phase.BANISHING
	pan_velocity = 0.0
	name_button.hide()
	clue_found.emit()
	ghost.disappear(banish_seconds)
	outcome_tween = create_tween()
	outcome_tween.tween_interval(banish_seconds)
	outcome_tween.tween_callback(_open_exit)


func _open_exit() -> void:
	phase = Phase.ESCAPING
	exit_door.get_node("Outline").show()


func _on_exit_pressed() -> void:
	if phase != Phase.ESCAPING or exit_door.disabled:
		return
	phase = Phase.SUCCESS
	pan_velocity = 0.0
	won.emit()


func finish_release() -> void:
	# The room calls this after its physical ghost-release sequence has finished.
	if phase == Phase.SUCCESS and not completion_sent:
		completion_sent = true
		completed.emit()


func _on_ghost_attacked() -> void:
	phase = Phase.FAILURE
	pan_velocity = 0.0
	hurt.emit()
	name_fragments.hide()
	outcome_tween = create_tween()
	outcome_tween.tween_property(self, "light_amount", 0.0, failure_seconds)
	outcome_tween.tween_callback(failed.emit)


func _on_close_pressed() -> void:
	ghost.reset()
	closed.emit()
