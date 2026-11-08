/// Mano de obra asociada a una orden.
class Trabajo {
  final int? id;
  final int ordenId;
  final String descripcion;
  final double precio;

  const Trabajo({
    this.id,
    required this.ordenId,
    required this.descripcion,
    required this.precio,
  });

  Map<String, Object?> toMap() => {
        'orden_id': ordenId,
        'descripcion': descripcion,
        'precio': precio,
      };

  factory Trabajo.fromMap(Map<String, Object?> m) => Trabajo(
        id: m['id'] as int?,
        ordenId: m['orden_id'] as int,
        descripcion: m['descripcion'] as String,
        precio: (m['precio'] as num).toDouble(),
      );
}
