extends Node3D

const WorldScript = preload("res://scripts/world.gd")
const PlayerScript = preload("res://scripts/player.gd")

var world: Node3D
var player: CharacterBody3D
var menu: PanelContainer
var deck_option: OptionButton
var room_option: OptionButton
var hud_label: Label
var hint_label: Label
var plan_panel: PanelContainer
var plan_map: Control
var plan_visible := false
var history: Array[Dictionary] = []
var selected_deck := "A Deck"
var popup_visible := false
var nearby_stairs := false
var tour_index := -1
var tour_button: Button
var contextual_hint: Label
var scene_environment: Environment
var daylight: DirectionalLight3D
var lighting_mode := 0
var cinema_grain_material: ShaderMaterial
var cinema_grain_rect: ColorRect
var cinema_grain_level := 1
const CINEMA_GRAIN_STRENGTH := [0.0, 0.052, 0.085, 0.120]
const SAVE_FILE := "user://titanic_explorer_save.json"
const TOUR_STOPS := [
 ["Boat Deck","Bridge"], ["Boat Deck","Gymnasium"],
 ["A Deck","Grand Staircase"], ["A Deck","First-Class Lounge"],
 ["A Deck","Reading & Writing Room"], ["B Deck","À La Carte Restaurant"],
 ["B Deck","Café Parisien"], ["C Deck","Purser's Office"],
 ["D Deck","First-Class Reception"], ["D Deck","First-Class Dining Saloon"],
 ["E Deck","Scotland Road"], ["F Deck","Swimming Bath"],
 ["F Deck","Turkish Baths"], ["G Deck","Post Office"],
 ["Orlop Deck","No. 2 Boiler Room"], ["Tank Top","Reciprocating Engines"]
]

func _ready() -> void:
 var environment := WorldEnvironment.new()
 environment.name = "WorldEnvironment"
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color(.065,.10,.15)
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color(.85,.85,.80)
 env.ambient_light_energy = .67
 environment.environment = env
 scene_environment = env
 add_child(environment)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55,35,0)
 sun.light_energy = .43
 sun.shadow_enabled = false
 daylight = sun
 add_child(sun)
 world = Node3D.new()
 world.set_script(WorldScript)
 world.name = "GeneratedDeck"
 add_child(world)
 world.build_deck(selected_deck)
 player = CharacterBody3D.new()
 player.set_script(PlayerScript)
 add_child(player)
 # Start inside the detailed first-class lounge instead of an empty corridor.
 player.position = Vector3(3.65,.14,-87.0)
 player.rotation.y = -PI*.5
 player.yaw = player.rotation.y
 _create_ui()
 if OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available()):
  _create_mobile_ui()
 _create_cinematic_overlay()
 print("TITANIC TEXTURES: image maps and runtime interior lighting enabled. Press L to cycle lighting.")
 print("TITANIC PLAYER: ",player.call("animation_status"))
 _load_state(false)
 _update_hud()

func _create_mobile_ui() -> void:
 var mobile := Control.new()
 mobile.set_script(preload("res://scripts/mobile_controls.gd"))
 mobile.name = "MobileTouchControls"
 add_child(mobile)
 mobile.attach(self, player)
 hint_label.visible = false
 hud_label.add_theme_font_size_override("font_size", 13)

func _create_cinematic_overlay() -> void:
 # Kept entirely separate from interactive UI: no input interception.
 # A tiny tiling image provides moving film grain without a screen capture.
 var canvas := CanvasLayer.new()
 canvas.name = "Cinematic_Filter"
 canvas.layer = 90
 add_child(canvas)
 var overlay := ColorRect.new()
 overlay.name = "Film_Grain_And_Subtle_Vignette"
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 overlay.color = Color.WHITE
 canvas.add_child(overlay)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 cinema_grain_rect = overlay
 cinema_grain_material = ShaderMaterial.new()
 cinema_grain_material.shader = load("res://shaders/cinematic_grain.gdshader")
 cinema_grain_material.set_shader_parameter("grain_tile", load("res://assets/textures/film_grain_tile.png"))
 cinema_grain_material.set_shader_parameter("grain_strength", CINEMA_GRAIN_STRENGTH[cinema_grain_level])
 cinema_grain_material.set_shader_parameter("vignette_strength", 0.09)
 overlay.material = cinema_grain_material
 print("TITANIC CINEMA: low-cost film grain on, press N for off/subtle/medium/strong")

