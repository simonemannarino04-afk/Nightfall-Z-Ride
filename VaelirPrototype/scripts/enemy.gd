extends CharacterBody3D

var target: Node3D
var health := 70.0
var speed := 3.1
var attack_timer := 0.0
var dead := false
var visual_root: Node3D

func _ready() -> void:
	add_to_group("enemies")
	_build_collision()
	_build_visuals()

func _physics_process(delta: float) -> void:
	if dead or target == null or not is_instance_valid(target):
		return
	attack_timer = max(0.0, attack_timer - delta)
	if not is_on_floor(): velocity.y -= 18.0 * delta
	var distance := global_position.distance_to(target.global_position)
	if distance < 13.0 and distance > 1.6:
		var dir := (target.global_position - global_position); dir.y = 0.0; dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
		move_and_slide()
	elif distance <= 1.7:
		velocity.x = 0.0; velocity.z = 0.0
		if attack_timer <= 0.0:
			attack_timer = 1.15
			if target.has_method("take_damage"): target.take_damage(11.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 5.0)
		move_and_slide()

func take_damage(amount: float) -> void:
	if dead: return
	health -= amount
	var t := create_tween()
	t.tween_property(visual_root, "scale", Vector3(1.15,0.85,1.15), 0.05)
	t.tween_property(visual_root, "scale", Vector3.ONE, 0.1)
	if health <= 0.0:
		dead = true
		remove_from_group("enemies")
		var fall := create_tween()
		fall.tween_property(visual_root, "rotation:x", 1.45, 0.28)
		fall.tween_property(self, "scale", Vector3.ZERO, 0.3).set_delay(0.35)
		fall.tween_callback(queue_free)

func _build_collision() -> void:
	var c := CollisionShape3D.new()
	var s := CapsuleShape3D.new(); s.radius = 0.45; s.height = 1.8
	c.shape = s; c.position.y = 0.95; add_child(c)

func _mat(color: Color, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = color; m.metallic = metallic; m.roughness = 0.6; return m

func _mesh(mesh: PrimitiveMesh, pos: Vector3, mat: Material, scale_value := Vector3.ONE) -> void:
	var n := MeshInstance3D.new(); n.mesh = mesh; n.position = pos; n.scale = scale_value; n.material_override = mat; visual_root.add_child(n)

func _build_visuals() -> void:
	visual_root = Node3D.new(); add_child(visual_root)
	var black := _mat(Color("17171b"),0.45)
	var steel := _mat(Color("555864"),0.8)
	var red := StandardMaterial3D.new(); red.albedo_color = Color("4f0710"); red.emission_enabled = true; red.emission = Color("9c1023"); red.emission_energy_multiplier = 1.8
	var torso := CapsuleMesh.new(); torso.radius=.38; torso.height=1.05; _mesh(torso,Vector3(0,1.2,0),black)
	var helm := SphereMesh.new(); helm.radius=.34; helm.height=.68; _mesh(helm,Vector3(0,1.95,0),steel,Vector3(1,1.05,.9))
	var visor := BoxMesh.new(); visor.size=Vector3(.5,.1,.05); _mesh(visor,Vector3(0,1.96,-.31),red)
	for side in [-1.0,1.0]:
		var arm := CapsuleMesh.new(); arm.radius=.12; arm.height=.75; _mesh(arm,Vector3(.48*side,1.28,0),black)
		var leg := CapsuleMesh.new(); leg.radius=.14; leg.height=.95; _mesh(leg,Vector3(.21*side,.48,0),black)
	var weapon := BoxMesh.new(); weapon.size=Vector3(.08,1.15,.07); _mesh(weapon,Vector3(.62,1.05,-.08),steel)
