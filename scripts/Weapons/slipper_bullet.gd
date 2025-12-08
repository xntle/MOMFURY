extends Area2D

@export var speed: float = 400.0
@export var max_distance: float = 500.0
@export var damage: float = 20.0
@export var hit_effect_scene: PackedScene
@export var lifetime:float = 3.0

var direction: Vector2 = Vector2.ZERO
var travel_time: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

	# Play slipper throw sound
	_play_throw_sound()


func _play_throw_sound() -> void:
	# Array of throw sound paths
	var throw_sounds = [
		"res://assets/Sound/Throw/SWSH_MOVEMENT-Bamboo Whip_HY_PC-001.wav",
		"res://assets/Sound/Throw/SWSH_MOVEMENT-Bamboo Whip_HY_PC-002.wav",
		"res://assets/Sound/Throw/SWSH_MOVEMENT-Bamboo Whip_HY_PC-003.wav",
		"res://assets/Sound/Throw/SWSH_MOVEMENT-Bamboo Whip_HY_PC-004.wav",
		"res://assets/Sound/Throw/SWSH_MOVEMENT-Bamboo Whip_HY_PC-005.wav",
		"res://assets/Sound/Throw/SWSH_MOVEMENT-Bamboo Whip_HY_PC-006.wav"
	]

	# Pick random throw sound
	var random_sound_path = throw_sounds[randi() % throw_sounds.size()]
	var throw_sound = load(random_sound_path) as AudioStream

	if throw_sound != null:
		var audio_player = AudioStreamPlayer2D.new()
		get_tree().current_scene.add_child(audio_player)
		audio_player.stream = throw_sound
		audio_player.global_position = global_position

		# Ensure sound doesn't loop
		if throw_sound is AudioStreamWAV:
			throw_sound.loop_mode = AudioStreamWAV.LOOP_DISABLED

		audio_player.play()

		# Auto-cleanup after 2 seconds max
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)

		# Also cleanup when finished normally
		audio_player.finished.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)

func _physics_process(delta):
	global_position += direction * speed * delta
	rotation += 15.0 * delta
	travel_time += delta
	if travel_time >= lifetime:
		queue_free()
	

func _on_body_entered(body):
	print("Slipper bullet hit: ", body.name, " (", body.get_class(), ")")

	if body is PlayerController:
		print("  -> Ignoring player")
		return
		

	if body.has_method("take_damage"):
		print("  -> Dealing ", damage, " damage")
		body.take_damage(damage)

		# Spawn hit effect
		if hit_effect_scene != null:
			var hit_effect = hit_effect_scene.instantiate()
			get_tree().current_scene.add_child(hit_effect)
			hit_effect.global_position = global_position
		
	else:
		print("  -> No take_damage method found")

	queue_free()
