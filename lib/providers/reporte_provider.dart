import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/reportes.dart';

/// Reportes por rango de fechas (facturación y carga de trabajo por mecánico).
class ReporteProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  DateTime _desde = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _hasta = DateTime.now();
  ResumenPeriodo? _resumen;
  List<CargaMecanico> _carga = [];
  bool _cargando = false;

  DateTime get desde => _desde;
  DateTime get hasta => _hasta;
  ResumenPeriodo? get resumen => _resumen;
  List<CargaMecanico> get carga => _carga;
  bool get cargando => _cargando;

  Future<void> establecerRango(DateTime desde, DateTime hasta) async {
    _desde = DateTime(desde.year, desde.month, desde.day);
    _hasta = DateTime(hasta.year, hasta.month, hasta.day);
    await cargar();
  }

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    final ini = DateTime(_desde.year, _desde.month, _desde.day);
    final fin =
        DateTime(_hasta.year, _hasta.month, _hasta.day, 23, 59, 59, 999);
    _resumen = await _db.totalesPeriodo(ini, fin);
    _carga = await _db.cargaPorMecanico(ini, fin);
    _cargando = false;
    notifyListeners();
  }
}
