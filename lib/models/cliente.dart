class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String? direccion;

  const Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    this.direccion,
  });

  Map<String, Object?> toMap() => {
        'nombre': nombre,
        'telefono': telefono,
        'direccion': direccion,
      };

  factory Cliente.fromMap(Map<String, Object?> m) => Cliente(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        telefono: m['telefono'] as String,
        direccion: m['direccion'] as String?,
      );
}
