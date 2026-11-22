extends Node3D
# TITANIC 1912 — room-based, historically informed *schematic* exploration.
# Ship length is full-scale; partitions are designed for navigation, not traced survey plans.
const SHIP_LENGTH := 269.0
const DECK_WIDTH := 24.0
const DECK_HEIGHT := 3.25
const DECKS := ["Boat Deck", "A Deck", "B Deck", "C Deck", "D Deck", "E Deck", "F Deck", "G Deck", "Orlop Deck", "Tank Top"]
const DECK_INFO := {
 "Boat Deck": ["Bridge", "Wheelhouse", "Chart Room", "Captain's Quarters", "Officers' Quarters", "Gymnasium", "First-Class Entrance", "Lifeboat Promenade", "Second-Class Entrance", "Aft Promenade"],
 "A Deck": ["Grand Staircase", "First-Class Lounge", "Reading & Writing Room", "First-Class Smoking Room", "Verandah Café", "Palm Court", "First-Class Promenade", "Aft Staircase", "Private Promenade", "Second-Class Promenade"],
 "B Deck": ["Grand Staircase", "Parlour Suite B51", "First-Class Cabins", "À La Carte Restaurant", "Café Parisien", "Second-Class Smoking Room", "Reception Lobby", "Aft Staircase", "Private Promenade Suites", "Service Pantry"],
 "C Deck": ["Grand Staircase", "First-Class Cabins", "Purser's Office", "First-Class Library Area", "Second-Class Cabins", "Third-Class Cabins", "Forward Staircase", "Aft Staircase", "Steward's Pantry", "Accommodation Corridor"],
 "D Deck": ["First-Class Reception", "First-Class Dining Saloon", "Second-Class Dining Saloon", "First-Class Staircase", "Third-Class Open Space", "Third-Class Accommodation", "Dining Pantry", "Galley Complex", "Second-Class Staircase", "Service Corridor"],
 "E Deck": ["Scotland Road", "First-Class Cabins", "Second-Class Cabins", "Third-Class Cabins", "Crew Quarters", "Stewards' Quarters", "Linen Stores", "Forward Staircase", "Aft Staircase", "Service Rooms"],
 "F Deck": ["Swimming Bath", "Turkish Baths", "Cooling Room", "Third-Class Dining Saloon", "Third-Class Cabins", "Second-Class Cabins", "Crew Quarters", "Squash Court", "Service Pantry", "F Deck Corridor"],
 "G Deck": ["Third-Class Cabins", "Crew Accommodation", "Lower Accommodation", "Baggage Room", "Post Office", "Cargo Storage", "Forward Stores", "Provision Rooms", "Service Corridor", "Watertight Bulkhead"],
 "Orlop Deck": ["Forward Cargo Hold", "Lower Baggage Hold", "Mail Sorting Space", "Refrigerated Stores", "No. 1 Boiler Room", "No. 2 Boiler Room", "No. 3 Boiler Room", "No. 4 Boiler Room", "Engine Access", "Aft Cargo Hold"],
 "Tank Top": ["Forepeak Tank", "Forward Hold Bottom", "No. 5 Boiler Room", "No. 6 Boiler Room", "Coal Bunkers", "Reciprocating Engines", "Turbine Engine", "Shaft Tunnel", "Double Bottom", "Afterpeak Tank"]
}
const PALETTE := {
 "timber":Color(.39,.205,.105), "mahogany":Color(.27,.12,.075), "oak":Color(.61,.385,.205),
 "cream":Color(.84,.78,.64), "ivory":Color(.96,.91,.78), "white":Color(.91,.91,.84),
 "brass":Color(.77,.59,.29), "dark":Color(.12,.14,.17), "steel":Color(.34,.41,.44),
 "carpet":Color(.35,.12,.105), "green":Color(.20,.37,.29), "navy":Color(.16,.29,.40),
 "blue":Color(.20,.48,.62), "tile":Color(.77,.82,.80), "linen":Color(.91,.87,.76),
 "stone":Color(.52,.51,.47), "black":Color(.065,.083,.095), "glass":Color(.24,.48,.55),
 "wine":Color(.41,.09,.16), "gold":Color(.83,.69,.39), "water":Color(.16,.42,.54), "porcelain":Color(.90,.89,.84)
}
var active_deck := "A Deck"
var room_positions: Dictionary = {}
var room_footprints: Dictionary = {}
var current_geometry: Node3D
var materials: Dictionary = {}
var detail_level := 2
var doorways: Array[Dictionary] = []
var signs := true
var stair_portals: Array[Vector3] = []
const STAIR_Z := [-109.0, -1.0, 109.0]

