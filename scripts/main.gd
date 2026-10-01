extends Node2D

const W := 1280.0
const H := 720.0
var player := Vector2(640, 470)
var zombies: Array[Dictionary] = []
var tracers: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var hp := 100
var ammo := 30
var reserve := 120
var score := 0
var wave := 1
var kills := 0
var combo := 0
var combo_timer := 0.0
var muzzle := 0.0
var shake := 0.0
var time := 0.0
var game_over := false

func _ready():
    randomize()
    spawn_wave()
    queue_redraw()

func spawn_wave():
    var count := 8 + wave * 3
    for i in range(count):
        var edge := randi() % 3
        var p := Vector2(randf_range(40,1240), randf_range(175,430))
        if edge == 0: p.x = randf_range(20,130)
        elif edge == 1: p.x = randf_range(1150,1260)
        else: p.y = randf_range(165,230)
        var kind := randi()%5
        if wave >= 3 and i == count-1: kind = 5
        if wave >= 5 and i == count-2: kind = 6
        var base_hp := 2 + int(wave/3)
        if kind == 5: base_hp += 4
        if kind == 6: base_hp += 8
        zombies.append({"p":p,"hp":base_hp,"max_hp":base_hp,"type":kind,"phase":randf()*6.28,"hit":0.0})
    if wave % 2 == 0:
        pickups.append({"p":Vector2(randf_range(180,1100),randf_range(420,610)),"kind":randi()%2,"phase":randf()*6.28})

func _process(delta):
    time += delta
    muzzle = maxf(0.0,muzzle-delta*8.0)
    shake = maxf(0.0,shake-delta*18.0)
    combo_timer = maxf(0.0,combo_timer-delta)
    if combo_timer <= 0: combo = 0
    if game_over:
        queue_redraw(); return
    var dir := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
    player += dir * 245.0 * delta
    player.x = clampf(player.x,55,1225)
    player.y = clampf(player.y,310,635)
    for z in zombies:
        var d: Vector2 = (player-z.p).normalized()
        var speed := 38.0 + min(z.type,4)*6.0 + wave*2.0
        if z.type == 5: speed = 92.0 + wave
        if z.type == 6: speed = 27.0 + wave
        z.p += d * speed * delta
        z.hit = maxf(0.0,z.hit-delta*5.0)
        if z.p.distance_to(player) < 38:
            var damage := 16.0
            if z.type == 5: damage = 25.0
            if z.type == 6: damage = 38.0
            hp = maxi(0,hp-int(damage*delta))
    for t in tracers: t.life -= delta
    tracers = tracers.filter(func(t): return t.life>0)
    for p in particles:
        p.p += p.v*delta; p.v *= 0.92; p.life -= delta
    particles = particles.filter(func(p): return p.life>0)
    for pick in pickups:
        if pick.p.distance_to(player) < 42:
            if pick.kind == 0: hp = mini(100,hp+30)
            else: reserve = mini(240,reserve+60)
            pick["taken"] = true
    pickups = pickups.filter(func(p): return not p.get("taken",false))
    if hp <= 0: game_over = true
    if zombies.is_empty(): wave += 1; spawn_wave()
    queue_redraw()

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_R: reload()
        if event.keycode == KEY_ENTER and game_over: restart()
    if game_over: return
    if event is InputEventScreenTouch and event.pressed: shoot(event.position)
    elif event is InputEventMouseButton and event.pressed: shoot(event.position)

func restart():
    zombies.clear(); pickups.clear(); particles.clear(); tracers.clear()
    player=Vector2(640,470); hp=100; ammo=30; reserve=120; score=0; wave=1; kills=0; combo=0; game_over=false
    spawn_wave()

func reload():
    var need := 30-ammo
    var take := mini(need,reserve)
    ammo += take; reserve -= take

func shoot(target: Vector2):
    if ammo<=0: reload(); return
    ammo-=1; muzzle=1.0; shake=5.0
    var origin := player+Vector2(31,-9)
    tracers.append({"a":origin,"b":target,"life":0.09})
    var best := -1; var best_dist := 54.0
    for i in range(zombies.size()):
        var d: float = zombies[i].p.distance_to(target)
        if d<best_dist: best_dist=d; best=i
    if best>=0:
        zombies[best].hp -= 1; zombies[best].hit=1.0
        burst(zombies[best].p)
        if zombies[best].hp<=0:
            var dead := zombies[best]
            zombies.remove_at(best); kills+=1; combo+=1; combo_timer=2.2
            score += (100+wave*15)*maxi(1,combo)
            if randf()<0.08: pickups.append({"p":dead.p,"kind":randi()%2,"phase":randf()*6.28})

