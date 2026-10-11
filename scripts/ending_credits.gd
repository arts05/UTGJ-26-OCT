class_name EndingCredits
extends CanvasLayer
## Both endings use this same hard title cut, music cue, and credit cards.

signal finished

@export_range(0.0, 0.2, 0.005) var title_music_delay_seconds: float = 0.04
@export_range(1.0, 6.0) var title_seconds: float = 3.0
@export_range(1.0, 6.0) var team_credit_seconds: float = 3.0
@export_range(1.0, 8.0) var heritage_sources_seconds: float = 5.0
@export_range(1.0, 8.0) var asset_sources_seconds: float = 4.0

@onready var music: AudioStreamPlayer = $Music
@onready var black: ColorRect = $Black
@onready var title: Label = $Black/Title
@onready var team_credit: Label = $Black/Team
@onready var heritage_sources: VBoxContainer = $Black/HeritageSources
@onready var asset_sources: VBoxContainer = $Black/AssetSources
@onready var final_credit: VBoxContainer = $Black/Credits

var sequence: Tween


func _ready() -> void:
	music.finished.connect(finished.emit)


func play() -> void:
	black.show()
	title.show()
	sequence = create_tween()
	# Preserve the good ending's brief visual lead before the song's first hit.
	sequence.tween_interval(title_music_delay_seconds)
	sequence.tween_callback(music.play)
	sequence.tween_interval(title_seconds)
	sequence.tween_callback(_show_team_credit)
	sequence.tween_interval(team_credit_seconds)
	sequence.tween_callback(_show_heritage_sources)
	sequence.tween_interval(heritage_sources_seconds)
	sequence.tween_callback(_show_asset_sources)
	sequence.tween_interval(asset_sources_seconds)
	sequence.tween_callback(_show_final_credit)
	# The last card holds until the whole song finishes, then Main opens the menu.


func _show_team_credit() -> void:
	title.hide()
	team_credit.show()


func _show_heritage_sources() -> void:
	team_credit.hide()
	heritage_sources.show()


func _show_asset_sources() -> void:
	heritage_sources.hide()
	asset_sources.show()


func _show_final_credit() -> void:
	asset_sources.hide()
	final_credit.show()


func _exit_tree() -> void:
	music.stop()