func _cycle_film_grain() -> void:
 cinema_grain_level = (cinema_grain_level + 1) % CINEMA_GRAIN_STRENGTH.size()
 if cinema_grain_rect != null:
  cinema_grain_rect.visible = cinema_grain_level != 0
 if cinema_grain_material != null:
  cinema_grain_material.set_shader_parameter("grain_strength", CINEMA_GRAIN_STRENGTH[cinema_grain_level])
  cinema_grain_material.set_shader_parameter("vignette_strength", 0.0 if cinema_grain_level == 0 else 0.09)
 var names := ["OFF", "Subtle", "Medium", "Strong"]
 print("TITANIC CINEMA GRAIN: ", names[cinema_grain_level])

func _cycle_lighting() -> void:
 lighting_mode = (lighting_mode + 1) % 3
 var energies := [.67,.34,.90]
 var sun_energies := [.43,.15,.70]
 scene_environment.ambient_light_energy = energies[lighting_mode]
 daylight.light_energy = sun_energies[lighting_mode]
 var preset := ["Warm electric afternoon", "Evening lamps", "Bright inspection mode"][lighting_mode]
 print("TITANIC LIGHTING: " + preset)

func _save_screenshot() -> void:
 # Save the ACTUAL Godot viewport image on the user's Mac for visual QA.
 var folder := "user://screenshots"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 var snapshot: Image = get_viewport().get_texture().get_image()
 var path := "%s/titanic_%d.png" % [folder, int(Time.get_unix_time_from_system())]
 var err := snapshot.save_png(path)
 if err == OK:
  print("TITANIC SCREENSHOT SAVED: ",ProjectSettings.globalize_path(path))
 else:
  push_warning("Screenshot save failed: "+str(err))

func _process(_delta: float) -> void:
 if player != null and is_instance_valid(hud_label):
  hud_label.text = "RMS TITANIC  •  %s  •  %.0f m from centre   •  FPS %d" % [selected_deck, player.position.z, Engine.get_frames_per_second()]
 nearby_stairs = world.nearest_stair_distance(player.position) < 2.8
 if is_instance_valid(contextual_hint):
  contextual_hint.visible = nearby_stairs and not popup_visible and not plan_visible
  if nearby_stairs:
   contextual_hint.text = "DECK STAIRWELL   E: UP  •  Q: DOWN  |  Current: %s" % selected_deck
 if plan_visible and is_instance_valid(plan_map):
  plan_map.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_E and nearby_stairs and not popup_visible and not plan_visible:
   _transfer_stairs(-1)
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_Q and nearby_stairs and not popup_visible and not plan_visible:
   _transfer_stairs(1)
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_F12:
   _save_screenshot()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_F6:
   _save_state()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_F9:
   _load_state(true)
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_T:
   _next_tour_stop()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_N:
   _cycle_film_grain()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_L:
   _cycle_lighting()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_H:
   _toggle_detail()
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_G:
   set_map_visible(not plan_visible)
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_M or event.keycode == KEY_TAB:
   set_menu_visible(not popup_visible)
   get_viewport().set_input_as_handled()
  elif event.keycode == KEY_R and history.size() > 0 and not popup_visible:
   var old: Dictionary = history.pop_back()
   _travel(str(old["deck"]), str(old["room"]), false)
   get_viewport().set_input_as_handled()

