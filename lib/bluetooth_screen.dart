import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'services/bluetooth_service.dart';
import 'services/notification_service.dart';
import 'dart:async';
import 'test_screen.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final BluetoothService _bluetoothService = BluetoothService();
  final NotificationService _notificationService = NotificationService();
  List<BluetoothDevice> _devices = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _connectedDeviceName;
  int _pwmValue = 128;
  int _pendingPwmValue = 128;
  Timer? _pwmSendTimer;
  static const int _pwmHysteresis = 8;
  StreamSubscription<String>? _dataSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  String get _pwmEmoji {
    if (_pwmValue <= 100) return '😕';
    if (_pwmValue <= 200) return '😊';
    return '😎';
  }

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
    _isConnected = _bluetoothService.isConnected;
    _connectedDeviceName = _bluetoothService.connectedDevice?.name;
    _requestPermissions();
    _checkBluetoothStatus();
    _setupListeners();
  }

  Future<void> _requestPermissions() async {
    // Request notification permission
    await Permission.notification.request();

    // Request Bluetooth permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
  }

  void _checkBluetoothStatus() async {
    bool available = await _bluetoothService.isBluetoothAvailable();
    if (!available) {
      _showErrorDialog('Bluetooth no está disponible en este dispositivo');
      return;
    }

    bool enabled = await _bluetoothService.isBluetoothEnabled();
    if (!enabled) {
      _showErrorDialog('Por favor habilita el Bluetooth');
      return;
    }

    _loadDevices();
  }

  void _setupListeners() {
    _connectionSubscription = _bluetoothService.connectionStream.listen((
      connected,
    ) {
      setState(() {
        _isConnected = connected;
        if (!connected) {
          _connectedDeviceName = null;
          _currentStep = 0;
          _showPopup = false;
        }
      });
    });

    _dataSubscription = _bluetoothService.dataStream.listen((data) {
      _handleReceivedData(data);
    });
  }

  void _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<BluetoothDevice> devices = await _bluetoothService
          .getBondedDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al cargar dispositivos: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _bluetoothService.connectToDevice(device);
      _notificationService.showConnectionNotification(
        'Conectado a ${device.name ?? 'Dispositivo'}',
      );
      setState(() {
        _isConnected = true;
        _connectedDeviceName = device.name ?? 'Dispositivo';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al conectar: $e');
    }
  }

  void _disconnect() {
    _notificationService.showConnectionNotification('Desconectado');
    _bluetoothService.disconnect();
    setState(() {
      _isConnected = false;
      _connectedDeviceName = null;
      _currentStep = 0;
      _showPopup = false;
    });
  }

  void _sendPwmValue(int value) {
    if (!_isConnected) return;
    setState(() {
      _pwmValue = value;
      _pendingPwmValue = value;
    });
    _bluetoothService.sendData(value.toString());
    _notificationService.showModeNotification('PWM $value');
  }

  void _queuePwmSend(int value) {
    if (!_isConnected) return;
    _pwmSendTimer?.cancel();
    _pwmSendTimer = Timer(const Duration(milliseconds: 350), () {
      final int delta = (value - _pwmValue).abs();
      if (delta >= _pwmHysteresis) {
        _sendPwmValue(value);
      }
    });
  }

  void _applyPwmValue() {
    if (!_isConnected) return;
    _pwmSendTimer?.cancel();
    if (_pendingPwmValue == _pwmValue) return;
    _sendPwmValue(_pendingPwmValue);
  }

  void _onPwmSliderChanged(double value) {
    setState(() {
      _pendingPwmValue = value.round();
    });
  }

  void _onPwmSliderChangeEnd(double value) {
    final int newValue = value.round();
    final int delta = (newValue - _pwmValue).abs();
    if (delta >= _pwmHysteresis) {
      _queuePwmSend(newValue);
    }
  }

  void _sendMode(String mode) {
    if (mode == 'prueba') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TestScreen()),
      );
    }
  }

  void _handleReceivedData(String data) {
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
      _showStepPopup(2, 'Foto Enviada', 'Datos recibidos: $data', data);
    } else if (lowerData.contains('paso 3')) {
      _showStepPopup(
        3,
        'Posicionamiento',
        'Clasificación de posición en proceso',
        null,
      );
    } else if (lowerData.contains('paso 4')) {
      _showStepPopup(
        4,
        'Limón Clasificado',
        'Clasificación completada exitosamente',
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

    if (_currentStep == 4) {
      _showSuccessDialog();
      setState(() {
        _currentStep = 0;
        _showPopup = false;
      });
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text(
              '¡Proceso Completado!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _connectionSubscription?.cancel();
    _pwmSendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lemon Clasificator Cinta'),
        backgroundColor: const Color(0xFFF6D600),
        foregroundColor: Colors.black87,
        elevation: 4,
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnect,
              tooltip: 'Desconectar',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isConnected
              ? _buildOperationModesScreen()
              : _buildDeviceListScreen(),
        ),
      ),
    );
  }

  Widget _buildDeviceListScreen() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.bluetooth_searching, size: 80, color: Colors.blue),
        const SizedBox(height: 16),
        const Text(
          'Dispositivos Bluetooth',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecciona un dispositivo para conectar',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _devices.isEmpty
              ? const Center(
                  child: Text(
                    'No hay dispositivos vinculados',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.devices, color: Colors.blue),
                        title: Text(
                          device.name ?? 'Dispositivo desconocido',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(device.address),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue,
                        ),
                        onTap: () => _connectToDevice(device),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _loadDevices,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar lista'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationModesScreen() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(top: 20, bottom: 24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.bluetooth_connected,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bluetooth activo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _connectedDeviceName ?? 'Dispositivo conectado',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _buildPwmControlCard(),
              const SizedBox(height: 18),
              _buildPruebaCard(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Usa este deslizador para enviar directamente un valor PWM entre 0 y 255 al ESP32. El valor se envía en forma de número, sin texto adicional.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (_showPopup)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(child: _buildTestModePopup()),
            ),
          ),
      ],
    );
  }

  Widget _buildPwmControlCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Control PWM del motor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Valor actual: $_pwmValue  $_pwmEmoji',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.blue.shade700,
                  inactiveTrackColor: Colors.blue.shade100,
                  thumbColor: Colors.blue.shade700,
                  overlayColor: Colors.blue.withOpacity(0.2),
                  valueIndicatorColor: Colors.blue.shade700,
                  trackHeight: 6,
                ),
                child: Slider(
                  min: 0,
                  max: 255,
                  divisions: 255,
                  value: _pendingPwmValue.toDouble(),
                  label: '$_pendingPwmValue',
                  onChanged: _onPwmSliderChanged,
                  onChangeEnd: _onPwmSliderChangeEnd,
                ),
              ),
              const SizedBox(height: 10),
              if (_pendingPwmValue != _pwmValue)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Valor seleccionado: $_pendingPwmValue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: _pendingPwmValue == _pwmValue
                    ? null
                    : _applyPwmValue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Aplicar', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('0', style: TextStyle(fontSize: 14)),
                  Text('128', style: TextStyle(fontSize: 14)),
                  Text('255', style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPruebaCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => _sendMode('prueba'),
        borderRadius: BorderRadius.circular(20),
        child: Card(
          elevation: 7,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.science,
                    color: Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Modo Prueba',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Mantén el procedimiento de prueba como antes.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              ],
            ),
          ),
        ),
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
                      _currentStep == 4 ? Icons.check_circle : Icons.info,
                      size: 64,
                      color: _currentStep == 4 ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Paso $_currentStep: $_popupTitle',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
                        child: const Center(child: Text('Imagen recibida')),
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
                              backgroundColor: Colors.blue.shade600,
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
