extends Control
# Simple, scalable deck navigation diagram; NOT a reproduced historical floor plan.
var world:Node3D
var player:Node3D
var deck_name := "A Deck"
func _draw() -> void:
 if world == null or player == null:return
 var sx := size.x-54.0
 var sz := size.y-86.0
 var center := Vector2(size.x*.5,size.y*.52)
 var top := center.y-sz*.5
 draw_rect(Rect2(Vector2(center.x-20,top),Vector2(40,sz)),Color(.23,.31,.37),false,2.0)
 draw_line(Vector2(center.x,top),Vector2(center.x,top+sz),Color(.64,.51,.34),1.4)
 for key in world.room_positions:
  var pos:Vector3 = world.room_positions[key]
  var py := top+(pos.z+134.5)/269.0*sz
  var px := center.x+(-70 if pos.x < 0 else 70)
  draw_line(Vector2(center.x,py),Vector2(px,py),Color(.53,.46,.34,.45),1)
  draw_circle(Vector2(px,py),3.5,Color(.92,.73,.40))
  var font := ThemeDB.fallback_font
  var text_size := 10
  var tx := px-140 if pos.x<0 else px+10
  draw_string(font,Vector2(tx,py+3),str(key),HORIZONTAL_ALIGNMENT_LEFT,135,text_size,Color(.94,.88,.71))
 var pz := top+(player.position.z+134.5)/269.0*sz
 draw_circle(Vector2(center.x,pz),6.5,Color(.29,.87,.75))
 draw_arc(Vector2(center.x,pz),9,0,TAU,20,Color(.29,.87,.75),1.5)
 draw_string(ThemeDB.fallback_font,Vector2(24,24),deck_name.to_upper()+"   |   BOW AT TOP",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.95,.85,.65))
 draw_string(ThemeDB.fallback_font,Vector2(24,size.y-12),"SCHEMATIC PLAN — 269 m ship length; press G to close",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(.73,.73,.71))
