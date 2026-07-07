extends Node
# Regenerates the README screenshots. Run with:
#   godot --path . res://capture.tscn
# Saves docs/before.png (trick off) and docs/after.png (trick on), then quits.

func _ready() -> void:
	# Let the demo reach its steady state (menu appears at t=2s).
	await get_tree().create_timer(3.0).timeout
	await _save_screenshot("res://docs/before.png")
	_press_tab()
	await get_tree().create_timer(0.6).timeout
	await _save_screenshot("res://docs/after.png")
	get_tree().quit()

func _save_screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)

func _press_tab() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_TAB
	ev.pressed = true
	Input.parse_input_event(ev)
