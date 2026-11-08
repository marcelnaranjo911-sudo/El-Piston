import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/orden.dart';
import '../providers/orden_provider.dart';
import '../utils/ui.dart';
import '../widgets/estado_chip.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/orden_card.dart';
import 'orden_form_screen.dart';

class OrdenesScreen extends StatelessWidget {
  const OrdenesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrdenProvider>();
    final lista = prov.ordenesFiltradas;

    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes de servicio')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OrdenFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva orden'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _chip(
                  'Abiertas (${prov.totalAbiertas})',
                  prov.filtroAbiertas,
                  prov.filtrarAbiertas,
                ),
                _chip('Todas (${prov.todas.length})', prov.filtroTodas,
                    prov.filtrarTodas),
                for (final e in EstadoOrden.values)
                  _chip(
                    e.etiqueta,
                    prov.filtroEstado == e,
                    () => prov.filtrarPorEstado(e),
                  ),
              ],
            ),
          ),
          Expanded(
            child: prov.cargando
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.assignment_outlined,
                        titulo: 'No hay órdenes en esta vista',
                        mensaje: 'Crea una nueva con el botón "Nueva orden".',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: lista.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final o = lista[i];
                          return OrdenCard(
                            orden: o,
                            trailing: MenuEstado(
                              actual: o.estado,
                              onSeleccion: (e) =>
                                  cambiarEstadoOrden(context, o, e),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String texto, bool seleccionado, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: seleccionado,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
