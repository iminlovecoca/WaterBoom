extends SceneTree

const EXPECTED_SIZE := Vector2i(96, 96)
const EXPECTED_BASELINE := 88
const BASELINE_TOLERANCE := 4
const ALPHA_THRESHOLD := 8.0 / 255.0

var failures: Array[String] = []
var total_frames := 0
var characters := [
    "coral_diver", "red_rider", "sunny_mechanic", "mint_sprout",
    "boom_mascot", "cloud_bunny", "lime_dino", "star_skater", "cocoa_otter"
]

func _init() -> void:
    for char_id in characters:
        var directory := "res://assets/characters/%s/v10" % char_id
        var files: Array[String] = []
        _collect_png_files(directory, files)
        files.sort()
        for path in files:
            _validate_frame(char_id, path)

    print("SPRITE_VALIDATION_RESULT: %s | %d frames | %d failures" % [
        "PASS" if failures.is_empty() else "FAIL",
        total_frames,
        failures.size()
    ])
    for failure in failures:
        printerr("  ", failure)
    quit(0 if failures.is_empty() else 1)

func _validate_frame(char_id: String, path: String) -> void:
    var image := Image.new()
    var load_error := image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
    var name := "%s/%s" % [char_id, path.get_file()]
    total_frames += 1

    if load_error != OK or image.is_empty():
        failures.append("%s - load error" % name)
        return

    if image.get_size() != EXPECTED_SIZE:
        failures.append("%s - wrong size %s (expected %s)" % [name, image.get_size(), EXPECTED_SIZE])
        return

    var bottom := -1
    var opaque_border := 0
    for y in image.get_height():
        for x in image.get_width():
            if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
                bottom = maxi(bottom, y)
                if x == 0 or y == 0 or x == image.get_width() - 1 or y == image.get_height() - 1:
                    opaque_border += 1

    if opaque_border > 0:
        failures.append("%s - %d opaque border pixels (white fringe / grid artifact)" % [name, opaque_border])

    if bottom >= 0 and absi((bottom + 1) - EXPECTED_BASELINE) > BASELINE_TOLERANCE:
        failures.append("%s - baseline at %d (expected %d +/-%d)" % [name, bottom + 1, EXPECTED_BASELINE, BASELINE_TOLERANCE])

func _collect_png_files(directory: String, output: Array[String]) -> void:
    var access := DirAccess.open(directory)
    if access == null:
        return
    access.list_dir_begin()
    var entry := access.get_next()
    while not entry.is_empty():
        var fpath := "%s/%s" % [directory, entry]
        if access.current_is_dir():
            _collect_png_files(fpath, output)
        elif entry.get_extension().to_lower() == "png":
            output.append(fpath)
        entry = access.get_next()
    access.list_dir_end()
