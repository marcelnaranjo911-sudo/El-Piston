import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta de resumen (número grande + título) para el dashboard y reportes.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    this.color = AppColors.naranja,
    this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String valor;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  valor,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titulo,
                style: const TextStyle(
                    color: AppColors.textoSecundario, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
