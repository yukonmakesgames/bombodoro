@tool
extends EditorPlugin

var dock = null


func _enter_tree() -> void:
	dock = preload("res://addons/bombodoro/dock/BombodoroDock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)


func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()
