extends ProgressBar

@onready var boss: Node

func _ready() -> void:
	if boss == null:
		hide()
	else:
		boss.health_changed.connect(_on_boss_health_changed)
		show()
		if boss == null:
			hide()
		
func connect_boss(new_boss) -> void:
	boss = new_boss
	boss.health_changed.connect(_on_boss_health_changed)
	max_value = boss.max_health
	value = boss.health
	show()

func _on_boss_health_changed(new_health) -> void:
	value = new_health
	show()
	if value <= 0:
		hide()
		
	
