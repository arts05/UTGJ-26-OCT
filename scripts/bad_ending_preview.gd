extends GameRoom
## Run the preview scene with F6 to review the shutdown without replaying the quiz.


func _ready() -> void:
	super._ready()
	desktop._on_carl_accepted()
	$Camera3D._move_to_view($ComputerView, $Camera3D.ViewMode.COMPUTER, 0.01)
	await get_tree().create_timer(1.0).timeout
	desktop._on_carl_failed()
