class ResumenPeriodo {
  final int ordenes; // órdenes ingresadas en el período (sin canceladas)
  final double facturado; // total de esas órdenes
  final double cobrado; // pagos recibidos en el período

  const ResumenPeriodo({
    required this.ordenes,
    required this.facturado,
    required this.cobrado,
  });
}

class CargaMecanico {
  final int id;
  final String nombre;
  final int abiertas; // órdenes abiertas ahora mismo
  final int enPeriodo; // órdenes ingresadas en el período
  final double facturado; // facturación de esas órdenes

  const CargaMecanico({
    required this.id,
    required this.nombre,
    required this.abiertas,
    required this.enPeriodo,
    required this.facturado,
  });
}