# Reusable authored low-poly architectural modules exported as glTF 2.
# Materials and geometry are batched by surface so each room has relatively few draw calls.
const INTERIOR_SCENES := {
 "staircase": "res://assets/interiors/staircase.gltf",
 "lounge": "res://assets/interiors/lounge.gltf",
 "dining": "res://assets/interiors/dining.gltf",
 "library": "res://assets/interiors/library.gltf",
 "cafe": "res://assets/interiors/cafe.gltf",
 "cabin": "res://assets/interiors/cabin.gltf",
 "suite": "res://assets/interiors/suite.gltf",
 "reception": "res://assets/interiors/reception.gltf",
 "bridge": "res://assets/interiors/bridge.gltf",
 "pool": "res://assets/interiors/pool.gltf",
 "bath": "res://assets/interiors/bath.gltf",
 "machine": "res://assets/interiors/machine.gltf",
 "service": "res://assets/interiors/service.gltf",
 "cargo": "res://assets/interiors/cargo.gltf",
 "promenade": "res://assets/interiors/promenade.gltf",
 "office": "res://assets/interiors/office.gltf",
 "gym": "res://assets/interiors/gym.gltf"
}
var interior_cache: Dictionary = {}

# All structural materials use image textures; the detailed glTF rooms carry
# textured PBR materials internally. Keep textures small for Intel Iris 6100.
const SURFACE_TEXTURES := {
 "timber":"deck", "mahogany":"mahogany", "oak":"oak", "cream":"wallpaper",
 "ivory":"plaster", "white":"paint", "brass":"brass", "gold":"brass",
 "dark":"steel", "steel":"steel", "black":"steel", "carpet":"carpet",
 "green":"upholstery", "wine":"upholstery", "navy":"carpet", "blue":"water",
 "tile":"tile", "linen":"upholstery", "stone":"marble", "glass":"glass",
 "water":"water", "porcelain":"tile"
}
var ceiling_bulb_material: StandardMaterial3D

func _room_style(title: String) -> String:
 var t := title.to_lower()
 if t.contains("grand stair") or t.contains("aft stair") or t.contains("staircase") or t.contains("first-class entrance"): return "staircase"
 if t.contains("engine") or t.contains("boiler") or t.contains("turbine") or t.contains("shaft") or t.contains("coal"): return "machine"
 if t.contains("swimming"): return "pool"
 if t.contains("turkish") or t.contains("cooling room"): return "bath"
 if t.contains("restaurant") or t.contains("dining") or t.contains("saloon"): return "dining"
 if t.contains("café") or t.contains("cafe") or t.contains("palm court") or t.contains("verandah"): return "cafe"
 if t.contains("library") or t.contains("reading") or t.contains("writing"): return "library"
 if t.contains("lounge") or t.contains("smoking"): return "lounge"
 if t.contains("reception") or t.contains("lobby"): return "reception"
 if t.contains("parlour") or t.contains("private") or t.contains("suite"): return "suite"
 if t.contains("bridge") or t.contains("wheelhouse") or t.contains("chart room"): return "bridge"
 if t.contains("gymnasium") or t.contains("squash"): return "gym"
 if t.contains("office") or t.contains("purser") or t.contains("post"): return "office"
 if t.contains("cabin") or t.contains("quarters") or t.contains("accommodation"): return "cabin"
 if t.contains("promenade") or t.contains("open space") or t.contains("scotland road") or t.contains("corridor"): return "promenade"
 if t.contains("cargo") or t.contains("baggage") or t.contains("hold") or t.contains("stores") or t.contains("double bottom") or t.contains("tank") or t.contains("bulkhead"): return "cargo"
 if t.contains("service") or t.contains("galley") or t.contains("linen") or t.contains("pantry") or t.contains("provision"): return "service"
 return "reception"

func _place_light(parent: Node3D, pos: Vector3, colour: Color, energy: float, radius: float, label: String) -> void:
 var lamp := OmniLight3D.new()
 lamp.name = label
 lamp.position = pos
 lamp.light_color = colour
 lamp.light_energy = energy
 lamp.omni_range = radius
 lamp.omni_attenuation = 1.75
 lamp.light_specular = 0.35
 # No shadow maps on low-end Iris hardware; baked-looking local illumination.
 lamp.shadow_enabled = false
 parent.add_child(lamp)

func _add_interior(parent: Node3D, title: String, center_x: float, center_z: float) -> void:
 var style := _room_style(title)
 if not interior_cache.has(style):
  interior_cache[style] = load(INTERIOR_SCENES[style])
 var packed: PackedScene = interior_cache[style]
 if packed == null:
  push_warning("Missing interior scene " + style)
  return
 var room: Node3D = packed.instantiate()
 room.name = "Detailed_%s" % style
 room.position = Vector3(center_x, 0.0, center_z)
 parent.add_child(room)
 _furniture_obstacles(parent,style,center_x,center_z)
 # Local light pools read as electric ceiling fixtures without expensive GI.
 var utility := style in ["machine","cargo","service","bridge"]
 var water_space := style in ["pool","bath"]
 var hue := Color(.74,.86,1.0) if utility else (Color(.91,.95,1.0) if water_space else Color(1.0,.81,.57))
 var brightness := 1.05 if utility else 1.42
 _place_light(parent,Vector3(center_x,2.63,center_z),hue,brightness,10.4,"Working_Ceiling_Lamp")
 if style in ["staircase","dining","lounge","reception","library","cafe","suite","bath","pool"]:
  _place_light(parent,Vector3(center_x,2.62,center_z-6.4),hue,brightness*.78,7.7,"Forward_Chandelier")
  _place_light(parent,Vector3(center_x,2.62,center_z+6.4),hue,brightness*.78,7.7,"Aft_Chandelier")

