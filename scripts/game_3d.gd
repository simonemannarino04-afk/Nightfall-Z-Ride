extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var zombies: Array[CharacterBody3D] = []
var hp := 100
var kills := 0
var wave := 1
var fire_cooldown := 0.0
var hud_label: Label
var wave_label: Label
var crosshair: Label
var weapon_root: Node3D

const MOVE_SPEED := 7.5
const ZOMBIE_SPEED := 2.1
const FIRE_RATE := 0.16

func _ready():
    _build_environment()
    _build_map()
    _build_player()
    _build_hud()
    _spawn_wave()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_cooldown <= 0.0:
        _fire()
    _update_hud()

func _physics_process(_delta):
    if not is_instance_valid(player): return
    var x := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
    var z := float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
    var dir := Vector3(x, 0.0, z).normalized()
    player.velocity = dir * MOVE_SPEED
    player.move_and_slide()
    camera.global_position = camera.global_position.lerp(player.global_position + Vector3(0, 6.2, 10.5), 0.12)
    camera.look_at(player.global_position + Vector3(0, 1.2, 0), Vector3.UP)

    for zombie in zombies.duplicate():
        if not is_instance_valid(zombie):
            zombies.erase(zombie)
            continue
        var to_player := player.global_position - zombie.global_position
        to_player.y = 0.0
        if to_player.length() > 1.3:
            zombie.velocity = to_player.normalized() * ZOMBIE_SPEED
            zombie.move_and_slide()
            zombie.look_at(player.global_position, Vector3.UP)
        else:
            zombie.velocity = Vector3.ZERO
            hp -= 1
            if hp <= 0:
                Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
                get_tree().reload_current_scene()
                return

    if zombies.is_empty():
        wave += 1
        _spawn_wave()

func _unhandled_input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
        elif event.keycode == KEY_TAB:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _build_environment():
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.055, 0.075, 0.09)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.36, 0.42, 0.48)
    env.ambient_light_energy = 1.35
    env.fog_enabled = true
    env.fog_light_color = Color(0.2, 0.24, 0.28)
    env.fog_light_energy = 0.65
    env.fog_density = 0.008
    world_env.environment = env
    add_child(world_env)

    var moon := DirectionalLight3D.new()
    moon.light_color = Color(0.72, 0.82, 1.0)
    moon.light_energy = 1.35
    moon.rotation_degrees = Vector3(-48, -28, 0)
    moon.shadow_enabled = true
    add_child(moon)

func _build_map():
    _static_box(Vector3(0, -0.55, 0), Vector3(70, 1, 120), Color(0.07, 0.075, 0.08), "Ground")
    _static_box(Vector3(0, 0.0, 0), Vector3(18, 0.18, 120), Color(0.11, 0.115, 0.12), "Road")
    _static_box(Vector3(-11.5, 0.18, 0), Vector3(5, 0.35, 120), Color(0.28, 0.29, 0.30), "SidewalkLeft")
    _static_box(Vector3(11.5, 0.18, 0), Vector3(5, 0.35, 120), Color(0.28, 0.29, 0.30), "SidewalkRight")

    for z in range(-50, 51, 10):
        _box(Vector3(0, 0.12, z), Vector3(0.22, 0.04, 4.0), Color(0.84, 0.72, 0.28), null)

    for side in [-1, 1]:
        for i in range(8):
            var zpos := -48.0 + float(i) * 14.0
            var width := 8.0 + float(i % 3) * 2.0
            var height := 7.0 + float((i * 3) % 6)
            var depth := 10.0 + float(i % 2) * 3.0
            _static_box(Vector3(float(side) * 19.0, height / 2.0, zpos), Vector3(width, height, depth), Color(0.13 + 0.02 * (i % 3), 0.15, 0.17), "Building")
            for floor_i in range(2, int(height), 2):
                var win := Color(0.55, 0.42, 0.18) if (i + floor_i) % 3 == 0 else Color(0.08, 0.11, 0.13)
                _box(Vector3(float(side) * (14.85 if side > 0 else -14.85), float(floor_i), zpos), Vector3(0.08, 0.75, 1.1), win, null)

    for z in [-38.0, -8.0, 24.0, 43.0]:
        _make_car(Vector3(-3.2, 0.65, z), z > 0.0)
    for z in [-26.0, 12.0, 35.0]:
        _make_car(Vector3(3.2, 0.65, z), z < 0.0)

    for z in range(-45, 46, 18):
        _make_lamp(Vector3(-8.9, 0.0, float(z)))
        _make_lamp(Vector3(8.9, 0.0, float(z + 7)))

    for z in [-32.0, 5.0, 31.0]:
        _static_box(Vector3(-8.3, 0.65, z), Vector3(1.4, 1.3, 1.4), Color(0.24, 0.18, 0.12), "Crate")
        _static_box(Vector3(8.1, 0.45, z + 4.0), Vector3(1.0, 0.9, 1.0), Color(0.19, 0.22, 0.2), "Trash")

