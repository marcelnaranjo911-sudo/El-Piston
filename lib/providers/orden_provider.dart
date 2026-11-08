import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/mecanico.dart';
import '../models/orden.dart';
import '../models/pago.dart';
import '../models/trabajo.dart';
import '../utils/formato.dart';
import 'cliente_provider.dart';
import 'inventario_provider.dart';

/// Lógica de negocio de las órdenes: estados, mano de obra, repuestos y pagos.
class OrdenProvider extends ChangeNotifier {
  OrdenProvider(this._inventario, this._clientes);

  final InventarioProvider _inventario;
  final ClienteProvider _clientes;
  final _db = DatabaseHelper.instance;

  List<OrdenResumen> _ordenes = [];
  List<Mecanico> _mecanicos = [];
  OrdenDetalle? _detalle;
  double _ingresosMes = 0;
  bool _cargando = true;

  // Filtro de la lista de órdenes.
  bool _soloAbiertas = true;
  EstadoOrden? _estadoFiltro;

  // ------------------------------------------------------------- Consultas
  bool get cargando => _cargando;
  List<OrdenResumen> get todas => List.unmodifiable(_ordenes);
  List<Mecanico> get mecanicos => List.unmodifiable(_mecanicos);
  OrdenDetalle? get detalle => _detalle;

  /// Pagos recibidos en el mes en curso.
  double get ingresosMes => _ingresosMes;

  List<OrdenResumen> get abiertas =>
      _ordenes.where((o) => o.estado.abierta).toList();
  int get totalAbiertas => abiertas.length;

  Map<EstadoOrden, int> get conteoAbiertasPorEstado {
    final m = {
      for (final e in EstadoOrden.values.where((e) => e.abierta)) e: 0,
    };
    for (final o in _ordenes) {
      if (o.estado.abierta) m[o.estado] = (m[o.estado] ?? 0) + 1;
    }
    return m;
  }

  // Cuentas por cobrar
  List<OrdenResumen> get ordenesConSaldo =>
      _ordenes.where((o) => o.tieneSaldo).toList();
  double get totalPorCobrar =>
      _ordenes.fold(0.0, (suma, o) => suma + o.saldo);

  Map<int, double> get saldosPorCliente {
    final m = <int, double>{};
    for (final o in _ordenes) {
      if (o.tieneSaldo) m[o.clienteId] = (m[o.clienteId] ?? 0) + o.saldo;
    }
    return m;
  }

  double saldoDeCliente(int clienteId) => saldosPorCliente[clienteId] ?? 0;

  List<OrdenResumen> ordenesDeCliente(int clienteId) =>
      _ordenes.where((o) => o.clienteId == clienteId).toList();

  List<OrdenResumen> ordenesDeVehiculo(int vehiculoId) =>
      _ordenes.where((o) => o.orden.vehiculoId == vehiculoId).toList();

  /// Mecánico con menos órdenes abiertas (para sugerirlo al crear una orden).
  int? mecanicoMenosCargado() {
    if (_mecanicos.isEmpty) return null;
    Mecanico mejor = _mecanicos.first;
    var menor = 1 << 30;
    for (final m in _mecanicos) {
      final n = _ordenes
          .where((o) => o.orden.mecanicoId == m.id && o.estado.abierta)
          .length;
      if (n < menor) {
        menor = n;
        mejor = m;
      }
    }
    return mejor.id;
  }

  // ---------------------------------------------------------------- Filtro
  bool get filtroAbiertas => _soloAbiertas && _estadoFiltro == null;
  bool get filtroTodas => !_soloAbiertas && _estadoFiltro == null;
  EstadoOrden? get filtroEstado => _estadoFiltro;

  void filtrarAbiertas() {
    _soloAbiertas = true;
    _estadoFiltro = null;
    notifyListeners();
  }

  void filtrarTodas() {
    _soloAbiertas = false;
    _estadoFiltro = null;
    notifyListeners();
  }

  void filtrarPorEstado(EstadoOrden estado) {
    _soloAbiertas = false;
    _estadoFiltro = estado;
    notifyListeners();
  }

  List<OrdenResumen> get ordenesFiltradas {
    if (_estadoFiltro != null) {
      return _ordenes.where((o) => o.estado == _estadoFiltro).toList();
    }
    return _soloAbiertas ? abiertas : todas;
  }

  // ----------------------------------------------------------------- Carga
  Future<void> cargar() async {
    _mecanicos = await _db.obtenerMecanicos();
    await _recargarOrdenes();
    _cargando = false;
    notifyListeners();
  }

