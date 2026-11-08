import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/orden.dart';
import '../providers/inventario_provider.dart';
import '../providers/orden_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/estado_chip.dart';
import '../widgets/orden_card.dart';
import '../widgets/seccion_titulo.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onIrA});

  /// Cambia de pestaña (0 inicio, 1 órdenes, 2 clientes, 3 inventario, 4 reportes).
  final void Function(int indice) onIrA;

  @override
  Widget build(BuildContext context) {
    final ordenes = context.watch<OrdenProvider>();
    final inventario = context.watch<InventarioProvider>();
    final bajoStock = inventario.bajoStock;
    final conteo = ordenes.conteoAbiertasPorEstado;
    final recientes = ordenes.abiertas.take(4).toList();

    final hoy = toBeginningOfSentenceCase(
        DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now()));

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.build_circle, color: AppColors.naranja, size: 30),
            SizedBox(width: 10),
            Text('El Pistón'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Banner principal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.naranjaOscuro, AppColors.naranja],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black45, blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hoy ?? '',
                    style: const TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  ordenes.totalAbiertas == 0
                      ? 'Sin órdenes abiertas'
                      : '${ordenes.totalAbiertas} ${ordenes.totalAbiertas == 1 ? 'orden abierta' : 'órdenes abiertas'}',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icono: Icons.assignment_outlined,
                  titulo: 'Órdenes abiertas',
                  valor: '${ordenes.totalAbiertas}',
                  onTap: () {
                    ordenes.filtrarAbiertas();
                    onIrA(1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icono: Icons.payments_outlined,
                  titulo: 'Ingresos del mes',
                  valor: Formato.moneda(ordenes.ingresosMes),
                  color: AppColors.verde,
                  onTap: () => onIrA(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icono: Icons.account_balance_wallet_outlined,
                  titulo: 'Por cobrar',
                  valor: Formato.moneda(ordenes.totalPorCobrar),
                  color: AppColors.amarillo,
                  onTap: () => onIrA(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icono: Icons.warning_amber_rounded,
                  titulo: 'Repuestos con stock bajo',
                  valor: '${bajoStock.length}',
                  color: bajoStock.isEmpty ? AppColors.verde : AppColors.rojo,
                  onTap: () => onIrA(3),
                ),
              ),
            ],
          ),

          // Órdenes por estado
          const SeccionTitulo('Órdenes abiertas por estado'),
          Card(
            child: Column(
              children: [
                for (final e in conteo.keys)
                  ListTile(
                    leading: Icon(e.icono, color: e.color),
                    title: Text(e.etiqueta),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: e.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${conteo[e]}',
                          style: TextStyle(
                              color: e.color, fontWeight: FontWeight.w700)),
                    ),
                    onTap: () {
                      ordenes.filtrarPorEstado(e);
                      onIrA(1);
                    },
                  ),
              ],
            ),
          ),

          // Alertas de stock
          SeccionTitulo(
            'Alertas de stock',
            accion: TextButton(
                onPressed: () => onIrA(3), child: const Text('Ver inventario')),
          ),
          if (bajoStock.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle_outline, color: AppColors.verde),
                title: Text('Todo el inventario está en buen nivel'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final r in bajoStock.take(5))
                    ListTile(
                      leading: Icon(
                        r.agotado ? Icons.error_outline : Icons.warning_amber,
                        color: r.agotado ? AppColors.rojo : AppColors.amarillo,
                      ),
                      title: Text(r.nombre),
                      subtitle: Text(r.codigo),
                      trailing: Text(
                        r.agotado ? 'Agotado' : '${r.existencias} uds.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              r.agotado ? AppColors.rojo : AppColors.amarillo,
                        ),
                      ),
                      onTap: () => onIrA(3),
                    ),
                ],
              ),
            ),

          // Últimas órdenes
          SeccionTitulo(
            'Órdenes abiertas recientes',
            accion: TextButton(
                onPressed: () {
                  ordenes.filtrarAbiertas();
                  onIrA(1);
                },
                child: const Text('Ver todas')),
          ),
          if (recientes.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.inbox_outlined,
                    color: AppColors.textoSecundario),
                title: Text('No hay órdenes abiertas'),
              ),
            )
          else
            for (final o in recientes) ...[
              OrdenCard(orden: o),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
