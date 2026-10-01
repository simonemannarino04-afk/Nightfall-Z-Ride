class_name WeaponInventory
extends Node

signal equipped_changed(slot:int, weapon_id:String)
signal inventory_changed(slots:Array)

@export var max_slots := 2
var slots:Array[String] = ["m9","m4"]
var equipped_slot := 1

func current_id() -> String:
    if slots.is_empty(): return "m9"
    return slots[equipped_slot]

func equip_slot(index:int) -> String:
    if index < 0 or index >= slots.size(): return current_id()
    equipped_slot = index
    equipped_changed.emit(equipped_slot,current_id())
    return current_id()

func cycle(direction:int=1) -> String:
    if slots.size() <= 1: return current_id()
    equipped_slot = posmod(equipped_slot+direction,slots.size())
    equipped_changed.emit(equipped_slot,current_id())
    return current_id()

func pickup(weapon_id:String) -> Dictionary:
    if weapon_id in slots:
        equip_slot(slots.find(weapon_id))
        return {"picked":true,"replaced":"","weapon_id":weapon_id}
    var replaced := ""
    if slots.size() < max_slots:
        slots.append(weapon_id)
        equipped_slot = slots.size()-1
    else:
        replaced = slots[equipped_slot]
        slots[equipped_slot] = weapon_id
    inventory_changed.emit(slots)
    equipped_changed.emit(equipped_slot,current_id())
    return {"picked":true,"replaced":replaced,"weapon_id":weapon_id}

func slot_label(index:int) -> String:
    if index < 0 or index >= slots.size(): return "EMPTY"
    var w := WeaponData.get_weapon(slots[index])
    return "%d  %s  %s" % [index+1,w.name,w.rarity]
