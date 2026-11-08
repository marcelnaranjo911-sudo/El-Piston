import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/orden.dart';
import '../models/orden_repuesto.dart';
import '../models/pago.dart';
import '../models/repuesto.dart';
import '../models/trabajo.dart';
import '../providers/inventario_provider.dart';
import '../providers/orden_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/ui.dart';
import '../widgets/campo_selector.dart';
import '../widgets/dialogos_formulario.dart';
import '../widgets/estado_chip.dart';
import '../widgets/seccion_titulo.dart';

/// Detalle de una orden: estado, mano de obra, repuestos (descuentan stock) y pagos.
class OrdenDetalleScreen extends StatefulWidget {
  const OrdenDetalleScreen({super.key, required this.ordenId});
  final int ordenId;

  @override
  State<OrdenDetalleScreen> createState() => _OrdenDetalleScreenState();
}

class _OrdenDetalleScreenState extends State<OrdenDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrdenProvider>().cargarDetalle(widget.ordenId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OrdenProvider>();
    final d = prov.detalle;

    if (d == null || d.resumen.id != widget.ordenId) {
      return Scaffold(
        appBar: AppBar(title: Text('Orden #${widget.ordenId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final r = d.resumen;
    final editable = r.estado.abierta;
    final puedePagar = r.estado != EstadoOrden.cancelada && r.saldo > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${r.id}'),
        actions: [
          if (r.estado != EstadoOrden.cancelada)
            PopupMenuButton<String>(
              color: AppColors.superficieAlta,
              onSelected: (_) =>
                  cambiarEstadoOrden(context, r, EstadoOrden.cancelada),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'cancelar',
                  child: Row(children: [
                    Icon(Icons.cancel_outlined, color: AppColors.rojo),
                    SizedBox(width: 10),
                    Text('Cancelar orden'),
                  ]),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _encabezado(context, r),
          const SizedBox(height: 16),
          _resumenFinanciero(r),

          // ------------------------------------------------------ Mano de obra
          SeccionTitulo(
            'Mano de obra',
            accion: editable
                ? TextButton.icon(
                    onPressed: () => _dialogoTrabajo(r.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  )
                : null,
          ),
          if (d.trabajos.isEmpty)
            _vacio('Aún no se han registrado trabajos')
          else
            Card(
              child: Column(
                children: [
                  for (final t in d.trabajos)
                    ListTile(
                      leading: const Icon(Icons.handyman_outlined,
                          color: AppColors.naranja),
                      title: Text(t.descripcion),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Formato.moneda(t.precio),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          if (editable)
                            IconButton(
                              tooltip: 'Quitar',
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.textoSecundario),
                              onPressed: () => _quitarTrabajo(r.id, t),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // --------------------------------------------------------- Repuestos
          SeccionTitulo(
            'Repuestos usados',
            accion: editable
                ? TextButton.icon(
                    onPressed: () => _dialogoRepuesto(r.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  )
                : null,
          ),
          if (d.repuestos.isEmpty)
            _vacio('Aún no se han usado repuestos')
          else
            Card(
              child: Column(
                children: [
                  for (final l in d.repuestos)
                    ListTile(
                      leading: const Icon(Icons.settings_outlined,
                          color: AppColors.naranja),
                      title: Text(l.nombre),
                      subtitle: Text(
                          '${l.codigo} · ${l.cantidad} × ${Formato.moneda(l.precioUnitario)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(Formato.moneda(l.subtotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          if (editable)
                            IconButton(
                              tooltip: 'Quitar y devolver al inventario',
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.textoSecundario),
                              onPressed: () => _quitarRepuesto(r.id, l),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // -------------------------------------------------------------- Pagos
          SeccionTitulo(
            'Pagos',
            accion: puedePagar
                ? TextButton.icon(
                    onPressed: () => _dialogoPago(r),
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar pago'),
                  )
                : null,
          ),
          if (d.pagos.isEmpty)
            _vacio('Sin pagos registrados')
          else
            Card(
              child: Column(
                children: [
                  for (final p in d.pagos)
                    ListTile(
                      leading: const Icon(Icons.payments_outlined,
                          color: AppColors.verde),
                      title: Text(Formato.moneda(p.monto),
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${Formato.fechaHora(p.fecha)}${p.nota == null ? '' : ' · ${p.nota}'}',
                      ),
                      trailing: r.estado == EstadoOrden.cancelada
                          ? null
                          : IconButton(
                              tooltip: 'Eliminar pago',
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.textoSecundario),
                              onPressed: () => _quitarPago(r.id, p),
                            ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Secciones
  Widget _vacio(String texto) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(texto,
              style: const TextStyle(color: AppColors.textoSecundario)),
        ),
      );

  Widget _encabezado(BuildContext context, OrdenResumen r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.matricula,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      Text(r.vehiculo,
                          style: const TextStyle(
                              color: AppColors.textoSecundario)),
                    ],
                  ),
                ),
                EstadoChip(r.estado),
              ],
            ),
            const SizedBox(height: 14),
            _fila(Icons.person_outline, 'Cliente', r.clienteNombre),
            _fila(Icons.engineering_outlined, 'Mecánico', r.mecanicoNombre),
            _fila(Icons.calendar_today_outlined, 'Entrada',
                Formato.fecha(r.orden.fechaEntrada)),
            _fila(Icons.speed_outlined, 'Kilometraje', '${r.orden.kilometraje} km'),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Problema reportado',
                style: TextStyle(color: AppColors.textoSecundario, fontSize: 12)),
            const SizedBox(height: 4),
            Text(r.orden.problema),
            if (r.estado != EstadoOrden.cancelada) ...[
              const SizedBox(height: 16),
              const Text('Estado de la orden',
                  style:
                      TextStyle(color: AppColors.textoSecundario, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in EstadoOrden.values
                      .where((e) => e != EstadoOrden.cancelada))
                    ChoiceChip(
                      avatar: Icon(e.icono, size: 16, color: e.color),
                      label: Text(e.etiqueta),
                      selected: r.estado == e,
                      onSelected: (_) => cambiarEstadoOrden(context, r, e),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fila(IconData icono, String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icono, size: 18, color: AppColors.textoSecundario),
            const SizedBox(width: 10),
            SizedBox(
              width: 88,
              child: Text(etiqueta,
                  style: const TextStyle(color: AppColors.textoSecundario)),
            ),
            Expanded(
                child: Text(valor,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Widget _resumenFinanciero(OrdenResumen r) {
    Widget linea(String t, double v, {bool fuerte = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(t,
                    style: TextStyle(
                        fontSize: fuerte ? 16 : 14,
                        fontWeight: fuerte ? FontWeight.w700 : FontWeight.w400,
                        color: fuerte ? null : AppColors.textoSecundario)),
              ),
              Text(Formato.moneda(v),
                  style: TextStyle(
                      fontSize: fuerte ? 18 : 14,
                      fontWeight: fuerte ? FontWeight.w800 : FontWeight.w600,
                      color: color)),
            ],
          ),
        );

    final cancelada = r.estado == EstadoOrden.cancelada;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            linea('Mano de obra', r.manoObra),
            linea('Repuestos', r.repuestos),
            const Divider(height: 16),
            linea('Total', r.total, fuerte: true),
            linea('Pagado', r.pagado, color: AppColors.verde),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (r.tieneSaldo ? AppColors.rojo : AppColors.verde)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    cancelada
                        ? Icons.cancel_outlined
                        : (r.tieneSaldo
                            ? Icons.pending_actions
                            : Icons.check_circle_outline),
                    color: r.tieneSaldo ? AppColors.rojo : AppColors.verde,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cancelada
                          ? 'Orden cancelada'
                          : (r.tieneSaldo ? 'Saldo pendiente' : 'Sin saldo pendiente'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!cancelada)
                    Text(
                      Formato.moneda(r.saldo),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: r.tieneSaldo ? AppColors.rojo : AppColors.verde,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Acciones
  Future<void> _dialogoTrabajo(int ordenId) => showDialog<void>(
        context: context,
        builder: (_) => _DialogoTrabajo(ordenId: ordenId),
      );

  Future<void> _dialogoRepuesto(int ordenId) => showDialog<void>(
        context: context,
        builder: (_) => _DialogoRepuestoOrden(ordenId: ordenId),
      );

  Future<void> _dialogoPago(OrdenResumen r) => showDialog<void>(
        context: context,
        builder: (_) => _DialogoPago(ordenId: r.id, saldo: r.saldo),
      );

  Future<void> _quitarTrabajo(int ordenId, Trabajo t) async {
    final ok = await confirmar(context,
        titulo: 'Quitar trabajo',
        mensaje: '¿Quitar "${t.descripcion}" de la orden?',
        textoConfirmar: 'Quitar');
    if (!ok || !mounted) return;
    await ejecutar(
        context, () => context.read<OrdenProvider>().eliminarTrabajo(ordenId, t));
  }

  Future<void> _quitarRepuesto(int ordenId, OrdenRepuesto l) async {
    final ok = await confirmar(context,
        titulo: 'Quitar repuesto',
        mensaje:
            '¿Quitar ${l.cantidad} × ${l.nombre}? Las unidades volverán al inventario.',
        textoConfirmar: 'Quitar');
    if (!ok || !mounted) return;
    await ejecutar(
        context,
        () => context
            .read<OrdenProvider>()
            .quitarRepuesto(ordenId, l.id!, l.subtotal));
  }

  Future<void> _quitarPago(int ordenId, Pago p) async {
    final ok = await confirmar(context,
        titulo: 'Eliminar pago',
        mensaje: '¿Eliminar el pago de ${Formato.moneda(p.monto)}?',
        textoConfirmar: 'Eliminar');
    if (!ok || !mounted) return;
    await ejecutar(context,
        () => context.read<OrdenProvider>().eliminarPago(ordenId, p.id!));
  }
}

// ------------------------------------------------------------------ Diálogos

class _DialogoTrabajo extends StatefulWidget {
  const _DialogoTrabajo({required this.ordenId});
  final int ordenId;

  @override
  State<_DialogoTrabajo> createState() => _DialogoTrabajoState();
}

class _DialogoTrabajoState extends State<_DialogoTrabajo> {
  final _descripcion = TextEditingController();
  final _precio = TextEditingController();

  @override
  void dispose() {
    _descripcion.dispose();
    _precio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogoFormulario<void>(
      titulo: 'Agregar trabajo',
      campos: [
        TextFormField(
          controller: _descripcion,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              labelText: 'Descripción', hintText: 'Ej. Cambio de aceite'),
          validator: validarRequerido,
        ),
        TextFormField(
          controller: _precio,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Precio de mano de obra', prefixText: '\$ '),
          validator: validarMonto,
        ),
      ],
      onGuardar: () => context.read<OrdenProvider>().agregarTrabajo(
            widget.ordenId,
            _descripcion.text.trim(),
            parseMonto(_precio.text)!,
          ),
    );
  }
}

class _DialogoRepuestoOrden extends StatefulWidget {
  const _DialogoRepuestoOrden({required this.ordenId});
  final int ordenId;

  @override
  State<_DialogoRepuestoOrden> createState() => _DialogoRepuestoOrdenState();
}

class _DialogoRepuestoOrdenState extends State<_DialogoRepuestoOrden> {
  final _cantidad = TextEditingController(text: '1');
  Repuesto? _seleccion;

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = context
        .watch<InventarioProvider>()
        .repuestos
        .where((r) => r.existencias > 0)
        .toList();

    return DialogoFormulario<void>(
      titulo: 'Agregar repuesto',
      campos: [
        CampoSelector<int>(
          etiqueta: 'Repuesto',
          valor: _seleccion?.id,
          items: [
            for (final r in disponibles)
              DropdownMenuItem(
                value: r.id,
                child: Text('${r.nombre} · ${r.existencias} en stock',
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (id) => setState(() {
            _seleccion = disponibles.firstWhere((r) => r.id == id);
          }),
        ),
        if (disponibles.isEmpty)
          const Text('No hay repuestos con existencias en el inventario.',
              style: TextStyle(color: AppColors.rojo)),
        if (_seleccion != null)
          Text(
            'Precio: ${Formato.moneda(_seleccion!.precio)} · Disponibles: ${_seleccion!.existencias}',
            style: const TextStyle(color: AppColors.textoSecundario),
          ),
        TextFormField(
          controller: _cantidad,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cantidad'),
          validator: (v) => validarEntero(v,
              min: 1, max: _seleccion?.existencias),
        ),
      ],
      onGuardar: () async {
        if (_seleccion == null) {
          throw StateError('Selecciona un repuesto.');
        }
        await context.read<OrdenProvider>().agregarRepuesto(
              widget.ordenId,
              _seleccion!.id!,
              int.parse(_cantidad.text.trim()),
            );
      },
    );
  }
}

class _DialogoPago extends StatefulWidget {
  const _DialogoPago({required this.ordenId, required this.saldo});
  final int ordenId;
  final double saldo;

  @override
  State<_DialogoPago> createState() => _DialogoPagoState();
}

class _DialogoPagoState extends State<_DialogoPago> {
  late final _monto =
      TextEditingController(text: widget.saldo.toStringAsFixed(2));
  final _nota = TextEditingController();

  @override
  void dispose() {
    _monto.dispose();
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogoFormulario<void>(
      titulo: 'Registrar pago',
      textoGuardar: 'Registrar',
      campos: [
        Text(
          'Saldo pendiente: ${Formato.moneda(widget.saldo)}',
          style: const TextStyle(color: AppColors.textoSecundario),
        ),
        TextFormField(
          controller: _monto,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
          validator: validarMonto,
        ),
        TextFormField(
          controller: _nota,
          decoration: const InputDecoration(
              labelText: 'Nota (opcional)', hintText: 'Ej. Primer pago, efectivo'),
        ),
      ],
      onGuardar: () => context
          .read<OrdenProvider>()
          .registrarPago(widget.ordenId, parseMonto(_monto.text)!, _nota.text),
    );
  }
}
