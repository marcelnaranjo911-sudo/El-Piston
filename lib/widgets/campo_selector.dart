import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Lista desplegable con el mismo aspecto que los campos de texto.
class CampoSelector<T> extends StatelessWidget {
  const CampoSelector({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.items,
    required this.onChanged,
    this.icono,
  });

  final String etiqueta;
  final T? valor;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      isEmpty: valor == null,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: icono == null ? null : Icon(icono),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: valor,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.superficieAlta,
          borderRadius: BorderRadius.circular(14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
