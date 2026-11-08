import 'orden_repuesto.dart';
import 'pago.dart';
import 'trabajo.dart';

enum EstadoOrden {
  recibida('Recibida'),
  enDiagnostico('En diagnóstico'),
  enReparacion('En reparación'),
  listaParaEntregar('Lista para entregar'),
  entregada('Entregada'),
  cancelada('Cancelada');

  const EstadoOrden(this.etiqueta);
  final String etiqueta;

  /// Una orden está "abierta" mientras no se entregue ni se cancele.
  bool get abierta => this != entregada && this != cancelada;

  static EstadoOrden desdeNombre(String nombre) => EstadoOrden.values
      .firstWhere((e) => e.name == nombre, orElse: () => EstadoOrden.recibida);
}

class Orden {
  final int? id;
  final int vehiculoId;
  final int mecanicoId;
  final DateTime fechaEntrada;
  final String problema;
  final EstadoOrden estado;
  final int kilometraje; // km del vehículo al ingresar

  const Orden({
    this.id,
    required this.vehiculoId,
    required this.mecanicoId,
    required this.fechaEntrada,
    required this.problema,
    required this.estado,
    required this.kilometraje,
  });

  Map<String, Object?> toMap() => {
        'vehiculo_id': vehiculoId,
        'mecanico_id': mecanicoId,
        'fecha_entrada': fechaEntrada.toIso8601String(),
        'problema': problema,
        'estado': estado.name,
        'kilometraje': kilometraje,
      };

  factory Orden.fromMap(Map<String, Object?> m) => Orden(
        id: m['id'] as int?,
        vehiculoId: m['vehiculo_id'] as int,
        mecanicoId: m['mecanico_id'] as int,
        fechaEntrada: DateTime.parse(m['fecha_entrada'] as String),
        problema: m['problema'] as String,
        estado: EstadoOrden.desdeNombre(m['estado'] as String),
        kilometraje: (m['kilometraje'] as num).toInt(),
      );
}

/// Orden con datos del vehículo, cliente, mecánico y totales ya calculados.
class OrdenResumen {
  final Orden orden;
  final String matricula;
  final String marca;
  final String modelo;
  final int clienteId;
  final String clienteNombre;
  final String mecanicoNombre;
  final double manoObra;
  final double repuestos;
  final double pagado;

  const OrdenResumen({
    required this.orden,
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.clienteId,
    required this.clienteNombre,
    required this.mecanicoNombre,
    required this.manoObra,
    required this.repuestos,
    required this.pagado,
  });

  int get id => orden.id!;
  EstadoOrden get estado => orden.estado;
  String get vehiculo => '$marca $modelo';

  /// Total = mano de obra + repuestos.
  double get total => manoObra + repuestos;

  /// Saldo pendiente (0 si está cancelada o ya se pagó todo).
  double get saldo {
    if (estado == EstadoOrden.cancelada) return 0;
    final s = total - pagado;
    return s > 0.005 ? s : 0;
  }

  bool get tieneSaldo => saldo > 0;

  factory OrdenResumen.fromMap(Map<String, Object?> m) => OrdenResumen(
        orden: Orden.fromMap(m),
        matricula: m['matricula'] as String,
        marca: m['marca'] as String,
        modelo: m['modelo'] as String,
        clienteId: m['cliente_id'] as int,
        clienteNombre: m['cliente_nombre'] as String,
        mecanicoNombre: m['mecanico_nombre'] as String,
        manoObra: (m['mano_obra'] as num).toDouble(),
        repuestos: (m['repuestos'] as num).toDouble(),
        pagado: (m['pagado'] as num).toDouble(),
      );
}

/// Todo lo que muestra la pantalla de detalle de una orden.
class OrdenDetalle {
  final OrdenResumen resumen;
  final List<Trabajo> trabajos;
  final List<OrdenRepuesto> repuestos;
  final List<Pago> pagos;

  const OrdenDetalle({
    required this.resumen,
    required this.trabajos,
    required this.repuestos,
    required this.pagos,
  });
}
