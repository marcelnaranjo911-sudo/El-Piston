# El Pistón — Gestión de taller mecánico

Aplicación móvil (Flutter) **offline-first** para el taller "El Pistón": clientes, vehículos,
órdenes de servicio, mano de obra, repuestos, inventario, pagos parciales y reportes.
Toda la información se guarda en una base de datos SQLite local, así que funciona sin
conexión y conserva los datos aunque la aplicación se cierre.

Asignatura: Programación para Dispositivos Móviles · Actividad individual.

## Cómo ejecutarla

```bash
flutter pub get
flutter run            # Android/iOS o escritorio (Windows/Linux/macOS)
```

Dependencias: `provider`, `sqflite`, `path`, `intl`, `flutter_localizations` y
`sqflite_common_ffi` (solo para poder probar en escritorio).

## Pantallas

| Pantalla | Qué hace |
|---|---|
| **Inicio (dashboard)** | Órdenes abiertas, ingresos del mes, total por cobrar, alertas de stock bajo, órdenes por estado y las más recientes. Todo es "tocable" y lleva a la pantalla correspondiente. |
| **Órdenes** | Lista filtrable (Abiertas / Todas / por estado) y cambio de estado rápido desde cada tarjeta. |
| **Nueva orden** | Vehículo, mecánico, kilometraje, fecha y problema. Permite registrar cliente y vehículo nuevos sin salir del formulario. |
| **Detalle de orden** | Cambio de estado, mano de obra, repuestos usados (descuentan stock), pagos parciales y saldo pendiente. |
| **Clientes y vehículos** | Búsqueda por nombre, teléfono o matrícula; saldo pendiente por cliente; vehículos con su historial de visitas. |
| **Inventario** | Alta, edición y baja de repuestos; indicador visual de stock bajo/agotado. |
| **Reportes** | Facturación y carga de trabajo por mecánico en un rango de fechas, órdenes abiertas por estado, cuentas por cobrar y repuestos por agotarse. |

## Decisiones de diseño

**Arquitectura.** Capas separadas: `models` (clases + `toMap/fromMap`), `db` (SQLite y CRUD),
`providers` (lógica de negocio con Provider), `screens` y `widgets`. Las pantallas no
tocan SQL.

**Datos.** Tablas: `mecanicos`, `clientes`, `vehiculos`, `repuestos`, `ordenes`, `trabajos`,
`orden_repuestos` y `pagos`, con claves foráneas activadas. Los totales (mano de obra,
repuestos, pagado) se calculan con consultas, no se guardan, para que nunca queden
desincronizados.

**Reglas de negocio.**
- *Total de la orden = mano de obra + repuestos.* Saldo = total − pagado.
- *Pagos parciales:* no se acepta un pago mayor al saldo pendiente.
- *Inventario:* agregar un repuesto a una orden descuenta las existencias dentro de una
  transacción; no se puede usar más de lo que hay. Quitar la línea devuelve las unidades.
- *Precio congelado:* cada línea de repuesto guarda el precio del momento, así que cambiar
  el precio en el inventario no altera órdenes ya registradas.
- *Stock bajo:* 3 unidades o menos (constante `Repuesto.umbralStockBajo`).
- *Estados:* Recibida → En diagnóstico → En reparación → Lista para entregar → Entregada,
  o Cancelada. Una orden **cancelada** es definitiva: devuelve los repuestos al inventario
  y no cuenta en saldos ni facturación (no se puede cancelar si ya tiene pagos). Una orden
  **entregada** no admite cambios de trabajos/repuestos salvo que se reabra cambiando su estado;
  los pagos sí se pueden seguir registrando mientras haya saldo.
- *Kilometraje:* cada orden guarda el km de ingreso y actualiza el "km de la última visita"
  del vehículo.
- *Mecánicos:* los dos mecánicos se crean al inicializar la base de datos. Al crear una orden
  se sugiere el que tenga menos órdenes abiertas.
- *Facturación de un período:* suma el total de las órdenes ingresadas en esas fechas
  (sin canceladas). Además se muestra lo **cobrado** (pagos recibidos en ese rango).
  "Ingresos del mes" del inicio es lo cobrado en el mes actual.

**Experiencia de usuario.** Tema oscuro (negro y naranja) con Material 3, tarjetas redondeadas,
chips de estado con color e ícono, navegación inferior de 5 secciones, buscadores, estados
vacíos explicativos, confirmación antes de acciones destructivas, mensajes de error claros
(p. ej. "Existencias insuficientes: quedan 2") y, tras crear una orden, se abre su detalle
para registrar enseguida el trabajo. Interfaz y fechas en español.

## Estructura

```
lib/
├── main.dart
├── theme/app_theme.dart
├── utils/            formato.dart, ui.dart
├── models/           cliente, vehiculo, orden, trabajo, orden_repuesto, repuesto, pago, mecanico, reportes
├── db/database_helper.dart
├── providers/        cliente, inventario, orden, reporte
├── screens/          home, dashboard, ordenes, orden_form, orden_detalle,
│                     clientes, cliente_detalle, inventario, reportes
└── widgets/          estado_chip, stat_card, orden_card, seccion_titulo,
                      estado_vacio, campo_selector, dialogos_formulario
```

## Capturas

Ver la carpeta [`capturas/`](capturas/).

