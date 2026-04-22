extends CharacterBody3D

# ─────────────────────────────────────────────────────────────────────────────
#  CONFIGURACIÓN
# ─────────────────────────────────────────────────────────────────────────────
@export var speed:        float = 5.0
@export var gravity:      float = 9.8
@export var arrow_sens:   float = 2.0
@export var mouse_sens:   float = 0.002   # ← NUEVO: sensibilidad del ratón
@export var pitch_limit:  float = 80.0

# Sensibilidad del giroscopio (multiplica el ángulo resultante)
@export var gyro_sens:    float = 1.4

# Factor de suavizado: 0.0 = instantáneo, 1.0 = sin movimiento.
# Con 0.08 el 92 % del nuevo valor llega en cada frame → respuesta fluida.
@export var gyro_smooth:  float = 0.08

# ── Ajuste de ejes landscape ──────────────────────────────────────────────────
# Los sensores SIEMPRE reportan en el frame de coordenadas PORTRAIT del
# dispositivo, independientemente de que el juego esté en landscape.
#
# landscape_flipped:
#   false (por defecto) → landscape-right  (USB / home button a la DERECHA)
#   true                → landscape-left   (USB / home button a la IZQUIERDA)
#
# pitch_inverted / yaw_inverted:
#   Si al probar el pitch o el yaw van al revés de lo esperado, actívalos
#   desde el Inspector sin necesidad de tocar código.
@export var landscape_flipped: bool = false
@export var pitch_inverted:    bool = false
@export var yaw_inverted:      bool = false

@onready var head: Node3D = $Head

# ─────────────────────────────────────────────────────────────────────────────
#  ESTADO iCade
# ─────────────────────────────────────────────────────────────────────────────
var _dirs := { "up": false, "down": false, "left": false, "right": false }

const ICADE_MAP := {
	KEY_W: ["up",    true],
	KEY_E: ["up",    false],
	KEY_X: ["down",  true],
	KEY_Z: ["down",  false],
	KEY_A: ["left",  true],
	KEY_Q: ["left",  false],
	KEY_D: ["right", true],
	KEY_C: ["right", false],
}

# ─────────────────────────────────────────────────────────────────────────────
#  ESTADO FLECHAS
# ─────────────────────────────────────────────────────────────────────────────
var _arrow_up    := false
var _arrow_down  := false
var _arrow_left  := false
var _arrow_right := false

# ─────────────────────────────────────────────────────────────────────────────
#  ESTADO GIROSCOPIO  —  Filtro complementario
# ─────────────────────────────────────────────────────────────────────────────
var _gyro_enabled := false
var _calibrated   := false

var _pitch    := 0.0   # radianes; inclinación arriba/abajo de la cámara

# Peso del giroscopio vs gravedad en el filtro complementario.
# 0.98 = 98 % gyro (suave) + 2 % gravedad (corrige drift lentamente).
# Sube hacia 1.0 si quieres más suavidad; baja si hay demasiado drift.
const COMP_ALPHA := 0.98


# ─────────────────────────────────────────────────────────────────────────────
#  ARRANQUE
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if OS.get_name() == "Web":
		_setup_web_orientation()
	elif OS.get_name() == "iOS" or OS.get_name() == "Android":
		_gyro_enabled = true
		print("Giroscopio nativo activado (landscape)")


func _setup_web_orientation() -> void:
	print("Web: esperando window._orientation.ready")


func enable_gyro() -> void:
	_gyro_enabled = true
	_calibrated   = false


# ─────────────────────────────────────────────────────────────────────────────
#  WEB: orientación JavaScript (sin cambios)
# ─────────────────────────────────────────────────────────────────────────────
func _get_web_orientation() -> Vector3:
	var result = JavaScriptBridge.eval("""
		(window._orientation.alpha || 0) + ',' +
		(window._orientation.beta  || 0) + ',' +
		(window._orientation.gamma || 0)
	""")
	var parts := str(result).split(",")
	if parts.size() < 3:
		return Vector3.ZERO
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


func _orientation_to_quat(alpha_deg: float, beta_deg: float, gamma_deg: float) -> Quaternion:
	var base: Basis = Basis.from_euler(
		Vector3(deg_to_rad(beta_deg), deg_to_rad(alpha_deg), deg_to_rad(-gamma_deg)),
		EULER_ORDER_YXZ
	)
	return (Quaternion(base) * Quaternion(Vector3.RIGHT, -PI * 0.5)).normalized()


