class_name CombatSystem
extends Node2D

signal hit_confirmed(position:Vector2, damage:int, headshot:bool)
signal weapon_drop_spawned(position:Vector2, weapon_id:String)

@export var max_range := 1200.0
@export var headshot_multiplier := 2
var weapon_cycle := ["m9","mp5","m4","ak","shotgun","scar","m249","barrett"]

func fire_hitscan(origin:Vector2, direction:Vector2, damage:int, zombies:Array) -> Dictionary:
    var best = null
    var best_distance := max_range
    var impact := origin + direction * max_range
    var was_headshot := false
    for zombie in zombies:
        if not is_instance_valid(zombie): continue
        var to_enemy:Vector2 = zombie.global_position-origin
        var along := to_enemy.dot(direction)
        if along < 0.0 or along > max_range: continue
        var closest := origin + direction*along
        var body_distance := closest.distance_to(zombie.global_position)
        if body_distance <= 28.0 and along < best_distance:
            best = zombie
            best_distance = along
            impact = closest
            was_headshot = closest.y < zombie.global_position.y-15.0
    if best != null:
        var final_damage := damage * (headshot_multiplier if was_headshot else 1)
        best.hit(final_damage)
        hit_confirmed.emit(impact,final_damage,was_headshot)
        return {"hit":true,"position":impact,"damage":final_damage,"headshot":was_headshot,"target":best}
    return {"hit":false,"position":impact,"damage":0,"headshot":false,"target":null}

func roll_weapon_drop(position:Vector2, wave:int) -> Dictionary:
    var chance := minf(0.22,0.07+wave*0.008)
    if randf() > chance: return {}
    var max_index := mini(weapon_cycle.size()-1,1+int(wave/2))
    var id:String = weapon_cycle[randi_range(0,max_index)]
    weapon_drop_spawned.emit(position,id)
    return {"position":position,"weapon_id":id,"life":18.0}

func drop_label(id:String) -> String:
    var data := WeaponData.get_weapon(id)
    return "%s  [%s]" % [data.name,data.rarity]
