import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'size_list_screen.dart';
import 'models/elemento.dart';
import 'services/api_service.dart';

class GraficaScreen extends StatefulWidget {
  const GraficaScreen({super.key});

  @override
  State<GraficaScreen> createState() => _GraficaScreenState();
}

class _GraficaScreenState extends State<GraficaScreen> {
  List<Elemento> _elementos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadElementos();
  }

  Future<void> _loadElementos() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final elementos = await ApiService.getElementos();

      setState(() {
        _elementos = elementos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, int> _getTamanoCounts() {
    Map<String, int> counts = {'pequeño': 0, 'mediano': 0, 'grande': 0};
    for (var elemento in _elementos) {
      String tamano = elemento.tamano.toLowerCase();
      if (counts.containsKey(tamano)) {
        counts[tamano] = counts[tamano]! + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas Generales'),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Card(
                      color: Colors.red.shade50.withOpacity(0.9),
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
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
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Gráfica general
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white.withOpacity(0.9),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Distribución General por Tamaño',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _getPieSections(),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ..._getLegend(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Widgets por tamaño
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 1,
                            mainAxisSpacing: 16,
                            childAspectRatio: 3,
                            children: [
                              _buildSizeCard(
                                'Pequeño',
                                'pequeño',
                                Colors.green,
                              ),
                              _buildSizeCard(
                                'Mediano',
                                'mediano',
                                Colors.yellow.shade700,
                              ),
                              _buildSizeCard('Grande', 'grande', Colors.red),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeCard(String displayName, String sizeKey, Color color) {
    int count = _getTamanoCounts()[sizeKey] ?? 0;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color.withOpacity(0.9),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  SizeListScreen(size: sizeKey, allElementos: _elementos),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Limón $displayName',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$count registrados',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieSections() {
    Map<String, int> counts = _getTamanoCounts();
    List<Color> colors = [Colors.green, Colors.yellow, Colors.red];
    List<String> labels = ['pequeño', 'mediano', 'grande'];

    return List.generate(3, (index) {
      String label = labels[index];
      int count = counts[label] ?? 0;
      double percentage = _elementos.isNotEmpty
          ? (count / _elementos.length) * 100
          : 0;

      return PieChartSectionData(
        color: colors[index],
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  List<Widget> _getLegend() {
    Map<String, int> counts = _getTamanoCounts();
    List<Color> colors = [Colors.green, Colors.yellow, Colors.red];
    List<String> labels = ['Pequeño', 'Mediano', 'Grande'];

    return List.generate(3, (index) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 16, height: 16, color: colors[index]),
          const SizedBox(width: 8),
          Text(
            '${labels[index]}: ${counts[labels[index].toLowerCase()] ?? 0}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      );
    });
  }
}
