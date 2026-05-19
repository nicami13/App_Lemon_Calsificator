import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/elemento.dart';

class ApiService {
  // Cambia esta URL por la URL real de tu API en AWS
  static const String baseUrl =
      'http://ec2-16-59-26-200.us-east-2.compute.amazonaws.com:8000';

  static Future<List<Elemento>> getElementos() async {
    final response = await http.get(Uri.parse('$baseUrl/listar'));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Elemento.fromJson(json)).toList();
    } else {
      throw Exception('Error real: ${response.statusCode}');
    }
  }

  static Future<Elemento> getElemento(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/listar/$id'));

      if (response.statusCode == 200) {
        return Elemento.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al cargar elemento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Elemento> crearElemento(Elemento elemento) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clasificar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(elemento.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Elemento.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear elemento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> actualizarElemento(int id, Elemento elemento) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/elementos/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(elemento.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al actualizar elemento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> eliminarElemento(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/elementos/$id'));

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar elemento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Elemento> getUltimo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ultimo'));

      if (response.statusCode == 200) {
        return Elemento.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Error al obtener último elemento: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