# ─────────────────────────────────────────────────────────────────────────────
#  FILTRO COMPLEMENTARIO LANDSCAPE  —  iOS / Android
# ─────────────────────────────────────────────────────────────────────────────
func _apply_gyro_landscape(delta: float, arrow_yaw: float, arrow_pitch: float) -> void:
	var gyro: Vector3 = Input.get_gyroscope()
	var grav: Vector3 = Input.get_gravity()

	# ── Calibración inicial ────────────────────────────────────────────────────
	if not _calibrated:
		if grav.length() > 1.0:
			var init := atan2(grav.z, grav.x)
			_pitch = -init if pitch_inverted else init
			if landscape_flipped: _pitch = -_pitch
		else:
			_pitch = 0.0
		_calibrated = true
		print("Calibrado. Pitch inicial: %.1f°" % rad_to_deg(_pitch))
		return

	# ── Tasas de cambio según orientación ─────────────────────────────────────
	var pitch_rate: float
	var yaw_rate:   float

	if landscape_flipped:
		pitch_rate = -gyro.y
		yaw_rate   =  gyro.x
	else:
		pitch_rate =  gyro.y
		yaw_rate   = -gyro.x

	if pitch_inverted: pitch_rate = -pitch_rate
	if yaw_inverted:   yaw_rate   = -yaw_rate

	# ── Referencia de gravedad para corrección de drift en pitch ───────────────
	var grav_pitch_ref := _pitch
	if grav.length() > 1.0:
		var ref := atan2(grav.z, grav.x)
		if pitch_inverted or landscape_flipped: ref = -ref
		grav_pitch_ref = ref

	# ── Filtro complementario ──────────────────────────────────────────────────
	_pitch = lerp_angle(grav_pitch_ref, _pitch + pitch_rate * delta, COMP_ALPHA)

	# ── Aplicar a la cámara ────────────────────────────────────────────────────
	var target_pitch_deg: float = clamp(rad_to_deg(_pitch) * gyro_sens, -pitch_limit, pitch_limit)
	head.rotation_degrees.x = lerp(
		head.rotation_degrees.x,
		target_pitch_deg + rad_to_deg(arrow_pitch),
		1.0 - gyro_smooth
	)

	rotate_y(-yaw_rate * delta * gyro_sens + arrow_yaw)


# ─────────────────────────────────────────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	# ── CORRECCIÓN: ratón capturado pero nunca leído ───────────────────────────
	# El cursor queda atrapado con MOUSE_MODE_CAPTURED sin que ningún evento
	# InputEventMouseMotion se procesara → mirada con ratón completamente rota.
	# Se gestiona sólo cuando el giroscopio está desactivado para evitar
	# conflictos con la orientación del dispositivo.
	if event is InputEventMouseMotion and not _gyro_enabled:
		rotate_y(-event.relative.x * mouse_sens)
		head.rotation_degrees.x = clamp(
			head.rotation_degrees.x - event.relative.y * mouse_sens,
			-pitch_limit, pitch_limit
		)

	if event is InputEventKey and not event.echo:
		match event.keycode:
			KEY_UP:    _arrow_up    = event.pressed
			KEY_DOWN:  _arrow_down  = event.pressed
			KEY_LEFT:  _arrow_left  = event.pressed
			KEY_RIGHT: _arrow_right = event.pressed

		if event.pressed:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				# Re-calibrar: pitch vuelve a 0 relativo a la posición actual
				_calibrated = false

			var entry = ICADE_MAP.get(event.keycode, null)
			if entry:
				_dirs[entry[0]] = entry[1]


