class_name DamageIndicator
extends Node2D

var amount := 0
var headshot := false
var life := 0.65
var velocity := Vector2(0,-42)

func setup(value:int, is_headshot:bool):
    amount = value
    headshot = is_headshot
    queue_redraw()

func _process(delta):
    position += velocity*delta
    velocity.y += 22.0*delta
    life -= delta
    modulate.a = clampf(life/0.65,0.0,1.0)
    if life <= 0.0: queue_free()

func _draw():
    var text := "%d" % amount
    if headshot: text = "HEADSHOT  %d" % amount
    var color := Color("f2c14e") if headshot else Color.WHITE
    draw_string(ThemeDB.fallback_font,Vector2(-20,-10),text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