func _build_player():
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1.05, 36)
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.45
    capsule.height = 1.9
    shape.shape = capsule
    player.add_child(shape)
    add_child(player)

    _make_humanoid(player, Color(0.18, 0.23, 0.27), Color(0.72, 0.57, 0.45), false)
    weapon_root = Node3D.new()
    weapon_root.position = Vector3(0.52, 1.25, -0.2)
    player.add_child(weapon_root)
    _make_rifle(weapon_root)

    camera = Camera3D.new()
    camera.position = player.position + Vector3(0, 6.2, 10.5)
    camera.current = true
    camera.fov = 62
    add_child(camera)
    camera.look_at(player.position + Vector3(0, 1.2, 0), Vector3.UP)

func _build_hud():
    var layer := CanvasLayer.new()
    add_child(layer)
    hud_label = Label.new()
    hud_label.position = Vector2(24, 20)
    hud_label.add_theme_font_size_override("font_size", 22)
    layer.add_child(hud_label)
    wave_label = Label.new()
    wave_label.position = Vector2(24, 52)
    wave_label.add_theme_font_size_override("font_size", 17)
    layer.add_child(wave_label)
    crosshair = Label.new()
    crosshair.text = "+"
    crosshair.add_theme_font_size_override("font_size", 28)
    crosshair.set_anchors_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-8, -18)
    layer.add_child(crosshair)
    var hint := Label.new()
    hint.text = "WASD movimento   •   Mouse sinistro spara   •   ESC menu"
    hint.position = Vector2(24, 680)
    hint.add_theme_font_size_override("font_size", 15)
    layer.add_child(hint)

func _spawn_wave():
    for i in range(4 + wave * 2):
        var side := -1.0 if i % 2 == 0 else 1.0
        var z := -40.0 + float((i * 13 + wave * 7) % 70)
        var zombie := CharacterBody3D.new()
        zombie.position = Vector3(side * (3.0 + float(i % 3) * 1.8), 1.05, z)
        zombie.set_meta("is_zombie", true)
        zombie.set_meta("hp", 2 + int(wave / 2))
        var shape := CollisionShape3D.new()
        var capsule := CapsuleShape3D.new()
        capsule.radius = 0.45
        capsule.height = 1.9
        shape.shape = capsule
        zombie.add_child(shape)
        _make_humanoid(zombie, Color(0.18, 0.29, 0.19), Color(0.46, 0.56, 0.38), true)
        add_child(zombie)
        zombies.append(zombie)

func _fire():
    fire_cooldown = FIRE_RATE
    var from := camera.global_position
    var to := from + (-camera.global_transform.basis.z * 120.0)
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty(): return
    var collider = hit.get("collider")
    if collider is CharacterBody3D and collider.has_meta("is_zombie"):
        var current_hp := int(collider.get_meta("hp", 1)) - 1
        collider.set_meta("hp", current_hp)
        if current_hp <= 0:
            zombies.erase(collider)
            collider.queue_free()
            kills += 1

