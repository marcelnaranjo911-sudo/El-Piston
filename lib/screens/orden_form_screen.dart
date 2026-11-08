import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/orden.dart';
import '../providers/cliente_provider.dart';
import '../providers/orden_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/ui.dart';
import '../widgets/campo_selector.dart';
import '../widgets/dialogos_formulario.dart';
import 'orden_detalle_screen.dart';

/// Registro de una nueva orden de servicio (nueva visita de un vehículo).
class OrdenFormScreen extends StatefulWidget {
  const OrdenFormScreen({super.key, this.vehiculoId});

  /// Si se indica, el vehículo queda preseleccionado.
  final int? vehiculoId;

  @override
  State<OrdenFormScreen> createState() => _OrdenFormScreenState();
}

class _OrdenFormScreenState extends State<OrdenFormScreen> {
  final _form = GlobalKey<FormState>();
  final _problema = TextEditingController();
  final _km = TextEditingController();
  int? _vehiculoId;
  int? _mecanicoId;
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Se sugiere el mecánico con menos órdenes abiertas.
      setState(() => _mecanicoId = context.read<OrdenProvider>().mecanicoMenosCargado());
      if (widget.vehiculoId != null) _seleccionarVehiculo(widget.vehiculoId);
    });
  }

  @override
  void dispose() {
    _problema.dispose();
    _km.dispose();
    super.dispose();
  }

  void _seleccionarVehiculo(int? id) {
    setState(() => _vehiculoId = id);
    if (id == null) return;
    final v = context.read<ClienteProvider>().vehiculoPorId(id);
    if (v != null) _km.text = v.kilometraje.toString();
  }

  Future<void> _nuevoClienteYVehiculo() async {
    final clienteId = await mostrarDialogoCliente(context);
    if (clienteId == null || !mounted) return;
    final vehiculoId =
        await mostrarDialogoVehiculo(context, clienteId: clienteId);
    if (vehiculoId == null || !mounted) return;
    _seleccionarVehiculo(vehiculoId);
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (f != null) {
      setState(() => _fecha = DateTime(f.year, f.month, f.day,
          DateTime.now().hour, DateTime.now().minute));
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (_vehiculoId == null || _mecanicoId == null) {
      mostrarMensaje(context, 'Selecciona un vehículo y un mecánico',
          error: true);
      return;
    }
    setState(() => _guardando = true);
    final prov = context.read<OrdenProvider>();
    final nav = Navigator.of(context);
    try {
      final id = await prov.crearOrden(Orden(
        vehiculoId: _vehiculoId!,
        mecanicoId: _mecanicoId!,
        fechaEntrada: _fecha,
        problema: _problema.text.trim(),
        estado: EstadoOrden.recibida,
        kilometraje: int.parse(_km.text.trim()),
      ));
      if (!mounted) return;
      // Se abre el detalle para registrar enseguida el trabajo y los repuestos.
      nav.pushReplacement(MaterialPageRoute(
          builder: (_) => OrdenDetalleScreen(ordenId: id)));
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        mostrarMensaje(context, mensajeDeError(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientes = context.watch<ClienteProvider>();
    final mecanicos = context.watch<OrdenProvider>().mecanicos;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva orden')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CampoSelector<int>(
              etiqueta: 'Vehículo',
              icono: Icons.directions_car_outlined,
              valor: _vehiculoId,
              items: [
                for (final v in clientes.vehiculos)
                  DropdownMenuItem(
                    value: v.id,
                    child: Text(
                      '${v.matricula} · ${v.marca} ${v.modelo} — ${clientes.clientePorId(v.clienteId)?.nombre ?? ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _seleccionarVehiculo,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _nuevoClienteYVehiculo,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('¿Cliente o vehículo nuevo? Regístralo aquí'),
              ),
            ),
            const SizedBox(height: 8),
            CampoSelector<int>(
              etiqueta: 'Mecánico asignado',
              icono: Icons.engineering_outlined,
              valor: _mecanicoId,
              items: [
                for (final m in mecanicos)
                  DropdownMenuItem(value: m.id, child: Text(m.nombre)),
              ],
              onChanged: (v) => setState(() => _mecanicoId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _km,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometraje actual',
                suffixText: 'km',
                prefixIcon: Icon(Icons.speed_outlined),
              ),
              validator: (v) => validarEntero(v, min: 0),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _elegirFecha,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de entrada',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(Formato.fecha(_fecha)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _problema,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Problema reportado por el cliente',
                alignLabelWithHint: true,
              ),
              validator: validarRequerido,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.check),
              label: const Text('Registrar orden'),
            ),
            const SizedBox(height: 8),
            const Text(
              'La orden se crea en estado "Recibida".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textoSecundario, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
