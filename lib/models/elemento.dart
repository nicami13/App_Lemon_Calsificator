class Elemento {
  final String id;
  final String tamano;
  final double area;
  final String fecha;
  final String hora;
  final String timestamp;
  final String imagenBase64;

  Elemento({
    required this.id,
    required this.tamano,
    required this.area,
    required this.fecha,
    required this.hora,
    required this.timestamp,
    required this.imagenBase64,
  });

  factory Elemento.fromJson(Map<String, dynamic> json) {
    return Elemento(
      id: json['id']?.toString() ?? '',
      tamano: json['tamano']?.toString() ?? '',
      area: (json['area'] is num)
          ? (json['area'] as num).toDouble()
          : double.tryParse(json['area']?.toString() ?? '0') ?? 0.0,
      fecha: json['fecha']?.toString() ?? '',
      hora: json['hora']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      imagenBase64: json['imagen_base64']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tamano': tamano,
      'area': area,
      'fecha': fecha,
      'hora': hora,
      'timestamp': timestamp,
      'imagen_base64': imagenBase64,
    };
  }
}
