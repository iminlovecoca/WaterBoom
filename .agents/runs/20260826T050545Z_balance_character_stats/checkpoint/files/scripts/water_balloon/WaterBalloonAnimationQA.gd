extends Control

var selected_skin_id: StringName = &""
var preview_sprite: AnimatedSprite2D
var frame_label: Label
var anim_option: OptionButton
var bg_option: OptionButton
var fps_label: Label
var current_bg_color: Color = Color(0.1, 0.12, 0.18)
var current_anim: StringName = &"idle"
var frame_index: int = 0
var frame_timer: float = 0.0
var playback_speed: float = 6.0
var skin_grid: GridContainer
var zoom: float = 2.0
var zoom_label: Label

const BG_COLORS := {
	"Dark": Color(0.1, 0.12, 0.18),
	"Light": Color(0.85, 0.88, 0.9),
	"Blue": Color(0.1, 0.2, 0.5),
	"Green": Color(0.1, 0.4, 0.15),
	"Brown": Color(0.35, 0.25, 0.15),
}

func _ready() -> void:
	_build_ui()
	_populate_skins()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var title := Label.new()
	title.text = "ANIMATION QA TOOL"
	title.position = Vector2(20, 8)
	title.size = Vector2(400, 30)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#c4f3ff"))
	add_child(title)
	
	anim_option = OptionButton.new()
	anim_option.position = Vector2(440, 8)
	anim_option.size = Vector2(180, 30)
	var anims := ["idle", "wobble_slow", "wobble_medium", "wobble_fast", "warning", "pre_pop", "place", "squash", "rebound"]
	for a in anims:
		anim_option.add_item(a, anim_option.item_count)
	anim_option.item_selected.connect(func(i): current_anim = StringName(anims[i]); _play_current_anim())
	add_child(anim_option)
	
	bg_option = OptionButton.new()
	bg_option.position = Vector2(640, 8)
	bg_option.size = Vector2(140, 30)
	for bg_name in BG_COLORS:
		bg_option.add_item(bg_name, bg_option.item_count)
	bg_option.item_selected.connect(func(i): current_bg_color = BG_COLORS[BG_COLORS.keys()[i]]; _update_bg())
	add_child(bg_option)
	
	var zoom_in := Button.new()
	zoom_in.text = "+"
	zoom_in.position = Vector2(800, 8)
	zoom_in.size = Vector2(36, 30)
	zoom_in.pressed.connect(func(): zoom = minf(zoom + 0.5, 5.0); zoom_label.text = "Zoom: " + str(zoom) + "x"; _update_zoom())
	add_child(zoom_in)
	
	var zoom_out := Button.new()
	zoom_out.text = "-"
	zoom_out.position = Vector2(844, 8)
	zoom_out.size = Vector2(36, 30)
	zoom_out.pressed.connect(func(): zoom = maxf(zoom - 0.5, 0.5); zoom_label.text = "Zoom: " + str(zoom) + "x"; _update_zoom())
	add_child(zoom_out)
	
	zoom_label = Label.new()
	zoom_label.text = "Zoom: 2x"
	zoom_label.position = Vector2(888, 10)
	zoom_label.size = Vector2(100, 24)
	zoom_label.add_theme_font_size_override("font_size", 12)
	zoom_label.add_theme_color_override("font_color", Color("#aabbcc"))
	add_child(zoom_label)
	
	var preview_bg := ColorRect.new()
	preview_bg.name = "PreviewBG"
	preview_bg.position = Vector2(340, 50)
	preview_bg.size = Vector2(580, 400)
	preview_bg.color = current_bg_color
	add_child(preview_bg)
	
	preview_sprite = AnimatedSprite2D.new()
	preview_sprite.position = Vector2(630, 250)
	preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(preview_sprite)
	
	frame_label = Label.new()
	frame_label.position = Vector2(340, 460)
	frame_label.size = Vector2(580, 30)
	frame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame_label.add_theme_font_size_override("font_size", 14)
	frame_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(frame_label)
	
	fps_label = Label.new()
	fps_label.position = Vector2(340, 490)
	fps_label.size = Vector2(580, 24)
	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fps_label.add_theme_font_size_override("font_size", 12)
	fps_label.add_theme_color_override("font_color", Color("#88aacc"))
	add_child(fps_label)
	
	var skin_scroll := ScrollContainer.new()
	skin_scroll.position = Vector2(10, 50)
	skin_scroll.size = Vector2(320, 660)
	skin_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(skin_scroll)
	
	skin_grid = GridContainer.new()
	skin_grid.columns = 2
	skin_grid.add_theme_constant_override("h_separation", 6)
	skin_grid.add_theme_constant_override("v_separation", 6)
	skin_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skin_scroll.add_child(skin_grid)

func _populate_skins() -> void:
	for child in skin_grid.get_children():
		child.queue_free()
	var all_ids := WaterBalloonSkinRegistry.get_all_skin_ids()
	for skin_id in all_ids:
		var def := WaterBalloonSkinRegistry.get_skin(skin_id)
		if def == null:
			continue
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(150, 50)
		btn.text = def.display_name
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(func(): _select_skin(skin_id))
		skin_grid.add_child(btn)

func _select_skin(skin_id: StringName) -> void:
	selected_skin_id = skin_id
	_play_current_anim()

func _play_current_anim() -> void:
	var def := WaterBalloonSkinRegistry.get_skin(selected_skin_id)
	if def == null or def.sprite_frames == null:
		frame_label.text = "No sprite frames for " + str(selected_skin_id)
		return
	if not def.sprite_frames.has_animation(current_anim):
		frame_label.text = "Animation '" + current_anim + "' not found"
		return
	preview_sprite.sprite_frames = def.sprite_frames
	preview_sprite.play(current_anim)
	_update_zoom()
	var anim_speed = def.sprite_frames.get_animation_speed(current_anim)
	fps_label.text = "FPS: " + str(anim_speed) + " | Frames: " + str(def.sprite_frames.get_frame_count(current_anim))
	frame_label.text = def.display_name + " | " + current_anim

func _update_bg() -> void:
	var bg := get_node_or_null("PreviewBG") as ColorRect
	if bg != null:
		bg.color = current_bg_color

func _update_zoom() -> void:
	if preview_sprite == null:
		return
	var normalized := WaterBalloonSkinRegistry.get_runtime_scale(selected_skin_id) if selected_skin_id != &"" else 1.0
	preview_sprite.scale = Vector2.ONE * zoom * normalized

func _process(_delta: float) -> void:
	if preview_sprite != null and preview_sprite.is_playing():
		frame_index = preview_sprite.frame
		frame_label.text = str(selected_skin_id) + " | " + current_anim + " | Frame " + str(frame_index)
