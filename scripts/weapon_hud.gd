class_name WeaponHUD
extends CanvasLayer

var weapon_name := "M4A1"
var rarity := "UNCOMMON"
var ammo := 30
var reserve := 120
var slot := 2
var reload_progress := 0.0

func set_weapon(id:String, current_ammo:int, reserve_ammo:int, equipped_slot:int):
    var data := WeaponData.get_weapon(id)
    weapon_name = str(data.name)
    rarity = str(data.rarity)
    ammo = current_ammo
    reserve = reserve_ammo
    slot = equipped_slot+1
    queue_redraw()

func set_ammo(current:int, reserve_ammo:int):
    ammo=current; reserve=reserve_ammo; queue_redraw()

func _draw():
    draw_rect(Rect2(900,610,350,90),Color(0.015,0.02,0.025,.9))
    draw_string(ThemeDB.fallback_font,Vector2(920,642),"SLOT %d   %s"%[slot,weapon_name],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(920,670),rarity,HORIZONTAL_ALIGNMENT_LEFT,-1,13,_rarity_color(rarity))
    draw_string(ThemeDB.fallback_font,Vector2(1100,675),"%02d / %03d"%[ammo,reserve],HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("f0eee8"))

func _rarity_color(value:String) -> Color:
    match value:
        "UNCOMMON": return Color("65b96e")
        "RARE": return Color("4f82d9")
        "EPIC": return Color("9b5bd1")
        "LEGENDARY": return Color("d99a3e")
    return Color("aab0b4")
