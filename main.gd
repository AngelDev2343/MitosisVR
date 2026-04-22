extends Node3D

@onready var head = $World/Player/Head
@onready var cam_left = $SubViewportContainerL/SubViewportL/Camera3D
@onready var cam_right = $SubViewportContainerR/SubViewportR/Camera3D

@export var eye_distance := 0.03

func _process(delta):
	# posición base (cabeza)
	var base_transform = head.global_transform

	# cámara izquierda
	cam_left.global_transform = base_transform
	cam_left.translate_object_local(Vector3(-eye_distance, 0, 0))

	# cámara derecha
	cam_right.global_transform = base_transform
	cam_right.translate_object_local(Vector3(eye_distance, 0, 0))