func _furniture_obstacles(parent: Node3D, style: String, x: float, z: float) -> void:
 var bases: Array[Vector3] = []
 if style == "lounge" or style == "library" or style == "reception":
  for zz in [-6.6,0.0,6.6]: bases.append(Vector3(x-1.5,0,z+zz))
 elif style == "dining":
  for zz in [-7.2,-2.35,2.5,7.35]:
   for xx in [-2.1,2.1]: bases.append(Vector3(x+xx,0,z+zz))
 elif style == "machine":
  for zz in [-7.3,0.0,7.3]:
   for xx in [-1.8,1.8]: bases.append(Vector3(x+xx,0,z+zz))
 elif style == "cabin" or style == "suite":
  for zz in [-6.7,0.0,6.7]:
   for off in [-1.2,1.35]: bases.append(Vector3(x+1.6,0,z+zz+off))
 elif style == "staircase":
  bases.append(Vector3(x,0,z-4.0))
 elif style == "pool": bases.append(Vector3(x,0,z))
 for pos in bases:
  var body := StaticBody3D.new()
  body.name = "Furniture_Collision"
  body.position = pos + Vector3(0,.52,0)
  parent.add_child(body)
  var shape := CollisionShape3D.new()
  var col := BoxShape3D.new()
  col.size = Vector3(1.05,1.00,1.50) if style != "pool" else Vector3(4.8,.45,14.2)
  if style == "staircase":col.size = Vector3(4.5,1.0,3.1)
  shape.shape = col
  body.add_child(shape)

func _corridor_finish(parent: Node3D, wealthy: bool) -> void:
 # A 269 m corridor is necessarily repetitive, but now has wall panelling and lit bays.
 for side in [-1,1]:
  for zz in range(-126,126,6):
   var z := float(zz)
   if fmod(absf(z+115.0),25.0)<1.0:continue
   _box(parent,"Wall dado rail",Vector3(side*1.96,1.04,z),Vector3(.06,.06,4.4),"brass" if wealthy else "oak")
   _box(parent,"Wall baseboard",Vector3(side*1.95,.20,z),Vector3(.07,.19,4.35),"mahogany" if wealthy else "steel")
   _box(parent,"Wall picture rail",Vector3(side*1.95,2.42,z),Vector3(.07,.055,4.2),"brass" if wealthy else "cream")
   for off in [-1.7,1.7]:
    _box(parent,"Wall panel stile",Vector3(side*1.92,1.62,z+off),Vector3(.045,1.15,.035),"oak")
  for zz in range(-120,121,12):
   _box(parent,"Wall lamp bracket",Vector3(side*1.77,1.97,float(zz)),Vector3(.24,.14,.15),"brass")
   _sphere(parent,"Frosted sconce",Vector3(side*1.64,2.12,float(zz)),.19,"ivory")
 for zz in range(-120,121,8):
  _box(parent,"Carpet runner border",Vector3(0,.064,float(zz)),Vector3(2.35,.008,7.82),"brass")
  _box(parent,"Carpet runner field",Vector3(0,.072,float(zz)),Vector3(2.17,.008,7.7),"carpet")
  _box(parent,"Carpet medallion",Vector3(0,.079,float(zz)),Vector3(.43,.005,.50),"gold")


func _ready() -> void:
 for key in PALETTE:
  var mat := StandardMaterial3D.new()
  mat.albedo_color = PALETTE[key]
  mat.roughness = .66
  mat.metallic = 0.0
  mat.cull_mode = BaseMaterial3D.CULL_DISABLED
  var tile_name: String = SURFACE_TEXTURES.get(key, "paint")
  var texture_path := "res://assets/textures/%s.png" % tile_name
  mat.albedo_texture = load(texture_path)
  mat.uv1_scale = Vector3(3.0, 4.0, 1.0)
  if key in ["timber", "oak", "mahogany"]:
   mat.uv1_scale = Vector3(6.0,12.0,1.0)
   mat.roughness = .56
  elif key in ["carpet", "navy", "wine", "green"]:
   mat.uv1_scale = Vector3(4.0,9.0,1.0)
   mat.roughness = .91
  elif key in ["brass", "gold", "steel"]:
   mat.metallic = .20
   mat.roughness = .43
  elif key in ["cream", "ivory", "white"]:
   mat.uv1_scale = Vector3(3.0, 10.0, 1.0)
  materials[key] = mat
 materials["glass"].transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 materials["glass"].albedo_color.a = .66
 ceiling_bulb_material = StandardMaterial3D.new()
 ceiling_bulb_material.albedo_color = Color(1.0,.89,.67)
 ceiling_bulb_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 ceiling_bulb_material.emission_enabled = true
 ceiling_bulb_material.emission = Color(1.0,.73,.42)
 ceiling_bulb_material.emission_energy_multiplier = 1.65

func _box(parent:Node3D, label:String, pos:Vector3, size:Vector3, material:String, collision:bool = false) -> Node3D:
 var n := Node3D.new()
 n.name = label
 n.position = pos
 parent.add_child(n)
 var vis := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 vis.mesh = mesh
 vis.material_override = materials[material]
 n.add_child(vis)
 if collision:
  var body := StaticBody3D.new()
  n.add_child(body)
  var shape := CollisionShape3D.new()
  var b := BoxShape3D.new()
  b.size = size
  shape.shape = b
  body.add_child(shape)
 return n