func burst(at: Vector2):
    for i in range(9): particles.append({"p":at,"v":Vector2(randf_range(-100,100),randf_range(-115,45)),"life":randf_range(.2,.55)})

func _draw():
    var cam := Vector2(randf_range(-shake,shake),randf_range(-shake,shake))
    draw_set_transform(cam)
    draw_rect(Rect2(0,0,W,H),Color("101820"))
    for y in range(0,430,18):
        var k=float(y)/430.0
        draw_rect(Rect2(0,y,W,19),Color(0.035+0.045*k,0.065+0.055*k,0.09+0.06*k))
    draw_circle(Vector2(1050,125),55,Color(0.72,0.62,0.48,0.12))
    for x in range(-20,1320,74):
        var h=95+int(abs(sin(float(x)*.017))*175)
        draw_rect(Rect2(x,420-h,60,h),Color("17232d"))
        draw_rect(Rect2(x+6,420-h+8,48,4),Color("263844"))
        for wy in range(440-h,405,25):
            if (x+wy)%3: draw_rect(Rect2(x+12,wy,7,10),Color(0.72,0.46,0.27,0.65))
    draw_colored_polygon(PackedVector2Array([Vector2(0,390),Vector2(1280,390),Vector2(1280,720),Vector2(0,720)]),Color("252b2e"))
    for y in range(410,720,54): draw_line(Vector2(0,y),Vector2(1280,y+18),Color(0.11,0.12,0.12),2)
    draw_colored_polygon(PackedVector2Array([Vector2(570,410),Vector2(710,410),Vector2(920,720),Vector2(350,720)]),Color("303537"))
    for y in range(455,700,90): draw_rect(Rect2(625,y,30,45),Color(0.78,0.66,0.35,0.55))
    for x in [120,1040]:
        draw_rect(Rect2(x,370,125,28),Color("d9d0b5")); draw_rect(Rect2(x+8,376,109,6),Color("b84a3d"))
    draw_car(Vector2(940,470),Color("33444f")); draw_car(Vector2(210,555),Color("593d38"))
    for x in [70,1190]:
        draw_line(Vector2(x,190),Vector2(x,500),Color("202529"),10); draw_circle(Vector2(x,205),15,Color("e8c77b"))
    for pick in pickups: draw_pickup(pick)
    for z in zombies: draw_zombie(z)
    draw_survivor(player)
    for t in tracers: draw_line(t.a,t.b,Color(1,.82,.42,t.life/.09),2)
    for p in particles: draw_circle(p.p,3,Color(.55,.08,.06,clampf(p.life*3,0,1)))
    draw_set_transform(Vector2.ZERO)
    draw_hud()
    if game_over: draw_game_over()

func draw_car(p:Vector2,c:Color):
    draw_rect(Rect2(p.x-58,p.y-20,116,39),c)
    draw_colored_polygon(PackedVector2Array([p+Vector2(-36,-20),p+Vector2(-18,-43),p+Vector2(31,-43),p+Vector2(48,-20)]),c.lightened(.08))
    draw_rect(Rect2(p.x-14,p.y-39,38,17),Color("17242b")); draw_circle(p+Vector2(-38,20),14,Color("111315")); draw_circle(p+Vector2(38,20),14,Color("111315"))

func draw_survivor(p:Vector2):
    var bob=sin(time*9.0)*2.0
    var q=p+Vector2(0,bob)
    draw_circle(q+Vector2(0,-34),15,Color("c99d7e"))
    draw_rect(Rect2(q.x-17,q.y-20,34,45),Color("263a48")); draw_rect(Rect2(q.x-14,q.y-14,28,8),Color("485a62"))
    draw_line(q+Vector2(-10,23),q+Vector2(-15,48),Color("202a31"),10); draw_line(q+Vector2(10,23),q+Vector2(15,48),Color("202a31"),10)
    draw_line(q+Vector2(10,-8),q+Vector2(34,-13),Color("c99d7e"),8); draw_line(q+Vector2(24,-13),q+Vector2(58,-17),Color("1a1d20"),7)
    draw_rect(Rect2(q.x+48,q.y-20,23,7),Color("343b40"))
    if muzzle>0: draw_circle(q+Vector2(74,-17),9*muzzle,Color(1,.67,.22,.8))

