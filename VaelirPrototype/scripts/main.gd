extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

var player
var father: Node3D
var cutscene_camera: Camera3D
var dialogue_panel: Panel
var dialogue_label: Label
var objective_label: Label
var health_bar: ProgressBar
var map_panel: Panel
var sword_voice_label: Label
var intro_done := false

func _ready() -> void:
	_build_world()
	_build_village()
	_build_player_and_father()
	_build_ui()
	_spawn_enemies()
	_start_prologue()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M and intro_done:
		map_panel.visible = not map_panel.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if map_panel.visible else Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("09080f")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("6e738f")
	e.ambient_light_energy = 0.36
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color("323746")
	e.fog_light_energy = 0.55
	e.fog_density = 0.018
	e.fog_height = 1.5
	e.fog_height_density = 0.18
	env.environment = e
	add_child(env)

	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-48,-32,0)
	moon.light_color = Color("aab7db")
	moon.light_energy = 1.2
	moon.shadow_enabled = true
	add_child(moon)

	var floor_body := StaticBody3D.new()
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new(); plane.size = Vector2(62,62)
	floor_mesh.mesh = plane
	var ground_mat := StandardMaterial3D.new(); ground_mat.albedo_color = Color("171a17"); ground_mat.roughness = 0.95
	floor_mesh.material_override = ground_mat
	floor_body.add_child(floor_mesh)
	var floor_col := CollisionShape3D.new(); var floor_shape := BoxShape3D.new(); floor_shape.size = Vector3(62,0.3,62); floor_col.shape = floor_shape; floor_col.position.y = -0.15
	floor_body.add_child(floor_col)
	add_child(floor_body)

	for i in 34:
		var angle := float(i) / 34.0 * TAU
		var radius := 20.0 + float((i * 7) % 8)
		_create_tree(Vector3(cos(angle)*radius,0,sin(angle)*radius), 0.8 + float((i*3)%5)*0.08)

func _build_village() -> void:
	_create_road(Vector3(0,0.015,1), Vector3(5.2,0.03,36))
	_create_road(Vector3(0,0.018,-7), Vector3(24,0.03,4.2))
	var houses := [Vector3(-6,0,5),Vector3(6,0,4),Vector3(-7,0,-5),Vector3(7,0,-7),Vector3(-9,0,-13),Vector3(9,0,-14)]
	for i in houses.size():
		_create_house(houses[i], -0.15 if i%2==0 else 0.12)
	_create_well(Vector3(-3,0,-1))
	_create_bonfire(Vector3(3,0,-2))
	_create_archway(Vector3(0,0,-19))

func _build_player_and_father() -> void:
	player = PlayerScript.new()
	player.position = Vector3(0,0,7)
	add_child(player)
	player.health_changed.connect(_on_health_changed)
	player.sword_whisper.connect(_on_sword_whisper)

	father = Node3D.new(); father.position = Vector3(-0.6,0,4.1); father.rotation.y = PI; add_child(father)
	_build_humanoid(father, Color("50301f"), Color("453934"), Color("b98b6c"), Color("2b211d"))
	var father_sword := _make_sword(Color("681020"), true); father_sword.name = "BloodboundSword"; father_sword.position = Vector3(0.55,0.85,0); father_sword.rotation.z = 0.35; father.add_child(father_sword)

	cutscene_camera = Camera3D.new(); cutscene_camera.position = Vector3(3.4,2.2,8.3); cutscene_camera.fov = 58; add_child(cutscene_camera)
	cutscene_camera.look_at(Vector3(-0.2,1.15,4.2),Vector3.UP); cutscene_camera.current = true

func _spawn_enemies() -> void:
	var spots := [Vector3(-4,0,-8),Vector3(5,0,-10),Vector3(0,0,-15),Vector3(10,0,-5)]
	for p in spots:
		var enemy = EnemyScript.new(); enemy.position = p; enemy.target = player; add_child(enemy)

