extends Panel

enum ScanState { READY, SCANNING, TASK_READY, TASK_RUNNING }

@export_range(0.1, 30.0, 0.1) var scan_duration_seconds: float = 5.0

@onready var scan_view: Control = $Content/ScanView
@onready var scan_button: Button = $Content/ScanView/ScanButton
@onready var scan_progress: ProgressBar = $Content/ScanView/ScanProgress
@onready var scan_status: Label = $Content/ScanView/ScanStatus
@onready var containment_task: ContainmentTask = $Content/ContainmentTask

var state: ScanState = ScanState.READY
var scan_elapsed_seconds: float = 0.0


func _process(delta: float) -> void:
	if state != ScanState.SCANNING:
		return

	scan_elapsed_seconds = minf(scan_elapsed_seconds + delta, scan_duration_seconds)
	scan_progress.value = 100.0 * scan_elapsed_seconds / scan_duration_seconds

	if scan_elapsed_seconds >= scan_duration_seconds:
		state = ScanState.TASK_READY
		scan_button.disabled = false
		scan_button.text = "Open task"
		scan_status.text = "Anomaly detected."


func _on_scan_button_pressed() -> void:
	match state:
		ScanState.READY:
			_start_scan()
		ScanState.TASK_READY:
			state = ScanState.TASK_RUNNING
			scan_button.disabled = true
			scan_view.hide()
			containment_task.start()


func _start_scan() -> void:
	state = ScanState.SCANNING
	scan_elapsed_seconds = 0.0
	scan_progress.value = 0.0
	scan_button.disabled = true
	scan_status.text = "Scanning..."


func _on_containment_task_finished(success: bool) -> void:
	containment_task.hide()
	scan_view.show()
	scan_button.disabled = false

	if success:
		state = ScanState.READY
		scan_button.text = "Scan again"
		scan_status.text = "Anomaly contained."
	else:
		state = ScanState.TASK_READY
		scan_button.text = "Retry task"
		scan_status.text = "Signal escaped. Try again."
