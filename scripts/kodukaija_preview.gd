extends GameRoom
## F6 this preview to enter the panorama without replaying Viljaneitsi.


func _ready() -> void:
	super._ready()
	desktop._on_kodukaija_accepted()
	$Camera3D._move_to_view($ComputerView, $Camera3D.ViewMode.COMPUTER, 0.01)
