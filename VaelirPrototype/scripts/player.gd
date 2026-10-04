extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal sword_whisper(text: String)
signal interact_requested
signal ability_requested
signal target_cycle_requested(direction: int)
signal target_lock_requested

var input_enabled := false
var max_health := 100.0
var health := 100.0
var speed := 6.5
var sprint_speed := 8.4
var dodge_speed := 13.0
var gravity := 18.0
var yaw := 0.0
var pitch := -0.18
var attack_cooldown := 0.0
var dodge_cooldown := 0.0
var sword_unlocked := false
var guarding := false
var camera_pivot: Node3D
var camera: Camera3D
var sword_root: Node3D
var body_root: Node3D

const JOY_DEADZONE := 0.18
const JOY_LOOK_SPEED := 2.6

func _ready() -> void:
	_build_visuals()
	_build_camera()
	_build_collision()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and input_enabled:
		yaw -= event.relative.x * 0.003
		pitch = clamp(pitch - event.relative.y * 0.0025, -0.75, 0.35)
		_apply_camera_rotation()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if input_enabled and sword_unlocked and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_attack(false)
	if input_enabled and event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_X:
				if sword_unlocked: _attack(false)
			JOY_BUTTON_B:
				_try_dodge()
			JOY_BUTTON_A:
				interact_requested.emit()
			JOY_BUTTON_Y:
				ability_requested.emit()
				if sword_unlocked: sword_whisper.emit("Il sangue ricorda.")
			JOY_BUTTON_LEFT_SHOULDER:
				target_cycle_requested.emit(-1)
			JOY_BUTTON_RIGHT_SHOULDER:
				target_cycle_requested.emit(1)
			JOY_BUTTON_RIGHT_STICK:
				target_lock_requested.emit()

func _physics_process(delta: float) -> void:
	attack_cooldown = max(0.0, attack_cooldown - delta)
	dodge_cooldown = max(0.0, dodge_cooldown - delta)
	_update_controller_camera(delta)
	guarding = input_enabled and Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.45
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.2
	if not input_enabled:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 5.0)
		move_and_slide()
		return

	var keyboard_x := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var keyboard_z := float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var joy_x := _deadzone(Input.get_joy_axis(0, JOY_AXIS_LEFT_X))
	var joy_z := _deadzone(Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	var x := joy_x if abs(joy_x) > abs(keyboard_x) else keyboard_x
	var z := joy_z if abs(joy_z) > abs(keyboard_z) else keyboard_z
	var direction := (transform.basis * Vector3(x, 0.0, z)).normalized()

	var current_speed := speed
	var sprinting := Input.is_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_STICK)
	if sprinting and direction.length() > 0.1:
		current_speed = sprint_speed
	velocity.x = move_toward(velocity.x, direction.x * current_speed, current_speed * delta * 8.0)
	velocity.z = move_toward(velocity.z, direction.z * current_speed, current_speed * delta * 8.0)
	move_and_slide()

	if direction.length() > 0.1:
		body_root.rotation.z = lerp(body_root.rotation.z, -x * 0.06, delta * 7.0)
	else:
		body_root.rotation.z = lerp(body_root.rotation.z, 0.0, delta * 7.0)

	if Input.is_key_pressed(KEY_SPACE) and sword_unlocked:
		_attack(false)
	if sword_unlocked and Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.72:
		_attack(true)

func _update_controller_camera(delta: float) -> void:
	if not input_enabled:
		return
	var look_x := _deadzone(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X))
	var look_y := _deadzone(Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if abs(look_x) > 0.0 or abs(look_y) > 0.0:
		yaw -= look_x * JOY_LOOK_SPEED * delta
		pitch = clamp(pitch - look_y * JOY_LOOK_SPEED * 0.75 * delta, -0.75, 0.35)
		_apply_camera_rotation()

func _apply_camera_rotation() -> void:
	rotation.y = yaw
	if camera_pivot:
		camera_pivot.rotation.x = pitch

func _try_dodge() -> void:
	if dodge_cooldown > 0.0:
		return
	var x := _deadzone(Input.get_joy_axis(0, JOY_AXIS_LEFT_X))
	var z := _deadzone(Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	var direction := (transform.basis * Vector3(x, 0.0, z)).normalized()
	if direction.length() < 0.1:
		direction = -global_transform.basis.z
	dodge_cooldown = 0.85
	velocity.x = direction.x * dodge_speed
	velocity.z = direction.z * dodge_speed

func _attack(heavy: bool) -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.78 if heavy else 0.48
	var damage := 52.0 if heavy else 34.0
	var swing := -1.55 if heavy else -1.25
	var tween := create_tween()
	tween.tween_property(sword_root, "rotation:z", swing, 0.16 if heavy else 0.11)
	tween.tween_property(sword_root, "rotation:z", 0.15, 0.30 if heavy else 0.2)
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node is Node3D:
			var enemy := enemy_node as Node3D
			if global_position.distance_to(enemy.global_position) < 2.9:
				var facing: Vector3 = -global_transform.basis.z
				var to_enemy: Vector3 = (enemy.global_position - global_position).normalized()
				if facing.dot(to_enemy) > 0.15 and enemy.has_method("take_damage"):
					enemy.call("take_damage", damage)

func take_damage(amount: float) -> void:
	if not input_enabled:
		return
	var applied := amount * (0.35 if guarding else 1.0)
	health = max(0.0, health - applied)
	health_changed.emit(health, max_health)
	var tween := create_tween()
	tween.tween_property(body_root, "scale", Vector3(1.08, 0.92, 1.08), 0.06)
	tween.tween_property(body_root, "scale", Vector3.ONE, 0.12)
	if health <= 0.0:
		global_position = Vector3(0, 1.2, 7)
		health = max_health
		health_changed.emit(health, max_health)

func unlock_sword() -> void:
	sword_unlocked = true
	sword_root.visible = true
	sword_whisper.emit("Ti ho aspettata... sangue del mio sangue.")

func _deadzone(value: float) -> float:
	if abs(value) < JOY_DEADZONE:
		return 0.0
	return value

func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = 0.95
	add_child(shape)

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.55, 0)
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0.55, 0.45, 4.3)
	camera.fov = 67.0
	camera.current = false
	camera_pivot.add_child(camera)

