extends Label

@export var player: CharacterBody2D
@export var show_seconds: float = 2.0

var _hide_token: int = 0

func _ready() -> void:
	hide()
	if player:
		player.round_changed.connect(_on_round_changed)

func _on_round_changed(new_round: int) -> void:
	text = "ROUND %d" % new_round
	show()

	# cancel any previous hide timer if rounds change quickly
	_hide_token += 1
	var token := _hide_token

	await get_tree().create_timer(show_seconds).timeout
	if token == _hide_token:
		hide()
