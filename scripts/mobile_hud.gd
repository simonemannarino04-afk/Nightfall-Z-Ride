class_name MobileHUD
extends Control

signal move_vector_changed(value:Vector2)
signal fire_pressed(target:Vector2)
signal reload_pressed
signal swap_pressed

var hp:=100
var ammo:=30
var reserve:=120
var weapon_name:="M4A1"
var objective:="SURVIVE"
var boss_name:=""
var boss_ratio:=0.0
var joystick_touch:=-1
var aim_touch:=-1
var joystick_center:=Vector2(145,570)
var joystick_knob:=Vector2.ZERO
var aim_pos:=Vector2(1030,390)

func _ready():
    set_process_input(true); queue_redraw()

func set_status(new_hp:int,new_ammo:int,new_reserve:int,new_weapon:String):
    hp=new_hp; ammo=new_ammo; reserve=new_reserve; weapon_name=new_weapon; queue_redraw()

func set_objective(text:String): objective=text; queue_redraw()
func set_boss(name:String,ratio:float): boss_name=name; boss_ratio=ratio; queue_redraw()
func clear_boss(): boss_name=""; boss_ratio=0.0; queue_redraw()

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x<430 and event.position.y>390 and joystick_touch<0:
                joystick_touch=event.index; joystick_center=event.position; joystick_knob=Vector2.ZERO
            elif Rect2(1120,535,125,125).has_point(event.position): fire_pressed.emit(aim_pos)
            elif Rect2(1015,585,85,70).has_point(event.position): reload_pressed.emit()
            elif Rect2(920,585,75,70).has_point(event.position): swap_pressed.emit()
            elif aim_touch<0:
                aim_touch=event.index; aim_pos=event.position; fire_pressed.emit(aim_pos)
        else:
            if event.index==joystick_touch:
                joystick_touch=-1; joystick_knob=Vector2.ZERO; move_vector_changed.emit(Vector2.ZERO)
            if event.index==aim_touch: aim_touch=-1
        queue_redraw()
    elif event is InputEventScreenDrag:
        if event.index==joystick_touch:
            joystick_knob=(event.position-joystick_center).limit_length(62.0)
            move_vector_changed.emit(joystick_knob/62.0)
        elif event.index==aim_touch:
            aim_pos=event.position
        queue_redraw()

func _draw():
    draw_rect(Rect2(24,20,355,78),Color(0.015,.02,.025,.88))
    draw_string(ThemeDB.fallback_font,Vector2(42,50),"HP %03d"%hp,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
    draw_rect(Rect2(42,65,220,9),Color("3b2021")); draw_rect(Rect2(42,65,220.0*hp/100.0,9),Color("c83b38"))
    draw_string(ThemeDB.fallback_font,Vector2(410,46),objective,HORIZONTAL_ALIGNMENT_CENTER,460,17,Color("eee9df"))
    draw_rect(Rect2(920,20,335,80),Color(0.015,.02,.025,.88))
    draw_string(ThemeDB.fallback_font,Vector2(940,50),weapon_name,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(1090,75),"%02d / %03d"%[ammo,reserve],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("e9e5dd"))
    if boss_name!="":
        draw_rect(Rect2(390,105,500,45),Color(0.02,.02,.02,.9)); draw_string(ThemeDB.fallback_font,Vector2(410,127),boss_name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e7d9cf"))
        draw_rect(Rect2(410,134,460,7),Color("3c2020")); draw_rect(Rect2(410,134,460*boss_ratio,7),Color("b52e2b"))
    draw_circle(joystick_center,78,Color(.1,.12,.13,.55)); draw_circle(joystick_center,64,Color(.16,.18,.19,.45)); draw_circle(joystick_center+joystick_knob,31,Color(.7,.72,.72,.58))
    draw_circle(Vector2(1182,598),61,Color(.48,.08,.08,.66)); draw_circle(Vector2(1182,598),43,Color(.72,.12,.1,.72)); draw_string(ThemeDB.fallback_font,Vector2(1152,606),"FIRE",HORIZONTAL_ALIGNMENT_CENTER,60,14,Color.WHITE)
    draw_rect(Rect2(1015,585,85,70),Color(.08,.1,.11,.72)); draw_string(ThemeDB.fallback_font,Vector2(1027,626),"RELOAD",HORIZONTAL_ALIGNMENT_CENTER,62,11,Color.WHITE)
    draw_rect(Rect2(920,585,75,70),Color(.08,.1,.11,.72)); draw_string(ThemeDB.fallback_font,Vector2(930,626),"SWAP",HORIZONTAL_ALIGNMENT_CENTER,55,11,Color.WHITE)
    draw_circle(aim_pos,13,Color(1,1,1,.22)); draw_line(aim_pos-Vector2(22,0),aim_pos+Vector2(22,0),Color(1,1,1,.45),2); draw_line(aim_pos-Vector2(0,22),aim_pos+Vector2(0,22),Color(1,1,1,.45),2)
