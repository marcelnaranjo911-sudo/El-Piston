class Mecanico {
  final int? id;
  final String nombre;

  const Mecanico({this.id, required this.nombre});

  Map<String, Object?> toMap() => {'nombre': nombre};

  factory Mecanico.fromMap(Map<String, Object?> m) =>
      Mecanico(id: m['id'] as int?, nombre: m['nombre'] as String);
}
