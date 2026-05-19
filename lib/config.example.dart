// Archivo de configuración de ejemplo
// Copia este archivo como config.dart y actualiza los valores

class Config {
  // URL base de tu API FastAPI alojada en AWS
  static const String apiBaseUrl = 'https://tu-api-fastapi-en-aws.com';

  // Configuración de timeouts
  static const Duration apiTimeout = Duration(seconds: 2);

  // Configuración de reintentos
  static const int maxRetries = 3;

  // Configuración de paginación
  static const int itemsPerPage = 20;
}
