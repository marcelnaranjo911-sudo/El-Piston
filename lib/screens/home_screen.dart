import 'package:flutter/material.dart';

import 'clientes_screen.dart';
import 'dashboard_screen.dart';
import 'inventario_screen.dart';
import 'ordenes_screen.dart';
import 'reportes_screen.dart';

/// Contenedor principal con la barra de navegación inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  Widget _pagina() {
    switch (_indice) {
      case 0:
        return DashboardScreen(onIrA: (i) => setState(() => _indice = i));
      case 1:
        return const OrdenesScreen();
      case 2:
        return const ClientesScreen();
      case 3:
        return const InventarioScreen();
      default:
        return const ReportesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(_indice), child: _pagina()),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Órdenes'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Clientes'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventario'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reportes'),
        ],
      ),
    );
  }
}
