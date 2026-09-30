extends Node2D

var player := Vector2(640, 430)
var zombies := []
var hp := 100
var ammo := 30
var score := 0

func _ready():
    for i in range(12):
        zombies.append(Vector2(100 + (i * 91) % 1100, 150 + (i * 137) % 380))
    queue_redraw()

func _process(delta):
    var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    player += dir * 230.0 * delta
    player.x = clamp(player.x, 40.0, 1240.0)
    player.y = clamp(player.y, 100.0, 680.0)
    for i in range(zombies.size()):
        var d: Vector2 = (player - zombies[i]).normalized()
        zombies[i] += d * (45.0 + i % 4 * 8.0) * delta
        if zombies[i].distance_to(player) < 34:
            hp = max(0, hp - 1)
    queue_redraw()

func _input(event):
    if event is InputEventScreenTouch and event.pressed:
        shoot(event.position)
    elif event is InputEventMouseButton and event.pressed:
        shoot(event.position)

func shoot(target: Vector2):
    if ammo <= 0: return
    ammo -= 1
    var best := -1
    var best_dist := 90.0
    for i in range(zombies.size()):
        var d: float = zombies[i].distance_to(target)
        if d < best_dist:
            best_dist = d
            best = i
    if best >= 0:
        zombies.remove_at(best)
        score += 100
    queue_redraw()

func _draw():
    # Boston skyline / quarantine atmosphere
    draw_rect(Rect2(0,0,1280,720), Color("101820"))
    draw_rect(Rect2(0,500,1280,220), Color("20252a"))
    for x in range(0,1280,90):
        var h = 100 + (x * 7) % 190
        draw_rect(Rect2(x,500-h,72,h), Color("17232d"))
        for wy in range(int(520-h),480,28):
            draw_rect(Rect2(x+12,wy,8,12), Color("c27b42"))
    draw_line(Vector2(0,520),Vector2(1280,520),Color("b53a2f"),4)
    # Player
    draw_circle(player,24,Color("d7c0a8"))
    draw_rect(Rect2(player.x-18,player.y+18,36,46),Color("344653"))
    draw_line(player+Vector2(12,28),player+Vector2(45,12),Color("b7b9ba"),8)
    # Zombies
    for i in range(zombies.size()):
        var z: Vector2 = zombies[i]
        var body = Color("5b7152") if i%3 else Color("77524e")
        draw_circle(z,20,Color("8a9a74"))
        draw_rect(Rect2(z.x-16,z.y+16,32,38),body)
        draw_circle(z+Vector2(-7,-2),3,Color("e44b3f"))
        draw_circle(z+Vector2(7,-2),3,Color("e44b3f"))
    # HUD
    draw_rect(Rect2(20,20,330,72),Color(0.02,0.03,0.04,0.88))
    draw_string(ThemeDB.fallback_font,Vector2(38,48),"BOSTON: QUARANTINE",HORIZONTAL_ALIGNMENT_LEFT,250,24,Color("f1f1ee"))
    draw_string(ThemeDB.fallback_font,Vector2(38,78),"HP %d   AMMO %d   SCORE %d" % [hp,ammo,score],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e3483e"))
    draw_string(ThemeDB.fallback_font,Vector2(900,45),"MISSIONE 1  •  EVACUAZIONE",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
