@tool
extends Control

@export_group("Properties")
@export var enabled_boom : bool = true
@export var paused_color : Color
@export var work_background : Texture2D
@export var break_background : Texture2D

@export_group("References")
@export var timer: Timer
@export var timer_label: Label
@export var status_label: Label
@export var count_label: Label
@export var start_button: Button
@export var skip_button: Button
@export var animation_player: AnimationPlayer
@export var about_panel : PanelContainer
@export var root : Control
@export var background : TextureRect
@export var boom_sfx_button : Button

var config = ConfigFile.new()
var audio_stream_player : AudioStreamPlayer
var on_break : bool = false
var count : int = 1
var editor_theme = null
var end_sound_position : float = 0
var boom_sfx

func _ready() -> void:
	# Load editor theme to load icons
	editor_theme = EditorInterface.get_editor_theme()
	skip_button.icon = editor_theme.get_icon("NextFrame", "EditorIcons")
	timer.stop()
	skip_button.visible = false
	refresh()
	animation_player.play("stopped")
	animation_player.animation_finished.connect(play_idle)
	disable_ui(about_panel)
	enable_ui(root)
	background.texture = work_background
	var _err = config.load("res://bombodoro.cfg")
	if _err == OK:
		enabled_boom = config.get_value("options", "enabled_boom", true)
	enabled_boom = !enabled_boom
	toggle_explosion_sfx()

func _process(delta: float) -> void:
	if timer.is_stopped():
		timer_label.text = get_converted_time(timer.wait_time)
	else:
		timer_label.text = get_converted_time(timer.time_left)
		if !timer.paused && timer.time_left <= 4.9 && audio_stream_player == null:
			play_sound()

func button() -> void:
	if timer.is_stopped() or timer.paused:
		start()
	else:
		pause()


func start() -> void:
	animation_player.play("ticking")
	timer_label.modulate = Color.WHITE
	if timer.is_stopped():
		timer.start()
		skip_button.visible = true
		end_sound_position = 0
	else:
		timer.paused = false
		if end_sound_position != 0:
			play_sound(end_sound_position)
	start_button.text = "PAUSE"

func pause() -> void:
	if audio_stream_player != null:
		end_sound_position = audio_stream_player.get_playback_position()
		audio_stream_player.stop()
		audio_stream_player.free()
	animation_player.play("stopped")
	timer.paused = true
	timer_label.modulate = paused_color
	start_button.text = "RESUME"

func end() -> void:
	end_sound_position = 0
	timer_label.modulate = Color.WHITE
	timer.paused = false
	timer.stop()
	skip_button.visible = false
	if on_break:
		count += 1
	on_break = !on_break
	refresh()
	animation_player.play("boom")
	var _audio = AudioStreamPlayer.new()
	_audio.stream = boom_sfx
	_audio.bus = "Master" # or your SFX bus
	# Add to the editor's main scene tree
	EditorInterface.get_base_control().add_child(_audio)
	_audio.play()
	# Clean up after it's done
	_audio.connect("finished", _audio.queue_free)

func refresh() -> void:
	if on_break:
		status_label.text = "Time for a break!"
		background.texture = break_background
		if count % 4 == 0:
			timer.wait_time = 900.0
		else:
			timer.wait_time = 300.0
	else:
		status_label.text = "Time to work!"
		background.texture = work_background
		timer.wait_time = 1500.0
	count_label.text = "#" + str(count)
	start_button.text = "START"


func get_converted_time(time: int) -> String:
	var minutes: int = floori(time / 60.0)
	var seconds: int = time % 60
	return "%02d:%02d" % [minutes, seconds]


func play_idle(_anim : String) -> void:
	if _anim == "boom":
		animation_player.play("stopped")


func toggle_about() -> void:
	if root.visible:
		disable_ui(root)
		enable_ui(about_panel)
	else:
		disable_ui(about_panel)
		enable_ui(root)

func disable_ui(_panel: Control):
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.propagate_call("set_disabled", [true]) # disable all children controls
	_panel.propagate_call("set_mouse_filter", [Control.MOUSE_FILTER_IGNORE])

func enable_ui(_panel: Control):
	_panel.visible = true
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.propagate_call("set_disabled", [false])
	_panel.propagate_call("set_mouse_filter", [Control.MOUSE_FILTER_STOP])

func play_sound(_playback_position : float = 0):
	audio_stream_player = AudioStreamPlayer.new()
	audio_stream_player.stream = load("res://addons/bombodoro/assets/tick.wav")
	audio_stream_player.bus = "Master" # or your SFX bus
	# Add to the editor's main scene tree
	EditorInterface.get_base_control().add_child(audio_stream_player)
	audio_stream_player.play(_playback_position)
	# Clean up after it's done
	audio_stream_player.connect("finished", audio_stream_player.queue_free)

func toggle_explosion_sfx() -> void:
	if enabled_boom:
		enabled_boom = false
		boom_sfx = load("res://addons/bombodoro/assets/fart.wav")
		boom_sfx_button.text = "FART SFX"
	else:
		enabled_boom = true
		boom_sfx = load("res://addons/bombodoro/assets/boom.wav")
		boom_sfx_button.text = "EXPLOSION SFX"
	config.set_value("options", "enabled_boom", enabled_boom)
	config.save("res://bombodoro.cfg")
	
