class Vehiculo {
  final int? id;
  final int clienteId;
  final String matricula;
  final String marca;
  final String modelo;
  final int anio;
  final int kilometraje; // kilometraje de la última visita

  const Vehiculo({
    this.id,
    required this.clienteId,
    required this.matricula,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.kilometraje,
  });

  String get descripcion => '$marca $modelo $anio';

  Map<String, Object?> toMap() => {
        'cliente_id': clienteId,
        'matricula': matricula,
        'marca': marca,
        'modelo': modelo,
        'anio': anio,
        'kilometraje': kilometraje,
      };

  factory Vehiculo.fromMap(Map<String, Object?> m) => Vehiculo(
        id: m['id'] as int?,
        clienteId: m['cliente_id'] as int,
        matricula: m['matricula'] as String,
        marca: m['marca'] as String,
        modelo: m['modelo'] as String,
        anio: (m['anio'] as num).toInt(),
        kilometraje: (m['kilometraje'] as num).toInt(),
      );
}