func _sphere(parent:Node3D, name:String, pos:Vector3, radius:float, material:String) -> void:
 var n := MeshInstance3D.new()
 n.name = name
 var mesh := SphereMesh.new()
 mesh.radius = radius
 mesh.height = radius * 2.0
 mesh.radial_segments = 8
 mesh.rings = 4
 n.mesh = mesh
 n.material_override = ceiling_bulb_material if name in ["Frosted glass globe", "Frosted sconce"] else materials[material]
 n.position = pos
 parent.add_child(n)

func _label(parent:Node3D, value:String, pos:Vector3, size:int = 44) -> void:
 if not signs:return
 var lbl := Label3D.new()
 lbl.text = value
 lbl.font_size = size
 lbl.pixel_size = .005
 lbl.position = pos
 lbl.modulate = Color(.94,.81,.54)
 lbl.outline_size = 6
 lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 parent.add_child(lbl)

func _partition_z(parent:Node3D, z:float, x1:float, x2:float, door_x:float = 999.0) -> void:
 var left := minf(x1,x2)
 var right := maxf(x1,x2)
 if door_x > 900:
  _box(parent,"Transverse wall",Vector3((left+right)*.5,1.48,z),Vector3(right-left,2.96,.16),"cream",true)
 else:
  var gap := 1.55
  if door_x-gap*.5 > left:
   _box(parent,"Wall left",Vector3((left+door_x-gap*.5)*.5,1.48,z),Vector3(door_x-gap*.5-left,2.96,.16),"cream",true)
  if door_x+gap*.5 < right:
   _box(parent,"Wall right",Vector3((door_x+gap*.5+right)*.5,1.48,z),Vector3(right-door_x-gap*.5,2.96,.16),"cream",true)
  _box(parent,"Door lintel",Vector3(door_x,2.61,z),Vector3(gap,.70,.18),"oak")

func _corridor_wall(parent:Node3D, x:float, z1:float, z2:float, entry_z:float, wall_mat:String) -> void:
 var gap := 2.0
 var near := entry_z-gap*.5
 var far := entry_z+gap*.5
 if near > z1+.1:
  _box(parent,"Panel wall",Vector3(x,1.5,(z1+near)*.5),Vector3(.15,3.0,near-z1),wall_mat,true)
 if far < z2-.1:
  _box(parent,"Panel wall",Vector3(x,1.5,(far+z2)*.5),Vector3(.15,3.0,z2-far),wall_mat,true)
 _box(parent,"Carved lintel",Vector3(x,2.69,entry_z),Vector3(.22,.61,gap+.12),"oak")
 _box(parent,"Doorstep",Vector3(x,.04,entry_z),Vector3(.48,.08,gap),"brass")

