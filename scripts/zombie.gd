class_name ZombieActor
extends CharacterBody2D

signal killed(zombie:ZombieActor)

var kind := 0
var hp := 2
var max_hp := 2
var move_speed := 42.0
var touch_damage := 16.0
var reward := 100
var target:Node2D

func setup(new_kind:int, wave:int, chase_target:Node2D):
    kind = new_kind
    target = chase_target
    var data := ZombieData.archetype(kind,wave)
    hp = data.hp
    max_hp = hp
    move_speed = data.speed
    touch_damage = data.damage
    reward = data.reward
    scale = Vector2.ONE * data.scale

func _physics_process(_delta):
    if not is_instance_valid(target): return
    velocity = global_position.direction_to(target.global_position) * move_speed
    move_and_slide()

func hit(damage:int=1):
    hp -= damage
    if hp <= 0:
        killed.emit(self)
        queue_free()

func health_ratio() -> float:
    return clampf(float(hp)/float(max_hp),0.0,1.0)
