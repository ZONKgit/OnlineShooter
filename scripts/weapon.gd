extends Node3D

@export var anim: AnimationPlayer
@export var damage: int
@export var shootSound: AudioStream

var shootRay: RayCast3D

func _ready():
	var shootSoundPlayer = AudioStreamPlayer3D.new()
	shootSoundPlayer.name = "shootSoundPlayer"
	shootSoundPlayer.stream = shootSound
	add_child(shootSoundPlayer)

func _process(delta):
	if not anim.is_playing():
		anim.play('idle')

func shoot() -> void:
	if anim == null: return
	if anim.current_animation != "idle": return
	
	anim.play("shoot")
	playShootSound.rpc()

func reload() -> void:
	anim.play('reload')

@rpc("call_local")
func playShootSound() -> void:
	$shootSoundPlayer.play()
