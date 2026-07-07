extends Node3D
# Demo: keep a 3D ship painted ON TOP of a between-levels menu.
#
# The menu lives on MenuLayer (CanvasLayer, layer = 1). The ship's meshes
# are on render layer 2. A second Camera3D sits inside a transparent
# SubViewport that shares this scene's World3D and culls to ONLY render
# layer 2; its output is composited on ShipOverlayLayer (CanvasLayer,
# layer = 2) — above the menu.
#
# TAB toggles the trick on/off (compare with the naive setup).
# SPACE shows/hides the menu.

const SHIP_RENDER_LAYER := 2

@onready var main_camera: Camera3D = $MainCamera
@onready var overlay_layer: CanvasLayer = $ShipOverlayLayer
@onready var overlay_camera: Camera3D = $ShipOverlayLayer/SubViewportContainer/ShipViewport/OverlayCamera
@onready var menu_layer: CanvasLayer = $MenuLayer
@onready var ship: Node3D = $Ship
@onready var mode_label: Label = $HintLayer/ModeLabel

var overlay_enabled := false
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _streaks: Array[MeshInstance3D] = []
var _streak_speeds: Array[float] = []

func _ready() -> void:
	_rng.seed = 1234
	_spawn_star_streaks()
	menu_layer.visible = false
	_apply_mode()
	# Fly for a moment, then the "end of level" menu comes up.
	await get_tree().create_timer(2.0).timeout
	menu_layer.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				menu_layer.visible = not menu_layer.visible
			KEY_TAB:
				overlay_enabled = not overlay_enabled
				_apply_mode()

func _apply_mode() -> void:
	# Naive mode: the main camera draws the ship too, so the menu
	# (CanvasLayer 1) covers it — all 3D renders below all CanvasLayers.
	# Trick mode: the main camera skips the ship's render layer; the
	# overlay viewport's camera draws ONLY that layer, composited on
	# CanvasLayer 2, above the menu.
	overlay_layer.visible = overlay_enabled
	main_camera.set_cull_mask_value(SHIP_RENDER_LAYER, not overlay_enabled)
	if overlay_enabled:
		mode_label.text = "TRICK ON — ship drawn via overlay SubViewport, ABOVE the menu\nTAB: toggle trick   SPACE: toggle menu"
	else:
		mode_label.text = "TRICK OFF — ship drawn by main camera, menu covers it\nTAB: toggle trick   SPACE: toggle menu"

func _process(delta: float) -> void:
	_t += delta
	# Gentle idle bob + roll so the ship feels alive.
	ship.position.y = -0.88 + sin(_t * 1.6) * 0.06
	ship.rotation.z = sin(_t * 0.9) * 0.05
	ship.rotation.x = sin(_t * 1.3) * 0.02
	# Keep the overlay camera glued to the main camera so the ship lands
	# on exactly the same pixels in both modes.
	overlay_camera.global_transform = main_camera.global_transform
	overlay_camera.fov = main_camera.fov
	_advance_streaks(delta)

func _spawn_star_streaks() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.85, 0.9, 1.0)
	for i in 90:
		var streak := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.02, 0.02, _rng.randf_range(4.0, 10.0))
		streak.mesh = box
		streak.material_override = mat
		streak.position = _random_streak_pos()
		add_child(streak)
		_streaks.append(streak)
		_streak_speeds.append(_rng.randf_range(35.0, 60.0))

func _random_streak_pos() -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var radius := _rng.randf_range(2.5, 15.0)
	return Vector3(cos(angle) * radius, sin(angle) * radius, _rng.randf_range(-90.0, 0.0))

func _advance_streaks(delta: float) -> void:
	for i in _streaks.size():
		var streak := _streaks[i]
		streak.position.z += _streak_speeds[i] * delta
		if streak.position.z > 12.0:
			var pos := _random_streak_pos()
			pos.z = -90.0
			streak.position = pos
