import 'package:flutter/material.dart';

import '../models/orden.dart';
import '../screens/orden_detalle_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import 'estado_chip.dart';

/// Tarjeta de una orden de servicio; al tocarla abre su detalle.
class OrdenCard extends StatelessWidget {
  const OrdenCard({super.key, required this.orden, this.trailing});

  final OrdenResumen orden;
  final Widget? trailing;

  Widget _dato(IconData icono, String texto) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: AppColors.textoSecundario),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textoSecundario, fontSize: 12),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final cancelada = orden.estado == EstadoOrden.cancelada;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => OrdenDetalleScreen(ordenId: orden.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.naranja.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_car,
                        color: AppColors.naranja),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${orden.id} · ${orden.matricula}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          orden.vehiculo,
                          style: const TextStyle(
                              color: AppColors.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 10),
              Text(
                orden.orden.problema,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _dato(Icons.person_outline, orden.clienteNombre),
                  _dato(Icons.engineering_outlined, orden.mecanicoNombre),
                  _dato(Icons.calendar_today_outlined,
                      Formato.fecha(orden.orden.fechaEntrada)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  EstadoChip(orden.estado),
                  if (!cancelada)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formato.moneda(orden.total),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          orden.tieneSaldo
                              ? 'Saldo ${Formato.moneda(orden.saldo)}'
                              : (orden.total > 0 ? 'Pagada' : 'Sin cargos'),
                          style: TextStyle(
                            fontSize: 12,
                            color: orden.tieneSaldo
                                ? AppColors.rojo
                                : AppColors.verde,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