func build_deck(deck:String) -> void:
 active_deck = deck
 if is_instance_valid(current_geometry):
  remove_child(current_geometry)
  current_geometry.queue_free()
 current_geometry = Node3D.new()
 current_geometry.name = deck.replace(" ","_")
 add_child(current_geometry)
 room_positions.clear()
 room_footprints.clear()
 doorways.clear()
 stair_portals.clear()
 var level := DECKS.find(deck)
 var classy := level <= 3
 var corridor_mat := "oak" if classy else "cream"
 var floor_mat := "timber" if level <= 2 else "stone"
 # One deck is streamed at a time, avoiding the cost of rendering the full ship.
 _box(current_geometry,"Structural deck",Vector3(0,-.23,0),Vector3(DECK_WIDTH,.46,SHIP_LENGTH),"steel",true)
 _box(current_geometry,"Walkable corridor",Vector3(0,.012,0),Vector3(3.7,.025,SHIP_LENGTH-7),floor_mat)
 _box(current_geometry,"Corridor runner",Vector3(0,.033,0),Vector3(2.40,.018,SHIP_LENGTH-10),"carpet")
 _box(current_geometry,"Ceiling",Vector3(0,3.06,0),Vector3(3.75,.12,SHIP_LENGTH-8),"ivory")
 for side in [-1,1]:
  _box(current_geometry,"Outer hull bulkhead",Vector3(side*11.8,1.45,0),Vector3(.4,2.9,SHIP_LENGTH-5),"cream",true)
  for z in range(-125,126,9):
   _box(current_geometry,"Porthole glass",Vector3(side*11.56,1.72,z),Vector3(.035,.65,.7),"glass")
   _box(current_geometry,"Porthole lower trim",Vector3(side*11.52,1.28,z),Vector3(.055,.07,.87),"brass")
 _partition_z(current_geometry,-132,-11.65,11.65)
 _partition_z(current_geometry,132,-11.65,11.65)
 # Segments: symmetrical room bays with transverse walls, individual portals, and furniture.
 # Each major location has a physically open doorway in the main promenade.
 var names:Array = DECK_INFO[deck]
 var spans := [Vector2(-126,-104),Vector2(-101,-79),Vector2(-76,-54),Vector2(-51,-29),Vector2(-26,-4),Vector2(-1,21),Vector2(24,46),Vector2(49,71),Vector2(74,96),Vector2(99,121)]
 for index in names.size():
  var name:String = names[index]
  var span:Vector2 = spans[index]
  var side := -1 if index%2 == 0 else 1
  var x := side*7.0
  var cz := (span.x+span.y)*.5
  var entrance := cz
  var room_parent := Node3D.new()
  room_parent.name = name.replace(" ","_").replace("'","")
  current_geometry.add_child(room_parent)
  _corridor_wall(room_parent,side*2.1,span.x,span.y,entrance,corridor_mat)
  _partition_z(room_parent,span.x,minf(side*2.1,side*11.6),maxf(side*2.1,side*11.6))
  _partition_z(room_parent,span.y,minf(side*2.1,side*11.6),maxf(side*2.1,side*11.6))
  _box(room_parent,"Room floor",Vector3(x,.024,cz),Vector3(9.25,.025,span.y-span.x-.30),"oak" if classy else "stone")
  _box(room_parent,"Area carpet",Vector3(x,.05,cz),Vector3(7.65,.022,span.y-span.x-3.0),"carpet" if classy else "navy")
  room_positions[name] = Vector3(side*3.9,.12,cz)
  room_footprints[name] = Rect2(Vector2(minf(side*2.1,side*11.6),span.x),Vector2(9.5,span.y-span.x))
  _label(room_parent,name,Vector3(side*1.84,2.38,cz),18)
  _box(room_parent,"Entrance frame left",Vector3(side*2.05,1.0,cz-1.04),Vector3(.24,2.0,.13),"brass")
  _box(room_parent,"Entrance frame right",Vector3(side*2.05,1.0,cz+1.04),Vector3(.24,2.0,.13),"brass")
  if detail_level >= 2:
   _add_interior(room_parent,name,x,cz)
  else:
   _furnish(room_parent,name,x,cz,side,level)
   _signature_details(room_parent,name,x,cz,side,level)
   _place_light(room_parent,Vector3(x,2.60,cz),Color(1,.85,.65) if classy else Color(.85,.91,1),.95,9.5,"Basic_Room_Light")
  doorways.append({"deck":deck,"name":name,"at":Vector3(side*2.1,0,cz)})
 # Opposite wing: passenger compartment bays; these are accessible from the central corridor.
 for index in range(10):
  var span:Vector2 = spans[index]
  var side := 1 if index%2 == 0 else -1
  var center := (span.x+span.y)*.5
  var wing := Node3D.new()
  wing.name = "Secondary_Cabin_%02d"%index
  current_geometry.add_child(wing)
  _corridor_wall(wing,side*2.1,span.x,span.y,center,"oak" if classy else "cream")
  _partition_z(wing,span.x,minf(side*2.1,side*11.6),maxf(side*2.1,side*11.6))
  _partition_z(wing,span.y,minf(side*2.1,side*11.6),maxf(side*2.1,side*11.6))
  _box(wing,"Cabin floor",Vector3(side*7.0,.02,center),Vector3(9.2,.025,span.y-span.x-.25),"timber")
  # Fully furnished opposite-side rooms instead of repeated empty box beds.
  if detail_level >= 2:
   _add_interior(wing,"First-Class Cabins" if classy else "Third-Class Cabins",side*7.0,center)
  else:
   _place_light(wing,Vector3(side*7.0,2.61,center),Color(1,.85,.65) if classy else Color(.91,.94,1),.85,9.0,"Basic_Cabin_Light")
   for k in range(3):
    var pz := center+(k-1)*6.5
    _bed(wing,side*8.9,pz,side,level)
    _cabinet(wing,side*5.7,pz+1.1)
  _label(wing,"CABINS  %s"%str(index*3+1),Vector3(side*3.1,2.2,center),28)
 for z in range(-120,121,12):
  _light(current_geometry,0,2.83,float(z))
  _box(current_geometry,"Corridor molding",Vector3(-1.94,2.71,z),Vector3(.12,.12,8),"brass")
  _box(current_geometry,"Corridor molding",Vector3(1.94,2.71,z),Vector3(.12,.12,8),"brass")
 # Local ceiling illumination spaced 18m apart: stable on older OpenGL GPUs.
 for zz in range(-117,118,18):
  _place_light(current_geometry,Vector3(0,2.76,float(zz)),Color(1.0,.84,.67) if classy else Color(.90,.93,1.0),.98,9.6,"Corridor_Light_%d" % zz)
 _corridor_finish(current_geometry,classy)
 _create_stair_portals()
 _label(current_geometry,"RMS TITANIC  /  %s"%deck,Vector3(0,2.13,-128),38)
 _label(current_geometry,"BOW",Vector3(0,1.85,-130),34)
 _label(current_geometry,"STERN",Vector3(0,1.85,130),34)

