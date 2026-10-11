extends Node
## Prepares one fresh room before the splash, and keeps that instance for Play.

signal progress_changed(value: float)

const TEXTURE_LOAD_BUDGET_USEC: int = 4000
const PARTICLE_WARMUP_FPS: int = 5

@onready var warmup_viewport: SubViewport = $WarmupViewport

var prepared_room: GameRoom
var room_scene: PackedScene
var room_scene_path: String = ""
var preparing: bool = false


func prepare(scene_path: String = "res://scenes/Main.tscn") -> Error:
	if preparing:
		return ERR_BUSY
	if prepared_room != null:
		return OK
	preparing = true
	progress_changed.emit(0.0)
	# Let the startup bar draw before loading or creating any room resources.
	await get_tree().process_frame
	var started := Time.get_ticks_msec()
	if room_scene == null or room_scene_path != scene_path:
		var error := await _load_room_scene(scene_path)
		if error != OK:
			preparing = false
			return error
	var resources_ms := Time.get_ticks_msec() - started

	started = Time.get_ticks_msec()
	prepared_room = room_scene.instantiate() as GameRoom
	prepared_room.start_on_ready = false
	prepared_room.get_node("SceneFade").fade_on_ready = false
	prepared_room.get_node("Computer/Audio/CRTLoop").autoplay = false
	warmup_viewport.size = get_tree().root.size
	warmup_viewport.msaa_3d = get_tree().root.msaa_3d
	# Our snow and dust move at constant speeds. Pre-roll them in larger steps,
	# then restore the normal frame rates before anything becomes visible.
	var particles := prepared_room.find_children("*", "CPUParticles3D", true, false)
	var particle_frame_rates: Array[int] = []
	for emitter: CPUParticles3D in particles:
		particle_frame_rates.append(emitter.fixed_fps)
		emitter.fixed_fps = PARTICLE_WARMUP_FPS
	warmup_viewport.add_child(prepared_room)
	for index in particles.size():
		particles[index].fixed_fps = particle_frame_rates[index]
	var scene_ms := Time.get_ticks_msec() - started

	started = Time.get_ticks_msec()
	await _render_room_views()
	var rendering_ms := Time.get_ticks_msec() - started
	# Keep the actual prepared room, including particle state and shader resources.
	# Its simulation and viewports stay idle while the splash and menu are shown.
	prepared_room.process_mode = Node.PROCESS_MODE_DISABLED
	prepared_room.get_node("Computer/ComputerViewport").render_target_update_mode = SubViewport.UPDATE_DISABLED
	warmup_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	preparing = false
	progress_changed.emit(1.0)
	print("Room startup: resources %d ms, scene setup %d ms, first rendering %d ms" % [resources_ms, scene_ms, rendering_ms])
	return OK


func _load_room_scene(scene_path: String) -> Error:
	var texture_paths: Array[String] = []
	_collect_texture_paths(scene_path, {}, texture_paths)
	# Hold these until the packed scene owns them, so its load reuses the textures.
	var loaded_textures: Array[Resource] = []
	var frame_started := Time.get_ticks_usec()
	for index in texture_paths.size():
		var texture := load(texture_paths[index])
		if texture == null:
			return ERR_CANT_OPEN
		loaded_textures.append(texture)
		progress_changed.emit(0.4 * float(index + 1) / texture_paths.size())
		# The single-threaded Web export cannot decode all images in the background.
		# Give the browser a frame between batches instead of one long blocking load.
		if Time.get_ticks_usec() - frame_started >= TEXTURE_LOAD_BUDGET_USEC:
			await get_tree().process_frame
			frame_started = Time.get_ticks_usec()

	var error := ResourceLoader.load_threaded_request(scene_path, "PackedScene")
	if error != OK:
		return error
	while true:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(scene_path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED:
			ResourceLoader.load_threaded_get(scene_path)
			return ERR_CANT_OPEN
		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			return ERR_CANT_OPEN
		progress_changed.emit(0.4 + float(progress[0]) * 0.1)
		await get_tree().process_frame
	room_scene = ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if room_scene == null:
		return ERR_INVALID_DATA
	room_scene_path = scene_path
	return OK


func _collect_texture_paths(path: String, visited: Dictionary, textures: Array[String]) -> void:
	if visited.has(path):
		return
	visited[path] = true
	if path.get_extension() in ["png", "svg"]:
		textures.append(path)
		return
	for dependency in ResourceLoader.get_dependencies(path):
		# Godot dependencies can include a UID and type before the actual file path.
		var dependency_path: String = dependency.split("::")[-1]
		_collect_texture_paths(dependency_path, visited, textures)


func _render_room_views() -> void:
	if DisplayServer.get_name() == "headless":
		return
	warmup_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var camera: Camera3D = prepared_room.get_node("Camera3D")
	var seated_transform := camera.transform
	camera.set_process(false)
	# Include the balcony materials as well as the computer directly ahead.
	var view_angles := [0.0, 65.0, -65.0, 0.0]
	for index in view_angles.size():
		camera.transform = seated_transform.rotated_local(Vector3.UP, deg_to_rad(view_angles[index]))
		for frame in 2:
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
		progress_changed.emit(0.5 + 0.5 * float(index + 1) / view_angles.size())
	camera.transform = seated_transform
	camera.set_process(true)


func take_room() -> GameRoom:
	assert(prepared_room != null and not preparing, "Prepare the room before opening it.")
	var room := prepared_room
	prepared_room = null
	room.reparent(get_tree().root)
	return room
