import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'detalle_elemento_screen.dart';
import 'models/elemento.dart';

class DayDetailScreen extends StatefulWidget {
  final String date;
  final List<Elemento> dayElementos;

  const DayDetailScreen({
    super.key,
    required this.date,
    required this.dayElementos,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, int> _getTamanoCounts() {
    Map<String, int> counts = {'pequeño': 0, 'mediano': 0, 'grande': 0};
    for (var elemento in widget.dayElementos) {
      String tamano = elemento.tamano.toLowerCase();
      if (counts.containsKey(tamano)) {
        counts[tamano] = counts[tamano]! + 1;
      }
    }
    return counts;
  }

  List<PieChartSectionData> _getPieSections() {
    Map<String, int> counts = _getTamanoCounts();
    List<Color> colors = [Colors.green, Colors.yellow, Colors.red];
    List<String> labels = ['pequeño', 'mediano', 'grande'];

    return List.generate(3, (index) {
      String label = labels[index];
      int count = counts[label] ?? 0;
      double percentage = widget.dayElementos.isNotEmpty
          ? (count / widget.dayElementos.length) * 100
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Datos del ${widget.date}'),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pequeños'),
            Tab(text: 'Medianos'),
            Tab(text: 'Grandes'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.3)),
          child: SafeArea(
            child: widget.dayElementos.isEmpty
                ? const Center(
                    child: Text(
                      'No hay elementos para este día',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : Column(
                    children: [
                      // Gráfica
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white.withOpacity(0.9),
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Text(
                                'Distribución por Tamaño - ${widget.date}',
                                style: const TextStyle(
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
                      // Tabs
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _SizeSection(
                              size: 'pequeño',
                              elementos: widget.dayElementos
                                  .where(
                                    (e) => e.tamano.toLowerCase() == 'pequeño',
                                  )
                                  .toList(),
                            ),
                            _SizeSection(
                              size: 'mediano',
                              elementos: widget.dayElementos
                                  .where(
                                    (e) => e.tamano.toLowerCase() == 'mediano',
                                  )
                                  .toList(),
                            ),
                            _SizeSection(
                              size: 'grande',
                              elementos: widget.dayElementos
                                  .where(
                                    (e) => e.tamano.toLowerCase() == 'grande',
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SizeSection extends StatefulWidget {
  final String size;
  final List<Elemento> elementos;

  const _SizeSection({required this.size, required this.elementos});

  @override
  State<_SizeSection> createState() => _SizeSectionState();
}

class _SizeSectionState extends State<_SizeSection> {
  List<Elemento> _filteredElementos = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredElementos = widget.elementos;
    _searchController.addListener(_filterElementos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterElementos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredElementos = widget.elementos.where((elemento) {
        return elemento.id.toLowerCase().contains(query) ||
            elemento.hora.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por ID o hora...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Lista
        Expanded(
          child: _filteredElementos.isEmpty
              ? Center(
                  child: Text(
                    'No hay ${widget.size}s registrados',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredElementos.length,
                  itemBuilder: (context, index) {
                    final elemento = _filteredElementos[index];
                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white.withOpacity(0.9),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: elemento.imagenBase64.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(elemento.imagenBase64),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                ),
                              ),
                        title: Text(
                          'ID: ${elemento.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Timestamp: ${elemento.timestamp.isNotEmpty ? elemento.timestamp : '${elemento.fecha} ${elemento.hora}'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Área: ${elemento.area}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalleElementoScreen(elemento: elemento),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
