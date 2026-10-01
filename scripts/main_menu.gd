extends Control

var selected_mission:=1
var save:=SaveManager.new()
var page:="HOME"
var hover_index:=-1
var missions:Array[Dictionary]=[]
var menu_items:=["CONTINUA","NUOVA PARTITA","SELEZIONE MISSIONI","ARSENALE","PERSONALIZZAZIONE","IMPOSTAZIONI"]

func _ready():
    add_child(save); save.load_game(); selected_mission=int(save.data.last_mission)
    missions=CampaignData.missions(); set_process_input(true); queue_redraw()

func _input(event):
    if event is InputEventMouseMotion:
        hover_index=_menu_hit(event.position); queue_redraw()
    if event is InputEventMouseButton and event.pressed:
        _activate_at(event.position)
    if event is InputEventScreenTouch and event.pressed:
        _activate_at(event.position)
    if event is InputEventKey and event.pressed:
        if event.keycode==KEY_ESCAPE: page="HOME"; queue_redraw(); return
        if page=="MISSIONS":
            if event.keycode in [KEY_LEFT,KEY_A]: selected_mission=maxi(1,selected_mission-1); queue_redraw()
            if event.keycode in [KEY_RIGHT,KEY_D]: selected_mission=mini(7,selected_mission+1); queue_redraw()
            if event.keycode in [KEY_ENTER,KEY_SPACE]: _deploy()

func _activate_at(p:Vector2):
    if page=="HOME":
        var idx:=_menu_hit(p)
        if idx==0: selected_mission=int(save.data.last_mission); _deploy()
        elif idx==1: selected_mission=1; _deploy()
        elif idx==2: page="MISSIONS"
        elif idx==3: page="ARSENAL"
        elif idx==4: page="CUSTOMIZE"
        elif idx==5: page="SETTINGS"
    elif page=="MISSIONS":
        for i in range(7):
            if Rect2(48+i*170,120,154,155).has_point(p): selected_mission=i+1
        if Rect2(925,560,285,78).has_point(p): _deploy()
        if Rect2(35,35,110,45).has_point(p): page="HOME"
    else:
        if Rect2(35,35,110,45).has_point(p): page="HOME"
    queue_redraw()

func _menu_hit(p:Vector2)->int:
    for i in range(menu_items.size()):
        if Rect2(55,245+i*54,300,45).has_point(p): return i
    return -1

func _deploy():
    if not save.is_unlocked(selected_mission): return
    get_tree().set_meta("selected_mission",selected_mission)
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _draw():
    if page=="HOME": _draw_home()
    elif page=="MISSIONS": _draw_missions()
    elif page=="ARSENAL": _draw_arsenal()
    elif page=="CUSTOMIZE": _draw_customize()
    else: _draw_settings()

func _background():
    draw_rect(Rect2(0,0,1280,720),Color("080d12"))
    for i in range(12):
        var h:=120+(i%4)*42
        draw_rect(Rect2(i*112,430-h,82,h),Color("111b23"))
        for y in range(int(445-h),410,24): draw_rect(Rect2(i*112+13,y,8,11),Color(0.78,.42,.22,.35))
    draw_circle(Vector2(1030,145),78,Color(.86,.37,.18,.09))
    draw_colored_polygon(PackedVector2Array([Vector2(0,480),Vector2(1280,430),Vector2(1280,720),Vector2(0,720)]),Color("14191d"))
    for x in range(0,1280,95): draw_line(Vector2(x,500),Vector2(x+180,720),Color(.1,.11,.12),2)

