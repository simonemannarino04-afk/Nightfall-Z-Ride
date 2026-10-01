class_name BossZombie
extends CharacterBody2D

signal phase_changed(phase:int)
signal boss_attack(kind:String, position:Vector2)
signal boss_defeated

@export var boss_type := "Tank"
var target:Node2D
var hp := 300
var max_hp := 300
var phase := 1
var speed := 34.0
var attack_cooldown := 0.0
var special_cooldown := 4.0

func setup(type:String, chase_target:Node2D):
    boss_type=type; target=chase_target
    match boss_type:
        "Alpha Runner": max_hp=180; speed=105.0
        "Brute": max_hp=260; speed=46.0
        "Tank": max_hp=360; speed=35.0
        "Harbor Mutant": max_hp=430; speed=42.0
        "Juggernaut": max_hp=520; speed=31.0
        "Patient Zero": max_hp=700; speed=52.0
    hp=max_hp

func _physics_process(delta):
    if not is_instance_valid(target): return
    attack_cooldown=maxf(0.0,attack_cooldown-delta)
    special_cooldown=maxf(0.0,special_cooldown-delta)
    var distance:=global_position.distance_to(target.global_position)
    if distance>70.0:
        velocity=global_position.direction_to(target.global_position)*speed*(1.0+0.12*(phase-1))
        move_and_slide()
    else:
        velocity=Vector2.ZERO
        if attack_cooldown<=0.0:
            boss_attack.emit("melee",global_position); attack_cooldown=maxf(.55,1.3-phase*.18)
    if special_cooldown<=0.0:
        _special_attack(); special_cooldown=maxf(2.2,5.2-phase*.65)

func hit(amount:int):
    hp=maxi(0,hp-amount)
    var ratio:=float(hp)/float(max_hp)
    var new_phase:=1
    if ratio<=.66: new_phase=2
    if ratio<=.33: new_phase=3
    if new_phase!=phase:
        phase=new_phase; phase_changed.emit(phase)
    if hp<=0:
        boss_defeated.emit(); queue_free()

func _special_attack():
    match boss_type:
        "Alpha Runner": boss_attack.emit("dash",global_position)
        "Brute": boss_attack.emit("ground_slam",global_position)
        "Tank": boss_attack.emit("charge",global_position)
        "Harbor Mutant": boss_attack.emit("toxic_burst",global_position)
        "Juggernaut": boss_attack.emit("shockwave",global_position)
        "Patient Zero": boss_attack.emit(["dash","summon","toxic_burst","shockwave"].pick_random(),global_position)

func health_ratio()->float:
    return clampf(float(hp)/float(max_hp),0.0,1.0)