func _create_ui() -> void:
 var ui := CanvasLayer.new()
 ui.name = "Interface"
 add_child(ui)
 var root := Control.new()
 root.set_anchors_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.add_child(root)
 var hud := PanelContainer.new()
 hud.position = Vector2(18,18)
 hud.custom_minimum_size = Vector2(490,52)
 root.add_child(hud)
 hud_label = Label.new()
 hud_label.add_theme_font_size_override("font_size",18)
 hud_label.add_theme_color_override("font_color",Color(.91,.84,.65))
 hud.add_child(hud_label)
 hint_label = Label.new()
 hint_label.text = "WASD move • Shift run • V view • M teleport • G map • E/Q stairs • T tour • F6 save • F9 load • H detail • N cinema grain"
 hint_label.position = Vector2(18,77)
 hint_label.add_theme_font_size_override("font_size",14)
 hint_label.add_theme_color_override("font_color",Color(.98,.92,.76))
 root.add_child(hint_label)
 contextual_hint = Label.new()
 contextual_hint.position = Vector2(22,108)
 contextual_hint.add_theme_font_size_override("font_size",17)
 contextual_hint.add_theme_color_override("font_color",Color(.97,.83,.52))
 contextual_hint.visible = false
 root.add_child(contextual_hint)
 menu = PanelContainer.new()
 menu.set_anchors_preset(Control.PRESET_CENTER)
 menu.offset_left = -235
 menu.offset_top = -260
 menu.offset_right = 235
 menu.offset_bottom = 260
 menu.custom_minimum_size = Vector2(470,520)
 menu.visible = false
 root.add_child(menu)
 var margin := MarginContainer.new()
 margin.add_theme_constant_override("margin_left",28)
 margin.add_theme_constant_override("margin_right",28)
 margin.add_theme_constant_override("margin_top",24)
 margin.add_theme_constant_override("margin_bottom",24)
 menu.add_child(margin)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",14)
 margin.add_child(stack)
 var heading := Label.new()
 heading.text = "R M S   T I T A N I C   ·   1 9 1 2"
 heading.add_theme_font_size_override("font_size",23)
 stack.add_child(heading)
 var subtitle := Label.new()
 subtitle.text = "DECK NAVIGATOR   /   STYLIZED HISTORICAL EXPLORER"
 subtitle.add_theme_font_size_override("font_size",12)
 stack.add_child(subtitle)
 var d_label := Label.new()
 d_label.text = "SELECT DECK"
 stack.add_child(d_label)
 deck_option = OptionButton.new()
 for d in world.DECKS: deck_option.add_item(d)
 deck_option.select(1)
 deck_option.item_selected.connect(_on_deck_changed)
 stack.add_child(deck_option)
 var r_label := Label.new()
 r_label.text = "SELECT LOCATION"
 stack.add_child(r_label)
 room_option = OptionButton.new()
 stack.add_child(room_option)
 _populate_rooms()
 var go := Button.new()
 go.text = "TELEPORT TO LOCATION"
 go.custom_minimum_size.y = 47
 go.pressed.connect(_on_travel)
 stack.add_child(go)
 tour_button = Button.new()
 tour_button.text = "START / CONTINUE GUIDED TOUR [T]"
 tour_button.pressed.connect(func(): _next_tour_stop())
 stack.add_child(tour_button)
 var back := Button.new()
 back.text = "RETURN TO PREVIOUS LOCATION"
 back.pressed.connect(_on_return)
 stack.add_child(back)
 var close := Button.new()
 close.text = "CLOSE  [M]"
 close.pressed.connect(func(): set_menu_visible(false))
 stack.add_child(close)
 var map_button := Button.new()
 map_button.text = "VIEW DECK MAP [G]"
 map_button.pressed.connect(func(): set_menu_visible(false); set_map_visible(true))
 stack.add_child(map_button)
 var quality := Button.new()
 quality.text = "DETAIL LEVEL: HIGH / FURNISHED [H]"
 quality.pressed.connect(_toggle_detail)
 quality.name = "DetailToggle"
 stack.add_child(quality)
 var footer := Label.new()
 footer.text = "Stylized reconstruction — room layouts are approximate.\nDeck stairwell transitions: E up / Q down near the marked posts."
 footer.add_theme_font_size_override("font_size",12)
 stack.add_child(footer)
 _create_deck_map(root)

func _populate_rooms() -> void:
 room_option.clear()
 var deck: String = world.DECKS[deck_option.selected]
 for location in world.get_locations(deck):
  room_option.add_item(str(location))
 room_option.select(0)

func _on_deck_changed(_idx: int) -> void:
 _populate_rooms()

func _on_travel() -> void:
 var deck: String = world.DECKS[deck_option.selected]
 var room: String = room_option.get_item_text(room_option.selected)
 _travel(deck,room,true)

func _on_return() -> void:
 if history.size() == 0: return
 var old: Dictionary = history.pop_back()
 _travel(str(old["deck"]),str(old["room"]),false)

func _travel(deck: String,room: String,save_history: bool) -> void:
 if save_history:
  history.append({"deck":selected_deck,"room":_nearest_room()})
 if selected_deck != deck:
  selected_deck = deck
  world.build_deck(deck)
 player.velocity = Vector3.ZERO
 player.global_position = world.teleport_position(room) + Vector3.UP*.12
 if is_instance_valid(plan_map):plan_map.deck_name = selected_deck
 player.rotation.y = PI if player.position.x < 0 else 0.0
 player.yaw = player.rotation.y
 _update_hud()
 set_menu_visible(false)

func _nearest_room() -> String:
 var best := str(world.get_locations(selected_deck)[0])
 var closest := INF
 for key in world.room_positions.keys():
  var d: float = player.position.distance_to(world.room_positions[key])
  if d < closest:
   closest = d
   best = str(key)
 return best

func _update_hud() -> void:
 if hud_label: hud_label.text = "RMS TITANIC  •  %s" % selected_deck

func set_menu_visible(enabled: bool) -> void:
 popup_visible = enabled
 menu.visible = enabled
 if enabled and plan_visible:
  plan_visible = false
  plan_panel.visible = false
 if not (OS.has_feature("web") and DisplayServer.is_touchscreen_available()):
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if enabled else Input.MOUSE_MODE_CAPTURED

