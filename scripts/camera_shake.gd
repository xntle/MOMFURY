extends Camera2D
class_name CameraShake

var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	original_offset = offset

func _process(delta: float) -> void:
	if shake_intensity > 0:
		shake_intensity -= shake_decay * delta
		shake_intensity = max(shake_intensity, 0.0)

		# Apply random shake offset
		offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		offset = original_offset

func shake(intensity: float, duration: float = 0.5) -> void:
	shake_intensity = intensity
	shake_decay = intensity / duration

func earthquake(duration: float = 2.0) -> void:
	shake(30.0, duration)
