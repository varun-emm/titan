extends Node3D
## Original, procedural character designed specifically for Titanic 1912.
## All mesh parts, materials, and locomotion are authored in this project.
## No downloaded character, rig, texture, or animation files are required.

var _torso: Node3D
var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_elbow: Node3D
var _right_elbow: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_knee: Node3D
var _right_knee: Node3D
var _left_foot: Node3D
var _right_foot: Node3D
var _phase := 0.0
var _motion_weight := 0.0
var _lean := 0.0
var _elapsed := 0.0
var _status := "Idle"

func _material(hex: String, roughness: float = 0.88, metallic: float = 0.0) -> StandardMaterial3D:
 var mat := StandardMaterial3D.new()
 mat.albedo_color = Color(hex)
 mat.roughness = roughness
 mat.metallic = metallic
 return mat

func _sphere(radius: float, vertical_scale: float = 1.0) -> SphereMesh:
 var mesh := SphereMesh.new()
 mesh.radius = radius
 mesh.height = radius * 2.0 * vertical_scale
 mesh.radial_segments = 12
 mesh.rings = 8
 return mesh

func _cylinder(top: float, bottom: float, height: float, segments: int = 10) -> CylinderMesh:
 var mesh := CylinderMesh.new()
 mesh.top_radius = top
 mesh.bottom_radius = bottom
 mesh.height = height
 mesh.radial_segments = segments
 return mesh

func _box(dimensions: Vector3) -> BoxMesh:
 var mesh := BoxMesh.new()
 mesh.size = dimensions
 return mesh

