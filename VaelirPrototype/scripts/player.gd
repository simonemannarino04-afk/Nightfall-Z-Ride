extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal sword_whisper(text: String)

var input_enabled := false
var max_health := 100.0
var health := 100.0
var speed := 6.5
var dodge_speed := 13.0
var gravity := 18.0
var yaw := 0.0
var pitch := -0.18
var attack_cooldown := 0.0
var dodge_cooldown := 0.0
var sword_unlocked := false
var camera_pivot: Node3D
var camera: Camera3D
var sword_root: Node3D
var body_root: Node3D

func _ready() -> void:
	_build_visuals()
	_build_camera()
	_build_collision()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and input_enabled:
		yaw -= event.relative.x * 0.003
		pitch = clamp(pitch - event.relative.y * 0.0025, -0.75, 0.35)
		rotation.y = yaw
		camera_pivot.rotation.x = pitch
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if input_enabled and sword_unlocked and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_attack()

func _physics_process(delta: float) -> void:
	attack_cooldown = max(0.0, attack_cooldown - delta)
	dodge_cooldown = max(0.0, dodge_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.2
	if not input_enabled:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 5.0)
		move_and_slide()
		return
	var x := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var z := float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var direction := (transform.basis * Vector3(x, 0.0, z)).normalized()
	var current_speed := speed
	if Input.is_key_pressed(KEY_SHIFT) and dodge_cooldown <= 0.0 and direction.length() > 0.1:
		current_speed = dodge_speed
		dodge_cooldown = 0.85
	velocity.x = move_toward(velocity.x, direction.x * current_speed, current_speed * delta * 8.0)
	velocity.z = move_toward(velocity.z, direction.z * current_speed, current_speed * delta * 8.0)
	move_and_slide()
	if direction.length() > 0.1:
		body_root.rotation.z = lerp(body_root.rotation.z, -x * 0.06, delta * 7.0)
	else:
		body_root.rotation.z = lerp(body_root.rotation.z, 0.0, delta * 7.0)
	if Input.is_key_pressed(KEY_SPACE) and sword_unlocked:
		_attack()

func _attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.48
	var tween := create_tween()
	tween.tween_property(sword_root, "rotation:z", -1.25, 0.11)
	tween.tween_property(sword_root, "rotation:z", 0.15, 0.2)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node3D and global_position.distance_to(enemy.global_position) < 2.7:
			var facing := -global_transform.basis.z
			var to_enemy := (enemy.global_position - global_position).normalized()
			if facing.dot(to_enemy) > 0.15 and enemy.has_method("take_damage"):
				enemy.take_damage(34.0)

func take_damage(amount: float) -> void:
	if not input_enabled:
		return
	health = max(0.0, health - amount)
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
