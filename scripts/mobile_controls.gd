extends Control
## Original touch navigation. Left stick = movement; right swipe = camera.
## The buttons call the game's existing functions; no external addons.
var game: Node3D
var explorer: CharacterBody3D
var move_id := -1
var look_id := -1
var move_origin := Vector2.ZERO
var move_current := Vector2.ZERO
var last_look := Vector2.ZERO
var buttons: Array[Button] = []
const STICK_RADIUS := 57.0

func attach(main_node: Node3D, player_node: CharacterBody3D) -> void:
 game = main_node
 explorer = player_node
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var configs := [
  ["MAP", func(): game.set_map_visible(not game.plan_visible)],
  ["TELEPORT", func(): game.set_menu_visible(not game.popup_visible)],
  ["VIEW", func(): explorer.toggle_camera_view()],
  ["TOUR", func(): game._next_tour_stop()],
  ["UP", func(): game._transfer_stairs(-1) if game.nearby_stairs else null],
  ["DOWN", func(): game._transfer_stairs(1) if game.nearby_stairs else null]
 ]
 for item in configs:
  var b := Button.new()
  b.text = item[0]
  b.add_theme_font_size_override("font_size", 17)
  b.custom_minimum_size = Vector2(112, 55)
  b.pressed.connect(item[1])
  add_child(b)
  buttons.append(b)
 queue_redraw()

func _process(_delta: float) -> void:
 var sz := get_viewport_rect().size
 size = sz
 for i in buttons.size():
  var b := buttons[i]
  b.position = Vector2(sz.x - 122 - (i % 2) * 118, 14 + int(i / 2) * 64)
  b.size = Vector2(110, 55)
 if explorer != null:
  explorer.touch_move = (move_current - move_origin).limit_length(STICK_RADIUS) / STICK_RADIUS if move_id != -1 else Vector2.ZERO
 queue_redraw()

func _input(event: InputEvent) -> void:
 if explorer == null or game.popup_visible or game.plan_visible:
  if move_id != -1:
   move_id = -1
   explorer.touch_move = Vector2.ZERO
  look_id = -1
  return
 var sz := get_viewport_rect().size
 if event is InputEventScreenTouch:
  var t := event as InputEventScreenTouch
  if t.pressed:
   if t.position.y > sz.y * .35 and t.position.x < sz.x * .46 and move_id == -1:
    move_id = t.index
    move_origin = t.position
    move_current = t.position
   elif t.position.y > 205 and t.position.x >= sz.x * .46 and look_id == -1:
    look_id = t.index
    last_look = t.position
  else:
   if t.index == move_id:
    move_id = -1
    explorer.touch_move = Vector2.ZERO
   if t.index == look_id:
    look_id = -1
 elif event is InputEventScreenDrag:
  var t := event as InputEventScreenDrag
  if t.index == move_id:
   move_current = t.position
  elif t.index == look_id:
   explorer.apply_touch_look(t.position - last_look)
   last_look = t.position

func _draw() -> void:
 var sz := get_viewport_rect().size
 var center := move_origin if move_id != -1 else Vector2(104, sz.y - 105)
 draw_circle(center, STICK_RADIUS + 12, Color(0.08,0.12,0.17,0.42))
 draw_arc(center, STICK_RADIUS, 0, TAU, 48, Color(0.95,0.82,0.60,0.65), 3)
 var thumb := center + (move_current - move_origin).limit_length(STICK_RADIUS) if move_id != -1 else center
 draw_circle(thumb, 23, Color(0.93,0.82,0.60,0.7))
