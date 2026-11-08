import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/orden.dart';
import '../providers/orden_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogos_formulario.dart';

/// Convierte una excepción en un mensaje entendible para el usuario.
String mensajeDeError(Object e) {
  if (e is StateError) return e.message;
  final t = e.toString();
  if (t.contains('UNIQUE')) {
    return 'Ya existe un registro con ese código o matrícula.';
  }
  if (t.contains('FOREIGN KEY')) {
    return 'No se puede completar: hay registros asociados (por ejemplo, órdenes).';
  }
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}

void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(texto),
      backgroundColor: error ? AppColors.rojo : AppColors.superficieAlta,
    ),
  );
}

/// Ejecuta una acción y muestra un mensaje si falla (o si se indica, si sale bien).
/// Devuelve true si la acción terminó sin errores.
Future<bool> ejecutar(
  BuildContext context,
  Future<void> Function() accion, {
  String? exito,
}) async {
  try {
    await accion();
    if (exito != null && context.mounted) mostrarMensaje(context, exito);
    return true;
  } catch (e) {
    if (context.mounted) mostrarMensaje(context, mensajeDeError(e), error: true);
    return false;
  }
}

double? parseMonto(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

String? validarRequerido(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

String? validarEntero(String? v, {int min = 0, int? max}) {
  final n = int.tryParse((v ?? '').trim());
  if (n == null) return 'Ingresa un número entero';
  if (n < min) return 'Debe ser mayor o igual a $min';
  if (max != null && n > max) return 'Debe ser menor o igual a $max';
  return null;
}

String? validarMonto(String? v, {bool permitirCero = false}) {
  final n = parseMonto(v ?? '');
  if (n == null) return 'Ingresa un monto válido';
  if (n < 0 || (!permitirCero && n == 0)) return 'Debe ser mayor que cero';
  return null;
}

/// Cambia el estado de una orden (pide confirmación al cancelar).
Future<void> cambiarEstadoOrden(
  BuildContext context,
  OrdenResumen orden,
  EstadoOrden nuevo,
) async {
  if (nuevo == orden.estado) return;
  if (nuevo == EstadoOrden.cancelada) {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar orden',
      mensaje:
          'La orden #${orden.id} quedará cancelada y los repuestos usados volverán al inventario. Esta acción no se puede deshacer.',
      textoConfirmar: 'Cancelar orden',
    );
    if (!ok) return;
  }
  if (!context.mounted) return;
  await ejecutar(
    context,
    () => context.read<OrdenProvider>().cambiarEstado(orden.id, nuevo),
    exito: 'Estado: ${nuevo.etiqueta}',
  );
}
