/// Línea de repuesto usado en una orden (guarda el precio al momento de usarlo).
class OrdenRepuesto {
  final int? id;
  final int ordenId;
  final int repuestoId;
  final int cantidad;
  final double precioUnitario;
  final String nombre; // viene del JOIN con repuestos
  final String codigo; // viene del JOIN con repuestos

  const OrdenRepuesto({
    this.id,
    required this.ordenId,
    required this.repuestoId,
    required this.cantidad,
    required this.precioUnitario,
    this.nombre = '',
    this.codigo = '',
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, Object?> toMap() => {
        'orden_id': ordenId,
        'repuesto_id': repuestoId,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
      };

  factory OrdenRepuesto.fromMap(Map<String, Object?> m) => OrdenRepuesto(
        id: m['id'] as int?,
        ordenId: m['orden_id'] as int,
        repuestoId: m['repuesto_id'] as int,
        cantidad: (m['cantidad'] as num).toInt(),
        precioUnitario: (m['precio_unitario'] as num).toDouble(),
        nombre: (m['nombre'] as String?) ?? '',
        codigo: (m['codigo'] as String?) ?? '',
      );
}
