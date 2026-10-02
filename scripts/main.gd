extends Node2D

const WORLD_SIZE := Vector2(1920.0, 1080.0)
const PLAYER_RADIUS := 24.0
const MAX_ZOMBIES := 160
const PICKUP_LIMIT := 10

var player := Vector2(960, 620)
var player_vel := Vector2.ZERO
var hp := 100.0
var max_hp := 100.0
var stamina := 100.0
var score := 0
var wave := 1
var kills := 0
var paused := false
var game_over := false
var show_help := true
var hit_flash := 0.0
var muzzle_flash := 0.0
var dash_cd := 0.0
var wave_cooldown := 0.0
var spawn_accum := 0.0
var fire_accum := 0.0
var reload_timer := 0.0
var is_reloading := false

var zombies: Array = []
var bullets: Array = []
var particles: Array = []
var pickups: Array = []

var weapons := [
    {"name":"M4A1", "mag":30, "ammo":30, "reserve":180, "damage":34.0, "rate":0.095, "reload":1.55, "spread":0.026, "speed":1450.0, "pellets":1},
    {"name":"M870", "mag":8, "ammo":8, "reserve":48, "damage":22.0, "rate":0.72, "reload":1.9, "spread":0.14, "speed":1120.0, "pellets":7},
    {"name":"M9", "mag":15, "ammo":15, "reserve":90, "damage":46.0, "rate":0.22, "reload":1.2, "spread":0.018, "speed":1320.0, "pellets":1}
]
var weapon_index := 0

func _ready() -> void:
    randomize()
    _setup_inputs()
    _start_wave()
    queue_redraw()

func _setup_inputs() -> void:
    _bind_key("move_left", KEY_A)
    _bind_key("move_right", KEY_D)
    _bind_key("move_up", KEY_W)
    _bind_key("move_down", KEY_S)
    _bind_key("reload", KEY_R)
    _bind_key("dash", KEY_SPACE)

