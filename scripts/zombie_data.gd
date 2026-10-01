class_name ZombieData
extends RefCounted

static func archetype(kind:int, wave:int) -> Dictionary:
    var data := {
        "name":"Walker", "speed":42.0 + wave*1.5, "hp":2 + int(wave/3),
        "damage":16.0, "scale":1.0, "reward":100
    }
    match kind:
        1:
            data.merge({"name":"Drifter","speed":50.0+wave*1.5,"damage":17.0,"reward":110},true)
        2:
            data.merge({"name":"Infected","speed":57.0+wave*1.5,"damage":18.0,"reward":120},true)
        3:
            data.merge({"name":"Biter","speed":63.0+wave*1.5,"damage":20.0,"reward":130},true)
        4:
            data.merge({"name":"Stalker","speed":69.0+wave*1.5,"damage":21.0,"reward":145},true)
        5:
            data.merge({"name":"Runner","speed":94.0+wave,"hp":5+int(wave/3),"damage":25.0,"scale":0.88,"reward":250},true)
        6:
            data.merge({"name":"Tank","speed":28.0+wave,"hp":10+int(wave/2),"damage":38.0,"scale":1.32,"reward":500},true)
    return data
