extends Node

const SETTINGS_PATH := "user://settings.cfg"
const RESOLUTION_NAMES: Array[String] = [
	"Chuẩn 720p (960 × 720)",
	"HD Sắc Nét (1280 × 960)",
	"Full HD (1440 × 1080)",
	"2K QHD (1920 × 1440)",
	"4K Ultra HD (2880 × 2160)"
]
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(960, 720),
	Vector2i(1280, 960),
	Vector2i(1440, 1080),
	Vector2i(1920, 1440),
	Vector2i(2880, 2160)
]

const QUALITY_PRESETS: Array[String] = [
	"Tiết kiệm (SD Standard)",
	"Sắc nét (HD 1080p - MSAA 2X)",
	"Siêu nét (UHD 4K - MSAA 4X + FXAA)"
]

var master_volume: float = 0.8
var bgm_volume: float = 0.75
var sfx_volume: float = 0.85
var fullscreen: bool = false
var vsync: bool = true
var resolution_index: int = 0
var graphics_quality: int = 2  # 0=SD, 1=HD, 2=UHD (default to Ultra HD!)

func _ready() -> void:
	_ensure_audio_buses()
	load_settings()
	apply_settings()

func _ensure_audio_buses() -> void:
	for bus_name in [&"BGM", &"SFX", &"UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = float(config.get_value("audio", "master", master_volume))
	bgm_volume = float(config.get_value("audio", "bgm", bgm_volume))
	sfx_volume = float(config.get_value("audio", "sfx", sfx_volume))
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	vsync = bool(config.get_value("display", "vsync", vsync))
	resolution_index = clampi(int(config.get_value("display", "resolution", resolution_index)), 0, RESOLUTIONS.size() - 1)
	graphics_quality = clampi(int(config.get_value("display", "quality", graphics_quality)), 0, QUALITY_PRESETS.size() - 1)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "bgm", bgm_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "vsync", vsync)
	config.set_value("display", "resolution", resolution_index)
	config.set_value("display", "quality", graphics_quality)
	config.save(SETTINGS_PATH)

func apply_settings() -> void:
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(&"BGM", bgm_volume)
	_set_bus_volume(&"SFX", sfx_volume)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not fullscreen:
		DisplayServer.window_set_size(RESOLUTIONS[resolution_index])
	
	var vp := get_viewport()
	if vp != null:
		var vp_rid := vp.get_viewport_rid()
		match graphics_quality:
			0:
				RenderingServer.viewport_set_msaa_2d(vp_rid, RenderingServer.VIEWPORT_MSAA_DISABLED)
				RenderingServer.viewport_set_screen_space_aa(vp_rid, RenderingServer.VIEWPORT_SCREEN_SPACE_AA_DISABLED)
			1:
				RenderingServer.viewport_set_msaa_2d(vp_rid, RenderingServer.VIEWPORT_MSAA_2X)
				RenderingServer.viewport_set_screen_space_aa(vp_rid, RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA)
			2:
				RenderingServer.viewport_set_msaa_2d(vp_rid, RenderingServer.VIEWPORT_MSAA_4X)
				RenderingServer.viewport_set_screen_space_aa(vp_rid, RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA)

func update_audio(master: float, bgm: float, sfx: float) -> void:
	master_volume = clampf(master, 0.0, 1.0)
	bgm_volume = clampf(bgm, 0.0, 1.0)
	sfx_volume = clampf(sfx, 0.0, 1.0)
	apply_settings()
	save_settings()

func update_display(p_fullscreen: bool, p_vsync: bool, p_resolution_index: int, p_graphics_quality: int = 2) -> void:
	fullscreen = p_fullscreen
	vsync = p_vsync
	resolution_index = clampi(p_resolution_index, 0, RESOLUTIONS.size() - 1)
	graphics_quality = clampi(p_graphics_quality, 0, QUALITY_PRESETS.size() - 1)
	apply_settings()
	save_settings()

func _set_bus_volume(bus_name: StringName, linear: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear, 0.001)))