func _bind_key(action: StringName, keycode: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    for e in InputMap.action_get_events(action):
        if e is InputEventKey and e.physical_keycode == keycode:
            return
    var ev := InputEventKey.new()
    ev.physical_keycode = keycode
    InputMap.action_add_event(action, ev)

func _process(delta: float) -> void:
    if paused:
        queue_redraw()
        return
    if game_over:
        queue_redraw()
        return

    hit_flash = maxf(0.0, hit_flash - delta * 3.5)
    muzzle_flash = maxf(0.0, muzzle_flash - delta * 8.0)
    dash_cd = maxf(0.0, dash_cd - delta)
    fire_accum = maxf(0.0, fire_accum - delta)

    _update_player(delta)
    _update_reload(delta)
    _update_fire()
    _update_bullets(delta)
    _update_zombies(delta)
    _update_particles(delta)
    _update_pickups(delta)
    _update_wave(delta)

    if hp <= 0.0:
        hp = 0.0
        game_over = true

    queue_redraw()

func _update_player(delta: float) -> void:
    var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var sprinting := Input.is_key_pressed(KEY_SHIFT) and stamina > 0.0 and dir.length_squared() > 0.01
    var speed := 340.0 if not sprinting else 465.0
    if sprinting:
        stamina = maxf(0.0, stamina - 31.0 * delta)
    else:
        stamina = minf(100.0, stamina + 22.0 * delta)

    player_vel = player_vel.lerp(dir * speed, minf(1.0, delta * 13.0))
    player += player_vel * delta
    player.x = clampf(player.x, 48.0, WORLD_SIZE.x - 48.0)
    player.y = clampf(player.y, 170.0, WORLD_SIZE.y - 58.0)

    if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and stamina >= 28.0:
        var dash_dir := dir if dir.length_squared() > 0.01 else (get_global_mouse_position() - player).normalized()
        player += dash_dir * 150.0
        player.x = clampf(player.x, 48.0, WORLD_SIZE.x - 48.0)
        player.y = clampf(player.y, 170.0, WORLD_SIZE.y - 58.0)
        stamina -= 28.0
        dash_cd = 0.75
        for i in range(9):
            _spawn_particle(player - dash_dir * randf_range(10.0, 45.0), Color(0.55,0.62,0.67,0.45), randf_range(2.0,5.0), 0.35)

    if Input.is_action_just_pressed("reload"):
        _begin_reload()

func _update_fire() -> void:
    if is_reloading:
        return
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _try_fire()

func _try_fire() -> void:
    var w: Dictionary = weapons[weapon_index]
    if fire_accum > 0.0:
        return
    if w["ammo"] <= 0:
        _begin_reload()
        return

    w["ammo"] -= 1
    weapons[weapon_index] = w
    fire_accum = w["rate"]
    muzzle_flash = 1.0

    var target := get_global_mouse_position()
    var aim := (target - player).normalized()
    if aim.length_squared() < 0.001:
        aim = Vector2.RIGHT

    for p in range(int(w["pellets"])):
        var angle := aim.angle() + randf_range(-float(w["spread"]), float(w["spread"]))
        var d := Vector2.RIGHT.rotated(angle)
        bullets.append({
            "pos": player + d * 34.0,
            "vel": d * float(w["speed"]),
            "life": 1.25,
            "damage": float(w["damage"]),
            "radius": 4.0 if int(w["pellets"]) == 1 else 3.0
        })

    for i in range(4):
        _spawn_particle(player + aim * 36.0, Color(1.0,0.72,0.28,0.9), randf_range(2.0,5.0), 0.12)

func _begin_reload() -> void:
    var w: Dictionary = weapons[weapon_index]
    if is_reloading or w["ammo"] >= w["mag"] or w["reserve"] <= 0:
        return
    is_reloading = true
    reload_timer = float(w["reload"])

func _update_reload(delta: float) -> void:
    if not is_reloading:
        return
    reload_timer -= delta
    if reload_timer <= 0.0:
        var w: Dictionary = weapons[weapon_index]
        var need: int = int(w["mag"]) - int(w["ammo"])
        var take: int = mini(need, int(w["reserve"]))
        w["ammo"] += take
        w["reserve"] -= take
        weapons[weapon_index] = w
        is_reloading = false

func _update_bullets(delta: float) -> void:
    for i in range(bullets.size() - 1, -1, -1):
        var b: Dictionary = bullets[i]
        b["pos"] += b["vel"] * delta
        b["life"] -= delta
        var remove := b["life"] <= 0.0

        if not remove:
            for zidx in range(zombies.size() - 1, -1, -1):
                var z: Dictionary = zombies[zidx]
                if (z["pos"] - b["pos"]).length_squared() <= pow(float(z["radius"]) + float(b["radius"]), 2.0):
                    z["hp"] -= b["damage"]
                    zombies[zidx] = z
                    _spawn_blood(b["pos"])
                    remove = true
                    if z["hp"] <= 0.0:
                        _kill_zombie(zidx)
                    break

        if remove:
            bullets.remove_at(i)
        else:
            bullets[i] = b

func _update_zombies(delta: float) -> void:
    for i in range(zombies.size()):
        var z: Dictionary = zombies[i]
        var to_player: Vector2 = player - z["pos"]
        var dist2 := to_player.length_squared()
        if dist2 > 1.0:
            var desired := to_player.normalized()
            var wobble := Vector2(sin(Time.get_ticks_msec() * 0.002 + float(z["seed"])), cos(Time.get_ticks_msec() * 0.0017 + float(z["seed"]))) * 0.12
            z["pos"] += (desired + wobble).normalized() * float(z["speed"]) * delta

        z["attack_cd"] = maxf(0.0, float(z["attack_cd"]) - delta)
        var reach: float = PLAYER_RADIUS + float(z["radius"]) + 7.0
        if dist2 < reach * reach and float(z["attack_cd"]) <= 0.0:
            hp -= float(z["damage"])
            z["attack_cd"] = 0.72
            hit_flash = 1.0
            var knock := (player - z["pos"]).normalized()
            player += knock * 28.0

        zombies[i] = z

func _kill_zombie(index: int) -> void:
    if index < 0 or index >= zombies.size():
        return
    var z: Dictionary = zombies[index]
    var pos: Vector2 = z["pos"]
    zombies.remove_at(index)
    kills += 1
    score += int(90 + wave * 12 + float(z["max_hp"]) * 0.4)
    for i in range(8):
        _spawn_particle(pos, Color(0.35,0.04,0.035,0.9), randf_range(3.0,8.0), randf_range(0.25,0.6))
    var roll := randf()
    if pickups.size() < PICKUP_LIMIT:
        if roll < 0.07:
            pickups.append({"pos":pos, "type":"med", "life":14.0})
        elif roll < 0.16:
            pickups.append({"pos":pos, "type":"ammo", "life":14.0})

func _spawn_blood(pos: Vector2) -> void:
    for i in range(3):
        _spawn_particle(pos, Color(0.42,0.03,0.03,0.85), randf_range(2.0,5.0), randf_range(0.18,0.38))

func _spawn_particle(pos: Vector2, color: Color, size: float, life: float) -> void:
    if particles.size() > 260:
        particles.pop_front()
    particles.append({"pos":pos, "vel":Vector2.from_angle(randf()*TAU)*randf_range(25.0,120.0), "color":color, "size":size, "life":life, "max_life":life})

func _update_particles(delta: float) -> void:
    for i in range(particles.size() - 1, -1, -1):
        var p: Dictionary = particles[i]
        p["life"] -= delta
        if p["life"] <= 0.0:
            particles.remove_at(i)
        else:
            p["pos"] += p["vel"] * delta
            p["vel"] *= 0.91
            particles[i] = p

func _update_pickups(delta: float) -> void:
    for i in range(pickups.size() - 1, -1, -1):
        var p: Dictionary = pickups[i]
        p["life"] -= delta
        var collected := (p["pos"] - player).length_squared() < 46.0 * 46.0
        if collected:
            if p["type"] == "med":
                hp = minf(max_hp, hp + 32.0)
            else:
                for wi in range(weapons.size()):
                    var w: Dictionary = weapons[wi]
                    w["reserve"] += int(w["mag"]) * 2
                    weapons[wi] = w
            pickups.remove_at(i)
        elif p["life"] <= 0.0:
            pickups.remove_at(i)
        else:
            pickups[i] = p

func _update_wave(delta: float) -> void:
    if zombies.is_empty():
        wave_cooldown += delta
        if wave_cooldown >= 2.2:
            wave += 1
            wave_cooldown = 0.0
            _start_wave()
        return

    spawn_accum += delta
    var target_count := mini(MAX_ZOMBIES, 10 + wave * 5)
    var interval := maxf(0.22, 0.72 - wave * 0.018)
    if spawn_accum >= interval and zombies.size() < target_count:
        spawn_accum = 0.0
        _spawn_zombie()

func _start_wave() -> void:
    var initial := mini(12 + wave * 3, 40)
    for i in range(initial):
        _spawn_zombie()

func _spawn_zombie() -> void:
    if zombies.size() >= MAX_ZOMBIES:
        return
    var side := randi() % 4
    var pos := Vector2.ZERO
    match side:
        0: pos = Vector2(randf_range(40.0, WORLD_SIZE.x-40.0), 145.0)
        1: pos = Vector2(WORLD_SIZE.x-35.0, randf_range(180.0, WORLD_SIZE.y-40.0))
        2: pos = Vector2(randf_range(40.0, WORLD_SIZE.x-40.0), WORLD_SIZE.y-35.0)
        _: pos = Vector2(35.0, randf_range(180.0, WORLD_SIZE.y-40.0))

    if pos.distance_to(player) < 380.0:
        pos = Vector2(WORLD_SIZE.x - pos.x, WORLD_SIZE.y - pos.y)

    var brute := randf() < minf(0.28, 0.05 + wave * 0.008)
    var maxz: float = (145.0 + wave * 9.0) if brute else (70.0 + wave * 5.0)
    zombies.append({
        "pos":pos,
        "hp":maxz,
        "max_hp":maxz,
        "speed":randf_range(62.0,88.0) + wave * 2.7 - (18.0 if brute else 0.0),
        "radius":30.0 if brute else randf_range(20.0,24.0),
        "damage":16.0 if brute else 8.0 + wave * 0.35,
        "attack_cd":randf_range(0.0,0.4),
        "seed":randf_range(0.0,10.0),
        "brute":brute
    })

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_ESCAPE:
                paused = not paused
            KEY_F11:
                var mode := DisplayServer.window_get_mode()
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
            KEY_F1:
                show_help = not show_help
            KEY_1:
                _select_weapon(0)
            KEY_2:
                _select_weapon(1)
            KEY_3:
                _select_weapon(2)
            KEY_ENTER:
                if game_over:
                    _restart()
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            _select_weapon((weapon_index + weapons.size() - 1) % weapons.size())
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            _select_weapon((weapon_index + 1) % weapons.size())

func _select_weapon(index: int) -> void:
    if index < 0 or index >= weapons.size():
        return
    weapon_index = index
    is_reloading = false
    fire_accum = 0.0

func _restart() -> void:
    player = Vector2(960,620)
    hp = max_hp
    stamina = 100.0
    score = 0
    wave = 1
    kills = 0
    zombies.clear()
    bullets.clear()
    particles.clear()
    pickups.clear()
    for i in range(weapons.size()):
        var w: Dictionary = weapons[i]
        w["ammo"] = w["mag"]
        w["reserve"] = int(w["mag"]) * 6
        weapons[i] = w
    game_over = false
    paused = false
    _start_wave()

func _draw() -> void:
    _draw_world()
    _draw_pickups()
    _draw_bullets()
    _draw_zombies()
    _draw_player()
    _draw_particles()
    _draw_hud()

func _draw_world() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("0a1016"))
    draw_rect(Rect2(0, 145, WORLD_SIZE.x, WORLD_SIZE.y-145), Color("171c20"))

    for x in range(0, 1920, 160):
        var h := 110 + (x * 7) % 260
        draw_rect(Rect2(x,145-h,132,h), Color("101820"))
        for wy in range(int(155-h),125,30):
            for wx in range(x+15,x+120,28):
                var lit := ((wx + wy + x) / 7) as int
                if lit % 4 == 0:
                    draw_rect(Rect2(wx,wy,10,14),Color("a96d3d"))

    draw_rect(Rect2(0, 145, WORLD_SIZE.x, 8), Color("7f2525"))
    for y in range(210, 1080, 150):
        draw_line(Vector2(0,y),Vector2(1920,y),Color(0.12,0.15,0.17,0.52),2)
    for x in range(0, 1920, 220):
        draw_line(Vector2(x,145),Vector2(x,1080),Color(0.09,0.11,0.13,0.45),2)

    draw_string(ThemeDB.fallback_font, Vector2(70, 195), "FEDERAL QUARANTINE ZONE • BOSTON", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.65,0.16,0.14,0.8))