func _add_mesh(parent: Node3D, label: String, shape: Mesh, material: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
 var part := MeshInstance3D.new()
 part.name = label
 part.mesh = shape
 part.material_override = material
 part.position = pos
 part.rotation_degrees = rot
 parent.add_child(part)
 return part

func _pivot(parent: Node3D, label: String, position: Vector3) -> Node3D:
 var point := Node3D.new()
 point.name = label
 point.position = position
 parent.add_child(point)
 return point

func _ready() -> void:
 name = "Original_Edwardian_Explorer"
 _build_explorer()
 set_motion(0.0, false, 0.016)

func _build_explorer() -> void:
 # A compact Edwardian walking suit; face points toward negative Z.
 var navy := _material("#223243")
 var navy_light := _material("#314355")
 var trouser := _material("#26313a")
 var vest := _material("#5d4f45")
 var shirt := _material("#e4ddd0")
 var skin := _material("#b78465")
 var skin_shadow := _material("#9a694f")
 var hair := _material("#2b2421")
 var hair_light := _material("#46352d")
 var shoes := _material("#35251e", 0.6)
 var sole := _material("#1b1817")
 var brass := _material("#c19c54", 0.32, 0.65)
 var burgundy := _material("#773e43")
 var white := _material("#f5eee4")
 var eyes := _material("#202326")

 # Legs rotate around real hip pivots rather than rotating around their centres.
 _left_leg = _pivot(self, "LeftHip", Vector3(-0.155, 0.91, 0.0))
 _right_leg = _pivot(self, "RightHip", Vector3(0.155, 0.91, 0.0))
 for side in ["L", "R"]:
  var hip: Node3D = _left_leg if side == "L" else _right_leg
  _add_mesh(hip, side + "_Thigh", _cylinder(0.124, 0.101, 0.43), trouser, Vector3(0, -0.225, 0))
  var crease_z := -0.099
  _add_mesh(hip, side + "_TrouserCrease", _box(Vector3(0.010, 0.33, 0.009)), navy_light, Vector3(0,-0.235,crease_z))
  var knee := _pivot(hip, side + "Knee", Vector3(0,-0.44,0))
  _add_mesh(knee, side + "_Calf", _cylinder(0.105, 0.085, 0.40), trouser, Vector3(0,-0.20,0))
  var foot := _pivot(knee, side + "Ankle", Vector3(0,-0.39,0.005))
  _add_mesh(foot, side + "_Shoe", _sphere(0.132, 0.42), shoes, Vector3(0,-0.015,-0.078))
  _add_mesh(foot, side + "_Sole", _box(Vector3(0.24,0.027,0.31)), sole, Vector3(0,-0.08,-0.08))
  _add_mesh(foot, side + "_ToeCap", _box(Vector3(0.17,0.006,0.035)), navy_light, Vector3(0,-0.045,-0.185))
  if side == "L":
   _left_knee = knee
   _left_foot = foot
  else:
   _right_knee = knee
   _right_foot = foot

 _torso = _pivot(self, "UpperBody", Vector3(0,1.055,0))
 # Tapered jacket silhouette, shirt and brown waistcoat.
 _add_mesh(_torso,"TailoredJacket",_cylinder(0.245,0.184,0.64,12),navy,Vector3(0,0.255,0))
 _add_mesh(_torso,"CoatLowerFront",_box(Vector3(0.43,0.20,0.16)),navy,Vector3(0,0.055,-0.03))
 _add_mesh(_torso,"ShirtFront",_box(Vector3(0.178,0.40,0.018)),shirt,Vector3(0,0.312,-0.218))
 _add_mesh(_torso,"VestFront",_box(Vector3(0.194,0.34,0.025)),vest,Vector3(0,0.22,-0.231))
 _add_mesh(_torso,"LeftLapel",_box(Vector3(0.084,0.36,0.025)),navy_light,Vector3(-0.139,0.405,-0.213),Vector3(0,0,-16))
 _add_mesh(_torso,"RightLapel",_box(Vector3(0.084,0.36,0.025)),navy_light,Vector3(0.139,0.405,-0.213),Vector3(0,0,16))
 _add_mesh(_torso,"CollarWhiteLeft",_box(Vector3(0.083,0.14,0.030)),white,Vector3(-0.056,0.544,-0.227),Vector3(0,0,-22))
 _add_mesh(_torso,"CollarWhiteRight",_box(Vector3(0.083,0.14,0.030)),white,Vector3(0.056,0.544,-0.227),Vector3(0,0,22))
 _add_mesh(_torso,"Necktie",_cylinder(0.035,0.017,0.24,6),burgundy,Vector3(0,0.413,-0.251))
 _add_mesh(_torso,"TieKnot",_sphere(0.041,0.65),burgundy,Vector3(0,0.522,-0.252))
 _add_mesh(_torso,"PocketSquare",_box(Vector3(0.066,0.020,0.009)),white,Vector3(-0.166,0.414,-0.225),Vector3(0,0,12))
 for i in 3:
  _add_mesh(_torso,"WaistcoatButton_%d"%i,_sphere(0.010),brass,Vector3(0,0.307-i*0.081,-0.253))
 _add_mesh(_torso,"Belt",_box(Vector3(0.35,0.047,0.28)),shoes,Vector3(0,0.007,0))
 _add_mesh(_torso,"BeltBuckle",_box(Vector3(0.053,0.038,0.013)),brass,Vector3(0,0.005,-0.150))

 for side in ["L","R"]:
  var sign: float = -1.0 if side == "L" else 1.0
  var arm := _pivot(_torso,side+"Shoulder",Vector3(sign*0.318,0.525,0))
  _add_mesh(arm,side+"ShoulderShape",_sphere(0.153,0.70),navy,Vector3(0,-0.050,0))
  _add_mesh(arm,side+"UpperSleeve",_cylinder(0.128,0.103,0.335),navy,Vector3(0,-0.225,0))
  var elbow := _pivot(arm,side+"Elbow",Vector3(0,-0.392,0))
  _add_mesh(elbow,side+"LowerSleeve",_cylinder(0.105,0.083,0.285),navy,Vector3(0,-0.14,0))
  _add_mesh(elbow,side+"Cuff",_cylinder(0.090,0.090,0.052),white,Vector3(0,-0.302,0))
  _add_mesh(elbow,side+"Hand",_sphere(0.091,1.1),skin,Vector3(0,-0.375,0))
  _add_mesh(elbow,side+"Thumb",_sphere(0.036,1.3),skin_shadow,Vector3(sign*0.078,-0.365,-0.042),Vector3(0,0,35*sign))
  if side == "L":
   _left_arm = arm
   _left_elbow = elbow
  else:
   _right_arm = arm
   _right_elbow = elbow

 _head = _pivot(_torso,"HeadAndNeck",Vector3(0,0.610,0))
 _add_mesh(_head,"Neck",_cylinder(0.083,0.091,0.14),skin,Vector3(0,0.0,0))
 _add_mesh(_head,"Face",_sphere(0.177,1.17),skin,Vector3(0,0.195,-0.015))
 _add_mesh(_head,"Jaw",_sphere(0.138,0.58),skin_shadow,Vector3(0,0.097,-0.052))
 _add_mesh(_head,"Nose",_sphere(0.041,1.40),skin,Vector3(0,0.187,-0.189))
 for side in [-1,1]:
  var x := float(side)*0.075
  _add_mesh(_head,"Eye_%d"%side,_sphere(0.018,0.7),eyes,Vector3(x,0.231,-0.161))
  _add_mesh(_head,"Brow_%d"%side,_box(Vector3(0.057,0.013,0.015)),hair,Vector3(x,0.270,-0.158),Vector3(0,0,-float(side)*7.0))
  _add_mesh(_head,"Ear_%d"%side,_sphere(0.051,1.3),skin,Vector3(float(side)*0.174,0.17,0))
 _add_mesh(_head,"HairCap",_sphere(0.179,0.65),hair,Vector3(0,0.338,0.005))
 _add_mesh(_head,"HairSideL",_sphere(0.052,1.20),hair,Vector3(-0.151,0.285,0.012))
 _add_mesh(_head,"HairSideR",_sphere(0.052,1.20),hair,Vector3(0.151,0.285,0.012))
 _add_mesh(_head,"HairPart",_box(Vector3(0.065,0.025,0.27)),hair_light,Vector3(-0.045,0.417,-0.01),Vector3(0,0,-9))
 _add_mesh(_head,"Mouth",_box(Vector3(0.074,0.008,0.009)),skin_shadow,Vector3(0,0.098,-0.17))

func set_motion(metres_per_second: float, sprinting: bool, delta: float) -> void:
 # Purely procedural authored animation: no keyframes from third-party packs.
 _elapsed += delta
 var target: float = clampf(metres_per_second / 2.2, 0.0, 1.0)
 _motion_weight = lerpf(_motion_weight,target,minf(1.0,delta*8.0))
 var run_factor: float = 1.0 if sprinting and metres_per_second > 3.7 else 0.0
 var stride_rate := lerpf(5.5,9.5,run_factor)
 _phase += delta*stride_rate*maxf(0.24,_motion_weight)
 var left := sin(_phase)
 var right := sin(_phase + PI)
 var amplitude := lerpf(0.47,0.69,run_factor)*_motion_weight
 _left_leg.rotation.x = left*amplitude
 _right_leg.rotation.x = right*amplitude
 _left_knee.rotation.x = -maxf(0.0,-left)*0.45*_motion_weight - run_factor*0.09
 _right_knee.rotation.x = -maxf(0.0,-right)*0.45*_motion_weight - run_factor*0.09
 _left_foot.rotation.x = -_left_leg.rotation.x*0.28 - _left_knee.rotation.x*0.20
 _right_foot.rotation.x = -_right_leg.rotation.x*0.28 - _right_knee.rotation.x*0.20
 _left_arm.rotation.x = -left*amplitude*0.87
 _right_arm.rotation.x = -right*amplitude*0.87
 _left_elbow.rotation.x = -0.16-maxf(0.0,left)*0.23*_motion_weight - run_factor*0.29
 _right_elbow.rotation.x = -0.16-maxf(0.0,right)*0.23*_motion_weight - run_factor*0.29
 _lean = lerpf(_lean,0.10*run_factor,minf(1.0,delta*5.0))
 _torso.rotation.x = _lean + sin(_phase*2.0)*0.020*_motion_weight
 _torso.position.y = 1.055 + sin(_elapsed*2.0)*0.005*(1.0-_motion_weight) + absf(sin(_phase))*0.025*_motion_weight
 _head.rotation.x = -_lean*0.45 + sin(_phase)*0.018*_motion_weight
 _head.rotation.z = sin(_elapsed*1.1)*0.009
 _status = "Run" if run_factor > 0.5 else ("Walk" if _motion_weight > 0.13 else "Idle")

func motion_status() -> String:
 return "Original procedural %s (no external rig/animations)" % _status