func activate_camera() -> void:
	camera.current = true

func _mat(color: Color, metallic := 0.0, roughness := 0.65, emission := Color(0,0,0,1)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emission.r + emission.g + emission.b > 0.01:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 2.2
	return m

func _mesh(parent: Node, mesh: PrimitiveMesh, pos: Vector3, mat: Material, rot := Vector3.ZERO, scale_value := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.scale = scale_value
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _build_visuals() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	var skin := _mat(Color("d7a07f"), 0.0, 0.8)
	var leather := _mat(Color("24191d"), 0.05, 0.72)
	var cloth := _mat(Color("3a151e"), 0.0, 0.85)
	var hair := _mat(Color("6a1020"), 0.0, 0.55)
	var metal := _mat(Color("4c4b51"), 0.75, 0.28)
	var red_glow := _mat(Color("4c0710"), 0.55, 0.24, Color("b2162d"))
	var torso := CapsuleMesh.new(); torso.radius = 0.36; torso.height = 1.05
	_mesh(body_root, torso, Vector3(0,1.2,0), cloth, Vector3(0,0,0), Vector3(0.85,1.0,0.65))
	var head := SphereMesh.new(); head.radius = 0.31; head.height = 0.62
	_mesh(body_root, head, Vector3(0,1.92,0), skin)
	var hair_back := SphereMesh.new(); hair_back.radius = 0.36; hair_back.height = 0.72
	_mesh(body_root, hair_back, Vector3(0,2.03,0.08), hair, Vector3(0,0,0), Vector3(1.0,1.05,0.92))
	var fringe := SphereMesh.new(); fringe.radius = 0.23; fringe.height = 0.46
	_mesh(body_root, fringe, Vector3(0.10,2.08,-0.25), hair, Vector3(0.2,0,0.25), Vector3(1.0,0.75,0.55))
	for side in [-1.0,1.0]:
		var arm := CapsuleMesh.new(); arm.radius = 0.11; arm.height = 0.76
		_mesh(body_root, arm, Vector3(0.48*side,1.28,0), leather, Vector3(0,0,0.12*side))
		var leg := CapsuleMesh.new(); leg.radius = 0.13; leg.height = 0.95
		_mesh(body_root, leg, Vector3(0.2*side,0.46,0), leather)
	var cloak := BoxMesh.new(); cloak.size = Vector3(0.8,1.2,0.07)
	_mesh(body_root, cloak, Vector3(0,1.2,0.32), cloth, Vector3(0.05,0,0))
	sword_root = Node3D.new()
	sword_root.position = Vector3(0.56,1.05,-0.18)
	sword_root.rotation = Vector3(-0.15,0.05,0.15)
	body_root.add_child(sword_root)
	var blade := BoxMesh.new(); blade.size = Vector3(0.09,1.18,0.04)
	_mesh(sword_root, blade, Vector3(0,0.58,0), metal)
	var blood_rune := BoxMesh.new(); blood_rune.size = Vector3(0.018,0.92,0.046)
	_mesh(sword_root, blood_rune, Vector3(0,0.6,-0.001), red_glow)
	var guard := BoxMesh.new(); guard.size = Vector3(0.48,0.08,0.10)
	_mesh(sword_root, guard, Vector3(0,-0.03,0), metal)
	var grip := CylinderMesh.new(); grip.top_radius = 0.055; grip.bottom_radius = 0.055; grip.height = 0.32
	_mesh(sword_root, grip, Vector3(0,-0.22,0), hair)
	sword_root.visible = false
