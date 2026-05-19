# SecónSecon - Sistema IoT Clasificador de Limones

Una aplicación Flutter para la clasificación inteligente de limones utilizando IoT y visión por computadora.

## Características

- **Interfaz IoT moderna**: Diseño profesional con tema Material 3
- **Consumo de API**: Integración con FastAPI alojado en AWS
- **Visualización de imágenes**: Decodificación y display de imágenes en base64
- **Navegación intuitiva**: Menú popup y navegación entre pantallas
- **Gestión de datos**: CRUD completo de elementos

## Configuración

### 1. API Backend

La aplicación consume datos desde una API FastAPI alojada en AWS. Para configurar la URL de la API:

1. Abre el archivo `lib/services/api_service.dart`
2. Cambia la constante `baseUrl` por tu URL real:

```dart
static const String baseUrl = 'https://tu-api-fastapi-en-aws.com';
```

### 2. Estructura de la API

La API debe proporcionar los siguientes endpoints:

- `GET /elementos` - Lista todos los elementos
- `GET /elementos/{id}` - Obtiene un elemento específico
- `POST /elementos` - Crea un nuevo elemento
- `PUT /elementos/{id}` - Actualiza un elemento
- `DELETE /elementos/{id}` - Elimina un elemento

### 3. Formato de datos

Cada elemento debe tener la siguiente estructura JSON:

```json
{
  "id": 1,
  "nombre": "Limón Tipo A",
  "descripcion": "Limón de alta calidad",
  "imagen_base64": "iVBORw0KGgoAAAANSUhEUgAA...",
  "fecha_creacion": "2024-01-15T10:30:00Z"
}
```

## Instalación

1. Clona el repositorio
2. Ejecuta `flutter pub get`
3. Configura la URL de la API
4. Ejecuta `flutter run`

## Estructura del proyecto

```
lib/
├── main.dart                    # Pantalla principal con listado
├── registro_screen.dart         # Pantalla de registro de elementos
├── detalle_elemento_screen.dart # Pantalla de detalle de elemento
├── models/
│   └── elemento.dart           # Modelo de datos
└── services/
    └── api_service.dart        # Servicio de API
```

## Dependencias

- `http: ^1.2.0` - Para peticiones HTTP
- `flutter/material.dart` - Framework Flutter

## Funcionalidades implementadas

✅ Menú popup con opción "Registros"  
✅ Pantalla de registro de nuevos elementos  
✅ Listado de elementos desde API  
✅ Visualización de imágenes en base64  
✅ Navegación entre pantallas  
✅ Manejo de estados de carga y error  
✅ Pull-to-refresh en el listado  
✅ Diseño responsive y profesional  

## Próximas mejoras

- [ ] Integración con cámara para captura de imágenes
- [ ] Funcionalidad completa de CRUD
- [ ] Autenticación de usuario
- [ ] Cache offline de datos
- [ ] Notificaciones push
