import 'package:flutter/material.dart';

import '../models/orden.dart';
import '../theme/app_theme.dart';

/// Color e ícono de cada estado de orden.
extension EstadoOrdenUi on EstadoOrden {
  Color get color {
    switch (this) {
      case EstadoOrden.recibida:
        return AppColors.azul;
      case EstadoOrden.enDiagnostico:
        return AppColors.amarillo;
      case EstadoOrden.enReparacion:
        return AppColors.naranja;
      case EstadoOrden.listaParaEntregar:
        return const Color(0xFF9CCC65);
      case EstadoOrden.entregada:
        return AppColors.verde;
      case EstadoOrden.cancelada:
        return AppColors.rojo;
    }
  }

  IconData get icono {
    switch (this) {
      case EstadoOrden.recibida:
        return Icons.inbox_outlined;
      case EstadoOrden.enDiagnostico:
        return Icons.search;
      case EstadoOrden.enReparacion:
        return Icons.build_outlined;
      case EstadoOrden.listaParaEntregar:
        return Icons.task_alt;
      case EstadoOrden.entregada:
        return Icons.verified_outlined;
      case EstadoOrden.cancelada:
        return Icons.cancel_outlined;
    }
  }
}

class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key});
  final EstadoOrden estado;

  @override
  Widget build(BuildContext context) {
    final c = estado.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estado.icono, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            estado.etiqueta,
            style: TextStyle(
                color: c, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Menú para cambiar el estado de una orden rápidamente.
class MenuEstado extends StatelessWidget {
  const MenuEstado({super.key, required this.actual, required this.onSeleccion});
  final EstadoOrden actual;
  final ValueChanged<EstadoOrden> onSeleccion;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EstadoOrden>(
      tooltip: 'Cambiar estado',
      icon: const Icon(Icons.swap_horiz),
      enabled: actual != EstadoOrden.cancelada,
      color: AppColors.superficieAlta,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onSeleccion,
      itemBuilder: (_) => EstadoOrden.values
          .where((e) => e != actual)
          .map(
            (e) => PopupMenuItem<EstadoOrden>(
              value: e,
              child: Row(
                children: [
                  Icon(e.icono, color: e.color, size: 20),
                  const SizedBox(width: 10),
                  Text(e.etiqueta),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
