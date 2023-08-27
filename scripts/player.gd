extends CharacterBody3D

@onready var head = $head
@onready var camera = $head/Camera3D
@onready var weapon = $head/weapon
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var IK = $Armature/Skeleton3D/SkeletonIK3D
@onready var shootRay = $head/shootRay
@onready var characterModel = $Armature
@onready var stepSoundPlayer = $stepSoundPlayer

@onready var rng:RandomNumberGenerator = RandomNumberGenerator.new()

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var weaponNode: Node3D = null
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var sensitivity:float = 1
var health: int = 100

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	rng.randomize()
	weapon.hide()
	$CanvasLayer.hide()
	if not is_multiplayer_authority(): return
	$CanvasLayer.show()
	weapon.show()
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	characterModel.hide()

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		animations.rpc("walk", 0.3)
	else:
		if not anim.current_animation in ["firing rifle"]:
			animations.rpc("idle", 0.3)
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	
	move_and_slide()


func _process(delta):
	IK.start()
	if not is_multiplayer_authority(): return
	weaponNode = weapon.get_child(0)

	if Input.is_action_pressed("shoot"):
		if weaponNode != null:
			weaponNode.shoot()
			if anim.current_animation != "firing rifle":
				animations.rpc("firing rifle", 0, 5)
				
				if shootRay.is_colliding():
					shootRay.get_collider().giveDamage.rpc_id(shootRay.get_collider().get_multiplayer_authority(), weaponNode.damage)

@rpc("call_local")
func animations(animName:String, blend:float=0, speed:float=1) -> void:
	if anim.current_animation == animName: return
	anim.play(animName, blend, speed)

@rpc("call_local")
func playRandomStepSound() -> void:
	var soundNum = rng.randi_range(1,4)
	stepSoundPlayer.stream = load("res://assets/sounds/player/footstep_concrete_00"+str(soundNum)+".ogg")
	stepSoundPlayer.play()

func _input(_e) -> void:
	if not is_multiplayer_authority(): return
	
	if _e is InputEventMouseMotion:
		rotation.y -= _e.relative.x * sensitivity*0.003
		head.rotation.x = clamp(head.rotation.x-_e.relative.y*sensitivity*0.003, -1.4,1.4)


@rpc("any_peer")
func giveDamage(hp: int) -> void:
	health -= hp
