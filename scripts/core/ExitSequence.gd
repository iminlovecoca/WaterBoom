extends Node

const OUT_SOUND_PATH := "res://assets/audio/ui/out.ogg"
const FALLBACK_DURATION := 1.0
const MIN_FADE_DURATION := 0.75

var _is_exiting := false
var _overlay: ColorRect
var _player: AudioStreamPlayer

func play_and_quit() -> void:
	if _is_exiting:
		return
	_is_exiting = true
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
		return

	if has_node("/root/SoundManager"):
		SoundManager.stop_bgm()

	var duration := _prepare_player()
	_prepare_overlay()

	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _player.stream != null:
		_player.play()
		await _player.finished
	else:
		await get_tree().create_timer(duration).timeout

	if tween.is_running():
		await tween.finished
	get_tree().quit()

func _prepare_player() -> float:
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "ExitSfxPlayer"
		_player.bus = "SFX" if AudioServer.get_bus_index(&"SFX") >= 0 else "Master"
		add_child(_player)

	var source := load(OUT_SOUND_PATH) as AudioStream
	if source == null:
		push_warning("Unable to load exit sound: %s" % OUT_SOUND_PATH)
		_player.stream = null
		return FALLBACK_DURATION

	var playable := source.duplicate() as AudioStream
	if playable is AudioStreamMP3:
		(playable as AudioStreamMP3).loop = false
	_player.stream = playable
	return maxf(playable.get_length(), MIN_FADE_DURATION)

func _prepare_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.color = Color(0, 0, 0, 0)
		_overlay.visible = true
		return

	var layer := CanvasLayer.new()
	layer.name = "ExitFadeLayer"
	layer.layer = 4096
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.name = "ExitFade"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_overlay)
