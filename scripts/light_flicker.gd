extends OmniLight3D
## A dim room light with occasional short interruptions.

@export var steady_energy: float = 0.06
@export var dimmed_energy: float = 0.008

const FLICKER_SECONDS: float = 0.08
const MINIMUM_PAUSE: float = 0.5
const MAXIMUM_PAUSE: float = 2.0

var seconds_remaining: float = 1.0
var is_dimmed: bool = false


func _ready() -> void:
	light_energy = steady_energy


func _process(delta: float) -> void:
	seconds_remaining -= delta
	if seconds_remaining > 0.0:
		return

	is_dimmed = not is_dimmed
	if is_dimmed:
		light_energy = dimmed_energy
		seconds_remaining = FLICKER_SECONDS
	else:
		light_energy = steady_energy
		seconds_remaining = randf_range(MINIMUM_PAUSE, MAXIMUM_PAUSE)
