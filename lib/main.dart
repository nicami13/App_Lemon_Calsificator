import 'package:flutter/material.dart';
import 'bluetooth_screen.dart';
import 'grafica_screen.dart';
import 'day_detail_screen.dart';
import 'models/elemento.dart';
import 'services/api_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lemon Clasificator Cinta',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF6D600),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F3C8),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.88),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFF0C400), width: 1.2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF6D600),
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.92),
          prefixIconColor: Colors.black54,
          hintStyle: const TextStyle(color: Colors.black45),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const ListaScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ListaScreen extends StatefulWidget {
  const ListaScreen({super.key});

  @override
  State<ListaScreen> createState() => _ListaScreenState();
}

class _ListaScreenState extends State<ListaScreen> {
  Map<String, List<Elemento>> _groupedElementos = {};
  List<String> _dates = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadElementos();
    _searchController.addListener(_filterDates);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadElementos() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final elementos = await ApiService.getElementos();

      // Group by fecha
      Map<String, List<Elemento>> grouped = {};
      for (var elemento in elementos) {
        String date = elemento.fecha;
        if (!grouped.containsKey(date)) {
          grouped[date] = [];
        }
        grouped[date]!.add(elemento);
      }

      setState(() {
        _groupedElementos = grouped;
        _dates = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // Sort descending
        _filterDates();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterDates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _dates =
          _groupedElementos.keys.where((date) => date.contains(query)).toList()
            ..sort((a, b) => b.compareTo(a));
    });
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Card(
          color: Colors.red.shade50.withOpacity(0.9),
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar datos:\n$_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadElementos,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadElementos,
      child: _dates.isEmpty
          ? const Center(
              child: Text(
                'No hay días registrados',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _dates.length,
              itemBuilder: (context, index) {
                final date = _dates[index];
                final dayElementos = _groupedElementos[date]!;
                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.white.withOpacity(0.9),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      date,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    subtitle: Text(
                      '${dayElementos.length} limones registrados',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.blue,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DayDetailScreen(
                            date: date,
                            dayElementos: dayElementos,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset('images/logo.png', fit: BoxFit.contain),
        ),
        title: const Text('Lemon Clasificator Cinta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF6D600), Color(0xFFF4D03F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            image: DecorationImage(
              image: AssetImage('images/logo.png'),
              fit: BoxFit.contain,
              opacity: 0.12,
              alignment: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BluetoothScreen(),
                ),
              );
            },
            tooltip: 'Control Bluetooth',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const GraficaScreen()),
              );
            },
            tooltip: 'Ver estadísticas generales',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por fecha...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withOpacity(0.95),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('images/fondo.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.28)),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(
                'images/logo.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Lista de elementos
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
