extends Node2D

const PLAYER_SCENE=preload("res://scenes/player.tscn")
const ZOMBIE_SCENE=preload("res://scenes/zombie.tscn")
const WEAPON_SCENE=preload("res://scenes/weapon.tscn")
const PICKUP_SCENE=preload("res://scenes/weapon_pickup.tscn")
const DAMAGE_SCENE=preload("res://scenes/damage_indicator.tscn")
const BOSS_SCENE=preload("res://scenes/boss.tscn")

var player:Survivor
var weapon:Weapon
var inventory:=WeaponInventory.new()
var combat:=CombatSystem.new()
var missions:=MissionManager.new()
var cinema:=CinematicDirector.new()
var save:=SaveManager.new()
var zombies:Array=[]
var drops:Array=[]
var mission_id:=1
var score:=0
var kills:=0
var wave:=1
var locked:=false

func _ready():
    add_child(inventory); add_child(combat); add_child(missions); add_child(cinema); add_child(save)
    save.load_game()
    mission_id=int(get_tree().get_meta("selected_mission",1))
    player=PLAYER_SCENE.instantiate(); add_child(player); player.position=Vector2(640,500); player.died.connect(_on_player_died)
    weapon=WEAPON_SCENE.instantiate(); player.get_node("VisualRoot/WeaponRoot").add_child(weapon)
    inventory.equipped_changed.connect(_on_equipped_changed)
    combat.hit_confirmed.connect(_on_hit_confirmed)
    missions.mission_completed.connect(_on_mission_complete)
    cinema.gameplay_lock.connect(func(v): locked=v)
    missions.start(mission_id)
    weapon.equip(inventory.current_id())
    spawn_wave()
    cinema.play_intro(mission_id)

func _process(delta):
    for d in drops:
        if is_instance_valid(d): d.life-=delta
    drops=drops.filter(func(d): return is_instance_valid(d))
    zombies=zombies.filter(func(z): return is_instance_valid(z))
    if not locked and zombies.is_empty():
        wave+=1
        if wave in [3,6]: missions.complete_objective()
        if wave>=8: _spawn_boss()
        else: spawn_wave()

func _unhandled_input(event):
    if locked: return
    if event is InputEventKey and event.pressed:
        if event.keycode==KEY_1: inventory.equip_slot(0)
        elif event.keycode==KEY_2: inventory.equip_slot(1)
        elif event.keycode==KEY_Q: inventory.cycle()
        elif event.keycode==KEY_R: weapon.start_reload()
        elif event.keycode==KEY_ESCAPE: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
    if event is InputEventMouseButton and event.pressed: _fire(event.position)
    if event is InputEventScreenTouch and event.pressed: _fire(event.position)

func spawn_wave():
    var count:=6+wave*2
    for i in range(count):
        var z:ZombieActor=ZOMBIE_SCENE.instantiate(); add_child(z)
        z.position=Vector2(randf_range(60,1220),randf_range(180,330))
        var kind:=randi_range(0,mini(4+int(wave/3),6)); z.setup(kind,wave,player)
        z.killed.connect(_on_zombie_killed); zombies.append(z)

func _fire(target:Vector2):
    if not weapon.fire_at(target): return
    var direction:=weapon.global_position.direction_to(target)
    for i in range(int(weapon.stats.pellets)):
        var dir:=direction.rotated(deg_to_rad(randf_range(-float(weapon.stats.spread),float(weapon.stats.spread))))
        combat.fire_hitscan(weapon.global_position,dir,int(weapon.stats.damage),zombies)

func _on_zombie_killed(z:ZombieActor):
    kills+=1; score+=z.reward
    var drop_data:=combat.roll_weapon_drop(z.global_position,wave)
    if not drop_data.is_empty(): _spawn_weapon_drop(drop_data)

func _spawn_weapon_drop(data:Dictionary):
    var p:WeaponPickup=PICKUP_SCENE.instantiate(); add_child(p); p.position=data.position; p.weapon_id=data.weapon_id
    p.collected.connect(_on_pickup_collected); drops.append(p)

func _on_pickup_collected(p:WeaponPickup,id:String):
    inventory.pickup(id); p.queue_free()

func _on_equipped_changed(_slot:int,id:String):
    weapon.equip(id)

func _on_hit_confirmed(pos:Vector2,damage:int,headshot:bool):
    var indicator:DamageIndicator=DAMAGE_SCENE.instantiate(); add_child(indicator); indicator.position=pos; indicator.setup(damage,headshot)

func _spawn_boss():
    wave=-999
    var m:=CampaignData.get_mission(mission_id); var name:=str(m.boss)
    if name=="None": missions.complete_objective(); return
    cinema.play_boss_reveal(name)
    var boss:BossZombie=BOSS_SCENE.instantiate(); add_child(boss); boss.position=Vector2(640,210); boss.setup(name,player)
    boss.boss_defeated.connect(func(): score+=2000; missions.complete_objective())

func _on_mission_complete(_data:Dictionary):
    save.complete_mission(mission_id,score)
    await get_tree().create_timer(2.0).timeout
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_player_died():
    await get_tree().create_timer(1.2).timeout
    get_tree().reload_current_scene()
