import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'services/bluetooth_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import '../models/elemento.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<String>? _dataSubscription;

  // Test mode state
  int _currentStep = 0;
  bool _showPopup = false;
  String _popupTitle = '';
  String _popupMessage = '';
  String? _popupImageData;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    _setupListeners();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    _dataSubscription = _bluetoothService.dataStream.listen((data) {
      _handleReceivedData(data);
    });
  }

  void _handleReceivedData(String data) {
    print('Datos recibidos: $data');

    // Solo procesar si estamos en modo prueba
    if (_currentStep > 0) {
      _processTestModeData(data);
    }
  }

  void _processTestModeData(String data) {
    String lowerData = data.toLowerCase().trim();

    if (lowerData.contains('paso 1')) {
      _showStepPopup(
        1,
        'Limón Detectado',
        'Tipo de limón detectado por sensor ultrasónico',
        null,
      );
    } else if (lowerData.contains('paso 2')) {
      // Obtener datos de la API endpoint 'ultimo'
      _fetchUltimoAndShowPopup();
    }
  }

  Future<void> _fetchUltimoAndShowPopup() async {
    try {
      Elemento ultimoElemento = await ApiService.getUltimo();
      String datosCompletos =
          'ID: ${ultimoElemento.id}\n'
          'Tamaño: ${ultimoElemento.tamano}\n'
          'Área: ${ultimoElemento.area.toStringAsFixed(2)}\n'
          'Fecha: ${ultimoElemento.fecha}\n'
          'Hora: ${ultimoElemento.hora}';

      _showStepPopup(
        2,
        'Foto Enviada',
        datosCompletos,
        ultimoElemento.imagenBase64,
      );
    } catch (e) {
      print('Error al obtener último elemento: $e');
      _showStepPopup(
        2,
        'Foto Enviada',
        'Error al cargar datos de la API',
        null,
      );
    }
  }

  void _showStepPopup(
    int step,
    String title,
    String message,
    String? imageData,
  ) {
    setState(() {
      _currentStep = step;
      _showPopup = true;
      _popupTitle = title;
      _popupMessage = message;
      _popupImageData = imageData;
    });
  }

  void _handleNextStep() {
    String confirmation = 'confirmado $_currentStep';
    _bluetoothService.sendData(confirmation);

    if (_currentStep == 2) {
      // Después del paso 2, mostrar éxito
      setState(() {
        _currentStep = 0;
        _showPopup = false;
      });
      _showSuccessDialog();
    } else {
      setState(() {
        _showPopup = false;
      });
    }
  }

  void _handleCancelStep() {
    setState(() {
      _currentStep = 0;
      _showPopup = false;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Operación Exitosa!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('😊', style: TextStyle(fontSize: 80)),
            SizedBox(height: 16),
            Text(
              '¡Proceso completado exitosamente!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'El limón ha sido clasificado correctamente',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startTestMode() {
    setState(() {
      _currentStep = 1; // Iniciar en paso 1 para procesar datos
    });
    _bluetoothService.sendData('prueba');
    _notificationService.showModeNotification('Prueba');
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salir del Modo Prueba'),
        content: const Text(
          '¿Estás seguro de que deseas salir del modo prueba? Perderás el progreso actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Salir de la pantalla
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3C8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6D600),
        foregroundColor: Colors.black87,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showExitConfirmation,
        ),
        title: const Text('Lemon Clasificator Cinta'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/fondo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.science, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Modo de Prueba',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Secuencia de clasificación de limones',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Botón de inicio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: _startTestMode,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar Prueba'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    minimumSize: const Size(double.infinity, 60),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Estado actual
              if (_currentStep > 0) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 12),
                          const Text(
                            'Estado Actual',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Paso $_currentStep: $_popupTitle',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Popup overlay
          if (_showPopup) _buildTestModePopup(),
        ],
      ),
    );
  }

  Widget _buildTestModePopup() {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Fondo semitransparente
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          // Contenido del popup centrado
          Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentStep == 2 ? Icons.check_circle : Icons.info,
                      size: 64,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Paso $_currentStep: $_popupTitle',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _popupMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_popupImageData != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _popupImageData!.isNotEmpty
                              ? Image.memory(
                                  base64Decode(_popupImageData!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Text('Error al cargar imagen'),
                                    );
                                  },
                                )
                              : const Center(child: Text('No hay imagen')),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _handleCancelStep,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleNextStep,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Siguiente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
