import 'package:flutter/material.dart';

class SeccionTitulo extends StatelessWidget {
  const SeccionTitulo(this.titulo, {super.key, this.accion});
  final String titulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          if (accion != null) accion!,
        ],
      ),
    );
  }
}