  Future<void> _recargarOrdenes() async {
    _ordenes = await _db.obtenerOrdenesResumen();
    final ahora = DateTime.now();
    final inicio = DateTime(ahora.year, ahora.month, 1);
    final fin = DateTime(ahora.year, ahora.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
    _ingresosMes = (await _db.totalesPeriodo(inicio, fin)).cobrado;
  }

  Future<void> cargarDetalle(int ordenId) async {
    _detalle = await _db.obtenerDetalle(ordenId);
    notifyListeners();
  }

  /// Recarga lista + detalle + inventario (que puede haber cambiado).
  Future<void> _refrescar(int? ordenId) async {
    await _recargarOrdenes();
    if (ordenId != null) _detalle = await _db.obtenerDetalle(ordenId);
    await _inventario.cargar();
    notifyListeners();
  }

  // ---------------------------------------------------------------- Órdenes
  Future<int> crearOrden(Orden orden) async {
    final id = await _db.insertarOrden(orden);
    await _clientes.cargar(); // el kilometraje del vehículo cambió
    await _refrescar(id);
    return id;
  }

  Future<void> cambiarEstado(int ordenId, EstadoOrden nuevo) async {
    await _db.cambiarEstado(ordenId, nuevo);
    await _refrescar(ordenId);
  }

  Future<OrdenDetalle> _detalleEditable(int ordenId) async {
    final d = await _db.obtenerDetalle(ordenId);
    if (d == null) throw StateError('La orden no existe.');
    if (!d.resumen.estado.abierta) {
      throw StateError(
          'Solo se puede modificar una orden abierta. Cambia su estado para reabrirla.');
    }
    return d;
  }

  // ------------------------------------------------------------ Mano de obra
  Future<void> agregarTrabajo(
      int ordenId, String descripcion, double precio) async {
    await _detalleEditable(ordenId);
    if (precio <= 0) throw StateError('El precio debe ser mayor que cero.');
    await _db.insertarTrabajo(
        Trabajo(ordenId: ordenId, descripcion: descripcion, precio: precio));
    await _refrescar(ordenId);
  }

  Future<void> eliminarTrabajo(int ordenId, Trabajo trabajo) async {
    final d = await _detalleEditable(ordenId);
    if (d.resumen.total - trabajo.precio < d.resumen.pagado - 0.005) {
      throw StateError(
          'No puedes quitar este trabajo: el total quedaría por debajo de lo ya pagado.');
    }
    await _db.eliminarTrabajo(trabajo.id!);
    await _refrescar(ordenId);
  }

  // --------------------------------------------------------------- Repuestos
  /// Agrega el repuesto a la orden y descuenta las existencias.
  Future<void> agregarRepuesto(
      int ordenId, int repuestoId, int cantidad) async {
    await _detalleEditable(ordenId);
    await _db.agregarRepuestoAOrden(
        ordenId: ordenId, repuestoId: repuestoId, cantidad: cantidad);
    await _refrescar(ordenId);
  }

  /// Quita la línea y devuelve las unidades al inventario.
  Future<void> quitarRepuesto(int ordenId, int lineaId, double subtotal) async {
    final d = await _detalleEditable(ordenId);
    if (d.resumen.total - subtotal < d.resumen.pagado - 0.005) {
      throw StateError(
          'No puedes quitar este repuesto: el total quedaría por debajo de lo ya pagado.');
    }
    await _db.quitarRepuestoDeOrden(lineaId);
    await _refrescar(ordenId);
  }

  // ------------------------------------------------------------------- Pagos
  Future<void> registrarPago(int ordenId, double monto, String? nota) async {
    if (monto <= 0) throw StateError('El monto debe ser mayor que cero.');
    final d = await _db.obtenerDetalle(ordenId);
    if (d == null) throw StateError('La orden no existe.');
    if (d.resumen.estado == EstadoOrden.cancelada) {
      throw StateError('No se pueden registrar pagos en una orden cancelada.');
    }
    if (monto > d.resumen.saldo + 0.005) {
      throw StateError(
          'El pago (${Formato.moneda(monto)}) excede el saldo pendiente (${Formato.moneda(d.resumen.saldo)}).');
    }
    await _db.insertarPago(Pago(
      ordenId: ordenId,
      monto: monto,
      fecha: DateTime.now(),
      nota: (nota == null || nota.trim().isEmpty) ? null : nota.trim(),
    ));
    await _refrescar(ordenId);
  }

  Future<void> eliminarPago(int ordenId, int pagoId) async {
    await _db.eliminarPago(pagoId);
    await _refrescar(ordenId);
  }
}