func _draw_player() -> void:
    var aim := (get_global_mouse_position() - player).normalized()
    if aim.length_squared() < 0.001:
        aim = Vector2.RIGHT
    draw_circle(player + Vector2(0,20), 27, Color(0,0,0,0.25))
    draw_circle(player, PLAYER_RADIUS, Color("d8c2aa"))
    draw_rect(Rect2(player.x-18,player.y+18,36,45),Color("384a57"))
    draw_line(player + aim*12.0, player + aim*52.0, Color("c5c8c8"), 9.0)
    draw_line(player + aim*43.0, player + aim*63.0, Color("50565b"), 5.0)
    if muzzle_flash > 0.0:
        draw_circle(player + aim*68.0, 10.0 + muzzle_flash*7.0, Color(1.0,0.65,0.2,0.8*muzzle_flash))

func _draw_zombies() -> void:
    for z in zombies:
        var pos: Vector2 = z["pos"]
        var r: float = z["radius"]
        var brute: bool = z["brute"]
        draw_circle(pos + Vector2(0,r*0.8), r*0.9, Color(0,0,0,0.23))
        draw_circle(pos, r, Color("7d8c68") if not brute else Color("665451"))
        draw_rect(Rect2(pos.x-r*0.72,pos.y+r*0.55,r*1.44,r*1.55),Color("4c5e47") if not brute else Color("573d3d"))
        draw_circle(pos + Vector2(-r*0.34,-r*0.12), 3.2, Color("f04d3f"))
        draw_circle(pos + Vector2(r*0.34,-r*0.12), 3.2, Color("f04d3f"))
        if float(z["hp"]) < float(z["max_hp"]):
            var pct: float = clampf(float(z["hp"]) / float(z["max_hp"]),0.0,1.0)
            draw_rect(Rect2(pos.x-r,pos.y-r-13,r*2,4),Color(0.18,0.05,0.05,0.8))
            draw_rect(Rect2(pos.x-r,pos.y-r-13,r*2*pct,4),Color(0.65,0.12,0.1,0.95))

