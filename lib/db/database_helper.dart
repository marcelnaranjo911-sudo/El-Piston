import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cliente.dart';
import '../models/mecanico.dart';
import '../models/orden.dart';
import '../models/orden_repuesto.dart';
import '../models/pago.dart';
import '../models/repuesto.dart';
import '../models/reportes.dart';
import '../models/trabajo.dart';
import '../models/vehiculo.dart';

/// Total de una orden (mano de obra + repuestos). Requiere el alias `o` en la consulta.
const String _totalOrdenSql = '''
(COALESCE((SELECT SUM(t.precio) FROM trabajos t WHERE t.orden_id = o.id), 0)
 + COALESCE((SELECT SUM(r.cantidad * r.precio_unitario) FROM orden_repuestos r WHERE r.orden_id = o.id), 0))
''';

const String _selectResumen = '''
SELECT o.*,
       v.matricula AS matricula, v.marca AS marca, v.modelo AS modelo,
       c.id AS cliente_id, c.nombre AS cliente_nombre,
       m.nombre AS mecanico_nombre,
       COALESCE((SELECT SUM(t.precio) FROM trabajos t WHERE t.orden_id = o.id), 0) AS mano_obra,
       COALESCE((SELECT SUM(r.cantidad * r.precio_unitario) FROM orden_repuestos r WHERE r.orden_id = o.id), 0) AS repuestos,
       COALESCE((SELECT SUM(p.monto) FROM pagos p WHERE p.orden_id = o.id), 0) AS pagado
FROM ordenes o
JOIN vehiculos v ON v.id = o.vehiculo_id
JOIN clientes c ON c.id = v.cliente_id
JOIN mecanicos m ON m.id = o.mecanico_id
''';

