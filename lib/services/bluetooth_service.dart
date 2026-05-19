import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  StreamSubscription? _inputSubscription;
  bool _isConnected = false;
  StreamController<String>? _dataController;
  StreamController<bool>? _connectionController;

  Stream<String> get dataStream {
    _dataController ??= StreamController<String>.broadcast();
    return _dataController!.stream;
  }

  Stream<bool> get connectionStream {
    _connectionController ??= StreamController<bool>.broadcast();
    return _connectionController!.stream;
  }

  bool get isConnected => _isConnected;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  void _ensureControllersOpen() {
    if (_dataController == null || _dataController!.isClosed) {
      _dataController = StreamController<String>.broadcast();
    }
    if (_connectionController == null || _connectionController!.isClosed) {
      _connectionController = StreamController<bool>.broadcast();
    }
  }

  Future<bool> isBluetoothAvailable() async {
    return await FlutterBluetoothSerial.instance.isAvailable == true;
  }

  Future<bool> isBluetoothEnabled() async {
    return await FlutterBluetoothSerial.instance.isEnabled == true;
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print('=== INICIANDO CONEXIÓN ===');

      // Desconectar primero si hay conexión previa
      await disconnect();
      await Future.delayed(const Duration(milliseconds: 1000));

      // RECREAR los controllers completamente para evitar "closed" errors
      print('Recreando StreamControllers...');
      if (_dataController != null && !_dataController!.isClosed) {
        await _dataController!.close();
      }
      if (_connectionController != null && !_connectionController!.isClosed) {
        await _connectionController!.close();
      }
      _dataController = StreamController<String>.broadcast();
      _connectionController = StreamController<bool>.broadcast();
      print('StreamControllers recreados exitosamente');

      print('Intentando conectar a ${device.name} (${device.address})');

      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;
      _isConnected = true;

      // Verificar que el controller esté abierto antes de agregar
      if (_connectionController != null && !_connectionController!.isClosed) {
        _connectionController!.add(true);
      }
      print('Conectado exitosamente');

      _inputSubscription = _connection!.input!.listen(
        (data) {
          String received = String.fromCharCodes(data);
          print('Datos recibidos: $received');
          if (_dataController != null && !_dataController!.isClosed) {
            _dataController!.add(received);
          }
        },
        onError: (error) {
          print('Error en stream: $error');
          disconnect();
        },
        onDone: () {
          print('Stream terminado');
          disconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('Error al conectar: $e');
      _isConnected = false;
      if (_connectionController != null && !_connectionController!.isClosed) {
        _connectionController!.add(false);
      }
      rethrow;
    }
  }

  void sendData(String data) {
    if (_connection != null && _isConnected) {
      _connection!.output.add(utf8.encode(data + '\n'));
      _connection!.output.allSent;
    }
  }

  Future<void> disconnect() async {
    print('=== INICIANDO DESCONEXIÓN ===');

    // Cancelar la suscripción del stream
    if (_inputSubscription != null) {
      await _inputSubscription!.cancel();
      _inputSubscription = null;
      print('Suscripción cancelada');
    }

    // Cerrar la conexión
    if (_connection != null) {
      try {
        await _connection!.close();
        _connection!.dispose();
        print('Conexión cerrada y dispose completado');
      } catch (e) {
        print('Error al cerrar conexión: $e');
      }
      _connection = null;
    }

    _isConnected = false;
    _connectedDevice = null;

    // NO cerrar los controllers aquí - solo enviar evento
    if (_connectionController != null && !_connectionController!.isClosed) {
      _connectionController!.add(false);
    }
    print('=== DESCONEXIÓN COMPLETADA ===');
  }

  Future<void> forceCleanup() async {
    print('=== FORZANDO LIMPIEZA ===');
    await disconnect();

    // Esperar para asegurar que el Bluetooth del sistema se libere
    await Future.delayed(const Duration(milliseconds: 1500));
    print('Limpieza completada');
  }

  void dispose() {
    disconnect();
    _dataController?.close();
    _connectionController?.close();
  }
}
