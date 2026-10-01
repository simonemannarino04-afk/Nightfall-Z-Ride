class_name CinematicDirector
extends Node

signal cinematic_started(id:String)
signal cinematic_finished(id:String)
signal subtitle(text:String,duration:float)
signal camera_event(kind:String,data:Dictionary)
signal gameplay_lock(locked:bool)

var playing := false
var current_id := ""

func play_intro(mission_id:int):
    if playing: return
    playing=true; current_id="mission_%d_intro"%mission_id
    gameplay_lock.emit(true); cinematic_started.emit(current_id)
    match mission_id:
        1: await _sequence(["Boston Emergency Management: All civilians remain indoors.","Checkpoint Seven, respond...","No response. Move."],[2.2,1.8,1.2])
        2: await _sequence(["Kenmore Station. Rescue team signal ends below us.","Lights are dead. Stay close."],[2.4,1.8])
        4: await _sequence(["Convoy is pinned downtown.","We get them out or nobody does."],[2.0,1.8])
        7: await _sequence(["This is where it started.","Get the data. Burn everything else."],[2.2,2.2])
        _: await _sequence(["Quarantine line breached. Continue the mission."],[2.0])
    _finish()

func play_boss_reveal(name:String):
    if playing: return
    playing=true; current_id="boss_%s"%name.to_lower().replace(" ","_")
    gameplay_lock.emit(true); cinematic_started.emit(current_id)
    camera_event.emit("shake",{"strength":9.0,"duration":.8})
    subtitle.emit("WARNING — %s"%name.to_upper(),1.8)
    await get_tree().create_timer(1.8).timeout
    camera_event.emit("boss_focus",{"duration":1.0})
    await get_tree().create_timer(1.0).timeout
    _finish()

func _sequence(lines:Array[String],durations:Array[float]):
    for i in range(lines.size()):
        subtitle.emit(lines[i],durations[i])
        await get_tree().create_timer(durations[i]).timeout

func _finish():
    var finished:=current_id
    playing=false; current_id=""
    gameplay_lock.emit(false); cinematic_finished.emit(finished)
