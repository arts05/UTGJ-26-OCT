extends Marker2D
## Placeholder notes; their positions and name fragments are editable in the scene.

@export var name_fragment: String


func set_collected(collected: bool) -> void:
	$Paper.modulate = Color(0.25, 0.25, 0.25) if collected else Color.WHITE