func _build_ui() -> void:
	var canvas := CanvasLayer.new(); add_child(canvas)
	objective_label = Label.new(); objective_label.position = Vector2(24,22); objective_label.size = Vector2(720,50); objective_label.add_theme_font_size_override("font_size",22); objective_label.text = "PROLOGO — Il sangue ricorda"; canvas.add_child(objective_label)
	health_bar = ProgressBar.new(); health_bar.position = Vector2(24,70); health_bar.size = Vector2(280,22); health_bar.max_value = 100; health_bar.value = 100; health_bar.show_percentage = false; canvas.add_child(health_bar)
	var controls := Label.new(); controls.position = Vector2(24,105); controls.size = Vector2(500,80); controls.text = "WASD Muovi   Mouse Guarda   Click/Spazio Attacca   Shift Schiva   M Mappa"; controls.modulate = Color(0.78,0.78,0.82,0.9); canvas.add_child(controls)

	dialogue_panel = Panel.new(); dialogue_panel.position = Vector2(250,610); dialogue_panel.size = Vector2(1100,190); dialogue_panel.visible = false; canvas.add_child(dialogue_panel)
	dialogue_label = Label.new(); dialogue_label.position = Vector2(36,28); dialogue_label.size = Vector2(1020,135); dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; dialogue_label.add_theme_font_size_override("font_size",26); dialogue_panel.add_child(dialogue_label)

	sword_voice_label = Label.new(); sword_voice_label.position = Vector2(320,530); sword_voice_label.size = Vector2(960,60); sword_voice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sword_voice_label.add_theme_font_size_override("font_size",24); sword_voice_label.modulate = Color("c9475b"); sword_voice_label.visible = false; canvas.add_child(sword_voice_label)

	map_panel = Panel.new(); map_panel.position = Vector2(390,120); map_panel.size = Vector2(820,620); map_panel.visible = false; canvas.add_child(map_panel)
	var title := Label.new(); title.position = Vector2(30,20); title.text = "VALLE DI DRAEVEN — BORGO DI VELMORA"; title.add_theme_font_size_override("font_size",28); map_panel.add_child(title)
	var map_bg := ColorRect.new(); map_bg.position = Vector2(35,70); map_bg.size = Vector2(750,500); map_bg.color = Color(0.08,0.07,0.08,0.94); map_panel.add_child(map_bg)
	_add_map_marker(map_bg,Vector2(365,270),"TU",Color("8f2337"))
	_add_map_marker(map_bg,Vector2(365,100),"PORTA NORD",Color("a39b82"))
	_add_map_marker(map_bg,Vector2(170,230),"BOSCO NERO",Color("4e6b4f"))
	_add_map_marker(map_bg,Vector2(560,320),"CAPPELLA",Color("82745e"))
	_add_map_marker(map_bg,Vector2(390,420),"STRADA REALE",Color("82745e"))

func _add_map_marker(parent: Control, pos: Vector2, text: String, color: Color) -> void:
	var dot := ColorRect.new(); dot.position = pos; dot.size = Vector2(12,12); dot.color = color; parent.add_child(dot)
	var label := Label.new(); label.position = pos + Vector2(18,-7); label.text = text; label.add_theme_font_size_override("font_size",16); parent.add_child(label)

func _start_prologue() -> void:
	player.input_enabled = false
	await get_tree().create_timer(0.8).timeout
	_show_dialogue("PADRE", "Ascoltami... non abbiamo più tempo. Ho sperato che questa notte non arrivasse mai.")
	await get_tree().create_timer(3.2).timeout
	_show_dialogue("PADRE", "Questa spada apparteneva alla famiglia che ti diede la vita. Io ho solo avuto l'onore di crescerti.")
	await get_tree().create_timer(3.8).timeout
	_show_dialogue("PROTAGONISTA", "Che cosa stai dicendo? Padre... chi sono io?")
	await get_tree().create_timer(2.8).timeout
	_show_dialogue("PADRE", "Quando il sangue chiamerà, la lama ricorderà. Non temere la sua voce. Temi chi vuole possederla.")
	await get_tree().create_timer(4.0).timeout
	var sword = father.get_node_or_null("BloodboundSword")
	if sword: sword.visible = false
	player.unlock_sword()
	var fall := create_tween(); fall.tween_property(father,"rotation:z",1.32,0.9); fall.tween_property(father,"position:y",-0.25,0.35)
	_show_dialogue("PADRE", "Vivi. E quando scoprirai la verità... scegli tu chi diventare.")
	await get_tree().create_timer(3.6).timeout
	dialogue_panel.visible = false
	cutscene_camera.current = false
	player.activate_camera()
	player.input_enabled = true
	intro_done = true
	objective_label.text = "OBIETTIVO — Difendi Velmora e raggiungi la Porta Nord"

