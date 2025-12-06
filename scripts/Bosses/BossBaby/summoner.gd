# Summoner.gd (Godot 4, 2D)
extends Node
class_name Summoner

@export var enemy_scene: PackedScene
@export var count := 5
@export var radius := 200.0
@export var parent_path: NodePath
@export var center_path: NodePath  # optional override (if Summoner isn't a direct child)

func summon() -> void:
	if enemy_scene == null:
		return

	var center_node := _get_center_node()
	if center_node == null:
		push_warning("Summoner center must be Node2D.")
		return

	var parent := _resolve_parent()

	var start_angle := randf() * TAU
	var step := TAU / float(max(count, 1))

	for i in range(count):
		var angle := start_angle + step * i
		var offset := Vector2(cos(angle), sin(angle)) * radius

		var enemy := enemy_scene.instantiate() as Node2D
		enemy.global_position = center_node.global_position + offset
		parent.add_child(enemy)

func _get_center_node() -> Node2D:
	# If assigned, use it
	if center_path != NodePath("") and has_node(center_path):
		return get_node(center_path) as Node2D

	# Otherwise, use the runtime parent (the thing you're attached to)
	return get_parent() as Node2D

func _resolve_parent() -> Node:
	if parent_path != NodePath("") and has_node(parent_path):
		return get_node(parent_path)
	return get_tree().current_scene
