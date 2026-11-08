import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
  });
  final IconData icono;
  final String titulo;
  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: AppColors.superficieAlta),
            const SizedBox(height: 12),
            Text(titulo,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (mensaje != null) ...[
              const SizedBox(height: 6),
              Text(mensaje!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textoSecundario)),
            ],
          ],
        ),
      ),
    );
  }
}