func _furnish(p:Node3D, title:String, x:float,z:float, side:int,level:int) -> void:
 var text := title.to_lower()
 if text.contains("boiler") or text.contains("engine") or text.contains("turbine") or text.contains("shaft") or text.contains("coal"):
  _machinery(p,x,z)
 elif text.contains("stair") or text.contains("entrance"):
  _staircase(p,x,z,side)
 elif text.contains("dining") or text.contains("restaurant") or text.contains("café") or text.contains("palm court"):
  for a in [-6.5,0.0,6.5]:
   _table(p,x,z+a)
   _chair(p,x-1.75,z+a)
   _chair(p,x+1.75,z+a)
 elif text.contains("lounge") or text.contains("reading") or text.contains("smoking") or text.contains("library") or text.contains("reception"):
  for a in [-6.2,0.0,6.2]:
   _sofa(p,x,z+a)
   _table(p,x-2.1,z+a)
  if text.contains("reading"):_bookshelf(p,x+side*2.6,z-8.1)
 elif text.contains("bath") or text.contains("pool"):
  _pool(p,x,z)
 elif text.contains("gym") or text.contains("squash"):
  for a in [-5.0,0.0,5.0]:
   _box(p,"Gym exercise platform",Vector3(x,.25,z+a),Vector3(2.2,.4,1.3),"oak",true)
   _box(p,"Equipment rail",Vector3(x,1.22,z+a),Vector3(.13,1.7,1.7),"steel")
 elif text.contains("bridge") or text.contains("wheelhouse") or text.contains("chart"):
  _box(p,"Navigation console",Vector3(x,.9,z),Vector3(2.2,1.15,5.2),"oak",true)
  _box(p,"Brass binnacle",Vector3(x,1.55,z-2),Vector3(.7,.2,.7),"brass")
  _box(p,"Chart",Vector3(x,1.52,z+2),Vector3(1.5,.02,1.4),"linen")
 elif text.contains("office") or text.contains("purser") or text.contains("post"):
  _table(p,x,z)
  for a in [-6.0,6.0]:_cabinet(p,x,z+a)
 elif text.contains("galley") or text.contains("pantry") or text.contains("service") or text.contains("store") or text.contains("cargo") or text.contains("baggage") or text.contains("linen"):
  for a in [-7.0,-2.4,2.4,7.0]:
   _box(p,"Storage counter",Vector3(x,.7,z+a),Vector3(1.5,1.25,2.4),"steel" if level>3 else "oak",true)
   _box(p,"Storage lid",Vector3(x,1.4,z+a),Vector3(1.6,.08,2.5),"cream")
 elif text.contains("corridor") or text.contains("scotland") or text.contains("promenade") or text.contains("open space"):
  for a in [-7.0,0.0,7.0]:
   _box(p,"Promenade bench",Vector3(x,.42,z+a),Vector3(1.2,.55,2.3),"oak",true)
   _box(p,"Promenade seat back",Vector3(x+side*.6,1.0,z+a),Vector3(.13,1.3,2.3),"oak")
 elif text.contains("quarters") or text.contains("cabin") or text.contains("accommodation") or text.contains("suite"):
  _bed(p,x+side*1.5,z-5,side,level)
  _bed(p,x+side*1.5,z+5,side,level)
  _cabinet(p,x-side*1.9,z-6)
  _cabinet(p,x-side*1.9,z+6)
  if level<3:_sofa(p,x-side*.3,z)
 else:
  _table(p,x,z)
  for a in [-6,6]:_cabinet(p,x,z+a)

func _machinery(p:Node3D,x:float,z:float) -> void:
 for k in [-6.0,0.0,6.0]:
  _box(p,"Machine housing",Vector3(x,1.0,z+k),Vector3(2.4,1.9,3.0),"steel",true)
  _box(p,"Machinery top",Vector3(x,2.08,z+k),Vector3(2.45,.20,3.15),"dark")
  for dx in [-1.0,1.0]:
   _box(p,"Vertical steam pipe",Vector3(x+dx,2.30,z+k),Vector3(.18,1.30,.18),"brass")
  _box(p,"Engine axle",Vector3(x,.7,z+k),Vector3(3.2,.25,.26),"black")

func _room_ornaments(p:Node3D, x:float,z:float,depth:float, side:int,level:int) -> void:
 for dz in [-depth*.38,depth*.38]:
  for dx in [-3.25,3.25]:
   _box(p,"Decorative pilaster",Vector3(x+dx,1.3,z+dz),Vector3(.22,2.6,.22),"oak" if level<4 else "steel")
   _box(p,"Pilaster capital",Vector3(x+dx,2.65,z+dz),Vector3(.36,.15,.36),"brass")
 for dz in [-7.4,0.0,7.4]:
  _box(p,"Ceiling cross beam",Vector3(x,2.84,z+dz),Vector3(7.8,.12,.22),"oak" if level<4 else "white")
  _light(p,x,2.62,z+dz)
 if level<4:
  _box(p,"Dado rail",Vector3(x+side*4.36,.93,z),Vector3(.11,.10,depth-1.0),"oak")

func _light(p:Node3D,x:float,y:float,z:float) -> void:
 _box(p,"Brass lamp base",Vector3(x,y+.12,z),Vector3(.42,.12,.42),"brass")
 _sphere(p,"Frosted glass globe",Vector3(x,y-.14,z),.25,"ivory")

