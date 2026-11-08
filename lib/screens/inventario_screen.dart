import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/repuesto.dart';
import '../providers/inventario_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../utils/ui.dart';
import '../widgets/dialogos_formulario.dart';
import '../widgets/estado_vacio.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String _busqueda = '';
  bool _soloBajo = false;

  Future<void> _eliminar(Repuesto r) async {
    final ok = await confirmar(context,
        titulo: 'Eliminar repuesto',
        mensaje:
            '¿Eliminar "${r.nombre}"? Solo es posible si no se ha usado en ninguna orden.',
        textoConfirmar: 'Eliminar');
    if (!ok || !mounted) return;
    await ejecutar(
        context, () => context.read<InventarioProvider>().eliminar(r.id!),
        exito: 'Repuesto eliminado');
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventarioProvider>();
    final bajo = inv.bajoStock;
    final q = _busqueda.trim().toLowerCase();
    final lista = inv.repuestos.where((r) {
      if (_soloBajo && !r.stockBajo) return false;
      return q.isEmpty ||
          r.nombre.toLowerCase().contains(q) ||
          r.codigo.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
            context: context, builder: (_) => const _DialogoRepuesto()),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo repuesto'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  avatar: Icon(Icons.warning_amber_rounded,
                      size: 18,
                      color: bajo.isEmpty
                          ? AppColors.textoSecundario
                          : AppColors.amarillo),
                  label: Text('Stock bajo (${bajo.length})'),
                  selected: _soloBajo,
                  onSelected: (v) => setState(() => _soloBajo = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: inv.cargando
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.inventory_2_outlined,
                        titulo: 'No hay repuestos para mostrar')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: lista.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) => _TarjetaRepuesto(
                          repuesto: lista[i],
                          onEditar: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                _DialogoRepuesto(repuesto: lista[i]),
                          ),
                          onEliminar: () => _eliminar(lista[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaRepuesto extends StatelessWidget {
  const _TarjetaRepuesto({
    required this.repuesto,
    required this.onEditar,
    required this.onEliminar,
  });

  final Repuesto repuesto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final r = repuesto;
    final color = r.agotado
        ? AppColors.rojo
        : (r.stockBajo ? AppColors.amarillo : AppColors.verde);
    final estado = r.agotado ? 'Agotado' : (r.stockBajo ? 'Stock bajo' : 'En stock');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  r.stockBajo ? Icons.warning_amber_rounded : Icons.inventory_2,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nombre,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${r.codigo} · ${Formato.moneda(r.precio)}',
                        style: const TextStyle(
                            color: AppColors.textoSecundario, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${r.existencias}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  Text(estado, style: TextStyle(color: color, fontSize: 11)),
                ],
              ),
              PopupMenuButton<String>(
                color: AppColors.superficieAlta,
                onSelected: (v) => v == 'editar' ? onEditar() : onEliminar(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogoRepuesto extends StatefulWidget {
  const _DialogoRepuesto({this.repuesto});
  final Repuesto? repuesto;

  @override
  State<_DialogoRepuesto> createState() => _DialogoRepuestoState();
}

class _DialogoRepuestoState extends State<_DialogoRepuesto> {
  late final _nombre = TextEditingController(text: widget.repuesto?.nombre);
  late final _codigo = TextEditingController(text: widget.repuesto?.codigo);
  late final _precio = TextEditingController(
      text: widget.repuesto?.precio.toStringAsFixed(2));
  late final _existencias = TextEditingController(
      text: (widget.repuesto?.existencias ?? 0).toString());

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    _precio.dispose();
    _existencias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogoFormulario<void>(
      titulo: widget.repuesto == null ? 'Nuevo repuesto' : 'Editar repuesto',
      campos: [
        TextFormField(
          controller: _nombre,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: validarRequerido,
        ),
        TextFormField(
          controller: _codigo,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Código'),
          validator: validarRequerido,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _precio,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Precio de venta', prefixText: '\$ '),
                validator: (v) => validarMonto(v, permitirCero: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _existencias,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Existencias'),
                validator: (v) => validarEntero(v, min: 0),
              ),
            ),
          ],
        ),
        Text(
          'Se avisa de stock bajo con ${Repuesto.umbralStockBajo} unidades o menos.',
          style: const TextStyle(color: AppColors.textoSecundario, fontSize: 12),
        ),
      ],
      onGuardar: () => context.read<InventarioProvider>().guardar(Repuesto(
            id: widget.repuesto?.id,
            nombre: _nombre.text.trim(),
            codigo: _codigo.text.trim().toUpperCase(),
            precio: parseMonto(_precio.text)!,
            existencias: int.parse(_existencias.text.trim()),
          )),
    );
  }
}