/// Acceso a SQLite: creación de tablas y CRUD de todas las entidades.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Future<Database>? _dbFuture;
  Future<Database> get database => _dbFuture ??= _abrir();

  Future<Database> _abrir() async {
    final ruta = join(await getDatabasesPath(), 'piston.db');
    return openDatabase(
      ruta,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _crearTablas,
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mecanicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        direccion TEXT
      )''');
    await db.execute('''
      CREATE TABLE vehiculos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        matricula TEXT NOT NULL UNIQUE,
        marca TEXT NOT NULL,
        modelo TEXT NOT NULL,
        anio INTEGER NOT NULL,
        kilometraje INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
      )''');
    await db.execute('''
      CREATE TABLE repuestos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        codigo TEXT NOT NULL UNIQUE,
        precio REAL NOT NULL,
        existencias INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE ordenes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehiculo_id INTEGER NOT NULL,
        mecanico_id INTEGER NOT NULL,
        fecha_entrada TEXT NOT NULL,
        problema TEXT NOT NULL,
        estado TEXT NOT NULL,
        kilometraje INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (vehiculo_id) REFERENCES vehiculos (id),
        FOREIGN KEY (mecanico_id) REFERENCES mecanicos (id)
      )''');
    await db.execute('''
      CREATE TABLE trabajos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orden_id INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        precio REAL NOT NULL,
        FOREIGN KEY (orden_id) REFERENCES ordenes (id) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE orden_repuestos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orden_id INTEGER NOT NULL,
        repuesto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        FOREIGN KEY (orden_id) REFERENCES ordenes (id) ON DELETE CASCADE,
        FOREIGN KEY (repuesto_id) REFERENCES repuestos (id)
      )''');
    await db.execute('''
      CREATE TABLE pagos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orden_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL,
        nota TEXT,
        FOREIGN KEY (orden_id) REFERENCES ordenes (id) ON DELETE CASCADE
      )''');
    await db.execute('CREATE INDEX idx_vehiculos_cliente ON vehiculos (cliente_id)');
    await db.execute('CREATE INDEX idx_ordenes_vehiculo ON ordenes (vehiculo_id)');
    await db.execute('CREATE INDEX idx_ordenes_estado ON ordenes (estado)');
    await db.execute('CREATE INDEX idx_pagos_orden ON pagos (orden_id)');

    // Datos iniciales: los 2 mecánicos del taller y algunos repuestos de ejemplo.
    await db.insert('mecanicos', {'nombre': 'Carlos Méndez'});
    await db.insert('mecanicos', {'nombre': 'Luis Ortega'});
    const ejemplos = [
      ['Aceite 10W-40 (1 L)', 'ACE-001', 8.5, 24],
      ['Filtro de aceite', 'FIL-001', 6.0, 12],
      ['Pastillas de freno delanteras', 'FRE-001', 35.0, 5],
      ['Bujía', 'BUJ-001', 4.0, 3],
      ['Batería 12V', 'BAT-001', 95.0, 2],
    ];
    for (final e in ejemplos) {
      await db.insert('repuestos', {
        'nombre': e[0],
        'codigo': e[1],
        'precio': e[2],
        'existencias': e[3],
      });
    }
  }

  // ---------------------------------------------------------------- Mecánicos
  Future<List<Mecanico>> obtenerMecanicos() async {
    final db = await database;
    final r = await db.query('mecanicos', orderBy: 'nombre');
    return r.map(Mecanico.fromMap).toList();
  }

  // ----------------------------------------------------------------- Clientes
  Future<int> insertarCliente(Cliente c) async =>
      (await database).insert('clientes', c.toMap());

  Future<int> actualizarCliente(Cliente c) async => (await database)
      .update('clientes', c.toMap(), where: 'id = ?', whereArgs: [c.id]);

  Future<int> eliminarCliente(int id) async =>
      (await database).delete('clientes', where: 'id = ?', whereArgs: [id]);

  Future<List<Cliente>> obtenerClientes() async {
    final db = await database;
    final r = await db.query('clientes', orderBy: 'nombre COLLATE NOCASE');
    return r.map(Cliente.fromMap).toList();
  }

  // ---------------------------------------------------------------- Vehículos
  Future<int> insertarVehiculo(Vehiculo v) async =>
      (await database).insert('vehiculos', v.toMap());

  Future<int> actualizarVehiculo(Vehiculo v) async => (await database)
      .update('vehiculos', v.toMap(), where: 'id = ?', whereArgs: [v.id]);

  Future<int> eliminarVehiculo(int id) async =>
      (await database).delete('vehiculos', where: 'id = ?', whereArgs: [id]);

  Future<List<Vehiculo>> obtenerVehiculos() async {
    final db = await database;
    final r = await db.query('vehiculos', orderBy: 'matricula');
    return r.map(Vehiculo.fromMap).toList();
  }

  // --------------------------------------------------------------- Repuestos
  Future<int> insertarRepuesto(Repuesto r) async =>
      (await database).insert('repuestos', r.toMap());

  Future<int> actualizarRepuesto(Repuesto r) async => (await database)
      .update('repuestos', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  Future<int> eliminarRepuesto(int id) async =>
      (await database).delete('repuestos', where: 'id = ?', whereArgs: [id]);

  Future<List<Repuesto>> obtenerRepuestos() async {
    final db = await database;
    final r = await db.query('repuestos', orderBy: 'nombre COLLATE NOCASE');
    return r.map(Repuesto.fromMap).toList();
  }

  // ------------------------------------------------------------------ Órdenes
  /// Crea la orden y actualiza el kilometraje de la última visita del vehículo.
  Future<int> insertarOrden(Orden o) async {
    final db = await database;
    return db.transaction((txn) async {
      final id = await txn.insert('ordenes', o.toMap());
      await txn.update(
        'vehiculos',
        {'kilometraje': o.kilometraje},
        where: 'id = ?',
        whereArgs: [o.vehiculoId],
      );
      return id;
    });
  }

  /// Todas las órdenes (o solo una) con vehículo, cliente, mecánico y totales.
  Future<List<OrdenResumen>> obtenerOrdenesResumen({int? ordenId}) async {
    final db = await database;
    final filtro = ordenId != null ? 'WHERE o.id = ?' : '';
    final r = await db.rawQuery(
      '$_selectResumen $filtro ORDER BY o.fecha_entrada DESC, o.id DESC',
      ordenId != null ? [ordenId] : null,
    );
    return r.map(OrdenResumen.fromMap).toList();
  }

  Future<OrdenDetalle?> obtenerDetalle(int ordenId) async {
    final db = await database;
    final res = await obtenerOrdenesResumen(ordenId: ordenId);
    if (res.isEmpty) return null;
    final trabajos = await db.query('trabajos',
        where: 'orden_id = ?', whereArgs: [ordenId], orderBy: 'id');
    final repuestos = await db.rawQuery('''
      SELECT r.*, p.nombre AS nombre, p.codigo AS codigo
      FROM orden_repuestos r
      JOIN repuestos p ON p.id = r.repuesto_id
      WHERE r.orden_id = ?
      ORDER BY r.id''', [ordenId]);
    final pagos = await db.query('pagos',
        where: 'orden_id = ?', whereArgs: [ordenId], orderBy: 'fecha DESC, id DESC');
    return OrdenDetalle(
      resumen: res.first,
      trabajos: trabajos.map(Trabajo.fromMap).toList(),
      repuestos: repuestos.map(OrdenRepuesto.fromMap).toList(),
      pagos: pagos.map(Pago.fromMap).toList(),
    );
  }

  /// Cambia el estado. Al cancelar, los repuestos usados vuelven al inventario.
  Future<void> cambiarEstado(int ordenId, EstadoOrden nuevo) async {
    final db = await database;
    await db.transaction((txn) async {
      final r = await txn.query('ordenes',
          columns: ['estado'], where: 'id = ?', whereArgs: [ordenId]);
      if (r.isEmpty) throw StateError('La orden no existe.');
      final actual = EstadoOrden.desdeNombre(r.first['estado'] as String);
      if (actual == nuevo) return;
      if (actual == EstadoOrden.cancelada) {
        throw StateError('La orden está cancelada y no puede cambiar de estado.');
      }
      if (nuevo == EstadoOrden.cancelada) {
        final pagos = await txn.rawQuery(
            'SELECT COUNT(*) AS n FROM pagos WHERE orden_id = ?', [ordenId]);
        if ((pagos.first['n'] as num).toInt() > 0) {
          throw StateError(
              'No se puede cancelar una orden con pagos registrados. Elimina los pagos primero.');
        }
        final lineas = await txn
            .query('orden_repuestos', where: 'orden_id = ?', whereArgs: [ordenId]);
        for (final l in lineas) {
          await txn.rawUpdate(
            'UPDATE repuestos SET existencias = existencias + ? WHERE id = ?',
            [l['cantidad'], l['repuesto_id']],
          );
        }
      }
      await txn.update('ordenes', {'estado': nuevo.name},
          where: 'id = ?', whereArgs: [ordenId]);
    });
  }

  // ----------------------------------------------------------------- Trabajos
  Future<int> insertarTrabajo(Trabajo t) async =>
      (await database).insert('trabajos', t.toMap());

  Future<int> eliminarTrabajo(int id) async =>
      (await database).delete('trabajos', where: 'id = ?', whereArgs: [id]);

  // ------------------------------------------------- Repuestos usados en orden
  /// Agrega un repuesto a la orden y descuenta las existencias (en una transacción).
  Future<void> agregarRepuestoAOrden({
    required int ordenId,
    required int repuestoId,
    required int cantidad,
  }) async {
    if (cantidad <= 0) throw StateError('La cantidad debe ser mayor que cero.');
    final db = await database;
    await db.transaction((txn) async {
      final rep = await txn
          .query('repuestos', where: 'id = ?', whereArgs: [repuestoId]);
      if (rep.isEmpty) throw StateError('El repuesto no existe.');
      final existencias = (rep.first['existencias'] as num).toInt();
      if (existencias < cantidad) {
        throw StateError('Existencias insuficientes: quedan $existencias.');
      }
      final precio = (rep.first['precio'] as num).toDouble();
      final linea = await txn.query(
        'orden_repuestos',
        where: 'orden_id = ? AND repuesto_id = ? AND precio_unitario = ?',
        whereArgs: [ordenId, repuestoId, precio],
      );
      if (linea.isNotEmpty) {
        await txn.rawUpdate(
          'UPDATE orden_repuestos SET cantidad = cantidad + ? WHERE id = ?',
          [cantidad, linea.first['id']],
        );
      } else {
        await txn.insert('orden_repuestos', {
          'orden_id': ordenId,
          'repuesto_id': repuestoId,
          'cantidad': cantidad,
          'precio_unitario': precio,
        });
      }
      await txn.rawUpdate(
        'UPDATE repuestos SET existencias = existencias - ? WHERE id = ?',
        [cantidad, repuestoId],
      );
    });
  }

  /// Quita una línea de repuesto de la orden y devuelve las unidades al inventario.
  Future<void> quitarRepuestoDeOrden(int lineaId) async {
    final db = await database;
    await db.transaction((txn) async {
      final l = await txn
          .query('orden_repuestos', where: 'id = ?', whereArgs: [lineaId]);
      if (l.isEmpty) return;
      await txn.rawUpdate(
        'UPDATE repuestos SET existencias = existencias + ? WHERE id = ?',
        [l.first['cantidad'], l.first['repuesto_id']],
      );
      await txn.delete('orden_repuestos', where: 'id = ?', whereArgs: [lineaId]);
    });
  }

  // -------------------------------------------------------------------- Pagos
  Future<int> insertarPago(Pago p) async =>
      (await database).insert('pagos', p.toMap());

  Future<int> eliminarPago(int id) async =>
      (await database).delete('pagos', where: 'id = ?', whereArgs: [id]);

  // ----------------------------------------------------------------- Reportes
  /// Facturado = total de las órdenes (no canceladas) ingresadas en el período.
  /// Cobrado = pagos recibidos en el período.
  Future<ResumenPeriodo> totalesPeriodo(DateTime desde, DateTime hasta) async {
    final db = await database;
    final ini = desde.toIso8601String();
    final fin = hasta.toIso8601String();
    final f = await db.rawQuery('''
      SELECT COUNT(*) AS n, COALESCE(SUM($_totalOrdenSql), 0) AS total
      FROM ordenes o
      WHERE o.estado != 'cancelada' AND o.fecha_entrada BETWEEN ? AND ?''',
        [ini, fin]);
    final c = await db.rawQuery('''
      SELECT COALESCE(SUM(p.monto), 0) AS cobrado
      FROM pagos p JOIN ordenes o ON o.id = p.orden_id
      WHERE o.estado != 'cancelada' AND p.fecha BETWEEN ? AND ?''', [ini, fin]);
    return ResumenPeriodo(
      ordenes: (f.first['n'] as num).toInt(),
      facturado: (f.first['total'] as num).toDouble(),
      cobrado: (c.first['cobrado'] as num).toDouble(),
    );
  }

  Future<List<CargaMecanico>> cargaPorMecanico(
      DateTime desde, DateTime hasta) async {
    final db = await database;
    final ini = desde.toIso8601String();
    final fin = hasta.toIso8601String();
    final r = await db.rawQuery('''
      SELECT m.id AS id, m.nombre AS nombre,
        (SELECT COUNT(*) FROM ordenes o
          WHERE o.mecanico_id = m.id AND o.estado NOT IN ('entregada', 'cancelada')) AS abiertas,
        (SELECT COUNT(*) FROM ordenes o
          WHERE o.mecanico_id = m.id AND o.estado != 'cancelada'
            AND o.fecha_entrada BETWEEN ? AND ?) AS en_periodo,
        (SELECT COALESCE(SUM($_totalOrdenSql), 0) FROM ordenes o
          WHERE o.mecanico_id = m.id AND o.estado != 'cancelada'
            AND o.fecha_entrada BETWEEN ? AND ?) AS facturado
      FROM mecanicos m
      ORDER BY m.nombre''', [ini, fin, ini, fin]);
    return r
        .map((m) => CargaMecanico(
              id: m['id'] as int,
              nombre: m['nombre'] as String,
              abiertas: (m['abiertas'] as num).toInt(),
              enPeriodo: (m['en_periodo'] as num).toInt(),
              facturado: (m['facturado'] as num).toDouble(),
            ))
        .toList();
  }
}
