class Pago {
  final int? id;
  final int ordenId;
  final double monto;
  final DateTime fecha;
  final String? nota;

  const Pago({
    this.id,
    required this.ordenId,
    required this.monto,
    required this.fecha,
    this.nota,
  });

  Map<String, Object?> toMap() => {
        'orden_id': ordenId,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'nota': nota,
      };

  factory Pago.fromMap(Map<String, Object?> m) => Pago(
        id: m['id'] as int?,
        ordenId: m['orden_id'] as int,
        monto: (m['monto'] as num).toDouble(),
        fecha: DateTime.parse(m['fecha'] as String),
        nota: m['nota'] as String?,
      );
}
