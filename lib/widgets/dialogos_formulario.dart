import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cliente.dart';
import '../models/vehiculo.dart';
import '../providers/cliente_provider.dart';
import '../theme/app_theme.dart';
import '../utils/ui.dart';

/// Diálogo de confirmación. Devuelve true si el usuario confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Confirmar',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.rojo, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Diálogo base: valida el formulario, ejecuta [onGuardar] y muestra errores dentro del diálogo.
/// Al terminar cierra el diálogo devolviendo lo que retorne [onGuardar].
class DialogoFormulario<T> extends StatefulWidget {
  const DialogoFormulario({
    super.key,
    required this.titulo,
    required this.campos,
    required this.onGuardar,
    this.textoGuardar = 'Guardar',
  });

  final String titulo;
  final List<Widget> campos;
  final Future<T> Function() onGuardar;
  final String textoGuardar;

  @override
  State<DialogoFormulario<T>> createState() => _DialogoFormularioState<T>();
}

class _DialogoFormularioState<T> extends State<DialogoFormulario<T>> {
  final _form = GlobalKey<FormState>();
  String? _error;
  bool _guardando = false;

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final r = await widget.onGuardar();
      if (mounted) Navigator.of(context).pop(r);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = mensajeDeError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hijos = <Widget>[];
    for (final c in widget.campos) {
      if (hijos.isNotEmpty) hijos.add(const SizedBox(height: 12));
      hijos.add(c);
    }
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ...hijos,
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.rojo)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
              : Text(widget.textoGuardar),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Cliente

/// Crea o edita un cliente. Devuelve el id del cliente guardado (o null si se cancela).
Future<int?> mostrarDialogoCliente(BuildContext context, {Cliente? cliente}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _DialogoCliente(cliente: cliente),
  );
}

class _DialogoCliente extends StatefulWidget {
  const _DialogoCliente({this.cliente});
  final Cliente? cliente;

  @override
  State<_DialogoCliente> createState() => _DialogoClienteState();
}

class _DialogoClienteState extends State<_DialogoCliente> {
  late final _nombre = TextEditingController(text: widget.cliente?.nombre);
  late final _telefono = TextEditingController(text: widget.cliente?.telefono);
  late final _direccion =
      TextEditingController(text: widget.cliente?.direccion);

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogoFormulario<int>(
      titulo: widget.cliente == null ? 'Nuevo cliente' : 'Editar cliente',
      campos: [
        TextFormField(
          controller: _nombre,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: validarRequerido,
        ),
        TextFormField(
          controller: _telefono,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Teléfono'),
          validator: validarRequerido,
        ),
        TextFormField(
          controller: _direccion,
          decoration:
              const InputDecoration(labelText: 'Dirección (opcional)'),
        ),
      ],
      onGuardar: () {
        final dir = _direccion.text.trim();
        return context.read<ClienteProvider>().guardarCliente(Cliente(
              id: widget.cliente?.id,
              nombre: _nombre.text.trim(),
              telefono: _telefono.text.trim(),
              direccion: dir.isEmpty ? null : dir,
            ));
      },
    );
  }
}

// ----------------------------------------------------------------- Vehículo

/// Crea o edita un vehículo de un cliente. Devuelve el id del vehículo (o null si se cancela).
Future<int?> mostrarDialogoVehiculo(
  BuildContext context, {
  required int clienteId,
  Vehiculo? vehiculo,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _DialogoVehiculo(clienteId: clienteId, vehiculo: vehiculo),
  );
}

class _DialogoVehiculo extends StatefulWidget {
  const _DialogoVehiculo({required this.clienteId, this.vehiculo});
  final int clienteId;
  final Vehiculo? vehiculo;

  @override
  State<_DialogoVehiculo> createState() => _DialogoVehiculoState();
}

class _DialogoVehiculoState extends State<_DialogoVehiculo> {
  late final _matricula =
      TextEditingController(text: widget.vehiculo?.matricula);
  late final _marca = TextEditingController(text: widget.vehiculo?.marca);
  late final _modelo = TextEditingController(text: widget.vehiculo?.modelo);
  late final _anio =
      TextEditingController(text: widget.vehiculo?.anio.toString());
  late final _km = TextEditingController(
      text: (widget.vehiculo?.kilometraje ?? 0).toString());

  @override
  void dispose() {
    _matricula.dispose();
    _marca.dispose();
    _modelo.dispose();
    _anio.dispose();
    _km.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogoFormulario<int>(
      titulo: widget.vehiculo == null ? 'Nuevo vehículo' : 'Editar vehículo',
      campos: [
        TextFormField(
          controller: _matricula,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Matrícula'),
          validator: validarRequerido,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _marca,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Marca'),
                validator: validarRequerido,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _modelo,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Modelo'),
                validator: validarRequerido,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _anio,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Año'),
                validator: (v) => validarEntero(v,
                    min: 1950, max: DateTime.now().year + 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _km,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Kilometraje', suffixText: 'km'),
                validator: (v) => validarEntero(v, min: 0),
              ),
            ),
          ],
        ),
      ],
      onGuardar: () => context.read<ClienteProvider>().guardarVehiculo(
            Vehiculo(
              id: widget.vehiculo?.id,
              clienteId: widget.clienteId,
              matricula: _matricula.text.trim().toUpperCase(),
              marca: _marca.text.trim(),
              modelo: _modelo.text.trim(),
              anio: int.parse(_anio.text.trim()),
              kilometraje: int.parse(_km.text.trim()),
            ),
          ),
    );
  }
}