func _update_hud():
    if hud_label:
        hud_label.text = "SALUTE  %d     UCCISIONI  %d" % [hp, kills]
    if wave_label:
        wave_label.text = "ONDATA  %d   •   ZOMBIE  %d" % [wave, zombies.size()]

func _make_humanoid(root: Node3D, clothes: Color, skin: Color, zombie := false):
    _box(Vector3(0, 1.15, 0), Vector3(0.78, 0.95, 0.42), clothes, root)
    _box(Vector3(0, 1.84, 0), Vector3(0.52, 0.52, 0.52), skin, root)
    _box(Vector3(-0.25, 0.47, 0), Vector3(0.25, 0.8, 0.28), Color(0.1, 0.11, 0.12) if not zombie else clothes, root)
    _box(Vector3(0.25, 0.47, 0), Vector3(0.25, 0.8, 0.28), Color(0.1, 0.11, 0.12) if not zombie else clothes, root)
    _box(Vector3(-0.55, 1.18, 0), Vector3(0.24, 0.85, 0.24), skin, root)
    _box(Vector3(0.55, 1.18, 0), Vector3(0.24, 0.85, 0.24), skin, root)

func _make_rifle(root: Node3D):
    _box(Vector3(0, 0, 0), Vector3(0.18, 0.22, 1.35), Color(0.07, 0.075, 0.08), root)
    _box(Vector3(0, -0.12, 0.2), Vector3(0.12, 0.35, 0.28), Color(0.12, 0.12, 0.11), root)
    _box(Vector3(0, 0.02, -0.86), Vector3(0.08, 0.08, 0.5), Color(0.035, 0.035, 0.035), root)
    _box(Vector3(0, 0.12, 0.35), Vector3(0.14, 0.08, 0.4), Color(0.18, 0.2, 0.2), root)

func _make_car(pos: Vector3, flipped := false):
    var root := Node3D.new()
    root.position = pos
    root.rotation_degrees.y = 180.0 if flipped else 0.0
    add_child(root)
    _box(Vector3(0, 0, 0), Vector3(2.0, 0.65, 4.0), Color(0.16, 0.17, 0.19), root)
    _box(Vector3(0, 0.55, -0.15), Vector3(1.65, 0.75, 1.8), Color(0.09, 0.12, 0.14), root)
    for x in [-0.9, 0.9]:
        for z in [-1.25, 1.25]:
            var wheel := MeshInstance3D.new()
            var mesh := CylinderMesh.new()
            mesh.top_radius = 0.32
            mesh.bottom_radius = 0.32
            mesh.height = 0.22
            wheel.mesh = mesh
            wheel.rotation_degrees.z = 90
            wheel.position = Vector3(x, -0.3, z)
            wheel.material_override = _material(Color(0.025, 0.025, 0.025))
            root.add_child(wheel)

func _make_lamp(pos: Vector3):
    var root := Node3D.new()
    root.position = pos
    add_child(root)
    _box(Vector3(0, 2.6, 0), Vector3(0.12, 5.2, 0.12), Color(0.12, 0.13, 0.14), root)
    _box(Vector3(0.32, 5.05, 0), Vector3(0.65, 0.16, 0.22), Color(0.16, 0.17, 0.18), root)
    var light := OmniLight3D.new()
    light.position = Vector3(0.55, 4.85, 0)
    light.light_color = Color(1.0, 0.72, 0.38)
    light.light_energy = 2.0
    light.omni_range = 8.0
    root.add_child(light)

func _static_box(pos: Vector3, size: Vector3, color: Color, node_name := "Static"):
    var body := StaticBody3D.new()
    body.name = node_name
    body.position = pos
    add_child(body)
    _box(Vector3.ZERO, size, color, body)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _box(pos: Vector3, size: Vector3, color: Color, parent):
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.position = pos
    mesh_instance.material_override = _material(color)
    if parent == null:
        add_child(mesh_instance)
    else:
        parent.add_child(mesh_instance)
    return mesh_instance

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.72
    return mat
