extends Control

var selected_mission:=1
var save:=SaveManager.new()

func _ready():
    add_child(save); save.load_game(); selected_mission=int(save.data.last_mission)
    queue_redraw()

func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode in [KEY_LEFT,KEY_A]: selected_mission=maxi(1,selected_mission-1); queue_redraw()
        if event.keycode in [KEY_RIGHT,KEY_D]: selected_mission=mini(7,selected_mission+1); queue_redraw()
        if event.keycode in [KEY_ENTER,KEY_SPACE] and save.is_unlocked(selected_mission):
            get_tree().set_meta("selected_mission",selected_mission)
            get_tree().change_scene_to_file("res://scenes/main.tscn")

func _draw():
    draw_rect(Rect2(0,0,1280,720),Color("090d11"))
    for i in range(9):
        draw_rect(Rect2(i*155,250-(i%3)*35,120,360+(i%3)*35),Color("111a21"))
    draw_circle(Vector2(1050,120),65,Color(.78,.57,.36,.12))
    draw_rect(Rect2(0,530,1280,190),Color(0.03,.035,.04,.94))
    draw_string(ThemeDB.fallback_font,Vector2(70,105),"BOSTON",HORIZONTAL_ALIGNMENT_LEFT,-1,58,Color("e9e4dc"))
    draw_string(ThemeDB.fallback_font,Vector2(72,151),"APOCALYPSE",HORIZONTAL_ALIGNMENT_LEFT,-1,35,Color("c74c42"))
    draw_string(ThemeDB.fallback_font,Vector2(72,190),"THE CITY IS LOST. SURVIVE WHAT REMAINS.",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(1,1,1,.58))
    var missions:=CampaignData.missions()
    var m:Dictionary=missions[selected_mission-1]
    var unlocked:=save.is_unlocked(selected_mission)
    draw_string(ThemeDB.fallback_font,Vector2(70,580),"MISSION %02d  —  %s"%[selected_mission,m.title],HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color.WHITE if unlocked else Color(.45,.45,.45))
    draw_string(ThemeDB.fallback_font,Vector2(70,612),str(m.location),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("c5a66a"))
    draw_string(ThemeDB.fallback_font,Vector2(70,646),str(m.brief),HORIZONTAL_ALIGNMENT_LEFT,760,15,Color(1,1,1,.7))
    draw_string(ThemeDB.fallback_font,Vector2(70,687),"◀  SELECT MISSION  ▶        ENTER: DEPLOY" if unlocked else "◀  SELECT MISSION  ▶        LOCKED",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e7e1d8"))
    draw_string(ThemeDB.fallback_font,Vector2(1010,675),"%d / 7 COMPLETE"%save.data.completed.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(1,1,1,.55))
