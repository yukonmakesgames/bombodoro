@tool
extends Control

@export_group("References")
@export var timer: Timer
@export var timer_label: Label
@export var status_label: Label
@export var count_label: Label
@export var start_button: Button
@export var skip_button: Button
@export var animation_player: AnimationPlayer

var on_break : bool = false
var count : int = 1
var editor_theme = null


func _ready() -> void:
	# Load editor theme to load icons
	editor_theme = EditorInterface.get_editor_theme()
	skip_button.icon = editor_theme.get_icon("NextFrame", "EditorIcons")
	timer.stop()
	skip_button.visible = false
	refresh()
	play_idle("boom")
	animation_player.animation_finished.connect(play_idle)

func _process(delta: float) -> void:
	if timer.is_stopped():
		timer_label.text = get_converted_time(timer.wait_time)
	else:
		timer_label.text = get_converted_time(timer.time_left)

func button() -> void:
	play_idle(animation_player.current_animation)
	if timer.is_stopped() or timer.paused:
		start()
	else:
		pause()


func start() -> void:
	if timer.is_stopped():
		timer.start()
		skip_button.visible = true
	else:
		timer.paused = false
	start_button.text = "PAUSE"

func pause() -> void:
	timer.paused = true
	start_button.text = "RESUME"

func end() -> void:
	timer.paused = false
	timer.stop()
	skip_button.visible = false
	if on_break:
		count += 1
	on_break = !on_break
	refresh()
	animation_player.play("boom")

func refresh() -> void:
	if on_break:
		status_label.text = "Time for a break!"
		if count % 4 == 0:
			timer.wait_time = 900.0
		else:
			timer.wait_time = 300.0
	else:
		status_label.text = "Time to work!"
		timer.wait_time = 1500.0
	count_label.text = "#" + str(count)
	start_button.text = "START"


func get_converted_time(time: int) -> String:
	var minutes: int = floori(time / 60.0)
	var seconds: int = time % 60
	return "%02d:%02d" % [minutes, seconds]


func play_idle(_anim : String) -> void:
	if _anim == "boom":
		animation_player.play("idle")
