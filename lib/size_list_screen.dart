import 'dart:convert';
import 'package:flutter/material.dart';
import 'detalle_elemento_screen.dart';
import 'models/elemento.dart';

class SizeListScreen extends StatefulWidget {
  final String size;
  final List<Elemento> allElementos;

  const SizeListScreen({
    super.key,
    required this.size,
    required this.allElementos,
  });

  @override
  State<SizeListScreen> createState() => _SizeListScreenState();
}

class _SizeListScreenState extends State<SizeListScreen> {
  List<Elemento> _filteredElementos = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredElementos = widget.allElementos
        .where((e) => e.tamano.toLowerCase() == widget.size.toLowerCase())
        .toList();
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
      _filteredElementos = widget.allElementos
          .where((e) => e.tamano.toLowerCase() == widget.size.toLowerCase())
          .where((elemento) {
            return elemento.id.toLowerCase().contains(query) ||
                elemento.hora.contains(query);
          })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Limones ${widget.size}s'),
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
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
            child: Column(
              children: [
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                            'No hay limones ${widget.size}s registrados',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                      'Fecha: ${elemento.fecha} • Hora: ${elemento.hora}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
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
                                          DetalleElementoScreen(
                                            elemento: elemento,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