# ─────────────────────────────────────────────────────────────────────────────
#  FÍSICA
# ─────────────────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_check_gyro_ready()

	# ── 1. Gravedad ────────────────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= gravity * delta

	# ── 2. Movimiento iCade ────────────────────────────────────────────────────
	var raw := Vector2(
		(-1.0 if _dirs["left"]  else 0.0) + ( 1.0 if _dirs["right"] else 0.0),
		( 1.0 if _dirs["up"]    else 0.0) + (-1.0 if _dirs["down"]  else 0.0)
	)

	# ── 3. Gamepad ─────────────────────────────────────────────────────────────
	var gamepads := Input.get_connected_joypads()
	if gamepads.size() > 0:
		var pad: int       = gamepads[0]
		var left_x: float  = Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		var left_y: float  = Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)
		var right_x: float = Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X)
		var right_y: float = Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
		if absf(left_x)  < 0.15: left_x  = 0.0
		if absf(left_y)  < 0.15: left_y  = 0.0
		if absf(right_x) < 0.15: right_x = 0.0
		if absf(right_y) < 0.15: right_y = 0.0
		var left_mag:  float = Vector2(left_x,  left_y).length()
		var right_mag: float = Vector2(right_x, right_y).length()
		# ── CORRECCIÓN: eje Y del gamepad invertido ────────────────────────────
		# En Godot 4, JOY_AXIS_LEFT_Y devuelve -1 al empujar el stick hacia
		# adelante y +1 al tirarlo hacia atrás; lo contrario de lo que necesita
		# raw.y para avanzar. Sin negar, el jugador retrocedía al empujar el
		# stick hacia adelante. Se aplica la misma corrección al stick derecho.
		if left_mag >= right_mag:
			raw += Vector2(left_x, -left_y)
		else:
			raw += Vector2(right_x, -right_y)

	var input_dir := raw.normalized()
	var cam_basis := global_transform.basis

	var forward := -cam_basis.z
	forward.y = 0
	forward = forward.normalized()

	var right_vec := cam_basis.x
	right_vec.y = 0
	right_vec = right_vec.normalized()
	var move_dir  := forward * input_dir.y + right_vec * input_dir.x
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	move_and_slide()

	# ── 4. Flechas ─────────────────────────────────────────────────────────────
	var arrow_yaw   := 0.0
	var arrow_pitch := 0.0
	if _arrow_left:  arrow_yaw   += arrow_sens * delta
	if _arrow_right: arrow_yaw   -= arrow_sens * delta
	if _arrow_up:    arrow_pitch += arrow_sens * delta
	if _arrow_down:  arrow_pitch -= arrow_sens * delta

	# ── 5. Giroscopio ──────────────────────────────────────────────────────────
	if _gyro_enabled:
		if OS.get_name() == "Web":
			# Web: lógica original sin modificar
			var v: Vector3    = _get_web_orientation()
			var q: Quaternion = _orientation_to_quat(v.x, v.y, v.z)
			if not _calibrated:
				_calibrated = true
			var t := 1.0 - gyro_smooth
			var rel_q := Quaternion.IDENTITY.slerp((Quaternion.IDENTITY.inverse() * q).normalized(), t)
			var euler := Basis(rel_q).get_euler(EULER_ORDER_YXZ)
			rotation.y              = euler.y + arrow_yaw
			head.rotation_degrees.x = clamp(
				rad_to_deg(euler.x) * gyro_sens + rad_to_deg(arrow_pitch),
				-pitch_limit, pitch_limit
			)
		else:
			# Nativo iOS / Android: filtro complementario landscape
			_apply_gyro_landscape(delta, arrow_yaw, arrow_pitch)
	else:
		rotate_y(arrow_yaw)
		head.rotation_degrees.x = clamp(
			head.rotation_degrees.x + rad_to_deg(arrow_pitch),
			-pitch_limit, pitch_limit
		)


# ─────────────────────────────────────────────────────────────────────────────
#  DETECCIÓN GIROSCOPIO WEB
# ─────────────────────────────────────────────────────────────────────────────
func _check_gyro_ready() -> void:
	if _gyro_enabled:
		return
	if OS.get_name() != "Web":
		return
	var alpha      = JavaScriptBridge.eval("+(window._orientation && window._orientation.alpha) || 0")
	var beta       = JavaScriptBridge.eval("+(window._orientation && window._orientation.beta)  || 0")
	var ready_flag = JavaScriptBridge.eval("window._orientation ? (window._orientation.ready ? 1 : 0) : 0")
	if ready_flag == 1 or absf(float(str(alpha))) > 0.5 or absf(float(str(beta))) > 0.5:
		_gyro_enabled = true
		_calibrated   = false
		JavaScriptBridge.eval("window._gd_yaw=0;window._gd_pitch=0;")
		print("Giroscopio Web activado")
