extends Control

signal failed
signal closed
signal won
signal completed
signal clue_found
signal hurt

enum Phase { SEARCHING, NAMING, ESCAPING, SUCCESS, FAILURE }

@export_range(1, 10) var contacts_before_crash: int = 4
@export var initial_visibility: float = 300.0
@export var minimum_visibility: float = 150.0
@export var interaction_distance: float = 55.0
@export var naming_distance: float = 100.0

@export_group("Objective glow")
@export var glow_distance: float = 950.0
@export_range(0.0, 1.0) var distant_glow: float = 0.3
@export_range(0.0, 1.0) var nearby_glow: float = 1.0

@onready var house = $GameView/HouseViewport/House
@onready var house_viewport: SubViewport = $GameView/HouseViewport
@onready var player = $GameView/HouseViewport/House/Player
@onready var ghost = $GameView/HouseViewport/House/Ghost
@onready var spawn: Marker2D = $GameView/HouseViewport/House/PlayerSpawn
@onready var exit_door: Marker2D = $GameView/HouseViewport/House/Exit
@onready var summoning_point: Marker2D = $GameView/HouseViewport/House/SummoningPoint
@onready var clues: Array[Node] = $GameView/HouseViewport/House/Clues.get_children()
@onready var darkness: ColorRect = $Darkness
@onready var prompt: Label = $InteractionPrompt
@onready var name_fragment: Label = $NameFragment
@onready var continue_button: Button = $ContinueButton

var phase: Phase = Phase.SEARCHING
var clue_index: int = 0
var discovered_name: String = ""
var contact_count: int = 0
var visibility_radius: float = 300.0
var target_visibility: float = 300.0
var computer_focused: bool = false
var fog_time: float = 0.0
var fragment_seconds: float = 0.0
var release_tween: Tween


func _ready() -> void:
	ghost.touched_player.connect(_on_ghost_contact)
	player.interacted.connect(_interact)
	reset()


func reset() -> void:
	if release_tween:
		release_tween.kill()
	set_process(true)
	phase = Phase.SEARCHING
	clue_index = 0
	discovered_name = ""
	contact_count = 0
	visibility_radius = initial_visibility
	target_visibility = initial_visibility
	player.position = spawn.position
	player.set_controls_enabled(false)
	ghost.reset()
	ghost.active = true
	for clue in clues:
		clue.set_collected(false)
	fragment_seconds = 0.0
	name_fragment.hide()
	prompt.hide()
	continue_button.hide()


func set_computer_focused(focused: bool) -> void:
	computer_focused = focused
	player.set_controls_enabled(focused and phase in [Phase.SEARCHING, Phase.NAMING, Phase.ESCAPING])


func _process(delta: float) -> void:
	fog_time += delta
	fragment_seconds = maxf(0.0, fragment_seconds - delta)
	name_fragment.visible = fragment_seconds > 0.0
	name_fragment.modulate.a = minf(fragment_seconds, 1.0)
	visibility_radius = move_toward(visibility_radius, target_visibility, delta * 180.0)
	darkness.material.set_shader_parameter("radius", visibility_radius)
	darkness.material.set_shader_parameter("fog_time", fog_time)
	darkness.material.set_shader_parameter("view_size", darkness.size)
	if phase == Phase.FAILURE:
		if visibility_radius <= 0.0:
			set_process(false)
			failed.emit()
		return
	_update_objective_glow()
	_update_prompt()


func _target_position() -> Vector2:
	match phase:
		Phase.SEARCHING:
			return clues[clue_index].position
		Phase.NAMING:
			return ghost.position
		Phase.ESCAPING:
			return exit_door.position
	return player.position


func _update_objective_glow() -> void:
	var active := phase in [Phase.SEARCHING, Phase.NAMING, Phase.ESCAPING]
	var target := _target_position()
	var center := darkness.size * 0.5
	var projected: Vector2 = house_viewport.get_canvas_transform() * house.to_global(target)
	var direction := projected - center
	# Off-screen objectives cast their glow from the corresponding edge of the void.
	var bounds := center - Vector2(55, 55)
	var edge_scale := maxf(1.0, maxf(absf(direction.x) / bounds.x, absf(direction.y) / bounds.y))
	var light_position := center + direction / edge_scale
	var proximity := 1.0 - smoothstep(interaction_distance, glow_distance, player.position.distance_to(target))
	var strength := lerpf(distant_glow, nearby_glow, proximity) if active else 0.0
	darkness.material.set_shader_parameter("objective_position", light_position)
	darkness.material.set_shader_parameter("objective_strength", strength)
	darkness.material.set_shader_parameter("escaping", phase == Phase.ESCAPING)


func _interact() -> void:
	match phase:
		Phase.SEARCHING:
			if player.position.distance_to(_target_position()) <= interaction_distance:
				_collect_note()
		Phase.NAMING:
			if player.position.distance_to(ghost.position) <= naming_distance:
				_release_ghost()
		Phase.ESCAPING:
			if player.position.distance_to(exit_door.position) <= interaction_distance:
				phase = Phase.SUCCESS
				player.set_controls_enabled(false)
				continue_button.show()
				won.emit()


func _collect_note() -> void:
	var clue = clues[clue_index]
	clue.set_collected(true)
	discovered_name += clue.name_fragment
	clue_index += 1
	name_fragment.text = discovered_name + ("…" if clue_index < clues.size() else "")
	fragment_seconds = 2.5
	# Finding a memory gives back one piece of light, so an early hit isn't decisive.
	contact_count = maxi(0, contact_count - 1)
	_update_visibility()
	clue_found.emit()
	if clue_index == clues.size():
		phase = Phase.NAMING
		ghost.active = false
		ghost.position = summoning_point.position


func _release_ghost() -> void:
	phase = Phase.ESCAPING
	ghost.active = false
	target_visibility = initial_visibility
	release_tween = create_tween()
	release_tween.tween_property(ghost, "modulate:a", 0.0, 1.0)
	clue_found.emit()


func _on_ghost_contact() -> void:
	if phase != Phase.SEARCHING:
		return
	contact_count += 1
	hurt.emit()
	_update_visibility()
	if contact_count >= contacts_before_crash:
		phase = Phase.FAILURE
		ghost.active = false
		player.set_controls_enabled(false)
		prompt.hide()
		_update_objective_glow()


func _update_visibility() -> void:
	var damage := float(contact_count) / contacts_before_crash
	target_visibility = lerpf(initial_visibility, minimum_visibility, damage)
	if contact_count >= contacts_before_crash:
		target_visibility = 0.0


func _update_prompt() -> void:
	var near_target: bool = player.position.distance_to(_target_position()) <= interaction_distance
	prompt.text = "Space"
	prompt.visible = near_target and phase in [Phase.SEARCHING, Phase.ESCAPING]
	if phase == Phase.NAMING:
		prompt.text = "%s · Space" % discovered_name
		prompt.visible = player.position.distance_to(ghost.position) <= naming_distance


func _on_continue_pressed() -> void:
	if phase == Phase.SUCCESS:
		completed.emit()


func _on_close_pressed() -> void:
	ghost.active = false
	player.set_controls_enabled(false)
	closed.emit()
