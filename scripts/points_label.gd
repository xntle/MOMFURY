extends Label

@export var player: CharacterBody2D

func _ready():
	if player:
		player.connect("points_changed", update_points)
		update_points(player.current_points)

func update_points(new_points: int) -> void:
	text = "Points: %d" % new_points
