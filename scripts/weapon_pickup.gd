class_name WeaponPickup
extends Area2D

signal collected(pickup:WeaponPickup, weapon_id:String)

@export var weapon_id := "m4"
var life := 18.0
var phase := 0.0

func _ready():
    phase = randf()*TAU
    body_entered.connect(_on_body_entered)
    queue_redraw()

func _process(delta):
    life -= delta
    position.y += sin(Time.get_ticks_msec()/1000.0*3.0+phase)*4.0*delta
    if life <= 0.0: queue_free()
    queue_redraw()

func _on_body_entered(body:Node):
    if body is Survivor:
        collected.emit(self,weapon_id)

func _draw():
    var data := WeaponData.get_weapon(weapon_id)
    draw_circle(Vector2.ZERO,25,Color(0.03,0.04,0.05,.92))
    draw_circle(Vector2.ZERO,21,_rarity_color(str(data.rarity)))
    draw_rect(Rect2(-14,-3,28,6),Color("20262b"))
    draw_rect(Rect2(4,3,6,9),Color("20262b"))
    draw_string(ThemeDB.fallback_font,Vector2(-34,-31),str(data.name),HORIZONTAL_ALIGNMENT_CENTER,68,13,Color.WHITE)

func _rarity_color(rarity:String) -> Color:
    match rarity:
        "UNCOMMON": return Color("65b96e")
        "RARE": return Color("4f82d9")
        "EPIC": return Color("9b5bd1")
        "LEGENDARY": return Color("d99a3e")
    return Color("8d969d")
