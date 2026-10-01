class_name CampaignData
extends RefCounted

static func missions() -> Array[Dictionary]:
    return [
        {"id":1,"title":"ZERO HOUR","location":"Back Bay","brief":"Emergency broadcasts go silent. Reach the first quarantine checkpoint.","objectives":["Reach Commonwealth Ave","Restore checkpoint power","Survive the breach"],"boss":"None","reward":"MP5"},
        {"id":2,"title":"THE GREEN LINE","location":"Kenmore","brief":"A rescue team disappeared below street level. Enter the abandoned transit tunnels.","objectives":["Enter Kenmore station","Find the rescue team","Escape the tunnel swarm"],"boss":"Alpha Runner","reward":"M4A1"},
        {"id":3,"title":"BLACKOUT","location":"Beacon Hill","brief":"The district grid has failed and infected are pouring through the dark streets.","objectives":["Reach the substation","Recover two fuses","Restart the grid","Defend the substation"],"boss":"Brute","reward":"AK-47"},
        {"id":4,"title":"LAST SHIFT","location":"Downtown","brief":"A police evacuation convoy is trapped behind a collapsed quarantine line.","objectives":["Reach the convoy","Clear three barricades","Escort survivors","Hold the extraction zone"],"boss":"Tank","reward":"M590"},
        {"id":5,"title":"RED WATER","location":"Boston Harbor","brief":"The military believes the outbreak source moved through the harbor laboratories.","objectives":["Enter the harbor","Collect research samples","Destroy infected nests","Reach the ferry"],"boss":"Harbor Mutant","reward":"SCAR-H"},
        {"id":6,"title":"NO WAY OUT","location":"North End","brief":"The evacuation route has collapsed. The horde is closing from every direction.","objectives":["Locate the emergency radio","Call extraction","Survive the siege","Reach the rooftop"],"boss":"Juggernaut","reward":"M249"},
        {"id":7,"title":"PATIENT ZERO","location":"Quarantine Research Complex","brief":"Evidence points to a sealed research site beneath the city.","objectives":["Enter the complex","Download outbreak data","Destroy the containment core","Escape before lockdown"],"boss":"Patient Zero","reward":"M82"}
    ]

static func get_mission(id:int) -> Dictionary:
    for mission in missions():
        if mission.id == id: return mission.duplicate(true)
    return missions()[0].duplicate(true)
