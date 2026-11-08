import 'package:flutter/foundation.dart';

import '../db/database_helper.dart';
import '../models/cliente.dart';
import '../models/vehiculo.dart';

class ClienteProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Cliente> _clientes = [];
  List<Vehiculo> _vehiculos = [];
  bool _cargando = true;

  List<Cliente> get clientes => List.unmodifiable(_clientes);
  List<Vehiculo> get vehiculos => List.unmodifiable(_vehiculos);
  bool get cargando => _cargando;

  Future<void> cargar() async {
    _clientes = await _db.obtenerClientes();
    _vehiculos = await _db.obtenerVehiculos();
    _cargando = false;
    notifyListeners();
  }

  List<Vehiculo> vehiculosDe(int clienteId) =>
      _vehiculos.where((v) => v.clienteId == clienteId).toList();

  Cliente? clientePorId(int id) {
    for (final c in _clientes) {
      if (c.id == id) return c;
    }
    return null;
  }

  Vehiculo? vehiculoPorId(int id) {
    for (final v in _vehiculos) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Inserta o actualiza. Devuelve el id del cliente.
  Future<int> guardarCliente(Cliente c) async {
    final int id;
    if (c.id == null) {
      id = await _db.insertarCliente(c);
    } else {
      await _db.actualizarCliente(c);
      id = c.id!;
    }
    await cargar();
    return id;
  }

  Future<void> eliminarCliente(int id) async {
    if (vehiculosDe(id).isNotEmpty) {
      throw StateError(
          'No se puede eliminar un cliente que tiene vehículos registrados.');
    }
    await _db.eliminarCliente(id);
    await cargar();
  }

  /// Inserta o actualiza. Devuelve el id del vehículo.
  Future<int> guardarVehiculo(Vehiculo v) async {
    final int id;
    if (v.id == null) {
      id = await _db.insertarVehiculo(v);
    } else {
      await _db.actualizarVehiculo(v);
      id = v.id!;
    }
    await cargar();
    return id;
  }

  Future<void> eliminarVehiculo(int id) async {
    await _db.eliminarVehiculo(id);
    await cargar();
  }
}
