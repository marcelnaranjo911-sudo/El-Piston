import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cliente_provider.dart';
import '../providers/orden_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/dialogos_formulario.dart';
import '../widgets/estado_vacio.dart';
import 'cliente_detalle_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  String _busqueda = '';

  void _abrirDetalle(int id) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ClienteDetalleScreen(clienteId: id)),
      );

  Future<void> _nuevoCliente() async {
    final id = await mostrarDialogoCliente(context);
    if (id != null && mounted) _abrirDetalle(id);
  }

  @override
  Widget build(BuildContext context) {
    final clientes = context.watch<ClienteProvider>();
    final ordenes = context.watch<OrdenProvider>();
    final saldos = ordenes.saldosPorCliente;

    final q = _busqueda.trim().toLowerCase();
    final lista = clientes.clientes.where((c) {
      if (q.isEmpty) return true;
      final placas = clientes
          .vehiculosDe(c.id!)
          .map((v) => v.matricula.toLowerCase())
          .join(' ');
      return c.nombre.toLowerCase().contains(q) ||
          c.telefono.contains(q) ||
          placas.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes y vehículos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoCliente,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo cliente'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre, teléfono o matrícula',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: clientes.cargando
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.people_outline,
                        titulo: 'No hay clientes para mostrar',
                        mensaje: 'Registra uno con el botón "Nuevo cliente".',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: lista.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final c = lista[i];
                          final vehiculos = clientes.vehiculosDe(c.id!);
                          final saldo = saldos[c.id] ?? 0;
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _abrirDetalle(c.id!),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.naranja
                                          .withValues(alpha: 0.18),
                                      child: Text(
                                        c.nombre.isEmpty
                                            ? '?'
                                            : c.nombre[0].toUpperCase(),
                                        style: const TextStyle(
                                            color: AppColors.naranja,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(c.nombre,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text(c.telefono,
                                              style: const TextStyle(
                                                  color: AppColors
                                                      .textoSecundario)),
                                          const SizedBox(height: 2),
                                          Text(
                                            vehiculos.isEmpty
                                                ? 'Sin vehículos'
                                                : vehiculos
                                                    .map((v) => v.matricula)
                                                    .join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color:
                                                    AppColors.textoSecundario,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (saldo > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.rojo
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text('Debe',
                                                style: TextStyle(
                                                    color: AppColors.rojo,
                                                    fontSize: 11)),
                                            Text(Formato.moneda(saldo),
                                                style: const TextStyle(
                                                    color: AppColors.rojo,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                          ],
                                        ),
                                      )
                                    else
                                      const Icon(Icons.chevron_right,
                                          color: AppColors.textoSecundario),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
