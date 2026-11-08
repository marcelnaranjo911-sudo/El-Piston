import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/repuesto.dart';

class InventarioProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Repuesto> _repuestos = [];
  bool _cargando = true;

  List<Repuesto> get repuestos => List.unmodifiable(_repuestos);
  bool get cargando => _cargando;

  /// Repuestos con existencias <= umbral, los más escasos primero.
  List<Repuesto> get bajoStock {
    final l = _repuestos.where((r) => r.stockBajo).toList();
    l.sort((a, b) => a.existencias.compareTo(b.existencias));
    return l;
  }

  Future<void> cargar() async {
    _repuestos = await _db.obtenerRepuestos();
    _cargando = false;
    notifyListeners();
  }

  Future<void> guardar(Repuesto r) async {
    if (r.id == null) {
      await _db.insertarRepuesto(r);
    } else {
      await _db.actualizarRepuesto(r);
    }
    await cargar();
  }

  Future<void> eliminar(int id) async {
    await _db.eliminarRepuesto(id);
    await cargar();
  }
}
