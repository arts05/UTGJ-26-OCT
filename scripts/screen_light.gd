extends OmniLight3D
## Lets the live desktop light the desk and props, with a softer light on the casing.

@export var desktop_viewport: SubViewport
@export var casing_light: OmniLight3D
@export var screen_dust: CPUParticles3D
@export var maximum_energy: float = 0.35
@export var casing_maximum_energy: float = 0.025
@export_range(0.1, 1.0) var sample_interval: float = 0.2

const SAMPLE_COLUMNS: int = 12
const SAMPLE_ROWS: int = 9
const FADE_SPEED: float = 8.0

var seconds_until_sample: float = 0.2
var target_color := Color.WHITE
var target_brightness: float = 0.0


func _ready() -> void:
	# Headless checks have no rendered viewport texture to read.
	set_process(false)
	if DisplayServer.get_name() == "headless":
		return

	await RenderingServer.frame_post_draw
	_sample_screen()
	seconds_until_sample = sample_interval
	set_process(true)


func _process(delta: float) -> void:
	seconds_until_sample -= delta
	if seconds_until_sample <= 0.0:
		_sample_screen()
		seconds_until_sample = sample_interval

	var blend := 1.0 - exp(-FADE_SPEED * delta)
	light_color = light_color.lerp(target_color, blend)
	light_energy = lerpf(light_energy, target_brightness * maximum_energy, blend)
	casing_light.light_color = light_color
	casing_light.light_energy = lerpf(
		casing_light.light_energy, target_brightness * casing_maximum_energy, blend
	)
	# Dust catches the same changing light and disappears when the screen goes dark.
	screen_dust.color = Color(light_color, lerpf(screen_dust.color.a, target_brightness, blend))


func _sample_screen() -> void:
	# Sample periodically to keep the GPU readback out of most frames.
	var screen_image := desktop_viewport.get_texture().get_image()
	var total := Color(0, 0, 0, 0)
	for row in range(SAMPLE_ROWS):
		for column in range(SAMPLE_COLUMNS):
			var x := int((column + 0.5) * screen_image.get_width() / SAMPLE_COLUMNS)
			var y := int((row + 0.5) * screen_image.get_height() / SAMPLE_ROWS)
			total += screen_image.get_pixel(x, y).srgb_to_linear()

	# Average light in linear space, then separate its hue from its intensity.
	var average := total / float(SAMPLE_COLUMNS * SAMPLE_ROWS)
	target_brightness = maxf(average.r, maxf(average.g, average.b))
	if target_brightness > 0.0:
		target_color = Color(
			average.r / target_brightness,
			average.g / target_brightness,
			average.b / target_brightness
		).linear_to_srgb()
