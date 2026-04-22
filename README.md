# 🔬 Mitosis VR

![Motor](https://img.shields.io/badge/motor-Godot%204-blue)
![Plataforma](https://img.shields.io/badge/plataforma-Web%20%7C%20iOS%20%7C%20Android-brightgreen)
![VR](https://img.shields.io/badge/VR-Cardboard%20compatible-purple)
![Educativo](https://img.shields.io/badge/tipo-educativo-informational)

**Mitosis VR** es una experiencia educativa inmersiva en **realidad virtual** desarrollada en **Godot 4** como proyecto academico, que permite explorar en 3D las distintas fases de la mitosis celular. Diseñada para ser usada con cualquier lente tipo **Cardboard** desde cualquier dispositivo móvil, o directamente en escritorio con mouse y teclado.

https://github.com/user-attachments/assets/22a59d27-2b45-4ae1-9878-91b5effb37d3

---

## 🎯 Objetivo

Desarrollado como **proyecto academico**, Mitosis VR busca ofrecer una herramienta de aprendizaje visual e interactivo sobre la **división celular mitótica**, permitiendo al estudiante "caminar" entre los modelos 3D de cada fase y observarlas desde cualquier ángulo con o sin lentes VR.

---

## 🧬 Contenido educativo

La escena incluye **6 modelos 3D** de células, uno por cada etapa del proceso de mitosis:

| Fase | Modelo 3D |
|------|-----------|
| **Interfase** | `celula_interfase_completa.glb` |
| **Profase** | `celula_profase.glb` |
| **Prometafase** | `celula_prometafase.glb` |
| **Metafase** | `celula_metafase.glb` |
| **Anafase** | `celula_anafase.glb` |
| **Telofase** | `celula_telofase.glb` |

Cada modelo se muestra rotando continuamente sobre su propio eje y tiene su etiqueta en 3D con el nombre de la fase, visibles desde cualquier posición dentro del espacio virtual.

---

## 🥽 Sistema VR

El renderizado estereoscópico se implementa mediante **dos SubViewports independientes** (uno por ojo), con cámaras separadas por una distancia interocular configurable.

```
ojo izquierdo  ←  distancia interocular  →  ojo derecho
   Camera3D                                   Camera3D
   (SubViewportL)                          (SubViewportR)
```

- Resolución por ojo: **960 × 1080 px**
- Distancia interocular por defecto: `0.03` unidades (ajustable via `@export`)
- Ambas cámaras siguen la posición y rotación de la cabeza del jugador en tiempo real

---

## 🕹️ Controles

El proyecto soporta múltiples métodos de entrada para máxima compatibilidad:

### Giroscopio (principal en VR)

- **iOS / Android:** usa el giroscopio nativo con un **filtro complementario** (98% giroscopio + 2% gravedad) para eliminar el drift de forma gradual.
- **Web:** lee la orientación desde la API `DeviceOrientationEvent` de JavaScript via `JavaScriptBridge`.
- Calibración automática al inicio; se puede **recalibrar** en cualquier momento presionando `Espacio` o `Enter`.
- Soporte para orientación landscape (normal e invertida) configurables desde el Inspector.

### Teclado

| Tecla | Acción |
|-------|--------|
| Flechas | Rotar la cámara (pitch y yaw) |
| `Espacio` / `Enter` | Recalibrar giroscopio |

### Mouse

- Movimiento libre de cámara con el cursor capturado (`MOUSE_MODE_CAPTURED`).
- Activo únicamente cuando el giroscopio está desactivado (modo escritorio).

### Gamepad

- Compatible con cualquier mando conectado.
- Stick izquierdo: movimiento; stick derecho: tambien movimiento.
- Dead zone aplicado en `0.15` para evitar toques accidentales.
- Corrección del eje Y del stick (comportamiento estándar de Godot 4).

### iCade (teclado arcade Bluetooth)

Mapeo personalizado para compatibilidad con el periférico iCade:

| Tecla iCade | Acción |
|-------------|--------|
| `W` / `E` | Avanzar / soltar |
| `X` / `Z` | Retroceder / soltar |
| `A` / `Q` | Izquierda / soltar |
| `D` / `C` | Derecha / soltar |

---

## ⚙️ Parámetros configurables

Todos los parámetros clave están expuestos como `@export` y son ajustables desde el Inspector de Godot sin tocar el código:

| Parámetro | Valor por defecto | Descripción |
|-----------|-------------------|-------------|
| `speed` | `5.0` | Velocidad de movimiento del jugador |
| `gravity` | `9.8` | Gravedad aplicada al jugador |
| `mouse_sens` | `0.002` | Sensibilidad del ratón |
| `arrow_sens` | `2.0` | Sensibilidad de las teclas de flecha |
| `gyro_sens` | `1.4` | Multiplicador de sensibilidad del giroscopio |
| `gyro_smooth` | `0.08` | Suavizado del giroscopio (0 = instantáneo) |
| `pitch_limit` | `80.0°` | Límite máximo de inclinación vertical |
| `eye_distance` | `0.03` | Separación interocular de las cámaras VR |
| `landscape_flipped` | `false` | Orientación landscape invertida |
| `pitch_inverted` | `false` | Invertir eje vertical del giroscopio |
| `yaw_inverted` | `false` | Invertir eje horizontal del giroscopio |

---

## 📱 Compatibilidad

| Plataforma | Modo de control | VR |
|------------|-----------------|----|
| Android | Giroscopio nativo | ✅ Con Cardboard |
| iOS | Giroscopio nativo | ✅ Con Cardboard |
| Web (navegador) | `DeviceOrientationEvent` JS | ✅ Con Cardboard |
| Windows / Linux / macOS | Mouse + teclado + gamepad | ❌ Solo pantalla plana |

> Para la experiencia VR se requieren lentes tipo Cardboard o cualquier visor de realidad virtual compatible con smartphones.

---

## 🛠️ Requisitos técnicos

- **Godot 4.x**
- Modelos en formato `.glb` (en `res://models/`)
- Texturas en `res://texture/`
- Para Web: servidor con soporte HTTPS (necesario para `DeviceOrientationEvent` en iOS/Android)

---

## 🚀 Cómo ejecutar

1. Abre la siguiente pagina -> [🥽 Probar ahora 🥽](https://mitosis1.netlify.app/main.html)

2. En Android (Chrome) dirígete a la parte superior derecha de tu navegador, en este simbolo ⋮ , despues da clic en "Agregar a la pantalla de inicio" y despues "Instalar".

3. En iPhone (Safari) dirigete al boton "Compartir" de la parte inferior, despues "Agregar a inicio" o "Add to home", y por ultimo "Agregar" o "Add".

---

## 🌟 Easter egg

Hay dos instancias de **Baby Yoda** escondidas en la escena. ¡A encontrarlas!

---

## 👥 Créditos

- **Motor:** Godot Engine 4
- **Modelos 3D:** Propios del equipo (formato `.glb`)
- **Inspiración pedagógica:** enseñanza de biología celular mediante experiencias inmersivas

---

## 📄 Licencia

Todos los derechos reservados. Proyecto de uso educativo.