func _draw_bullets() -> void:
    for b in bullets:
        draw_circle(b["pos"], b["radius"], Color("ffd27a"))

func _draw_particles() -> void:
    for p in particles:
        var alpha: float = clampf(float(p["life"]) / float(p["max_life"]),0.0,1.0)
        var c: Color = p["color"]
        c.a *= alpha
        draw_circle(p["pos"], float(p["size"]), c)

func _draw_pickups() -> void:
    for p in pickups:
        var pos: Vector2 = p["pos"]
        var pulse := 1.0 + sin(Time.get_ticks_msec()*0.006)*0.12
        if p["type"] == "med":
            draw_circle(pos,18*pulse,Color(0.12,0.55,0.22,0.85))
            draw_rect(Rect2(pos.x-4,pos.y-12,8,24),Color.WHITE)
            draw_rect(Rect2(pos.x-12,pos.y-4,24,8),Color.WHITE)
        else:
            draw_rect(Rect2(pos.x-17,pos.y-12,34,24),Color(0.72,0.55,0.18,0.9))
            draw_string(ThemeDB.fallback_font,pos+Vector2(-10,7),"AM",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("161616"))

func _draw_hud() -> void:
    draw_rect(Rect2(24,22,560,112),Color(0.015,0.02,0.026,0.91))
    draw_string(ThemeDB.fallback_font,Vector2(44,55),"BOSTON: QUARANTINE",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("f2f1ed"))
    draw_string(ThemeDB.fallback_font,Vector2(44,85),"WAVE %d   •   KILLS %d   •   SCORE %d" % [wave,kills,score],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d74a40"))

    var hp_pct := hp/max_hp
    draw_rect(Rect2(44,101,230,12),Color("2b1010"))
    draw_rect(Rect2(44,101,230*hp_pct,12),Color("b83b35"))
    draw_string(ThemeDB.fallback_font,Vector2(286,113),"HP %d" % int(hp),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)

    draw_rect(Rect2(640,22,420,112),Color(0.015,0.02,0.026,0.91))
    var w: Dictionary = weapons[weapon_index]
    draw_string(ThemeDB.fallback_font,Vector2(660,56),str(w["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("f0d39b"))
    draw_string(ThemeDB.fallback_font,Vector2(660,91),"%02d / %03d" % [w["ammo"],w["reserve"]],HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color.WHITE)
    if is_reloading:
        draw_string(ThemeDB.fallback_font,Vector2(840,91),"RELOADING...",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e8a04b"))

    draw_rect(Rect2(1100,22,790,112),Color(0.015,0.02,0.026,0.91))
    draw_string(ThemeDB.fallback_font,Vector2(1120,58),"MISSION 01 • BREAK THE CORDON",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(1120,92),"Survive the quarantine waves and reach the extraction zone.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("aab3b8"))

    draw_rect(Rect2(44,1040,260,10),Color("252b2e"))
    draw_rect(Rect2(44,1040,260*(stamina/100.0),10),Color("679b8a"))
    draw_string(ThemeDB.fallback_font,Vector2(315,1052),"STAMINA",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("a8c7bd"))

    if show_help:
        draw_rect(Rect2(1340,880,550,154),Color(0.01,0.015,0.02,0.87))
        draw_string(ThemeDB.fallback_font,Vector2(1360,912),"WASD move   •   Mouse aim/fire   •   R reload",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("dce2e4"))
        draw_string(ThemeDB.fallback_font,Vector2(1360,942),"SHIFT sprint   •   SPACE dash   •   1/2/3 weapons",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("dce2e4"))
        draw_string(ThemeDB.fallback_font,Vector2(1360,972),"F11 fullscreen   •   ESC pause   •   F1 hide help",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("dce2e4"))

    if hit_flash > 0.0:
        draw_rect(Rect2(Vector2.ZERO,WORLD_SIZE),Color(0.5,0.02,0.02,0.09*hit_flash))

    if paused:
        draw_rect(Rect2(Vector2.ZERO,WORLD_SIZE),Color(0,0,0,0.62))
        draw_string(ThemeDB.fallback_font,Vector2(780,500),"PAUSED",HORIZONTAL_ALIGNMENT_CENTER,360,46,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(780,555),"Press ESC to resume",HORIZONTAL_ALIGNMENT_CENTER,360,20,Color("b9c0c4"))

    if game_over:
        draw_rect(Rect2(Vector2.ZERO,WORLD_SIZE),Color(0,0,0,0.74))
        draw_string(ThemeDB.fallback_font,Vector2(700,455),"QUARANTINE FAILED",HORIZONTAL_ALIGNMENT_CENTER,520,48,Color("d9433c"))
        draw_string(ThemeDB.fallback_font,Vector2(700,520),"Score %d  •  Wave %d  •  Kills %d" % [score,wave,kills],HORIZONTAL_ALIGNMENT_CENTER,520,22,Color.WHITE)
        draw_string(ThemeDB.fallback_font,Vector2(700,575),"Press ENTER to restart",HORIZONTAL_ALIGNMENT_CENTER,520,20,Color("c7cdcf"))
