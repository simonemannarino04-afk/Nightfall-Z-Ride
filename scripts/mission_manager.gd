class_name MissionManager
extends Node

signal mission_started(data:Dictionary)
signal objective_changed(text:String,index:int,total:int)
signal checkpoint_reached(index:int)
signal mission_completed(data:Dictionary)

var mission_id := 1
var mission:Dictionary = {}
var objective_index := 0
var checkpoint := 0
var completed := false

func start(id:int):
    mission_id = id
    mission = CampaignData.get_mission(id)
    objective_index = 0
    checkpoint = 0
    completed = false
    mission_started.emit(mission)
    _emit_objective()

func current_objective() -> String:
    if mission.is_empty(): return ""
    var objectives:Array = mission.objectives
    if objective_index >= objectives.size(): return "MISSION COMPLETE"
    return str(objectives[objective_index])

func complete_objective():
    if completed or mission.is_empty(): return
    objective_index += 1
    checkpoint = objective_index
    checkpoint_reached.emit(checkpoint)
    if objective_index >= mission.objectives.size():
        completed = true
        mission_completed.emit(mission)
    else:
        _emit_objective()

func restore_checkpoint() -> Dictionary:
    return {"mission_id":mission_id,"objective_index":checkpoint,"objective":current_objective()}

func _emit_objective():
    objective_changed.emit(current_objective(),objective_index+1,mission.objectives.size())
