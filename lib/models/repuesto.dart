class Repuesto {
  /// Con esta cantidad o menos se considera "stock bajo".
  static const int umbralStockBajo = 3;

  final int? id;
  final String nombre;
  final String codigo;
  final double precio;
  final int existencias;

  const Repuesto({
    this.id,
    required this.nombre,
    required this.codigo,
    required this.precio,
    required this.existencias,
  });

  bool get stockBajo => existencias <= umbralStockBajo;
  bool get agotado => existencias <= 0;

  Map<String, Object?> toMap() => {
        'nombre': nombre,
        'codigo': codigo,
        'precio': precio,
        'existencias': existencias,
      };

  factory Repuesto.fromMap(Map<String, Object?> m) => Repuesto(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        codigo: m['codigo'] as String,
        precio: (m['precio'] as num).toDouble(),
        existencias: (m['existencias'] as num).toInt(),
      );
}
