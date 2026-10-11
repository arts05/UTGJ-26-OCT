extends GameRoom
## Run the preview scene with F6 to review the ending without replaying the quiz.


func _ready() -> void:
	super._ready()
	desktop._on_victory_pause_timeout()
	$Camera3D._move_to_view($ComputerView, $Camera3D.ViewMode.COMPUTER, 0.01)
