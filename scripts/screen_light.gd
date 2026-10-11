extends OmniLight3D
## Lets the live desktop light the desk and props, with a softer light on the casing.

@export var desktop_viewport: SubViewport
@export var color_sample: SubViewport
@export var casing_light: OmniLight3D
@export var screen_dust: CPUParticles3D
@export var maximum_energy: float = 0.35
@export var casing_maximum_energy: float = 0.025
@export_range(0.1, 1.0) var sample_interval: float = 0.2
@export_range(0.0, 1.0) var power: float = 1.0

const FADE_SPEED: float = 8.0

var seconds_until_sample: float = 0.2
var target_color := Color.WHITE
var target_brightness: float = 0.0


func _ready() -> void:
	# Headless checks have no rendered viewport texture to read.
	set_process(false)
	if DisplayServer.get_name() == "headless":
		return

	color_sample.get_node("DesktopSample").texture = desktop_viewport.get_texture()
	await _sample_screen()
	seconds_until_sample = sample_interval
	set_process(true)


func _process(delta: float) -> void:
	seconds_until_sample -= delta
	if seconds_until_sample <= 0.0:
		seconds_until_sample = sample_interval
		_sample_screen()

	var blend := 1.0 - exp(-FADE_SPEED * delta)
	light_color = light_color.lerp(target_color, blend)
	light_energy = lerpf(light_energy, target_brightness * maximum_energy * power, blend)
	casing_light.light_color = light_color
	casing_light.light_energy = lerpf(
		casing_light.light_energy, target_brightness * casing_maximum_energy * power, blend
	)
	# Dust catches the same changing light and disappears when the screen goes dark.
	screen_dust.color = Color(light_color, lerpf(screen_dust.color.a, target_brightness * power, blend))


func _sample_screen() -> void:
	# Downsample on the GPU; copy only 108 pixels instead of the full desktop.
	color_sample.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	var screen_image := color_sample.get_texture().get_image()
	var total := Color(0, 0, 0, 0)
	for y in range(screen_image.get_height()):
		for x in range(screen_image.get_width()):
			total += screen_image.get_pixel(x, y).srgb_to_linear()

	# Average light in linear space, then separate its hue from its intensity.
	var average := total / float(screen_image.get_width() * screen_image.get_height())
	target_brightness = maxf(average.r, maxf(average.g, average.b))
	if target_brightness > 0.0:
		target_color = Color(
			average.r / target_brightness,
			average.g / target_brightness,
			average.b / target_brightness
		).linear_to_srgb()
