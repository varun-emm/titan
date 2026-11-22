extends CharacterBody3D
## Original procedural character. No imported models, skeletons or third-party animations.
const OriginalCharacter = preload("res://scripts/original_character.gd")

var speed := 3.30
var sprint_speed := 5.50
var mouse_sensitivity := .0024
var pitch := -.09
var yaw := 0.0
var first_person := false
var head: Node3D
var camera: Camera3D
var visual: Node3D
var character: Node3D
var camera_distance := 2.45
var touch_move := Vector2.ZERO
var touch_sprint := false
var camera_raycast: RayCast3D

func _ready() -> void:
 name = "Explorer"
 var shape := CapsuleShape3D.new()
 shape.radius = .30
 shape.height = 1.8
 var col := CollisionShape3D.new()
 col.shape = shape
 col.position.y = .9
 add_child(col)
 visual = Node3D.new()
 visual.name = "Original_Character_Visual"
 add_child(visual)
 character = Node3D.new()
 character.set_script(OriginalCharacter)
 character.name = "Edwardian_Explorer"
 visual.add_child(character)
 head = Node3D.new()
 head.position.y = 1.58
 add_child(head)
 camera = Camera3D.new()
 camera.current = true
 camera.fov = 72.0
 head.add_child(camera)
 camera_raycast = RayCast3D.new()
 camera_raycast.target_position = Vector3(0,.20,2.7)
 camera_raycast.collision_mask = 1
 camera_raycast.exclude_parent = true
 head.add_child(camera_raycast)
 _refresh_camera()
 if not (OS.has_feature("web") and DisplayServer.is_touchscreen_available()):
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func animation_status() -> String:
 if character != null:
  return str(character.call("motion_status"))
 return "Procedural character initializing"

func _input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  yaw -= event.relative.x * mouse_sensitivity
  pitch = clampf(pitch - event.relative.y * mouse_sensitivity,-1.2,1.0)
  rotation.y = yaw
  head.rotation.x = pitch
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_V:
   first_person = not first_person
   _refresh_camera()
  elif event.keycode == KEY_ESCAPE:
   Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func apply_touch_look(relative_motion: Vector2) -> void:
 yaw -= relative_motion.x * mouse_sensitivity * 1.35
 pitch = clampf(pitch - relative_motion.y * mouse_sensitivity * 1.35,-1.2,1.0)
 rotation.y = yaw
 head.rotation.x = pitch

func toggle_camera_view() -> void:
 first_person = not first_person
 _refresh_camera()

func _refresh_camera() -> void:
 if camera == null:
  return
 visual.visible = not first_person
 camera.position = Vector3(0,0,0) if first_person else Vector3(0,.23,camera_distance)

func _physics_process(delta: float) -> void:
 if not is_on_floor():
  velocity.y -= 18.0 * delta
 else:
  velocity.y = -.15
 var direction := Vector3.ZERO
 if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or touch_move.length_squared() > 0.0:
  if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.z -= 1
  if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.z += 1
  if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1
  if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1
 direction.x += touch_move.x
 direction.z += touch_move.y
 direction = (global_transform.basis * direction).normalized()
 var is_running := (Input.is_key_pressed(KEY_SHIFT) or touch_sprint) and direction.length_squared() > 0.001
 var target_speed := sprint_speed if is_running else speed
 velocity.x = move_toward(velocity.x,direction.x * target_speed,delta * 13.0)
 velocity.z = move_toward(velocity.z,direction.z * target_speed,delta * 13.0)
 move_and_slide()
 if not first_person and camera_raycast != null:
  camera_raycast.force_raycast_update()
  if camera_raycast.is_colliding():
   camera.position.z = maxf(.38,head.to_local(camera_raycast.get_collision_point()).z - .18)
  else:
   camera.position.z = move_toward(camera.position.z,camera_distance,delta*6.0)
 if character != null:
  character.call("set_motion", Vector2(velocity.x, velocity.z).length(), is_running, delta)
