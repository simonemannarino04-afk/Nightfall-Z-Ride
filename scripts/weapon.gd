class_name Weapon
extends Node2D

signal shot(origin:Vector2, direction:Vector2, damage:int)
signal ammo_changed(current:int, reserve:int)
signal reload_started(duration:float)

@export var weapon_id := "m4"
var stats:Dictionary
var ammo := 0
var reserve := 0
var cooldown := 0.0
var reloading := false
var reload_left := 0.0
var recoil := 0.0

func _ready():
    equip(weapon_id)

func equip(id:String):
    weapon_id = id
    stats = WeaponData.get_weapon(id)
    ammo = stats.mag
    reserve = stats.reserve
    cooldown = 0.0
    reloading = false
    ammo_changed.emit(ammo,reserve)

func _process(delta):
    cooldown = maxf(0.0,cooldown-delta)
    recoil = maxf(0.0,recoil-delta*8.0)
    if reloading:
        reload_left -= delta
        if reload_left <= 0.0: finish_reload()

func fire_at(target:Vector2) -> bool:
    if reloading or cooldown > 0.0: return false
    if ammo <= 0:
        start_reload()
        return false
    ammo -= 1
    cooldown = 60.0 / float(stats.rpm)
    recoil = minf(1.0,recoil+0.35)
    var base := global_position.direction_to(target)
    for i in range(int(stats.pellets)):
        var angle := deg_to_rad(randf_range(-float(stats.spread),float(stats.spread)))
        shot.emit(global_position,base.rotated(angle),int(stats.damage))
    ammo_changed.emit(ammo,reserve)
    return true

func start_reload():
    if reloading or ammo >= int(stats.mag) or reserve <= 0: return
    reloading = true
    reload_left = float(stats.reload)
    reload_started.emit(reload_left)

func finish_reload():
    var need := int(stats.mag)-ammo
    var take := mini(need,reserve)
    ammo += take
    reserve -= take
    reloading = false
    ammo_changed.emit(ammo,reserve)

func add_reserve(amount:int):
    reserve += amount
    ammo_changed.emit(ammo,reserve)

func display_name() -> String:
    return str(stats.name)

func rarity() -> String:
    return str(stats.rarity)