func _draw_home():
    _background()
    draw_rect(Rect2(0,0,410,720),Color(0.015,.02,.025,.9))
    draw_string(ThemeDB.fallback_font,Vector2(52,92),"BOSTON",HORIZONTAL_ALIGNMENT_LEFT,-1,62,Color("f0ede7"))
    draw_string(ThemeDB.fallback_font,Vector2(54,140),"APOCALYPSE",HORIZONTAL_ALIGNMENT_LEFT,-1,37,Color("c52e2e"))
    draw_string(ThemeDB.fallback_font,Vector2(57,175),"SURVIVE WHAT REMAINS",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(1,1,1,.52))
    for i in range(menu_items.size()):
        var r:=Rect2(55,245+i*54,300,45); var active:=i==hover_index
        draw_rect(r,Color("7b1719") if active else Color(.055,.07,.08,.95))
        draw_rect(Rect2(r.position,Vector2(4,r.size.y)),Color("df3935") if active else Color("38434a"))
        draw_string(ThemeDB.fallback_font,r.position+Vector2(18,29),menu_items[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(930,665),"CAMPAGNA  %d / 7"%save.data.completed.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(1,1,1,.55))

func _draw_missions():
    _background(); _top_bar("SELEZIONE MISSIONI")
    for i in range(7):
        var m:Dictionary=missions[i]; var unlocked:=save.is_unlocked(i+1); var selected:=selected_mission==i+1
        var r:=Rect2(48+i*170,120,154,155)
        draw_rect(r,Color("351518") if selected else Color(.035,.045,.055,.95))
        draw_rect(Rect2(r.position,Vector2(r.size.x,5)),Color("e13d38") if selected else Color("3a464e"))
        draw_rect(Rect2(r.position+Vector2(12,15),Vector2(130,78)),Color("172731") if unlocked else Color("101417"))
        draw_string(ThemeDB.fallback_font,r.position+Vector2(14,119),"%d  %s"%[i+1,m.location.to_upper()],HORIZONTAL_ALIGNMENT_LEFT,126,13,Color.WHITE if unlocked else Color(.38,.4,.42))
        if not unlocked: draw_string(ThemeDB.fallback_font,r.position+Vector2(58,65),"LOCK",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(.65,.65,.65))
    var m:Dictionary=missions[selected_mission-1]; var unlocked:=save.is_unlocked(selected_mission)
    draw_rect(Rect2(48,320,1162,318),Color(.018,.025,.03,.94)); draw_rect(Rect2(48,320,8,318),Color("b52d2c"))
    draw_string(ThemeDB.fallback_font,Vector2(78,365),"%02d — %s"%[selected_mission,m.title],HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(78,397),str(m.location),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("d5a04f"))
    draw_string(ThemeDB.fallback_font,Vector2(78,432),str(m.brief),HORIZONTAL_ALIGNMENT_LEFT,760,16,Color(1,1,1,.72))
    draw_string(ThemeDB.fallback_font,Vector2(78,475),"OBIETTIVI",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("d64b46"))
    for i in range(m.objectives.size()): draw_string(ThemeDB.fallback_font,Vector2(90,510+i*29),"○  "+str(m.objectives[i]),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.88,.88,.88))
    draw_string(ThemeDB.fallback_font,Vector2(925,485),"RICOMPENSA",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(.75,.75,.75))
    draw_string(ThemeDB.fallback_font,Vector2(925,525),str(m.reward),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e5b657"))
    var deploy:=Rect2(925,560,285,78); draw_rect(deploy,Color("a91e20") if unlocked else Color("303438")); draw_rect(Rect2(deploy.position,Vector2(deploy.size.x,4)),Color("f0443f") if unlocked else Color("555b60"))
    draw_string(ThemeDB.fallback_font,deploy.position+Vector2(83,49),"DEPLOY" if unlocked else "BLOCCATA",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)

func _draw_arsenal():
    _background(); _top_bar("ARSENALE")
    var weapons:=WeaponData.all()
    for i in range(weapons.size()):
        var col:=i%4; var row:=i/4; var r:=Rect2(70+col*295,155+row*210,255,165); var w:Dictionary=weapons[i]
        draw_rect(r,Color(.025,.035,.042,.96)); draw_rect(Rect2(r.position,Vector2(r.size.x,4)),_rarity(str(w.rarity)))
        draw_string(ThemeDB.fallback_font,r.position+Vector2(18,42),str(w.name),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE)
        draw_string(ThemeDB.fallback_font,r.position+Vector2(18,70),str(w.rarity),HORIZONTAL_ALIGNMENT_LEFT,-1,13,_rarity(str(w.rarity)))
        draw_string(ThemeDB.fallback_font,r.position+Vector2(18,110),"DMG %d   MAG %d"%[w.damage,w.mag],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(.78,.8,.82))
        draw_string(ThemeDB.fallback_font,r.position+Vector2(18,137),"RPM %d   RELOAD %.1fs"%[int(w.rpm),float(w.reload)],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.6,.64,.67))

func _draw_customize():
    _background(); _top_bar("PERSONALIZZAZIONE")
    draw_rect(Rect2(80,145,420,500),Color(.025,.033,.04,.95)); draw_rect(Rect2(535,145,660,500),Color(.025,.033,.04,.95))
    draw_circle(Vector2(290,265),58,Color("ad846a")); draw_rect(Rect2(225,325,130,190),Color("26323a")); draw_rect(Rect2(205,365,170,70),Color("39464d"))
    draw_string(ThemeDB.fallback_font,Vector2(190,585),"OPERATORE",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
    var labels=["TESTA","TORSO","PANTALONI","ZAINO","ARMA PRIMARIA","ARMA SECONDARIA"]
    for i in range(labels.size()):
        var r:=Rect2(570,190+i*65,580,48); draw_rect(r,Color("11191f")); draw_string(ThemeDB.fallback_font,r.position+Vector2(18,30),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.85,.87,.88))
        draw_string(ThemeDB.fallback_font,r.position+Vector2(440,30),"CAMBIA  >",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("d64b46"))

func _draw_settings():
    _background(); _top_bar("IMPOSTAZIONI")
    draw_rect(Rect2(160,155,960,470),Color(.025,.033,.04,.96))
    var opts=["AUDIO","MUSICA","EFFETTI","VIBRAZIONE","QUALITÀ GRAFICA","60 FPS"]
    for i in range(opts.size()):
        draw_string(ThemeDB.fallback_font,Vector2(210,215+i*62),opts[i],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
        draw_rect(Rect2(720,195+i*62,330,28),Color("182128")); draw_rect(Rect2(720,195+i*62,240 if i<3 else 330,28),Color("8f2425"))

func _top_bar(title:String):
    draw_rect(Rect2(0,0,1280,92),Color(.012,.017,.021,.96)); draw_string(ThemeDB.fallback_font,Vector2(180,59),title,HORIZONTAL_ALIGNMENT_LEFT,-1,31,Color.WHITE)
    draw_rect(Rect2(35,35,110,45),Color("161e24")); draw_string(ThemeDB.fallback_font,Vector2(58,64),"< INDIETRO",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(.85,.85,.85))

func _rarity(v:String)->Color:
    match v:
        "UNCOMMON": return Color("65b96e")
        "RARE": return Color("4f82d9")
        "EPIC": return Color("9b5bd1")
        "LEGENDARY": return Color("d99a3e")
    return Color("8d969d")