func _bed(p:Node3D,x:float,z:float,side:int,level:int) -> void:
 _box(p,"Bed frame",Vector3(x,.38,z),Vector3(1.65,.62,2.35),"oak",true)
 _box(p,"Mattress",Vector3(x,.74,z),Vector3(1.54,.15,2.18),"linen")
 _box(p,"Pillow",Vector3(x,.86,z-.73),Vector3(1.16,.13,.43),"white")
 _box(p,"Headboard",Vector3(x,1.02,z-1.17),Vector3(1.72,1.15,.12),"mahogany" if level<3 else "steel")

func _cabinet(p:Node3D,x:float,z:float) -> void:
 _box(p,"Wardrobe",Vector3(x,1.01,z),Vector3(1.2,2.02,1.25),"mahogany",true)
 _box(p,"Door handle",Vector3(x-.15,1.08,z+.66),Vector3(.07,.17,.07),"brass")

func _table(p:Node3D,x:float,z:float) -> void:
 _box(p,"Tabletop",Vector3(x,.82,z),Vector3(1.5,.14,2.0),"oak",true)
 for dx in [-.55,.55]:
  for dz in [-.78,.78]:_box(p,"Table leg",Vector3(x+dx,.4,z+dz),Vector3(.11,.73,.11),"timber")

func _chair(p:Node3D,x:float,z:float) -> void:
 _box(p,"Chair",Vector3(x,.5,z),Vector3(.66,.19,.74),"oak",true)
 _box(p,"Chair back",Vector3(x,1.01,z+.32),Vector3(.68,1.06,.11),"oak")

func _sofa(p:Node3D,x:float,z:float) -> void:
 _box(p,"Sofa cushion",Vector3(x,.52,z),Vector3(1.25,.45,2.05),"green",true)
 _box(p,"Sofa back",Vector3(x+.62,.99,z),Vector3(.24,1.20,2.08),"green")
 _box(p,"Carved sofa trim",Vector3(x,.28,z),Vector3(1.3,.18,2.18),"oak")

func _bookshelf(p:Node3D,x:float,z:float) -> void:
 _box(p,"Library case",Vector3(x,1.25,z),Vector3(.65,2.5,2.35),"mahogany",true)
 for y in [.63,1.25,1.88]:
  _box(p,"Bookcase shelf",Vector3(x+.36,y,z),Vector3(.10,.08,2.25),"brass")

func _pool(p:Node3D,x:float,z:float) -> void:
 _box(p,"Pool tile surround",Vector3(x,.075,z),Vector3(5.2,.15,13.5),"tile")
 _box(p,"Water surface",Vector3(x,.16,z),Vector3(4.25,.015,11.9),"blue")
 for dz in [-6.55,6.55]:_box(p,"Pool coping",Vector3(x,.23,z+dz),Vector3(5.35,.22,.4),"ivory")
 for dx in [-2.53,2.53]:_box(p,"Pool coping",Vector3(x+dx,.23,z),Vector3(.4,.22,13.5),"ivory")

func _staircase(p:Node3D,x:float,z:float,side:int) -> void:
 # Architectural display staircase. Deck transfers remain via navigator while
 # matching multilevel stair geometry is not yet architecturally validated.
 for i in range(10):
  var y := .11+float(i)*.20
  var zz := z-5.3+float(i)*.66
  _box(p,"Carved tread %02d"%i,Vector3(x,y,zz),Vector3(3.0,.2,.71),"oak",true)
 for dx in [-1.65,1.65]:
  for i in range(10):
   _box(p,"Baluster",Vector3(x+dx,.86+float(i)*.20,z-5.3+float(i)*.66),Vector3(.11,1.36,.11),"brass")
 _box(p,"Staircase feature wall",Vector3(x+side*2.5,1.6,z+2),Vector3(.3,2.8,5.2),"mahogany",true)
 _label(p,"STAIRCASE / DECK TRANSFER: M",Vector3(x,2.58,z+7.5),24)

func get_locations(deck:String) -> Array:
 return DECK_INFO.get(deck,[])

func teleport_position(title:String) -> Vector3:
 return room_positions.get(title,Vector3(0,.12,-115))

