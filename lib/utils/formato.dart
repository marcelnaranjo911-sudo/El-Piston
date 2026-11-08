import 'package:intl/intl.dart';

/// Formatos de moneda y fecha usados en toda la app.
class Formato {
  Formato._();

  static final NumberFormat _moneda =
      NumberFormat.currency(locale: 'es', symbol: '\$', decimalDigits: 2);
  static final DateFormat _fecha = DateFormat('dd/MM/yyyy');
  static final DateFormat _fechaHora = DateFormat('dd/MM/yyyy HH:mm');

  static String moneda(num valor) => _moneda.format(valor);
  static String fecha(DateTime d) => _fecha.format(d);
  static String fechaHora(DateTime d) => _fechaHora.format(d);
}