func draw_zombie(z:Dictionary):
    var p:Vector2=z.p; var gait=sin(time*6.0+z.phase)*7.0
    var skins=[Color("77806b"),Color("6f7562"),Color("82746b"),Color("68776b"),Color("817e68"),Color("9a715c"),Color("5f665b")]
    var clothes=[Color("4d5960"),Color("59433f"),Color("384b42"),Color("5a5548"),Color("3f4654"),Color("6e332d"),Color("252b2d")]
    var skin:Color=skins[z.type]; var cloth:Color=clothes[z.type]
    if z.hit>0: skin=skin.lerp(Color("d7c1aa"),z.hit)
    var scale := 1.0
    if z.type==5: scale=.88
    if z.type==6: scale=1.32
    draw_line(p+Vector2(-7,20)*scale,p+Vector2(-14+gait,48)*scale,cloth.darkened(.25),10*scale)
    draw_line(p+Vector2(7,20)*scale,p+Vector2(14-gait,48)*scale,cloth.darkened(.25),10*scale)
    draw_rect(Rect2(p+Vector2(-15,-16)*scale,Vector2(30,39)*scale),cloth)
    draw_line(p+Vector2(-12,-8)*scale,p+Vector2(-29-gait*.3,14)*scale,skin,8*scale)
    draw_line(p+Vector2(12,-8)*scale,p+Vector2(30+gait*.3,8)*scale,skin,8*scale)
    draw_circle(p+Vector2(0,-29)*scale,15*scale,skin)
    draw_circle(p+Vector2(-6,-31)*scale,2.2*scale,Color("e74b3f")); draw_circle(p+Vector2(6,-31)*scale,2.2*scale,Color("e74b3f"))
    if z.type>=5:
        draw_rect(Rect2(p.x-24,p.y-62*scale,48,5),Color("2a1919")); draw_rect(Rect2(p.x-24,p.y-62*scale,48*float(z.hp)/float(z.max_hp),5),Color("d14b40"))

func draw_pickup(pick:Dictionary):
    var p:Vector2=pick.p+Vector2(0,sin(time*4.0+pick.phase)*5.0)
    draw_circle(p,18,Color(0.08,0.1,0.1,.88)); draw_circle(p,15,Color("d9c36f") if pick.kind==1 else Color("b95a54"))
    if pick.kind==0:
        draw_rect(Rect2(p.x-3,p.y-10,6,20),Color.WHITE); draw_rect(Rect2(p.x-10,p.y-3,20,6),Color.WHITE)
    else:
        draw_rect(Rect2(p.x-8,p.y-7,16,14),Color("343b40")); draw_line(p+Vector2(-5,-3),p+Vector2(5,-3),Color("e7d5a0"),2)

func draw_hud():
    draw_rect(Rect2(18,18,390,86),Color(0.015,0.022,0.027,.91))
    draw_string(ThemeDB.fallback_font,Vector2(36,50),"BOSTON: APOCALYPSE",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("f2eee7"))
    draw_string(ThemeDB.fallback_font,Vector2(36,82),"HP %03d   5.56  %02d / %03d"%[hp,ammo,reserve],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e25a4e"))
    draw_rect(Rect2(36,91,220,5),Color("402b2b")); draw_rect(Rect2(36,91,220.0*hp/100.0,5),Color("c84b43"))
    draw_string(ThemeDB.fallback_font,Vector2(930,42),"WAVE %02d   KILLS %03d"%[wave,kills],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(930,69),"SCORE %07d"%score,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("d5b36c"))
    if combo>1: draw_string(ThemeDB.fallback_font,Vector2(555,72),"x%d COMBO"%combo,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("f0b24e"))
    draw_string(ThemeDB.fallback_font,Vector2(36,690),"MOVE: ARROWS/WASD   •   FIRE: CLICK/TAP   •   RELOAD: R",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(1,1,1,.62))

func draw_game_over():
    draw_rect(Rect2(0,0,W,H),Color(0,0,0,.72))
    draw_string(ThemeDB.fallback_font,Vector2(455,300),"BOSTON HAS FALLEN",HORIZONTAL_ALIGNMENT_LEFT,-1,42,Color("e9e4dc"))
    draw_string(ThemeDB.fallback_font,Vector2(510,350),"SCORE %d  •  KILLS %d"%[score,kills],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("d15a50"))
    draw_string(ThemeDB.fallback_font,Vector2(505,405),"PRESS ENTER TO REDEPLOY",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