# RELEASE FINISHING ELEMENTS
# Deliberately stylized room landmarks (not replicas of unverified fittings).
func _signature_details(p:Node3D,title:String,x:float,z:float,side:int,level:int) -> void:
 var t := title.to_lower()
 if t.contains("grand staircase") or t.contains("first-class entrance"):
  # Balustrades, chandelier, landings and ornamental wall clock.
  for dz in [-8.0,8.0]:
   _box(p,"Decorated landing",Vector3(x,.15,z+dz),Vector3(5.9,.3,2.7),"oak",true)
   for dx in [-2.7,2.7]:
    _box(p,"Landing newel",Vector3(x+dx,.86,z+dz),Vector3(.28,1.6,.28),"mahogany")
    _sphere(p,"Gilded finial",Vector3(x+dx,1.71,z+dz),.21,"gold")
  _box(p,"Staircase clock case",Vector3(x+side*3.5,2.0,z+1.8),Vector3(.30,1.28,1.6),"mahogany")
  _sphere(p,"Staircase clock",Vector3(x+side*3.22,2.16,z+1.8),.46,"ivory")
  for dx in [-1.6,0.0,1.6]:
   _sphere(p,"Chandelier lamp",Vector3(x+dx,2.42,z+2),.22,"gold")
 elif t.contains("dining") or t.contains("restaurant"):
  for dz in [-9.0,9.0]:
   _box(p,"Salon sideboard",Vector3(x+side*3.65,.67,z+dz),Vector3(.85,1.15,2.4),"mahogany",true)
   _box(p,"Sideboard mantle",Vector3(x+side*3.65,1.3,z+dz),Vector3(1.02,.1,2.55),"brass")
  for dz in [-7.5,0.0,7.5]:
   _sphere(p,"Dining pendant globe",Vector3(x,2.44,z+dz),.30,"ivory")
 elif t.contains("lounge") or t.contains("smoking") or t.contains("reading"):
  _box(p,"Fireplace surround",Vector3(x+side*3.65,1.25,z),Vector3(.6,2.3,3.1),"mahogany",true)
  _box(p,"Hearth opening",Vector3(x+side*3.29,.65,z),Vector3(.05,1.1,1.70),"black")
  _box(p,"Mantel shelf",Vector3(x+side*3.28,2.08,z),Vector3(.96,.17,3.3),"oak")
  for dz in [-8,8]:_sphere(p,"Table lamp globe",Vector3(x,1.5,z+dz),.24,"ivory")
 elif t.contains("café") or t.contains("palm court") or t.contains("verandah"):
  for dz in [-8.2,8.2]:
   _box(p,"Planter",Vector3(x+side*3.4,.34,z+dz),Vector3(.8,.65,.8),"porcelain")
   _box(p,"Palm trunk",Vector3(x+side*3.4,1.55,z+dz),Vector3(.12,1.95,.12),"timber")
   for i in range(5):
    var theta := float(i)*TAU/5.0
    _box(p,"Palm canopy",Vector3(x+side*3.4+cos(theta)*.52,2.5,z+dz+sin(theta)*.52),Vector3(.65,.12,.24),"green")
 elif t.contains("turkish") or t.contains("cooling"):
  for dz in [-7,0,7]:
   for dx in [-3.3,3.3]:
    _box(p,"Bath tiled column",Vector3(x+dx,1.22,z+dz),Vector3(.32,2.5,.32),"porcelain")
    _box(p,"Tile crown",Vector3(x+dx,2.5,z+dz),Vector3(.52,.17,.52),"gold")
 elif t.contains("bridge") or t.contains("wheelhouse"):
  _box(p,"Bridge observation rail",Vector3(x-side*3.4,.83,z),Vector3(.15,1.4,10.0),"oak")
  for dz in [-4.0,4.0]:
   _box(p,"Forward window",Vector3(x-side*3.65,1.90,z+dz),Vector3(.08,1.22,3.0),"glass")
 elif t.contains("boiler") or t.contains("engine") or t.contains("turbine"):
  for dz in [-7.0,7.0]:
   _box(p,"Pipe manifold",Vector3(x+side*2.9,1.5,z+dz),Vector3(.32,2.8,.32),"brass")
   _box(p,"Overhead steam main",Vector3(x,2.7,z+dz),Vector3(6.6,.22,.22),"steel")
 elif t.contains("cabin") or t.contains("suite") or t.contains("quarters"):
  _box(p,"Vanity mirror",Vector3(x-side*3.8,1.65,z),Vector3(.10,1.5,1.1),"glass")
  _box(p,"Vanity frame",Vector3(x-side*3.75,2.49,z),Vector3(.22,.11,1.3),"brass")
 elif t.contains("scotland road"):
  _label(p,"SCOTLAND ROAD  ·  CREW PASSAGE",Vector3(x,2.35,z),27)

func _create_stair_portals() -> void:
 # Stairwell transition zones. The E/Q keys transfer between streamed decks.
 # They are NOT claimed to be continuous accurate architectural stair flights.
 for i in range(STAIR_Z.size()):
  var z:float = STAIR_Z[i]
  var node := Node3D.new()
  node.name = "Deck_Stairwell_%d"%i
  current_geometry.add_child(node)
  for dx in [-1.6,1.6]:
   _box(node,"Stairwell newel",Vector3(dx,.83,z),Vector3(.14,1.63,.14),"mahogany")
   _sphere(node,"Brass cap",Vector3(dx,1.69,z),.17,"gold")
  _box(node,"Stairwell threshold",Vector3(0,.065,z),Vector3(2.9,.06,1.2),"oak")
  _box(node,"Overhead deck plaque",Vector3(0,2.43,z),Vector3(2.5,.42,.10),"mahogany")
  _label(node,"DECK STAIRS [E UP / Q DOWN]",Vector3(0,2.10,z),23)
  stair_portals.append(Vector3(0,.12,z))

func nearest_stair_distance(pos:Vector3) -> float:
 var best := INF
 for portal in stair_portals:
  best = minf(best,Vector2(pos.x-portal.x,pos.z-portal.z).length())
 return best

func stair_portal_z(pos:Vector3) -> float:
 var best := STAIR_Z[0]
 var distance := INF
 for value in STAIR_Z:
  var d := absf(pos.z-value)
  if d < distance:
   distance = d
   best = value
 return best
