class_name SaveManager
extends Node

const SAVE_PATH := "user://boston_apocalypse_save.json"
var data := {"unlocked_mission":1,"completed":[],"best_scores":{},"last_mission":1,"audio":1.0}

func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH): return data
    var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
    var parsed=JSON.parse_string(file.get_as_text())
    if parsed is Dictionary: data.merge(parsed,true)
    return data

func save_game():
    var file:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    file.store_string(JSON.stringify(data))

func complete_mission(id:int,score:int):
    if id not in data.completed: data.completed.append(id)
    data.unlocked_mission=maxi(int(data.unlocked_mission),mini(7,id+1))
    data.last_mission=id
    var key:=str(id)
    data.best_scores[key]=maxi(int(data.best_scores.get(key,0)),score)
    save_game()

func is_unlocked(id:int)->bool:
    return id<=int(data.unlocked_mission)

func reset_progress():
    data={"unlocked_mission":1,"completed":[],"best_scores":{},"last_mission":1,"audio":1.0}
    save_game()