func _create_deck_map(root:Control) -> void:
 plan_panel = PanelContainer.new()
 plan_panel.name = "DeckPlanOverlay"
 plan_panel.set_anchors_preset(Control.PRESET_CENTER)
 plan_panel.offset_left = -310
 plan_panel.offset_right = 310
 plan_panel.offset_top = -290
 plan_panel.offset_bottom = 290
 plan_panel.custom_minimum_size = Vector2(620,580)
 plan_panel.visible = false
 root.add_child(plan_panel)
 plan_map = Control.new()
 plan_map.set_script(preload("res://scripts/deck_map.gd"))
 plan_panel.add_child(plan_map)
 plan_map.world = world
 plan_map.player = player
 plan_map.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_map_visible(enabled:bool) -> void:
 plan_visible = enabled
 plan_panel.visible = enabled
 if enabled:
  if popup_visible:set_menu_visible(false)
  plan_map.deck_name = selected_deck
  plan_map.queue_redraw()
 if not (OS.has_feature("web") and DisplayServer.is_touchscreen_available()):
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if enabled else Input.MOUSE_MODE_CAPTURED

func _toggle_detail() -> void:
 world.detail_level = 2 if world.detail_level == 1 else 1
 world.build_deck(selected_deck)
 var details := menu.find_child("DetailToggle",true,false)
 if details != null:
  details.text = "DETAIL LEVEL: HIGH [H]" if world.detail_level == 2 else "DETAIL LEVEL: LOW / MAC SAFE [H]"

func _transfer_stairs(direction:int) -> void:
 var idx:int = world.DECKS.find(selected_deck)
 var next_idx:int = idx + direction
 if next_idx < 0 or next_idx >= world.DECKS.size():
  if contextual_hint != null:
   contextual_hint.text = "END OF THE AVAILABLE DECKS"
  return
 var exit_z:float = world.stair_portal_z(player.position)
 history.append({"deck":selected_deck,"room":_nearest_room()})
 selected_deck = world.DECKS[next_idx]
 world.build_deck(selected_deck)
 player.velocity = Vector3.ZERO
 player.global_position = Vector3(0,.12,exit_z+3.4)
 if is_instance_valid(plan_map):plan_map.deck_name = selected_deck
 _update_hud()

func _next_tour_stop() -> void:
 tour_index = (tour_index + 1) % TOUR_STOPS.size()
 var stop:Array = TOUR_STOPS[tour_index]
 _travel(str(stop[0]),str(stop[1]),true)
 if is_instance_valid(hint_label):
  hint_label.text = "GUIDED TOUR %02d/%02d: %s  •  Press T for next stop" % [tour_index+1,TOUR_STOPS.size(),str(stop[1])]

func _save_state() -> void:
 var data := {
  "deck":selected_deck,
  "position":[player.position.x,player.position.y,player.position.z],
  "yaw":player.yaw,
  "first_person":player.first_person,
  "detail":world.detail_level,
  "tour_index":tour_index
 }
 var file := FileAccess.open(SAVE_FILE,FileAccess.WRITE)
 if file == null:return
 file.store_string(JSON.stringify(data))
 file.close()
 if is_instance_valid(hint_label):hint_label.text = "LOCATION SAVED  •  F9 restores it"

func _load_state(notify:bool) -> void:
 if not FileAccess.file_exists(SAVE_FILE):return
 var file := FileAccess.open(SAVE_FILE,FileAccess.READ)
 if file == null:return
 var data = JSON.parse_string(file.get_as_text())
 file.close()
 if not data is Dictionary:return
 var deck:String = str(data.get("deck","A Deck"))
 if not world.DECKS.has(deck):return
 selected_deck = deck
 world.detail_level = clampi(int(data.get("detail",1)),1,2)
 world.build_deck(deck)
 var coords:Array = data.get("position",[0,.12,-102])
 if coords.size() >= 3:
  player.position = Vector3(clampf(float(coords[0]),-10.8,10.8),maxf(float(coords[1]),.12),clampf(float(coords[2]),-128,128))
 player.yaw = float(data.get("yaw",0))
 player.rotation.y = player.yaw
 tour_index = clampi(int(data.get("tour_index",-1)),-1,TOUR_STOPS.size()-1)
 player.first_person = bool(data.get("first_person",false))
 player._refresh_camera()
 if is_instance_valid(plan_map):plan_map.deck_name = selected_deck
 if notify and is_instance_valid(hint_label):hint_label.text = "SAVED LOCATION RESTORED"
 _update_hud()
