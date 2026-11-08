import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vehiculo.dart';
import '../providers/cliente_provider.dart';
import '../providers/orden_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/ui.dart';
import '../widgets/dialogos_formulario.dart';
import '../widgets/estado_chip.dart';
import '../widgets/seccion_titulo.dart';
import 'orden_detalle_screen.dart';
import 'orden_form_screen.dart';

/// Datos del cliente, saldo pendiente total, vehículos e historial de servicios.
class ClienteDetalleScreen extends StatelessWidget {
  const ClienteDetalleScreen({super.key, required this.clienteId});
  final int clienteId;

  Future<void> _eliminarCliente(BuildContext context) async {
    final ok = await confirmar(context,
        titulo: 'Eliminar cliente',
        mensaje: '¿Eliminar este cliente? Solo es posible si no tiene vehículos.',
        textoConfirmar: 'Eliminar');
    if (!ok || !context.mounted) return;
    final nav = Navigator.of(context);
    final exito = await ejecutar(
        context, () => context.read<ClienteProvider>().eliminarCliente(clienteId));
    if (exito) nav.pop();
  }

  Future<void> _eliminarVehiculo(BuildContext context, Vehiculo v) async {
    final ok = await confirmar(context,
        titulo: 'Eliminar vehículo',
        mensaje:
            '¿Eliminar ${v.matricula}? Solo es posible si no tiene órdenes registradas.',
        textoConfirmar: 'Eliminar');
    if (!ok || !context.mounted) return;
    await ejecutar(
        context, () => context.read<ClienteProvider>().eliminarVehiculo(v.id!));
  }

  @override
  Widget build(BuildContext context) {
    final clientes = context.watch<ClienteProvider>();
    final ordenes = context.watch<OrdenProvider>();
    final cliente = clientes.clientePorId(clienteId);

    if (cliente == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    final vehiculos = clientes.vehiculosDe(clienteId);
    final saldo = ordenes.saldoDeCliente(clienteId);
    final historial = ordenes.ordenesDeCliente(clienteId);

    return Scaffold(
      appBar: AppBar(
        title: Text(cliente.nombre),
        actions: [
          IconButton(
            tooltip: 'Editar cliente',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => mostrarDialogoCliente(context, cliente: cliente),
          ),
          IconButton(
            tooltip: 'Eliminar cliente',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _eliminarCliente(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.phone_outlined,
                        size: 18, color: AppColors.textoSecundario),
                    const SizedBox(width: 10),
                    Text(cliente.telefono),
                  ]),
                  if (cliente.direccion != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: AppColors.textoSecundario),
                      const SizedBox(width: 10),
                      Expanded(child: Text(cliente.direccion!)),
                    ]),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (saldo > 0 ? AppColors.rojo : AppColors.verde)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          saldo > 0
                              ? Icons.pending_actions
                              : Icons.check_circle_outline,
                          color: saldo > 0 ? AppColors.rojo : AppColors.verde,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            saldo > 0
                                ? 'Saldo pendiente total'
                                : 'Sin saldo pendiente',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (saldo > 0)
                          Text(Formato.moneda(saldo),
                              style: const TextStyle(
                                  color: AppColors.rojo,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --------------------------------------------------------- Vehículos
          SeccionTitulo(
            'Vehículos (${vehiculos.length})',
            accion: TextButton.icon(
              onPressed: () =>
                  mostrarDialogoVehiculo(context, clienteId: clienteId),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ),
          if (vehiculos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Este cliente aún no tiene vehículos.',
                    style: TextStyle(color: AppColors.textoSecundario)),
              ),
            )
          else
            for (final v in vehiculos) ...[
              _TarjetaVehiculo(
                vehiculo: v,
                onEditar: () => mostrarDialogoVehiculo(context,
                    clienteId: clienteId, vehiculo: v),
                onEliminar: () => _eliminarVehiculo(context, v),
              ),
              const SizedBox(height: 12),
            ],

          // --------------------------------------------- Historial del cliente
          SeccionTitulo('Historial de servicios (${historial.length})'),
          if (historial.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Todavía no hay servicios registrados.',
                    style: TextStyle(color: AppColors.textoSecundario)),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final o in historial)
                    ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                OrdenDetalleScreen(ordenId: o.id)),
                      ),
                      title: Text('#${o.id} · ${o.matricula}'),
                      subtitle: Text(
                          '${Formato.fecha(o.orden.fechaEntrada)} · ${o.orden.problema}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          EstadoChip(o.estado),
                          const SizedBox(height: 2),
                          Text(Formato.moneda(o.total),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TarjetaVehiculo extends StatelessWidget {
  const _TarjetaVehiculo({
    required this.vehiculo,
    required this.onEditar,
    required this.onEliminar,
  });

  final Vehiculo vehiculo;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final historial =
        context.watch<OrdenProvider>().ordenesDeVehiculo(vehiculo.id!);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.naranja.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car, color: AppColors.naranja),
          ),
          title: Text(vehiculo.matricula,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
              '${vehiculo.descripcion} · ${vehiculo.kilometraje} km'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              OrdenFormScreen(vehiculoId: vehiculo.id)),
                    ),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Nueva orden'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                    tooltip: 'Editar',
                    onPressed: onEditar,
                    icon: const Icon(Icons.edit_outlined)),
                IconButton(
                    tooltip: 'Eliminar',
                    onPressed: onEliminar,
                    icon: const Icon(Icons.delete_outline)),
              ],
            ),
            const SizedBox(height: 8),
            if (historial.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Sin visitas registradas.',
                    style: TextStyle(color: AppColors.textoSecundario)),
              )
            else
              for (final o in historial)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => OrdenDetalleScreen(ordenId: o.id)),
                  ),
                  title: Text(
                      '${Formato.fecha(o.orden.fechaEntrada)} · ${o.orden.kilometraje} km'),
                  subtitle: Text(o.orden.problema,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: EstadoChip(o.estado),
                ),
          ],
        ),
      ),
    );
  }
}
