class_name WeaponData
extends RefCounted

static func all() -> Array[Dictionary]:
    return [
        {"id":"m9","name":"M9","damage":1,"mag":15,"reserve":90,"rpm":360.0,"spread":3.0,"pellets":1,"reload":1.35,"rarity":"COMMON"},
        {"id":"mp5","name":"MP5","damage":1,"mag":30,"reserve":150,"rpm":800.0,"spread":6.0,"pellets":1,"reload":1.8,"rarity":"COMMON"},
        {"id":"m4","name":"M4A1","damage":2,"mag":30,"reserve":120,"rpm":700.0,"spread":4.0,"pellets":1,"reload":2.0,"rarity":"UNCOMMON"},
        {"id":"ak","name":"AK-47","damage":3,"mag":30,"reserve":120,"rpm":600.0,"spread":7.0,"pellets":1,"reload":2.25,"rarity":"RARE"},
        {"id":"shotgun","name":"M590","damage":1,"mag":8,"reserve":48,"rpm":85.0,"spread":18.0,"pellets":8,"reload":2.6,"rarity":"RARE"},
        {"id":"scar","name":"SCAR-H","damage":4,"mag":20,"reserve":100,"rpm":520.0,"spread":4.5,"pellets":1,"reload":2.2,"rarity":"EPIC"},
        {"id":"m249","name":"M249","damage":2,"mag":100,"reserve":300,"rpm":750.0,"spread":8.0,"pellets":1,"reload":4.8,"rarity":"EPIC"},
        {"id":"barrett","name":"M82","damage":12,"mag":10,"reserve":30,"rpm":55.0,"spread":1.0,"pellets":1,"reload":3.4,"rarity":"LEGENDARY"}
    ]

static func get_weapon(id:String) -> Dictionary:
    for weapon in all():
        if weapon.id == id: return weapon.duplicate(true)
    return all()[0].duplicate(true)