func _show_dialogue(speaker: String, text: String) -> void:
	dialogue_panel.visible = true
	dialogue_label.text = speaker + "\n" + text

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum; health_bar.value = current

func _on_sword_whisper(text: String) -> void:
	sword_voice_label.text = "SPADA:  “" + text + "”"; sword_voice_label.visible = true
	var t := create_tween(); t.tween_interval(3.0); t.tween_property(sword_voice_label,"modulate:a",0.0,1.0); t.tween_callback(func(): sword_voice_label.visible=false; sword_voice_label.modulate.a=1.0)

func _mat(color: Color, metallic := 0.0, rough := 0.75, emission := Color(0,0,0,1)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color=color; m.metallic=metallic; m.roughness=rough
	if emission.r+emission.g+emission.b>0.01: m.emission_enabled=true; m.emission=emission; m.emission_energy_multiplier=2.2
	return m

func _static_box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var b := StaticBody3D.new(); b.position=pos; add_child(b)
	var mi:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size; mi.mesh=mesh; mi.material_override=_mat(color); b.add_child(mi)
	var c:=CollisionShape3D.new(); var s:=BoxShape3D.new(); s.size=size; c.shape=s; b.add_child(c); return b

func _create_house(pos: Vector3, rot: float) -> void:
	var root := Node3D.new(); root.position=pos; root.rotation.y=rot; add_child(root)
	var body:=StaticBody3D.new(); root.add_child(body)
	var wall:=MeshInstance3D.new(); var box:=BoxMesh.new(); box.size=Vector3(4.4,3.0,4.0); wall.mesh=box; wall.position.y=1.5; wall.material_override=_mat(Color("555047")); body.add_child(wall)
	var col:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=Vector3(4.4,3.0,4.0); col.shape=shape; col.position.y=1.5; body.add_child(col)
	var roof:=MeshInstance3D.new(); var roof_mesh:=PrismMesh.new(); roof_mesh.size=Vector3(5.0,1.7,4.7); roof.mesh=roof_mesh; roof.position.y=3.65; roof.rotation.y=PI/2.0; roof.material_override=_mat(Color("301e20")); root.add_child(roof)
	var window:=MeshInstance3D.new(); var w:=BoxMesh.new(); w.size=Vector3(.55,.75,.05); window.mesh=w; window.position=Vector3(0.8,1.65,-2.03); window.material_override=_mat(Color("5c331c"),0,0.4,Color("cc6a2a")); root.add_child(window)

func _create_tree(pos: Vector3, s: float) -> void:
	var root:=Node3D.new(); root.position=pos; root.scale=Vector3.ONE*s; add_child(root)
	var trunk:=MeshInstance3D.new(); var cyl:=CylinderMesh.new(); cyl.top_radius=.18; cyl.bottom_radius=.28; cyl.height=3.8; trunk.mesh=cyl; trunk.position.y=1.9; trunk.material_override=_mat(Color("2f2624")); root.add_child(trunk)
	for j in 3:
		var crown:=MeshInstance3D.new(); var cone:=CylinderMesh.new(); cone.top_radius=0.0; cone.bottom_radius=1.6-j*.22; cone.height=2.5; crown.mesh=cone; crown.position.y=3.3+j*1.05; crown.material_override=_mat(Color("17231d")); root.add_child(crown)

func _create_road(pos: Vector3, size: Vector3) -> void:
	var mi:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=size; mi.mesh=b; mi.position=pos; mi.material_override=_mat(Color("35302b")); add_child(mi)

func _create_well(pos: Vector3) -> void:
	var root:=Node3D.new(); root.position=pos; add_child(root)
	for i in 12:
		var stone:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=Vector3(.6,.45,.35); stone.mesh=b; var a=float(i)/12.0*TAU; stone.position=Vector3(cos(a)*1.0,.3,sin(a)*1.0); stone.rotation.y=-a; stone.material_override=_mat(Color("4b4b49")); root.add_child(stone)

func _create_bonfire(pos: Vector3) -> void:
	var light:=OmniLight3D.new(); light.position=pos+Vector3(0,1.1,0); light.light_color=Color("ff7d36"); light.light_energy=4.0; light.omni_range=8.0; add_child(light)
	var flame:=MeshInstance3D.new(); var cone:=CylinderMesh.new(); cone.top_radius=0.0; cone.bottom_radius=.45; cone.height=1.1; flame.mesh=cone; flame.position=pos+Vector3(0,.55,0); flame.material_override=_mat(Color("7b250d"),0,.4,Color("ff5722")); add_child(flame)

func _create_archway(pos: Vector3) -> void:
	_static_box(pos+Vector3(-2.4,2.2,0),Vector3(1.0,4.4,1.2),Color("47443f")); _static_box(pos+Vector3(2.4,2.2,0),Vector3(1.0,4.4,1.2),Color("47443f")); _static_box(pos+Vector3(0,4.4,0),Vector3(5.8,1.0,1.2),Color("47443f"))

func _build_humanoid(root: Node3D, clothes: Color, armor: Color, skin: Color, hair: Color) -> void:
	var torso:=MeshInstance3D.new(); var t:=CapsuleMesh.new(); t.radius=.38; t.height=1.05; torso.mesh=t; torso.position=Vector3(0,1.15,0); torso.material_override=_mat(clothes); root.add_child(torso)
	var head:=MeshInstance3D.new(); var h:=SphereMesh.new(); h.radius=.31; h.height=.62; head.mesh=h; head.position=Vector3(0,1.9,0); head.material_override=_mat(skin); root.add_child(head)
	var cap:=MeshInstance3D.new(); var c:=SphereMesh.new(); c.radius=.33; c.height=.55; cap.mesh=c; cap.position=Vector3(0,2.04,.05); cap.scale=Vector3(1,.65,1); cap.material_override=_mat(hair); root.add_child(cap)
	for side in [-1.0,1.0]:
		var arm:=MeshInstance3D.new(); var a:=CapsuleMesh.new(); a.radius=.11; a.height=.7; arm.mesh=a; arm.position=Vector3(.47*side,1.2,0); arm.material_override=_mat(armor); root.add_child(arm)
		var leg:=MeshInstance3D.new(); var l:=CapsuleMesh.new(); l.radius=.13; l.height=.9; leg.mesh=l; leg.position=Vector3(.2*side,.45,0); leg.material_override=_mat(armor); root.add_child(leg)

func _make_sword(glow: Color, visible_glow: bool) -> Node3D:
	var root:=Node3D.new(); var metal:=_mat(Color("2a2b30"),.8,.2); var red:=_mat(Color("3c070c"),.5,.2,glow if visible_glow else Color(0,0,0,1))
	var blade:=MeshInstance3D.new(); var b:=BoxMesh.new(); b.size=Vector3(.1,1.2,.05); blade.mesh=b; blade.position.y=.58; blade.material_override=metal; root.add_child(blade)
	var rune:=MeshInstance3D.new(); var r:=BoxMesh.new(); r.size=Vector3(.018,.92,.052); rune.mesh=r; rune.position=Vector3(0,.6,-.002); rune.material_override=red; root.add_child(rune)
	var guard:=MeshInstance3D.new(); var g:=BoxMesh.new(); g.size=Vector3(.48,.08,.1); guard.mesh=g; guard.material_override=metal; root.add_child(guard); return root