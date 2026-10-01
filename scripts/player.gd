class_name Survivor
extends CharacterBody2D

signal fired(origin:Vector2, target:Vector2)
signal died

@export var move_speed := 245.0
@export var max_hp := 100
var hp := 100
var ammo := 30
var reserve := 120
var aim_target := Vector2.RIGHT

func _ready():
    hp = max_hp

func _physics_process(_delta):
    var dir := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
    velocity = dir * move_speed
    move_and_slide()
    global_position.x = clampf(global_position.x,55.0,1225.0)
    global_position.y = clampf(global_position.y,310.0,635.0)

func aim_at(target:Vector2):
    aim_target = target

func try_fire(target:Vector2) -> bool:
    if ammo <= 0:
        reload()
        return false
    ammo -= 1
    aim_at(target)
    fired.emit(global_position,target)
    return true

func reload():
    var need := 30-ammo
    var take := mini(need,reserve)
    ammo += take
    reserve -= take

func damage(amount:int):
    hp = maxi(0,hp-amount)
    if hp == 0: died.emit()

func heal(amount:int):
    hp = mini(max_hp,hp+amount)

func add_ammo(amount:int):
    reserve = mini(240,reserve+amount)
