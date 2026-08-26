class_name BubbleState
extends RefCounted

var active: bool = false
var time_left: float = 0.0

func begin(duration: float) -> void:
	active = true
	time_left = maxf(duration, 0.0)

func tick(delta: float) -> bool:
	if not active:
		return false
	time_left -= delta
	return time_left <= 0.0

func clear() -> void:
	active = false
	time_left = 0.0
