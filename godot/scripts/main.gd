extends Node3D

var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    build_road()
    build_city()
    build_vehicle_interior()

func mesh_box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    box.material = mat
    m.mesh = box
    m.position = pos
    add_child(m)
    return m

func build_road():
    mesh_box(Vector3(18,0.15,420), Vector3(0,-0.1,-180), Color("30343a"))
    for z in range(-380,25,12):
        mesh_box(Vector3(0.12,0.02,4), Vector3(0,0.01,z), Color("d7c36c"))

func build_city():
    for z in range(-360,20,22):
        for side in [-1,1]:
            var x = side * rng.randf_range(12.0,16.0)
            var h = rng.randf_range(8.0,22.0)
            mesh_box(Vector3(rng.randf_range(7,11),h,16),Vector3(x,h/2.0,z),Color(rng.randf_range(.12,.22),rng.randf_range(.13,.23),rng.randf_range(.15,.25)))
            mesh_box(Vector3(.22,5,.22),Vector3(side*7.2,2.5,z+7),Color("555b60"))
            var lamp := OmniLight3D.new()
            lamp.position=Vector3(side*7.0,4.5,z+7)
            lamp.light_color=Color("ffc477")
            lamp.light_energy=4.0
            lamp.omni_range=16
            add_child(lamp)
    for z in [-55,-105,-165,-235]:
        mesh_box(Vector3(2.2,1.3,4.3),Vector3(rng.randf_range(-5,5),.65,z),Color("4b5158"))

func build_vehicle_interior():
    mesh_box(Vector3(4.4,.7,1.15),Vector3(0,1.05,2.55),Color("30383f"))
    mesh_box(Vector3(3.5,.25,2.6),Vector3(0,.8,.8),Color("59636b"))
    mesh_box(Vector3(.22,2.8,.28),Vector3(-1.75,2.05,2.15),Color("252a2f"))
    mesh_box(Vector3(.22,2.8,.28),Vector3(1.75,2.05,2.15),Color("252a2f"))
    mesh_box(Vector3(4.1,.3,2),Vector3(0,3.35,2.1),Color("202429"))
