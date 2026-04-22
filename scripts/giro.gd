extends Node3D

@export var speed := 20.0  # grados por segundo

func _process(delta):
	rotation_degrees.y += speed * delta
