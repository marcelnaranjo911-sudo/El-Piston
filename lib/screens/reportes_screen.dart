import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cliente_provider.dart';
import '../providers/inventario_provider.dart';
import '../providers/orden_provider.dart';
import '../providers/reporte_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/estado_chip.dart';
import '../widgets/seccion_titulo.dart';
import '../widgets/stat_card.dart';
import 'cliente_detalle_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReporteProvider>().cargar();
    });
  }

  Future<void> _elegirRango() async {
    final rep = context.read<ReporteProvider>();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: rep.desde, end: rep.hasta),
      helpText: 'Período del reporte',
      saveText: 'Aplicar',
    );
    if (r != null && mounted) rep.establecerRango(r.start, r.end);
  }

  void _atajo(DateTime desde, DateTime hasta) =>
      context.read<ReporteProvider>().establecerRango(desde, hasta);

  @override
  Widget build(BuildContext context) {
    final rep = context.watch<ReporteProvider>();
    final ordenes = context.watch<OrdenProvider>();
    final clientes = context.watch<ClienteProvider>();
    final inventario = context.watch<InventarioProvider>();

    final hoy = DateTime.now();
    final conteo = ordenes.conteoAbiertasPorEstado;
    final totalAbiertas = ordenes.totalAbiertas;
    final deudores = ordenes.saldosPorCliente.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxAbiertas = rep.carga.fold<int>(
        0, (m, c) => c.abiertas > m ? c.abiertas : m);
    final bajoStock = inventario.bajoStock;
    final resumen = rep.resumen;

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // --------------------------------------------------------- Período
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _elegirRango,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: AppColors.naranja),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Período',
                              style: TextStyle(
                                  color: AppColors.textoSecundario,
                                  fontSize: 12)),
                          Text(
                            '${Formato.fecha(rep.desde)}  –  ${Formato.fecha(rep.hasta)}',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_outlined,
                        color: AppColors.textoSecundario),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _atajoChip('Hoy', () => _atajo(hoy, hoy)),
                _atajoChip(
                    'Últimos 7 días',
                    () => _atajo(
                        hoy.subtract(const Duration(days: 6)), hoy)),
                _atajoChip('Este mes',
                    () => _atajo(DateTime(hoy.year, hoy.month, 1), hoy)),
                _atajoChip(
                    'Últimos 30 días',
                    () => _atajo(
                        hoy.subtract(const Duration(days: 29)), hoy)),
                _atajoChip('Este año',
                    () => _atajo(DateTime(hoy.year, 1, 1), hoy)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ------------------------------------------------------ Facturación
          if (resumen == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icono: Icons.receipt_long_outlined,
                    titulo: 'Facturado',
                    valor: Formato.moneda(resumen.facturado),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icono: Icons.payments_outlined,
                    titulo: 'Cobrado',
                    valor: Formato.moneda(resumen.cobrado),
                    color: AppColors.verde,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${resumen.ordenes} ${resumen.ordenes == 1 ? 'orden ingresada' : 'órdenes ingresadas'} en el período (sin canceladas). '
              'Facturado = total de esas órdenes; cobrado = pagos recibidos en esas fechas.',
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 12),
            ),
          ],

          // ------------------------------------------- Órdenes abiertas/estado
          const SeccionTitulo('Órdenes abiertas por estado'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final e in conteo.keys)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(e.icono, color: e.color, size: 20),
                          const SizedBox(width: 10),
                          SizedBox(
                              width: 130,
                              child: Text(e.etiqueta,
                                  overflow: TextOverflow.ellipsis)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: totalAbiertas == 0
                                    ? 0
                                    : conteo[e]! / totalAbiertas,
                                color: e.color,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text('${conteo[e]}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------ Carga por mecánico
          const SeccionTitulo('Carga de trabajo por mecánico'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (rep.carga.isEmpty)
                    const Text('Sin datos',
                        style: TextStyle(color: AppColors.textoSecundario)),
                  for (final c in rep.carga)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.engineering_outlined,
                                  color: AppColors.naranja, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(c.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                              Text(
                                '${c.abiertas} ${c.abiertas == 1 ? 'abierta' : 'abiertas'}',
                                style: const TextStyle(
                                    color: AppColors.naranja,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: maxAbiertas == 0
                                  ? 0
                                  : c.abiertas / maxAbiertas,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'En el período: ${c.enPeriodo} ${c.enPeriodo == 1 ? 'orden' : 'órdenes'} · ${Formato.moneda(c.facturado)} facturados',
                            style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ------------------------------------------------- Cuentas por cobrar
          SeccionTitulo(
            'Cuentas por cobrar',
            accion: Text(
              Formato.moneda(ordenes.totalPorCobrar),
              style: const TextStyle(
                  color: AppColors.rojo,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
            ),
          ),
          if (deudores.isEmpty)
            const Card(
              child: ListTile(
                leading:
                    Icon(Icons.check_circle_outline, color: AppColors.verde),
                title: Text('Nadie tiene saldo pendiente'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final d in deudores)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                          clientes.clientePorId(d.key)?.nombre ?? 'Cliente'),
                      subtitle: Text(
                          '${ordenes.ordenesConSaldo.where((o) => o.clienteId == d.key).length} orden(es) con saldo'),
                      trailing: Text(Formato.moneda(d.value),
                          style: const TextStyle(
                              color: AppColors.rojo,
                              fontWeight: FontWeight.w800)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                ClienteDetalleScreen(clienteId: d.key)),
                      ),
                    ),
                ],
              ),
            ),

          // ------------------------------------------- Repuestos por agotarse
          const SeccionTitulo('Repuestos por agotarse'),
          if (bajoStock.isEmpty)
            const Card(
              child: ListTile(
                leading:
                    Icon(Icons.check_circle_outline, color: AppColors.verde),
                title: Text('Ningún repuesto con stock bajo'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final r in bajoStock)
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
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _atajoChip(String texto, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(label: Text(texto), onPressed: onTap),
      );
}
